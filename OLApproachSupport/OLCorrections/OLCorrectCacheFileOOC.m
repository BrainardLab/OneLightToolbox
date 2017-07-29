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
%     'useAverageGamma'                false                            Force the useAverageGamma mode in the calibration?
%     'zeroPrimariesAwayFromPeak'      false                            Zero out calibrated primaries well away from their peaks.
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
p.addParameter('useAverageGamma', false, @islogical);
p.addParameter('zeroPrimariesAwayFromPeak', false, @islogical);
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

%% Check input OK
if (~correctionDescribe.simulate & (isempty(spectroRadiometerOBJ) | isempty(S)))
    error('Must pass radiometer objecta and S, unless simulating');
end

%% Get cached direction data as well as calibration file
[cacheData,adjustedCal] = OLGetCacheAndCalData(cacheFileNameFullPath, correctionDescribe);
if (isempty(S))
    S = adjustedCal.describe.S;
end

%% We might not want to seek
%
% If we aren't seeking just return now.  The reason we might do this is to
% get an uncorrected cache file with all the same naming conventions as a
% corrected one, so that we can run with uncorrected modulations using the
% same downstream naming conventions as code as if we had corrected.
if ~(correctionDescribe.doCorrection)
    return;
end

%% Set meterToggle so that we don't use the Omni radiometer in various measuremnt calls below.
meterToggle = [true false]; od = [];

%% Let user get the radiometer set up if desired.
if (~correctionDescribe.noRadiometerAdjustment)
    ol.setAll(true);
    commandwindow;
    fprintf('- Focus the radiometer and press enter to pause %d seconds and start measuring.\n', correctionDescribe.pauseDuration);
    input('');
    ol.setAll(false);
    pause(correctionDescribe.pauseDuration);
else
    ol.setAll(false);
end

%% Since we're working with hardware, things can go wrong.
%
% Use a try/catch to maximize robustness.
try
    % Keep time
    startMeas = GetSecs;
    
    % Say hello
    if (correctionDescribe.verbose), fprintf('- Performing radiometer measurements.\n'); end;    
    
    % State and temperature measurements
    if (~correctionDescribe.simulate & correctionDescribe.calStateMeas)
        if (correctionDescribe.verbose), fprintf('- State measurements \n'); end;
        [~, results.calStateMeas] = OLCalibrator.TakeStateMeasurements(adjustedCal, ol, od, spectroRadiometerOBJ, meterToggle, correctDescribe.nAverage, theLJdev, 'standAlone',true);
    else
        results.calStateMeas = [];
    end
    if (~correctionDescribe.simulate & correctionDescribe.takeTemperatureMeasurements & ~isempty(theLJdev))
        [~, results.temperatureMeas] = theLJdev.measure();
    else
        results.temperatureMeas = [];
    end
    
    % Do the seeking for each iteration and power level
    correctionDescribe.powerLevels = cacheData.directionParams.correctionPowerLevels;
    nPowerLevels = length(correctionDescribe.powerLevels);  
    for iter = 1:correctionDescribe.nIterations
        
        % Only get the primaries from the cache file if it's the
        % first iteration.  In this case we also store them for
        % future reference, since they are replaced on every
        % iteration.
        if iter == 1
            backgroundPrimaryUsed = cacheData.data(correctionDescribe.observerAgeInYrs).backgroundPrimary;
            differencePrimaryUsed = cacheData.data(correctionDescribe.observerAgeInYrs).differencePrimary;
            modulationPrimaryUsed = cacheData.data(correctionDescribe.observerAgeInYrs).backgroundPrimary+cacheData.data(correctionDescribe.observerAgeInYrs).differencePrimary;
            
            backgroundPrimaryInitial = cacheData.data(correctionDescribe.observerAgeInYrs).backgroundPrimary;
            differencePrimaryInitial = cacheData.data(correctionDescribe.observerAgeInYrs).differencePrimary;
            modulationPrimaryInitial = cacheData.data(correctionDescribe.observerAgeInYrs).backgroundPrimary+cacheData.data(correctionDescribe.observerAgeInYrs).differencePrimary;
        else
            backgroundPrimaryUsed = backgroundNextPrimaryTruncatedLearningRate;
            modulationPrimaryUsed = modulationNextPrimaryTruncatedLearningRate;
            differencePrimaryUsed = modulationPrimaryUsed-backgroundPrimaryUsed;
        end
        if (max(abs(modulationPrimaryUsed(:) - (backgroundPrimaryUsed(:) + differencePrimaryUsed(:)))) > 1e-8)
            error('Inconsistency between background, difference, and modulation');
        end
        
        % Set learning rate to use this iteration
        if (p.Results.learningRateDecrease)
            learningRateThisIter = correctionDescribe.learningRate*(1-(iter-1)*correctionDescribe.asympLearningRateFactor/(correctionDescribe.nIterations-1));
        else
            learningRateThisIter = correctionDescribe.learningRate;
        end
        
        % Get the desired primaries for each power level and make a measurement for each one.
        for i = 1:nPowerLevels
            if (correctionDescribe.verbose), fprintf('- Measuring spectrum %d, level %g...\n', i, correctionDescribe.powerLevels(i)); end
            
            % Get primary values for this power level, adding the
            % modulation difference to the background, after
            % scaling by the power level.
            primariesThisIter = backgroundPrimaryUsed+correctionDescribe.powerLevels(i).*differencePrimaryUsed;
            
            % Convert the primaries to mirror starts/stops
            settings = OLPrimaryToSettings(adjustedCal, primariesThisIter);
            [starts,stops] = OLSettingsToStartsStops(adjustedCal, settings);
            
            % Take the measurements.  Simulate with OLPrimaryToSpd when not measuring.
            if (~correctionDescribe.simulate)
                results.directionMeas(iter,i).meas = OLTakeMeasurementOOC(ol, [], spectroRadiometerOBJ, starts, stops, S, meterToggle, correctDescribe.nAverage);
            else
                results.directionMeas(iter,i).meas.pr650.spectrum = OLPrimaryToSpd(adjustedCal,primariesThisIter);
                results.directionMeas(iter,i).meas.pr650.time = [mglGetSecs mglGetSecs];
                results.directionMeas(iter,i).meas.omni = [];
            end
            
            % Save out information about this.
            results.directionMeas(iter,i).powerLevel = correctionDescribe.powerLevels(i);
            results.directionMeas(iter,i).primariesThisIter = primariesThisIter;
            results.directionMeas(iter,i).settings = settings;
            results.directionMeas(iter,i).starts = starts;
            results.directionMeas(iter,i).stops = stops;
            
            % If this is first time through the seeking, figure out
            % what spectrum we want, based on the stored primaries
            % and the calibration data.  The stored primaries were
            % generated so that they produced the desired spectrum
            % when mapped through the calibration, so we just
            % recreate the desired spectrum from the calibration
            % and the primaries. On the first iteration, the
            % primaries match those from the cache file, possibly
            % scaled by the appropriate power level.
            if (iter == 1)
                spdsDesired(:,i) = OLPrimaryToSpd(adjustedCal,primariesThisIter);
            end
        end
        
        % For convenience we pull out from the set of power level
        % measurements those corresonding to the background
        % (powerLevel == 0) and max (powerLevel == 1).
        theMaxIndex = find([results.directionMeas(iter,:).powerLevel] == 1);
        theBGIndex = find([results.directionMeas(iter,:).powerLevel] == 0);
        if (isempty(theMaxIndex) || isempty(theBGIndex))
            error('Should have measurements for power levels 0 and 1');
        end
        results.modulationMaxMeas = results.directionMeas(iter,theMaxIndex);
        modulationSpdDesired = spdsDesired(:,theMaxIndex);
        modulationSpdMeasured = results.modulationMaxMeas.meas.pr650.spectrum;
        
        results.modulationBGMeas = results.directionMeas(iter,theBGIndex);
        backgroundSpdDesired = spdsDesired(:,theBGIndex);
        backgroundSpdMeasured = results.modulationBGMeas.meas.pr650.spectrum;
        
        % If first time through, figure out a scaling factor from
        % the first measurement which puts the measured spectrum
        % into the same range as the predicted spectrum. This deals
        % with fluctuations with absolute light level.
        if iter == 1
            kScale = backgroundSpdMeasured \ backgroundSpdDesired;
        end
        
        % Find delta primaries using small signal linear methods.
        backgroundDeltaPrimaryTruncatedLearningRate = OLLinearDeltaPrimaries(backgroundPrimaryUsed,kScale*backgroundSpdMeasured,backgroundSpdDesired,learningRateThisIter,correctionDescribe.smoothness,adjustedCal);
        modulationDeltaPrimaryTruncatedLearningRate = OLLinearDeltaPrimaries(modulationPrimaryUsed,kScale*modulationSpdMeasured,modulationSpdDesired,learningRateThisIter,correctionDescribe.smoothness,adjustedCal);
        
        % Optionally use fmincon to improve the truncated learning
        % rate delta primaries by iterative search.
        %
        % Put that in your pipe and smoke it!
        if (correctionDescribe.iterativeSearch)
            backgroundDeltaPrimaryTruncatedLearningRate = OLIterativeDeltaPrimaries(backgroundDeltaPrimaryTruncatedLearningRate,backgroundPrimaryUsed,kScale*backgroundSpdMeasured,backgroundSpdDesired,learningRateThisIter,adjustedCal);
            modulationDeltaPrimaryTruncatedLearningRate = OLIterativeDeltaPrimaries(modulationDeltaPrimaryTruncatedLearningRate,modulationPrimaryUsed,kScale*modulationSpdMeasured,modulationSpdDesired,learningRateThisIter,adjustedCal);
        end
        
        % Compute and store the settings to use next time through
        backgroundNextPrimaryTruncatedLearningRate = backgroundPrimaryUsed + backgroundDeltaPrimaryTruncatedLearningRate;
        modulationNextPrimaryTruncatedLearningRate = modulationPrimaryUsed + modulationDeltaPrimaryTruncatedLearningRate;
              
        % Save the information in a convenient form for later.
        backgroundSpdMeasuredAll(:,iter) = backgroundSpdMeasured;
        modulationSpdMeasuredAll(:,iter) = modulationSpdMeasured;
        backgroundPrimaryUsedAll(:,iter) = backgroundPrimaryUsed;
        backgroundNextPrimaryTruncatedLearningRateAll(:,iter) = backgroundNextPrimaryTruncatedLearningRate;
        backgroundDeltaPrimaryTruncatedLearningRateAll(:,iter) = backgroundDeltaPrimaryTruncatedLearningRate;
        modulationPrimaryUsedAll(:,iter) = modulationPrimaryUsed;
        modulationNextPrimaryTruncatedLearningRateAll(:,iter) = modulationNextPrimaryTruncatedLearningRate;
        modulationDeltaPrimaryTruncatedLearningRateAll(:,iter)= modulationDeltaPrimaryTruncatedLearningRate;
    end
    
    
    %% Store information about corrected modulations for return.
    %
    % Since this routine only does the correction for one age, we set the data for that and zero out all
    % the rest, just to avoid accidently thinking we have corrected spectra where we do not. 
    for ii = 1:length(cacheData.data)
        if ii == correctionDescribe.observerAgeInYrs;
            cacheData.data(ii).correctionDescribe = correctionDescribe;
            cacheData.data(ii).cal = adjustedCal;
            cacheData.data(ii).correction.kScale = kScale;
            
            % Store the answer after the iteration.  This is storing the
            % next prediction.  We probably want to comb through everything
            % and pick the best we've seen so far.
            cacheData.data(ii).backgroundPrimary = backgroundNextPrimaryTruncatedLearningRateAll(:, end);
            cacheData.data(ii).modulationPrimarySignedPositive = modulationNextPrimaryTruncatedLearningRateAll(:, end);
            cacheData.data(ii).differencePrimary = modulationNextPrimaryTruncatedLearningRateAll(:, end)-backgroundNextPrimaryTruncatedLearningRateAll(:, end);
            cacheData.data(ii).modulationPrimarySignedNegative = [];
            
            % Store target spectra and initial primaries used.
            cacheData.data(ii).correction.backgroundSpdDesired = backgroundSpdDesired;
            cacheData.data(ii).correction.modulationSpdDesired =  modulationSpdDesired;
            cacheData.data(ii).correction.backgroundPrimaryInitial = backgroundPrimaryInitial;
            cacheData.data(ii).correction.differencePrimaryInitial = differencePrimaryInitial;
            cacheData.data(ii).correction.modulationPrimaryInitial =  modulationPrimaryInitial;
            
            cacheData.data(ii).correction.backgroundPrimaryUsedAll = backgroundPrimaryUsedAll;
            cacheData.data(ii).correction.backgroundSpdMeasuredAll = backgroundSpdMeasuredAll;
            cacheData.data(ii).correction.backgroundNextPrimaryTruncatedLearningRateAll = backgroundNextPrimaryTruncatedLearningRateAll;
            cacheData.data(ii).correction.backgroundDeltaPrimaryTruncatedLearningRateAll = backgroundDeltaPrimaryTruncatedLearningRateAll;
            
            cacheData.data(ii).correction.modulationPrimaryUsedAll = modulationPrimaryUsedAll;
            cacheData.data(ii).correction.modulationSpdMeasuredAll = modulationSpdMeasuredAll;
            cacheData.data(ii).correction.modulationNextPrimaryTruncatedLearningRateAll = modulationNextPrimaryTruncatedLearningRateAll;
            cacheData.data(ii).correction.modulationDeltaPrimaryTruncatedLearningRateAll = modulationDeltaPrimaryTruncatedLearningRateAll;
        else
            cacheData.data(ii).describe = [];
            cacheData.data(ii).backgroundPrimary = [];
            cacheData.data(ii).backgroundSpd = [];
            cacheData.data(ii).differencePrimary = [];
            cacheData.data(ii).differenceSpd = [];
            cacheData.data(ii).modulationPrimarySignedPositive = [];
            cacheData.data(ii).modulationPrimarySignedNegative = [];
            cacheData.data(ii).modulationSpdSignedPositive = [];
            cacheData.data(ii).modulationSpdSignedNegative = [];
            cacheData.data(ii).ambientSpd = [];
            cacheData.data(ii).operatingPoint = [];
            cacheData.data(ii).computeMethod = [];
        end
    end
    
    % Turn the OneLight mirrors off.
    ol.setAll(false);
      
% Something went wrong, try to close radiometer gracefully
catch e
  % Turn the OneLight mirrors off.
    ol.setAll(false);
    
    % Close the radiometer
    if (~correctionDescribe.simulate)
        if (~isempty(spectroRadiometerOBJ))
            spectroRadiometerOBJ.shutDown();
        end
        
        if (~isempty(theLJdev))
            theLJdev.close;
        end
    end
    
    % Rethrow the error
    rethrow(e)
end

end







