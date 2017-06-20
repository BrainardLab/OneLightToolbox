function [cacheData olCache openSpectroRadiometerOBJ, cal] = OLCorrectCacheFileOOC(cacheFileNameFullPath, emailRecipient, ...
    meterType, spectroRadiometerOBJ, spectroRadiometerOBJWillShutdownAfterMeasurement, varargin)
%%OLCorrectCacheFileOOC  Use iterated procedure to optimize modulations in a cache file
%    results = OLCorrectCacheFileOOC(cacheFileNameFullPath, emailRecipient, ...
%    meterType, spectroRadiometerOBJ, spectroRadiometerOBJWillShutdownAfterMeasurement, varargin)
%
% Uses an iterated procedure to bring a modulation as close as possible to
% its specified spectrum.
%
% Input:
% cacheFileNameFullPath (string) - The name of the cache file to validate.  The
%                             file name must be a full absolute path.  This is
%                             because relative path can match anything on the
%                             Matlab path, which could lead to unintended
%                             results.
% emailRecipient (string)   - Email address to receive notifications
% meterType (string)        - Meter type to use.
% spectroRadiometerOBJ      - A previously open PR650 or PR670 object
% spectroRadiometerOBJWillShutdownAfterMeasurement - Boolean, indicating
%                             whether to shutdown the radiometer object
% Output:
% results (struct) - Results struct. This is different depending on which mode is used.
% validationDir (str) - Validation directory.
%
% varargin (keyword-value)  - Optional key/value pairs
%      Keyword              Default   Behavior
%     'ReferenceMode'       true      Adds suffix to file name
%     'FullOnMeas'          true      Full-on
%     'HalfOnMeas'          false     Half-on
%     'CalStateMeas'        true      State measurements
%     'SkipBackground'      false     Background
%     'OBSERVER_AGE'        32        Observer age to correct for.
%     'ReducedPowerLevels'  true      Only 3 levels
%     'NoAdjustment '       true      Does not pause
%     'selectedCalType'     'EyeTrackerLongCableEyePiece1' Calibration type
%     'NIter'               scalar    number of iterations
%     'learningRate'        0.8       Learning rate
%     'learningRateDecrease' true     Decrease learning rate over iterations?
%     'asympLearningRateFactor' 0.5   If learningRateDecrease is true, the
%                                     asymptotic learning rate is (1-asympLearningRateFactor)*learningRate
%     'smoothness'          0.001     Smoothness parameter for OLSpdToPrimary
%     'iterativeSearch'     false     Do iterative search?
%     'regressionPredict'   false     Use regression to make predictions, rather than calibration
%     'postreceptoralCombinations'  scalar Post-receptoral combinations to calculate contrast w.r.t.
%     'takeTemperatureMeasurements' false  Whether to take temperature measurements (requires a
%                                          connected LabJack dev with a temperature probe)
%     'useAverageGamma'     false     Force the useAverageGamma mode in the
%                                     calibration.  When false, the value that was in the calibration file
%                                     is used.  When true, useAverageGamma is set to true.
%     'zeroPrimariesAwayFromPeak' false    Zero out calibrated primaries well away from their peaks.

% 1/21/14   dhb, ms  Convert to use OLSettingsToStartsStops.
% 1/30/14   ms       Added keyword parameters to make this useful.
% 7/06/16   npc      Adapted to use PR650dev/PR670dev objects
% 10/20/16  npc      Added ability to record temperature measurements
% 12/21/16  npc      Updated for new class @LJTemperatureProbe
% 01/03/16  dhb      Refactoring, cleaning, documenting.
% 06/05/17  dhb      Remove old style verbose arg from calls to OLSettingsToStartsStops

% Parse the input
p = inputParser;
p.addParameter('ReferenceMode', true, @islogical);
p.addParameter('FullOnMeas', true, @islogical);
p.addParameter('HalfOnMeas', false, @islogical);
p.addParameter('DarkMeas', false, @islogical);
p.addParameter('CalStateMeas', false, @islogical);
p.addParameter('SkipBackground', false, @islogical);
p.addParameter('ReducedPowerLevels', true, @islogical);
p.addParameter('NoAdjustment', false, @islogical);
p.addParameter('OBSERVER_AGE', 32, @isscalar);
p.addParameter('NIter', 20, @isscalar);
p.addParameter('learningRate', 0.8, @isscalar);
p.addParameter('learningRateDecrease',true,@islogical);
p.addParameter('asympLearningRateFactor',0.5,@isnumeric);
p.addParameter('smoothness', 0.001, @isscalar);
p.addParameter('iterativeSearch',false, @islogical);
p.addParameter('regressionPredict',false, @islogical);
p.addParameter('selectedCalType', [], @isstr);
p.addParameter('CALCULATE_SPLATTER', true, @islogical);
p.addParameter('doCorrection', true, @islogical);
p.addParameter('postreceptoralCombinations', [], @isnumeric);
p.addParameter('outDir', [], @isstr);
p.addParameter('takeTemperatureMeasurements', false, @islogical);
p.addParameter('powerLevels', [0 1.0000], @isnumeric);
p.addParameter('useAverageGamma', false, @islogical);
p.addParameter('zeroPrimariesAwayFromPeak', false, @islogical);
p.addParameter('simulate', false, @islogical);

p.parse(varargin{:});
correctDescribe = p.Results;

%% Set up email recipient
if isempty(emailRecipient)
    emailRecipient = GetWithDefault('Send status email to','igdalova@mail.med.upenn.edu');
end

%% Get cached modulation data as well as calibration file
[olCache,cacheData,cal,cacheDir,cacheFileName] = OLGetModulationCacheData(cacheFileNameFullPath, correctDescribe);

%% Force useAverageGamma?
if (correctDescribe.useAverageGamma)
    cal.describe.useAverageGamma = 1;
end

%% Clean up cal file primaries by zeroing out light we don't think is really there.
if (correctDescribe.zeroPrimariesAwayFromPeak)
    zeroItWLRangeMinus = 100;
    zeroItWLRangePlus = 100;
    cal = OLZeroCalPrimariesAwayFromPeak(cal,zeroItWLRangeMinus,zeroItWLRangePlus);
end

%% We might not want to seek
%
% If we aren't seeking just return now.  The reason we might do this is to
% get an uncorrected cache file with all the same naming conventions as a
% corrected one, so that we can run with uncorrected modulations using the
% same downstream naming conventions as code as if we had corrected.
if ~(correctDescribe.doCorrection)
    return;
end

%% Open up a radiometer object
%
% Set meterToggle so that we don't use the Omni radiometer here.
%
% All variables assigned in the following if (isempty(..)) block (except
% spectroRadiometerOBJ) must be declared as persistent.
%
% DHB: I DON'T UNDERSTAND THE USE OF PERSISTENT VARIABLES HERE.  CAN'T WE GET
% THESE OUT OF THE RETURNED OBJECT WHENEVER WE WANT THEM?
persistent S
persistent nAverage
persistent theMeterTypeID
if (isempty(spectroRadiometerOBJ))
    [spectroRadiometerOBJ,S,nAverage,theMeterTypeID] = OLOpenSpectroRadiometerObj(meterType);
end
meterToggle = [true false];

%% Save a copy of the radiometer object
%
% DHB: I DON'T UNDERSTAND WHY THIS IS NEEDED.  CAN'T WE JUST PASS BACK THE
% ONE WE HAVE?
openSpectroRadiometerOBJ = spectroRadiometerOBJ;

%% Attempt to open the LabJack temperature sensing device
%
% DHB: WHAT IS THE QUITNOW VARIABLE?  RETURNING WITHOUT MAKING ANY
% MEASUREMENTS DOES NOT SEEM LIKE THE RIGHT MOVE HERE.  CHECK.
if (correctDescribe.takeTemperatureMeasurements)
    % Gracefully attempt to open the LabJack
    [correctDescribe.takeTemperatureMeasurements, quitNow, theLJdev] = OLCalibrator.OpenLabJackTemperatureProbe(correctDescribe.takeTemperatureMeasurements);
    if (quitNow)
        return;
    end
else
    theLJdev = [];
end

%% Open up the OneLight
%
% And let user get the radiometer set up if desired.
ol = OneLight('simulate', correctDescribe.simulate);
if ~correctDescribe.NoAdjustment
    ol.setAll(true);
    pauseDuration = 0;
    fprintf('- Focus the radiometer and press enter to pause %d seconds and start measuring.\n', ...
        pauseDuration);
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
    %
    % DHB: DO WE NEED ALL OF THESE, OR DO THE CALSTATEMEASUREMENTS SUBSUME
    % THE OTHERS?
    %
    % MS: THE FIRST THREE CAN GO AWAY, WE THINK.  LET'S IMPLEMENT SOMETIME
    % SAFE AND SEE WHAT BREAKS.
    if correctDescribe.FullOnMeas
        fprintf('- Full-on measurement \n');
        [starts,stops] = OLSettingsToStartsStops(cal,1*ones(cal.describe.numWavelengthBands));
        results.fullOnMeas.meas = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, S, meterToggle, nAverage);
        results.fullOnMeas.starts = starts;
        results.fullOnMeas.stops = stops;
        results.fullOnMeas.predictedFromCal = cal.raw.fullOn(:, 1);
        if (correctDescribe.takeTemperatureMeasurements)
            printf('Taking temperature for fullOnMeas\n');
            [status, results.temperature.fullOnMeas] = theLJdev.measure();
        end
    end
    
    if correctDescribe.HalfOnMeas
        fprintf('- Half-on measurement \n');
        [starts,stops] = OLSettingsToStartsStops(cal,0.5*ones(cal.describe.numWavelengthBands));
        results.halfOnMeas.meas = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, S, meterToggle, nAverage);
        results.halfOnMeas.starts = starts;
        results.halfOnMeas.stops = stops;
        results.halfOnMeas.predictedFromCal = cal.raw.halfOnMeas(:, 1);
        if (correctDescribe.takeTemperatureMeasurements)
            [status, results.temperature.halfOnMeas] = theLJdev.measure();
        end
    end
    
    if correctDescribe.DarkMeas
        fprintf('- Dark measurement \n');
        [starts,stops] = OLSettingsToStartsStops(cal,0*ones(cal.describe.numWavelengthBands));
        results.offMeas.meas = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, S, meterToggle, nAverage);
        results.offMeas.starts = starts;
        results.offMeas.stops = stops;
        results.offMeas.predictedFromCal = cal.raw.darkMeas(:, 1);
        if (correctDescribe.takeTemperatureMeasurements)
            [status, results.temperature.offMeas] = theLJdev.measure();
        end
    end
    
    if correctDescribe.CalStateMeas
        fprintf('- State measurements \n');
        [~, calStateMeas] = OLCalibrator.TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, 'standAlone',true);
        OLCalibrator.SaveStateMeasurements(cal, calStateMeas);
    end
    
    %% Do the seeking for modulation background pairs
    %
    % This routine assumes only two power levels, 0 and 1.
    correctDescribe.powerLevels = [0 1];
    nPowerLevels = length(correctDescribe.powerLevels);
    
    for iter = 1:correctDescribe.NIter
        
        % Only get the primaries from the cache file if it's the
        % first iteration.  In this case we also store them for
        % future reference, since they are replaced on every
        % iteration.
        if iter == 1
            backgroundPrimaryUsed = cacheData.data(correctDescribe.OBSERVER_AGE).backgroundPrimary;
            differencePrimaryUsed = cacheData.data(correctDescribe.OBSERVER_AGE).differencePrimary;
            modulationPrimaryUsed = cacheData.data(correctDescribe.OBSERVER_AGE).backgroundPrimary+cacheData.data(correctDescribe.OBSERVER_AGE).differencePrimary;
            
            backgroundPrimaryInitial = cacheData.data(correctDescribe.OBSERVER_AGE).backgroundPrimary;
            differencePrimaryInitial = cacheData.data(correctDescribe.OBSERVER_AGE).differencePrimary;
            modulationPrimaryInitial = cacheData.data(correctDescribe.OBSERVER_AGE).backgroundPrimary+cacheData.data(correctDescribe.OBSERVER_AGE).differencePrimary;
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
            learningRateThisIter = correctDescribe.learningRate*(1-(iter-1)*correctDescribe.asympLearningRateFactor/(correctDescribe.NIter-1));
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
            settings = OLPrimaryToSettings(cal, primariesThisIter);
            
            % Compute the mirror starts and stops.
            [starts,stops] = OLSettingsToStartsStops(cal, settings);
            
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
                spdsDesired(:,i) = OLPrimaryToSpd(cal,primariesThisIter);
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
        backgroundDeltaPrimaryTruncatedLearningRate = OLLinearDeltaPrimaries(backgroundPrimaryUsed,kScale*backgroundSpdMeasured,backgroundSpdDesired,learningRateThisIter,correctDescribe.smoothness,cal);
        modulationDeltaPrimaryTruncatedLearningRate = OLLinearDeltaPrimaries(modulationPrimaryUsed,kScale*modulationSpdMeasured,modulationSpdDesired,learningRateThisIter,correctDescribe.smoothness,cal);
        
        % Optionally use fmincon to improve the truncated learning
        % rate delta primaries by iterative search.
        %
        % Put that in your pipe and smoke it!
        if (correctDescribe.iterativeSearch)
            backgroundDeltaPrimaryTruncatedLearningRate = OLIterativeDeltaPrimaries(backgroundDeltaPrimaryTruncatedLearningRate,backgroundPrimaryUsed,kScale*backgroundSpdMeasured,backgroundSpdDesired,learningRateThisIter,cal);
            modulationDeltaPrimaryTruncatedLearningRate = OLIterativeDeltaPrimaries(modulationDeltaPrimaryTruncatedLearningRate,modulationPrimaryUsed,kScale*modulationSpdMeasured,modulationSpdDesired,learningRateThisIter,cal);
        end
        
        % Compute and store the settings to use next time through
        backgroundNextPrimaryTruncatedLearningRate = backgroundPrimaryUsed + backgroundDeltaPrimaryTruncatedLearningRate;
        modulationNextPrimaryTruncatedLearningRate = modulationPrimaryUsed + modulationDeltaPrimaryTruncatedLearningRate;
        
        % Compute and print out information about the quality of
        % the current measurement, in contrast terms.
        theCanonicalPhotoreceptors = cacheData.data(correctDescribe.OBSERVER_AGE).describe.photoreceptors;
        T_receptors = cacheData.data(correctDescribe.OBSERVER_AGE).describe.T_receptors;
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
        if ii == correctDescribe.OBSERVER_AGE;
            cacheData.data(ii).correctDescribe = correctDescribe;
            cacheData.data(ii).cal = cal;
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
    if (spectroRadiometerOBJWillShutdownAfterMeasurement)
        if (~isempty(spectroRadiometerOBJ))
            spectroRadiometerOBJ.shutDown();
            openSpectroRadiometerOBJ = [];
        end
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







