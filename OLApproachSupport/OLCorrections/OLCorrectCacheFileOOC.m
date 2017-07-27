function [cacheData, adjustedCal] = OLCorrectCacheFileOOC(cacheFileNameFullPath, meterType, varargin)
%%OLCorrectCacheFileOOC  Use iterated procedure to optimize modulations in a cache file
%
% Usage:
%    results = OLCorrectCacheFileOOC(cacheFileNameFullPath, meterType)
%
% Description:
%   Uses an iterated procedure to bring a modulation as close as possible to
%   its specified spectrum.
%
% Input:
%     cacheFileNameFullPath (string) - The name of the cache file to validate.  The
%                                       file name must be a full absolute path.  This is
%                                       because relative path can match anything on the
%                                       Matlab path, which could lead to unintended
%                                       results.
%      emailRecipient (string)        - Email address to receive notifications
%      meterType (string)             - Meter type to use (e.g. 'PR-670');
%
% Output:
%     cacheData (struct)              - Contains the results
%     adjustedCal                     - Calibration struct as updated by this routine.
%
% Optional key/value pairs:
%      Keyword                         Default                          Behavior
%
%     'approach'                       ''                               What approach is calling us?
%     'calStateMeas'                   true                             State measurements
%     'observerAgeInYrs'               32                               Observer age to correct for.
%     'noRadiometerAdjustment '        true                             Does not pause  to allow aiming of radiometer.
%     'nIterations'                    20                               Number of iterations
%     'learningRate'                   0.8                              Learning rate
%     'learningRateDecrease'           true                             Decrease learning rate over iterations?
%     'asympLearningRateFactor'        0.5                              If learningRateDecrease is true, the
%                                                                       asymptotic learning rate is (1-asympLearningRateFactor)*learningRate
%     'smoothness'                     0.001                            Smoothness parameter for OLSpdToPrimary
%     'iterativeSearch'                false                            Do iterative search?
%     'calibrationType'                ''                               Calibration type
%     'doCorrection'                   true                             Actually do the correction?
%     'postreceptoralCombinations'     []                               Post-receptoral combinations to calculate contrast w.r.t.
%     'takeTemperatureMeasurements'    false                            Whether to take temperature measurements (requires a
%                                                                       connected LabJack dev with a temperature probe)
%     'powerLevels'                    [0 1]                            Power levels of diff modulation to seek for
%     'useAverageGamma'                false                            Force the useAverageGamma mode in the
%                                                                       calibration.  When false, the value that was in the calibration file
%                                                                       is used.  When true, useAverageGamma is set to true.
%     'zeroPrimariesAwayFromPeak'      false                            Zero out calibrated primaries well away from their peaks.
%     'emailRecipient'                 'igdalova@mail.med.upenn.edu'    Who gets email when this finishes.
%     'verbose'                        false                            Print out things in progress.

% 1/21/14   dhb, ms  Convert to use OLSettingsToStartsStops.
% 1/30/14   ms       Added keyword parameters to make this useful.
% 7/06/16   npc      Adapted to use PR650dev/PR670dev objects
% 10/20/16  npc      Added ability to record temperature measurements
% 12/21/16  npc      Updated for new class @LJTemperatureProbe
% 01/03/16  dhb      Refactoring, cleaning, documenting.
% 06/05/17  dhb      Remove old style verbose arg from calls to OLSettingsToStartsStops

% Parse the input
p = inputParser;
p.addParameter('approach','', @isstr);
p.addParameter('calStateMeas', false, @islogical);
p.addParameter('noRadiometerAdjustment', false, @islogical);
p.addParameter('observerAgeInYrs', 32, @isscalar);
p.addParameter('nIterations', 20, @isscalar);
p.addParameter('learningRate', 0.8, @isscalar);
p.addParameter('learningRateDecrease',true,@islogical);
p.addParameter('asympLearningRateFactor',0.5,@isnumeric);
p.addParameter('smoothness', 0.001, @isscalar);
p.addParameter('iterativeSearch',false, @islogical);
p.addParameter('calibrationType','', @isstr);
p.addParameter('doCorrection', true, @islogical);
p.addParameter('postreceptoralCombinations', [], @isnumeric);
p.addParameter('takeTemperatureMeasurements', false, @islogical);
p.addParameter('powerLevels', [0 1.0000], @isnumeric);
p.addParameter('useAverageGamma', false, @islogical);
p.addParameter('zeroPrimariesAwayFromPeak', false, @islogical);
p.addParameter('emailRecipient','igdalova@mail.med.upenn.edu', @isstr);
p.addParameter('verbose',false,@islogical);

p.parse(varargin{:});
correctDescribe = p.Results;

%% Get cached direction data as well as calibration file
[cacheData,adjustedCal] = OLGetCacheAndCalData(cacheFileNameFullPath, correctDescribe);

%% We might not want to seek
%
% If we aren't seeking just return now.  The reason we might do this is to
% get an uncorrected cache file with all the same naming conventions as a
% corrected one, so that we can run with uncorrected modulations using the
% same downstream naming conventions as code as if we had corrected.
if ~(correctDescribe.doCorrection)
    return;
end

%% Force useAverageGamma?
if (correctDescribe.useAverageGamma)
    adjustedCal.describe.useAverageGamma = 1;
end

%% Clean up cal file primaries by zeroing out light we don't think is really there.
if (correctDescribe.zeroPrimariesAwayFromPeak)
    zeroItWLRangeMinus = 100;
    zeroItWLRangePlus = 100;
    adjustedCal = OLZeroCalPrimariesAwayFromPeak(adjustedCal,zeroItWLRangeMinus,zeroItWLRangePlus);
end

%% Open up a radiometer object
%
% Set meterToggle so that we don't use the Omni radiometer in various measuremnt calls below.
[spectroRadiometerOBJ,S,nAverage] = OLOpenSpectroRadiometerObj(meterType);
meterToggle = [true false];

%% Attempt to open the LabJack temperature sensing device
%
% If quitNow is true, the user has responded to a prompt in the called routine 
% saying to give up.  Throw an error in that case.
if (correctDescribe.takeTemperatureMeasurements)
    % Gracefully attempt to open the LabJack.  If it doesn't work and the user OK's the
    % change, then the takeTemperature measurements flag is set to false and we proceed.
    % Otherwise it either worked (good) or we give up and throw an error.
    [correctDescribe.takeTemperatureMeasurements, quitNow, theLJdev] = OLCalibrator.OpenLabJackTemperatureProbe(correctDescribe.takeTemperatureMeasurements);
    if (quitNow)
        error('Unable to get temperature measurements to work as requested');
    end
else
    theLJdev = [];
end

%% Open up the OneLight
%
% And let user get the radiometer set up if desired.
ol = OneLight('simulate', correctDescribe.simulate);
if ~correctDescribe.noRadiometerAdjustment
    ol.setAll(true);
    pauseDuration = 0;
    fprintf('- Focus the radiometer and press enter to pause %d seconds and start measuring.\n', pauseDuration);
    input('');
    ol.setAll(false);
    pause(pauseDuration);
else
    ol.setAll(false);
end

try
    startMeas = GetSecs;
    fprintf('- Performing radiometer measurements.\n');
    
    %% Take reference measurements
    if correctDescribe.calStateMeas
        fprintf('- State measurements \n');
        [~, correctDescribe.calStateMeas] = OLCalibrator.TakeStateMeasurements(adjustedCal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, 'standAlone',true);
    end
    
    %% Do the seeking for modulation background pairs
    %
    % This routine assumes only two power levels, 0 and 1.
    correctDescribe.powerLevels = [0 1];
    nPowerLevels = length(correctDescribe.powerLevels);
    
    for iter = 1:correctDescribe.nIterations
        
        % Only get the primaries from the cache file if it's the
        % first iteration.  In this case we also store them for
        % future reference, since they are replaced on every
        % iteration.
        if iter == 1
            backgroundPrimaryUsed = cacheData.data(correctDescribe.observerAgeInYrs).backgroundPrimary;
            differencePrimaryUsed = cacheData.data(correctDescribe.observerAgeInYrs).differencePrimary;
            modulationPrimaryUsed = cacheData.data(correctDescribe.observerAgeInYrs).backgroundPrimary+cacheData.data(correctDescribe.observerAgeInYrs).differencePrimary;
            
            backgroundPrimaryInitial = cacheData.data(correctDescribe.observerAgeInYrs).backgroundPrimary;
            differencePrimaryInitial = cacheData.data(correctDescribe.observerAgeInYrs).differencePrimary;
            modulationPrimaryInitial = cacheData.data(correctDescribe.observerAgeInYrs).backgroundPrimary+cacheData.data(correctDescribe.observerAgeInYrs).differencePrimary;
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
            learningRateThisIter = correctDescribe.learningRate*(1-(iter-1)*correctDescribe.asympLearningRateFactor/(correctDescribe.nIterations-1));
        else
            learningRateThisIter = correctDescribe.learningRate;
        end
        
        % Get the desired primaries for each power level and make a measurement for each one.
        for i = 1:nPowerLevels
            fprintf('- Measuring spectrum %d, level %g...\n', i, correctDescribe.powerLevels(i));
            
            % Get primary values for this power level, adding the
            % modulation difference to the background, after
            % scaling by the power level.
            primariesThisIter = backgroundPrimaryUsed+correctDescribe.powerLevels(i).*differencePrimaryUsed;
            
            % Convert the primaries to mirror settings.
            settings = OLPrimaryToSettings(adjustedCal, primariesThisIter);
            
            % Compute the mirror starts and stops.
            [starts,stops] = OLSettingsToStartsStops(adjustedCal, settings);
            
            % Take the measurements
            results.modulationAllMeas(i).meas = OLTakeMeasurementOOC(ol, [], spectroRadiometerOBJ, starts, stops, S, meterToggle, nAverage);
            
            % Save out information about this.
            results.modulationAllMeas(i).powerLevel = correctDescribe.powerLevels(i);
            results.modulationAllMeas(i).primariesThisIter = primariesThisIter;
            results.modulationAllMeas(i).settings = settings;
            results.modulationAllMeas(i).starts = starts;
            results.modulationAllMeas(i).stops = stops;
            if (correctDescribe.takeTemperatureMeasurements)
                [status, tempData] = theLJdev.measure();
                results.temperature.modulationAllMeas(iter, i, :) = tempData;
            end
            
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
        theMaxIndex = find([results.modulationAllMeas(:).powerLevel] == 1);
        theBGIndex = find([results.modulationAllMeas(:).powerLevel] == 0);
        if (isempty(theMaxIndex) || isempty(theBGIndex))
            error('Should have measurements for power levels 0 and 1');
        end
        results.modulationMaxMeas = results.modulationAllMeas(theMaxIndex);
        modulationSpdDesired = spdsDesired(:,theMaxIndex);
        modulationSpdMeasured = results.modulationMaxMeas.meas.pr650.spectrum;
        
        results.modulationBGMeas = results.modulationAllMeas(theBGIndex);
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
        backgroundDeltaPrimaryTruncatedLearningRate = OLLinearDeltaPrimaries(backgroundPrimaryUsed,kScale*backgroundSpdMeasured,backgroundSpdDesired,learningRateThisIter,correctDescribe.smoothness,adjustedCal);
        modulationDeltaPrimaryTruncatedLearningRate = OLLinearDeltaPrimaries(modulationPrimaryUsed,kScale*modulationSpdMeasured,modulationSpdDesired,learningRateThisIter,correctDescribe.smoothness,adjustedCal);
        
        % Optionally use fmincon to improve the truncated learning
        % rate delta primaries by iterative search.
        %
        % Put that in your pipe and smoke it!
        if (correctDescribe.iterativeSearch)
            backgroundDeltaPrimaryTruncatedLearningRate = OLIterativeDeltaPrimaries(backgroundDeltaPrimaryTruncatedLearningRate,backgroundPrimaryUsed,kScale*backgroundSpdMeasured,backgroundSpdDesired,learningRateThisIter,adjustedCal);
            modulationDeltaPrimaryTruncatedLearningRate = OLIterativeDeltaPrimaries(modulationDeltaPrimaryTruncatedLearningRate,modulationPrimaryUsed,kScale*modulationSpdMeasured,modulationSpdDesired,learningRateThisIter,adjustedCal);
        end
        
        % Compute and store the settings to use next time through
        backgroundNextPrimaryTruncatedLearningRate = backgroundPrimaryUsed + backgroundDeltaPrimaryTruncatedLearningRate;
        modulationNextPrimaryTruncatedLearningRate = modulationPrimaryUsed + modulationDeltaPrimaryTruncatedLearningRate;
        
        % Compute and print out information about the quality of
        % the current measurement, in contrast terms.
        theCanonicalPhotoreceptors = cacheData.data(correctDescribe.observerAgeInYrs).describe.photoreceptors;
        T_receptors = cacheData.data(correctDescribe.observerAgeInYrs).describe.T_receptors;
        [contrasts(:,iter) postreceptoralContrasts(:,iter)] = ComputeAndReportContrastsFromSpds(['Iteration ' num2str(iter, '%02.0f')] ,theCanonicalPhotoreceptors,T_receptors,...
            backgroundSpdMeasured,modulationSpdMeasured,correctDescribe.postreceptoralCombinations,true);
        
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
        if ii == correctDescribe.observerAgeInYrs;
            cacheData.data(ii).correctDescribe = correctDescribe;
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
            
            cacheData.data(ii).correction.contrasts = contrasts;
            cacheData.data(ii).correction.postreceptoralContrasts = postreceptoralContrasts;
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
    
    if (correctDescribe.takeTemperatureMeasurements)
        cacheData.temperatureData = results.temperature;
    end
    
    % Turn the OneLight mirrors off.
    ol.setAll(false);
    
    % Close the radiometer
    if (~isempty(spectroRadiometerOBJ))
        spectroRadiometerOBJ.shutDown();
        openSpectroRadiometerOBJ = [];
    end
    
    % Check if we want to do splatter calculations
    try
        OLAnalyzeValidationReceptorIsolate(validationPath, 'short');
    catch e
        fprintf('Caught error during call to OLAnalyzeValidationReceptorIsolate\n');
        fprintf('The orignal error message was: %s\n',e.message);
    end
    
    % Something went wrong, try to close radiometer gracefully
catch e
    if (~isempty(spectroRadiometerOBJ))
        spectroRadiometerOBJ.shutDown();
        openSpectroRadiometerOBJ = [];
    end
    rethrow(e)
end

end







