function [cacheData, adjustedCal] = OLCorrectCacheFileOOC(cacheFileNameFullPath, ol, spectroRadiometerOBJ, S, theLJdev, varargin)
%%OLCorrectCacheFileOOC  Use iterated procedure to optimize modulations in a cache file
%
% Usage:
%    [cacheData, adjustedCal] = OLCorrectCacheFileOOC(cacheFileNameFullPath, ol, spectroRadiometerOBJ, S, theLJdev);
%
% Description:
%   Uses an iterated procedure to bring a modulation as close as possible to
%   its specified spectrum.
%
%   At present, this only works for powerLevels 0 (background) and 1 (maximum positive excursion).
%   It could be generalized fairly easily.
%
% Input:
%     cacheFileNameFullPath (string)  - Absolute path full name of the cache file to validate.
%     ol (object)                     - Open OneLight object.
%     spectroRadiometerOBJ (object)   - Object for the measurement meter. Can be passed empty if simulating.
%     S                               - Wavelength sampling for measurements. Can be passed empty if simulating.
%     theLJdev                        - Lab jack device.  Pass empty will skip temperature measurements.
%
% Output:
%     cacheData (struct)              - Contains the results
%     adjustedCal                     - Calibration struct as updated by this routine.
%
% Optional key/value pairs:
%      Keyword                         Default                          Behavior
%
%     'approach'                       ''                               What approach is calling us?
%     'simulate'                       false                            Run in simulation mode.
%     'doCorrection'                   true                             Actually do the correction?  Just copy if false.
%     'observerAgeInYrs'               32                               Observer age to correct for.
%     'noRadiometerAdjustment '        true                             Does not pause to allow aiming of radiometer.
%     'pauseDuration'                  0                                How long to pause (in secs) after radiometer is aimed by user.
%     'calibrationType'                ''                               Calibration type
%     'takeTemperatureMeasurements'    false                            Take temperature measurements? (Requires a connected LabJack dev with a temperature probe.)
%     'takeCalStateMeasurements'       true                             Take OneLight state measurements
%     'verbose'                        false                            Print out things in progress.
%     'nIterations'                    20                               Number of iterations
%     'learningRate'                   0.8                              Learning rate
%     'learningRateDecrease'           true                             Decrease learning rate over iterations?
%     'asympLearningRateFactor'        0.5                              If learningRateDecrease is true, the asymptotic learning rate is (1-asympLearningRateFactor)*learningRate
%     'smoothness'                     0.001                            Smoothness parameter for OLSpdToPrimary
%     'iterativeSearch'                false                            Do iterative search with fmincon on each measurement interation?
%     'nAverage'                       1                                Number of measurements to average for each spectrum measured.

% 1/21/14   dhb, ms  Convert to use OLSettingsToStartsStops.
% 1/30/14   ms       Added keyword parameters to make this useful.
% 7/06/16   npc      Adapted to use PR650dev/PR670dev objects
% 10/20/16  npc      Added ability to record temperature measurements
% 12/21/16  npc      Updated for new class @LJTemperatureProbe
% 01/03/16  dhb      Refactoring, cleaning, documenting.
% 06/05/17  dhb      Remove old style verbose arg from calls to OLSettingsToStartsStops
% 07/27/17  dhb      Massive interface redo.
% 07/29/17  dhb      Pull out radiometer open to one level up.
% 08/09/17  dhb, mab Comment out code that stores difference, just return background and max modulations.
%                    Also, don't try to use the now non-extant difference when we get the input.
% 08/21/17  dhb      Remove useAverageGamma, zeroPrimariesAwayFromPeak parameters.  These should be set in the calibration file and not monkey'd with.

% Parse the input
p = inputParser;
p.addParameter('approach','', @isstr);
p.addParameter('simulate',false,@islogical);
p.addParameter('doCorrection', true, @islogical);
p.addParameter('noRadiometerAdjustment', true, @islogical);
p.addParameter('pauseDuration',0,@inumeric);
p.addParameter('observerAgeInYrs', 32, @isscalar);
p.addParameter('calibrationType','', @isstr);
p.addParameter('takeCalStateMeasurements', false, @islogical);
p.addParameter('takeTemperatureMeasurements', false, @islogical);
p.addParameter('verbose',false,@islogical);
p.addParameter('nIterations', 20, @isscalar);
p.addParameter('learningRate', 0.8, @isscalar);
p.addParameter('learningRateDecrease',true,@islogical);
p.addParameter('asympLearningRateFactor',0.5,@isnumeric);
p.addParameter('smoothness', 0.001, @isscalar);
p.addParameter('iterativeSearch',false, @islogical);
p.addParameter('nAverage',1,@isnumeric);
p.parse(varargin{:});
correctionDescribe = p.Results;

nIterations = p.Results.nIterations;
learningRate = p.Results.learningRate;
learningRateDecrease = p.Results.learningRateDecrease;
asympLearningRateFactor = p.Results.asympLearningRateFactor;
smoothness = p.Results.smoothness;
iterativeSearch = p.Results.iterativeSearch;

%% Check input OK
if (~correctionDescribe.simulate && (isempty(spectroRadiometerOBJ) || isempty(S)))
    error('Must pass radiometer objecta and S, unless simulating');
end

%% Get cached direction data as well as calibration file
[cacheData,adjustedCal] = OLGetCacheAndCalData(cacheFileNameFullPath, correctionDescribe);
if (isempty(S))
    S = adjustedCal.describe.S;
end

%% Get directionStruct to correct
directionStruct = cacheData.data(p.Results.observerAgeInYrs);

%% We might not want to seek
if (~correctionDescribe.doCorrection)
    return;
end

%% Set meterToggle so that we don't use the Omni radiometer in various measuremnt calls below.
meterToggle = [true false]; od = [];

%% Let user get the radiometer set up if desired.
if (~correctionDescribe.noRadiometerAdjustment)
    ol.setAll(true);
    commandwindow;
    fprintf('\tFocus the radiometer and press enter to pause %d seconds and start measuring.\n', correctionDescribe.pauseDuration);
    input('');
    ol.setAll(false);
    pause(correctionDescribe.pauseDuration);
else
    ol.setAll(false);
end

%% Correct
    % Keep time
    startMeas = GetSecs;
    
    % Say hello
    if (correctionDescribe.verbose), fprintf('\tPerforming radiometer measurements\n'); end;    
    
    % State and temperature measurements
    if (~correctionDescribe.simulate && correctionDescribe.takeCalStateMeasurements)
        if (correctionDescribe.verbose), fprintf('\tState measurements\n'); end;
        [~, results.calStateMeas] = OLCalibrator.takeCalStateMeasurements(adjustedCal, ol, od, spectroRadiometerOBJ, meterToggle, correctionDescribe.nAverage, theLJdev, 'standAlone',true);
    else
        results.calStateMeas = [];
    end
    if (~correctionDescribe.simulate && correctionDescribe.takeTemperatureMeasurements & ~isempty(theLJdev))
        [~, results.temperatureMeas] = theLJdev.measure();
    else
        results.temperatureMeas = [];
    end
    
    %% Correct direction struct
    correctedDirectionStruct = OLCorrectDirection(directionStruct, adjustedCal, ol, spectroRadiometerOBJ,...
        'nIterations', nIterations,... 
        'learningRate', learningRate,...
        'learningRateDecrease',  learningRateDecrease,...
        'asympLearningRateFactor', asympLearningRateFactor,...
        'smoothness', smoothness,...
        'iterativeSearch', iterativeSearch);

    %% Store information about corrected modulations for return.
    % Since this routine only does the correction for one age, we set the data for that and zero out all
    % the rest, just to avoid accidently thinking we have corrected spectra where we do not.
    for ii = 1:length(cacheData.data)
        if ii == correctionDescribe.observerAgeInYrs
            cacheData.data(ii) = correctedDirectionStruct;
%             cacheData.data(ii).correctionDescribe = correctionDescribe;
%             cacheData.data(ii).cal = adjustedCal;
%             cacheData.data(ii).correction.kScale = dataBackground.correction.kScale;
%             cacheData.data(ii).backgroundPrimary = dataBackground.Primary;
%             cacheData.data(ii).modulationPrimarySignedPositive = dataModulation.Primary;    
%             cacheData.data(ii).modulationPrimarySignedNegative = [];
%             cacheData.data(ii).correction.backgroundSpdDesired = dataBackground.correction.SpdDesired;
%             cacheData.data(ii).correction.modulationSpdDesired = dataModulation.correction.SpdDesired;
%             cacheData.data(ii).correction.backgroundPrimaryInitial = backgroundPrimaryInitial;
%             cacheData.data(ii).correction.modulationPrimaryInitial = modulationPrimaryInitial;
%             cacheData.data(ii).correction.differencePrimaryInitial = [];
% 
%             cacheData.data(ii).correction.backgroundPrimaryUsedAll = dataBackground.correction.PrimaryUsedAll;
%             cacheData.data(ii).correction.backgroundSpdMeasuredAll = dataBackground.correction.SpdMeasuredAll;
%             cacheData.data(ii).correction.backgroundNextPrimaryTruncatedLearningRateAll = dataBackground.correction.NextPrimaryTruncatedLearningRateAll;
%             cacheData.data(ii).correction.backgroundDeltaPrimaryTruncatedLearningRateAll = dataBackground.correction.DeltaPrimaryTruncatedLearningRateAll;
% 
%             cacheData.data(ii).correction.modulationPrimaryUsedAll = dataModulation.correction.PrimaryUsedAll;
%             cacheData.data(ii).correction.modulationSpdMeasuredAll = dataModulation.correction.SpdMeasuredAll;
%             cacheData.data(ii).correction.modulationNextPrimaryTruncatedLearningRateAll = dataModulation.correction.NextPrimaryTruncatedLearningRateAll;
%             cacheData.data(ii).correction.modulationDeltaPrimaryTruncatedLearningRateAll = dataModulation.correction.DeltaPrimaryTruncatedLearningRateAll;
        else
            cacheData.data(ii).describe = [];
            cacheData.data(ii).backgroundPrimary = [];
            cacheData.data(ii).differentialPositive = [];
            cacheData.data(ii).differentialNegative = [];
        end
    end

end







