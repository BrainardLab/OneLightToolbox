function [cacheData, calibration] = OLCorrectCacheFileOOC(cacheFileNameFullPath, oneLight, radiometer, varargin)
%%OLCorrectCacheFileOOC  Use iterated procedure to optimize modulations in a cache file
%
% Usage:
%    [cacheData, adjustedCal] = OLCorrectCacheFileOOC(cacheFileNameFullPath, ol, spectroRadiometerOBJ);
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

%% Input validation
parser = inputParser;
parser.addRequired('cachFileNameFullPath',@ischar)
parser.addRequired('oneLight',@(x) isa(x,'OneLight'));
parser.addRequired('radiometer',@(x) isempty(x) || isa(x,'Radiometer'));
parser.addParameter('approach','', @isstr);
parser.addParameter('observerAgeInYrs', 32, @isscalar);
parser.addParameter('calibrationType','', @isstr);
parser.addParameter('verbose',false,@islogical);
parser.addParameter('nIterations', 20, @isscalar);
parser.addParameter('learningRate', 0.8, @isscalar);
parser.addParameter('learningRateDecrease',true,@islogical);
parser.addParameter('asympLearningRateFactor',0.5,@isnumeric);
parser.addParameter('smoothness', 0.001, @isscalar);
parser.addParameter('iterativeSearch',false, @islogical);
parser.addParameter('nAverage',1,@isnumeric);
parser.parse(cacheFileNameFullPath, oneLight, radiometer, varargin{:});
correctionDescribe = parser.Results;

nIterations = parser.Results.nIterations;
learningRate = parser.Results.learningRate;
learningRateDecrease = parser.Results.learningRateDecrease;
asympLearningRateFactor = parser.Results.asympLearningRateFactor;
smoothness = parser.Results.smoothness;
iterativeSearch = parser.Results.iterativeSearch;

%% Get cached direction data as well as calibration file
[cacheData,calibration] = OLGetCacheAndCalData(cacheFileNameFullPath, correctionDescribe);

%% Get directionStruct to correct
directionStruct = cacheData.data(parser.Results.observerAgeInYrs);

%% Correct direction struct
correctedDirectionStruct = OLCorrectDirection(directionStruct, calibration, oneLight, radiometer,...
    'nIterations', nIterations,...
    'learningRate', learningRate,...
    'learningRateDecrease',  learningRateDecrease,...
    'asympLearningRateFactor', asympLearningRateFactor,...
    'smoothness', smoothness,...
    'iterativeSearch', iterativeSearch);

%% Store information about corrected modulations for return.
% Since this routine only does the correction for one age, we set the
% data for that and zero out all the rest, just to avoid accidently
% thinking we have corrected spectra where we do not.
for ii = 1:length(cacheData.data)
    if ii == correctionDescribe.observerAgeInYrs
        cacheData.data(ii) = correctedDirectionStruct;
    else
        cacheData.data(ii).describe = [];
        cacheData.data(ii).backgroundPrimary = [];
        cacheData.data(ii).differentialPositive = [];
        cacheData.data(ii).differentialNegative = [];
    end
end

end