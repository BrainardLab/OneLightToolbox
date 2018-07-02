function cacheData = OLCorrectCacheFileOOC(cacheData, cal, ol, spectroRadiometerOBJ, varargin)
% results = OLCorrectCacheFileOOC(cacheFileName, emailRecipient, ...
%    meterType, spectroRadiometerOBJ, spectroRadiometerOBJWillShutdownAfterMeasurement, varargin)
%
% Description:
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
%
% varargin (keyword-value)  - Optional key/value pairs
%                              Keyword              Default   Behavior
%                             'ReferenceMode'       true      Adds suffix to file name
%                             'FullOnMeas'          true      Full-on
%                             'HalfOnMeas'          false     Half-on
%                             'CalStateMeas'        true      State measurements
%                             'SkipBackground'      false     Background
%                             'OBSERVER_AGE'        32        Observer age to correct for.
%                             'ReducedPowerLevels'  true      Only 3 levels
%                             'NoAdjustment '       true      Does not pause
%                             'selectedCalType'     'EyeTrackerLongCableEyePiece1' Calibration type
%                             'powerLevels'         scalar    Which power levels
%                             'NIter'               scalar    number of iterations
%                             'lambda'              scalar    Learning rate
%                             'postreceptoralCombinations'  scalar Post-receptoral combinations to calculate contrast w.r.t.
%                             'takeTemperatureMeasurements' false  Whether to take temperature measurements (requires a
%                                                                  connected LabJack dev with a temperature probe)
% Output:
% results (struct) - Results struct. This is different depending on which mode is used.
% validationDir (str) - Validation directory.

% 1/21/14   dhb, ms  Convert to use OLSettingsToStartsStops.
% 1/30/14   ms       Added keyword parameters to make this useful.
% 7/06/16   npc      Adapted to use PR650dev/PR670dev objects
% 10/20/16  npc      Added ability to record temperature measurements
% 12/21/16  npc      Updated for new class @LJTemperatureProbe
% 01/03/16  dhb      Refactoring, cleaning, documenting.
% 06/30/18  npc      Implemented state tracking SPD recording

% Parse the input
p = inputParser;
p.addOptional('ReferenceMode', true, @islogical);
p.addOptional('FullOnMeas', true, @islogical);
p.addOptional('HalfOnMeas', false, @islogical);
p.addOptional('DarkMeas', false, @islogical);
p.addOptional('CalStateMeas', false, @islogical);
p.addOptional('SkipBackground', false, @islogical);
p.addOptional('ReducedPowerLevels', true, @islogical);
p.addOptional('NoAdjustment', false, @islogical);
p.addOptional('OBSERVER_AGE', 32, @isscalar);
p.addOptional('NIter', 20, @isscalar);
p.addOptional('lambda', 0.8, @isscalar);
p.addOptional('selectedCalType', [], @isstr);
p.addOptional('CALCULATE_SPLATTER', true, @islogical);
p.addOptional('powerLevels', [0 1], @isnumeric);
p.addOptional('doCorrection', true, @islogical);
p.addOptional('postreceptoralCombinations', [], @isnumeric);
p.addOptional('outDir', [], @isstr);
p.addOptional('takeTemperatureMeasurements', false, @islogical);
p.addOptional('smoothness',.1, @isnumeric);
p.addOptional('measureStateTrackingSPDs', false, @islogical);
p.parse(varargin{:});
describe = p.Results;
powerLevels = describe.powerLevels;
takeTemperatureMeasurements = describe.takeTemperatureMeasurements;
measureStateTrackingSPDs = describe.measureStateTrackingSPDs;

% All variables assigned in the following if (isempty(..)) block (except
% spectroRadiometerOBJ) must be declared as persistent
persistent S
persistent nAverage
openSpectroRadiometerOBJ = spectroRadiometerOBJ;

%% Attempt to open the LabJack temperature sensing device
%
% DHB: WHAT IS THE QUITNOW VARIABLE?  RETURNING WITHOUT MAKING ANY
% MEASUREMENTS DOES NOT SEEM LIKE THE RIGHT MOVE HERE.  CHECK.
if (takeTemperatureMeasurements)
    % Gracefully attempt to open the LabJack
    [takeTemperatureMeasurements, quitNow, theLJdev] = OLCalibrator.OpenLabJackTemperatureProbe(takeTemperatureMeasurements);
    if (quitNow)
        return;
    end
else
    theLJdev = [];
end

%% Measure state-tracking SPDs
stateTrackingData = struct();
if (measureStateTrackingSPDs)
    % Generate temporary calibration struct with stateTracking info
    tmpCal = cal;
    tmpCal.describe.stateTracking = OLGenerateStateTrackingStruct(cal);
    
    % Take 1 measurement using the PR670
    od = []; meterToggle = [true false]; nAverage = 1;
    [~, calMeasOnly] = OLCalibrator.TakeStateMeasurements(tmpCal, ol, od, spectroRadiometerOBJ, ...
        meterToggle, nAverage, theLJdev, ...
        'standAlone', true);
    
    % Save the data
    stateTrackingData.spectralShift.spd    = calMeasOnly.raw.spectralShiftsMeas.measSpd;
    stateTrackingData.spectralShift.t      = calMeasOnly.raw.spectralShiftsMeas.t;
    stateTrackingData.powerFluctuation.spd = calMeasOnly.raw.powerFluctuationMeas.measSpd;
    stateTrackingData.powerFluctuation.t   = calMeasOnly.raw.powerFluctuationMeas.t;
    
    % Remove tmpCal
    clear('tmpCal')
end


startMeas = GetSecs;
fprintf('- Performing radiometer measurements.\n');
    
%     % Take reference measurements
%     if describe.FullOnMeas
%         fprintf('- Full-on measurement \n');
%         [starts,stops] = OLSettingsToStartsStops(cal,1*ones(cal.describe.numWavelengthBands, 1));
%         results.fullOnMeas.meas = OLTakeMeasurementOOC(ol, [], spectroRadiometerOBJ, starts, stops, S, [true false], nAverage);
%         results.fullOnMeas.starts = starts;
%         results.fullOnMeas.stops = stops;
%         results.fullOnMeas.predictedFromCal = cal.raw.fullOn(:, 1);
%         if (takeTemperatureMeasurements)
%             printf('Taking temperature for fullOnMeas\n');
%             [status, results.temperature.fullOnMeas] = theLJdev.measure();
%         end
%     end
%     
%     if describe.HalfOnMeas
%         fprintf('- Half-on measurement \n');
%         [starts,stops] = OLSettingsToStartsStops(cal,0.5*ones(cal.describe.numWavelengthBands, 1));
%         results.halfOnMeas.meas = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, S, meterToggle, nAverage);
%         results.halfOnMeas.starts = starts;
%         results.halfOnMeas.stops = stops;
%         results.halfOnMeas.predictedFromCal = cal.raw.halfOnMeas(:, 1);
%         if (takeTemperatureMeasurements)
%             [status, results.temperature.halfOnMeas] = theLJdev.measure();
%         end 
%     end
%     
%     if describe.DarkMeas
%         fprintf('- Dark measurement \n');
%         [starts,stops] = OLSettingsToStartsStops(cal,0*ones(cal.describe.numWavelengthBands, 1));
%         results.offMeas.meas = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, S, meterToggle, nAverage);
%         results.offMeas.starts = starts;
%         results.offMeas.stops = stops;
%         results.offMeas.predictedFromCal = cal.raw.darkMeas(:, 1);
%         if (takeTemperatureMeasurements)
%             [status, results.temperature.offMeas] = theLJdev.measure();
%         end
%     end
%     
%     if describe.CalStateMeas
%         fprintf('- State measurements \n');
%         [~, calStateMeas] = OLCalibrator.TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, 'standAlone',true);
%         OLCalibrator.SaveStateMeasurements(cal, calStateMeas);
%     end
    
    % Loop over the stimuli in the cache file and take a measurement with the PR-670.
    iter = 1;
    switch cacheData.computeMethod
        case 'ReceptorIsolate'
            for iter = 1:describe.NIter
                
                % Set up the power levels to use.  The cache file specifies
                % a full contrast modulation, but we can do seeking for
                % reduced contrast cases, which here are called power
                % levels.
                %
                % Reduced power levels just means do the high and low
                % moduation, plus the background or not as specified.
                %
                % If we're not doing reduced, then we just do what is in
                % the list given in vector powerLevels.
                %
                % DHB: I THINK THIS LOGIC SHOULD BE MOVED TO THE CALLING
                % PROGRAM, AND NOT HANDLED HERE.  THAT WOULD KEEP THIS MORE
                % GENERAL PURPOSE AND IN PARTICULAR MEAN THAT IT DID NOT
                % NEED TO KNOW WHAT 'PIPR' IS.  ANY REASON NOT TO MAKE THIS
                % CHANGE?
                %
                % MS: OK
                if describe.ReducedPowerLevels
                    if describe.SkipBackground
                        nPowerLevels = 2;
                        powerLevels = [-1 1];
                    else
                        if true
                            nPowerLevels = 2;
                            powerLevels = [0 1];
                        else
                            nPowerLevels = 3;
                            powerLevels = [-1 0 1];
                        end
                    end
                else
                    nPowerLevels = length(powerLevels);
                end
                
                % Only get the primaries from the cache file if it's the
                % first iteration.  In this case we also store them for
                % future reference, since they are replaced on every
                % iteration.
                %
                % DHB: EVENTUALLY PROBABLY ONLY WANT TO CARRY AROUND TWO OF
                % THESE THREE MUTUALLY DEPENDENT VALUES AND COMPUTE THE
                % THIRD ON THE FLY AS NEEDED.  THAT WOULD BE CLEARER.
                %
                % DHB: IT APPEARS THAT FOR REDUCED POWER, ON EACH
                % ITERATION THIS RESETS THE FULL ON PRIMARY BEING SOUGHT
                % AND THEN SEEKS SCALED VERSIONS OF THAT.  AN ALTERNATIVE
                % MIGHT BE TO SEEK INDIVIDUALLY ON THE SCALED VERSIONS FOR
                % EACH POWER.  INDEED, IT ISN'T CLEAR THAT THE WAY THIS IS
                % CURRENTLY WRITTEN DOES THAT MUCH FOR THE REDUCED POWER
                % CASES.
                if iter == 1
                    backgroundPrimaryMeasured = cacheData.data(describe.OBSERVER_AGE).backgroundPrimary;
                    differencePrimaryMeasured = cacheData.data(describe.OBSERVER_AGE).differencePrimary;
                    modulationPrimaryMeasured = cacheData.data(describe.OBSERVER_AGE).backgroundPrimary+cacheData.data(describe.OBSERVER_AGE).differencePrimary;
                    
                    backgroundPrimaryInitial = cacheData.data(describe.OBSERVER_AGE).backgroundPrimary;
                    differencePrimaryInitial = cacheData.data(describe.OBSERVER_AGE).differencePrimary;
                    modulationPrimaryInitial = cacheData.data(describe.OBSERVER_AGE).backgroundPrimary+cacheData.data(describe.OBSERVER_AGE).differencePrimary;
                else
                    backgroundPrimaryMeasured = backgroundPrimaryCorrected;
                    modulationPrimaryMeasured = modulationPrimaryCorrected;
                    differencePrimaryMeasured = modulationPrimaryMeasured-backgroundPrimaryMeasured;
                end
                if (max(abs(modulationPrimaryMeasured(:) - (backgroundPrimaryMeasured(:) + differencePrimaryMeasured(:)))) > 1e-8)
                    error('Inconsistency between background, difference, and modulation');
                end
                
                % Get the desired primaries for each power level and make a measurement for each one.
                for i = 1:nPowerLevels
                    fprintf('- Measuring spectrum %d, level %g...\n', i, powerLevels(i));
                    
                    % Get primary values for this power level.
                    primaries = backgroundPrimaryMeasured+powerLevels(i).*differencePrimaryMeasured;
                    
                    % Convert the primaries to mirror settings.
                    settings = OLPrimaryToSettings(cal, primaries);
                    
                    % Compute the mirror starts and stops.
                    [starts,stops] = OLSettingsToStartsStops(cal, settings);
                    
                    % Take the measurements
                    results.modulationAllMeas(i).meas = OLTakeMeasurementOOC(ol, [], spectroRadiometerOBJ, starts, stops, S, [true false], nAverage);
                    
                    % Save out information about this.
                    results.modulationAllMeas(i).powerLevel = powerLevels(i);
                    results.modulationAllMeas(i).primaries = primaries;
                    results.modulationAllMeas(i).settings = settings;
                    results.modulationAllMeas(i).starts = starts;
                    results.modulationAllMeas(i).stops = stops;
                    if (takeTemperatureMeasurements)
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
                        desiredSpds(:,i) = OLPrimaryToSpd(cal,primaries);
                    end
                end
                
                % For convenience we pull out from the set of power level
                % measurements those corresonding to the max power, min
                % power and background.
                theMaxIndex = find([results.modulationAllMeas(:).powerLevel] == 1);
                theMinIndex = find([results.modulationAllMeas(:).powerLevel] == -1);
                theBGIndex = find([results.modulationAllMeas(:).powerLevel] == 0);
                if ~isempty(theMaxIndex)
                    results.modulationMaxMeas = results.modulationAllMeas(theMaxIndex);
                    modDesiredSpd = desiredSpds(:,theMaxIndex);
                end
                
                % Sometimes there's no negative excursion, so we set the min one to the
                % background measurement.
                %
                % DHB: THIS CODE LOOKS WRONG BECAUSE IT IS CHECKING WHETHER
                % THE BG INDEX IS EMPTY RATHER THAN WHETHER THE MIN INDEX
                % IS EMPTY.  IF THE BG INDEX IS EMPTY I THINK THIS WILL
                % CRASH.
                if ~isempty(theBGIndex)
                    results.modulationMinMeas = results.modulationAllMeas(theMinIndex);
                else
                    results.modulationMinMeas = results.modulationAllMeas(theBGIndex);
                end
                
                % One of the measurements should have been the background,
                % pull that out so we have it handy.
                %
                % DHB: THERE IS A CASE IN THE POWER LEVELS SETTINGS ABOVE WHERE THE
                % BACKGROUND IS NOT MEASURED.  WILL THIS CRASH FOR THAT
                % CASE, SINCE THE BG MEAS WILL NOT BE SET.
                if ~isempty(theBGIndex)
                    results.modulationBGMeas = results.modulationAllMeas(theBGIndex);
                    bgDesiredSpd = desiredSpds(:,theBGIndex);
                end
                
                % DHB: STARTING HERE THE CODE SEEMS TO ASSUME THAT THERE IS
                % A BACKGROUND AND A SINGLE POSITIVE (POWERLEVEL == 1)
                % MODULATION, AS THE SEEKING ONLY HAPPENS ON THOSE TWO
                % SPECTRA.
                
                % If first time through, figure out a scaling factor from
                % the first measurement which puts the measured spectrum
                % into the same range as the predicted spectrum. This deals
                % with fluctuations with absolute light level.
                %
                % Note that on the first iteration, the field predictedSpd
                % is also the desired spd, because the prediction for the
                % first iteration is based on the primaries that we
                % actually want.
                %
                % While we're at it, tuck away the spectra we are trying in
                % the end to produce.
                if iter == 1
                    kScale = results.modulationBGMeas.meas.pr650.spectrum \ bgDesiredSpd;
                end
                
                % Find out how much we missed by in primary space, by
                % taking the difference between the measured spectrum and
                % what we wanted to get.
                deltaBackgroundPrimaryInferred = OLSpdToPrimary(cal, (kScale*results.modulationBGMeas.meas.pr650.spectrum)-...
                    bgDesiredSpd, 'differentialMode', true, 'lambda', p.Results.smoothness, 'primaryHeadroom', 0);
                deltaModulationPrimaryInferred = OLSpdToPrimary(cal, (kScale*results.modulationMaxMeas.meas.pr650.spectrum)-...
                    modDesiredSpd, 'differentialMode', true, 'lambda', p.Results.smoothness, 'primaryHeadroom', 0);
                
                % Also convert measured spds into  measured primaries.
                % These are a mess, because the smoothness parameter is too
                % smooth for these spectra.
                backgroundPrimaryInferred = OLSpdToPrimary(cal, results.modulationBGMeas.meas.pr650.spectrum);
                modulationPrimaryInferred = OLSpdToPrimary(cal, results.modulationMaxMeas.meas.pr650.spectrum);
                
                % Take a learning-rate-scaled version of the delta and
                % subtract it from the primaries we're trying, to get the
                % new desired primaries.
                backgroundPrimaryCorrectedNotTruncated = backgroundPrimaryMeasured - describe.lambda*deltaBackgroundPrimaryInferred;
                modulationPrimaryCorrectedNotTruncated = modulationPrimaryMeasured - describe.lambda*deltaModulationPrimaryInferred;
                
                % Make sure new primaries are between 0 and 1 by
                % truncating.
                backgroundPrimaryCorrected = backgroundPrimaryCorrectedNotTruncated;
                backgroundPrimaryCorrected(backgroundPrimaryCorrected > 1) = 1;
                backgroundPrimaryCorrected(backgroundPrimaryCorrected < 0) = 0;
                modulationPrimaryCorrected = modulationPrimaryCorrectedNotTruncated;
                modulationPrimaryCorrected(modulationPrimaryCorrected > 1) = 1;
                modulationPrimaryCorrected(modulationPrimaryCorrected < 0) = 0;
                  
                % Compute and print out information about the correction
                theCanonicalPhotoreceptors = cacheData.data(describe.OBSERVER_AGE).describe.photoreceptors;
                T_receptors = cacheData.data(describe.OBSERVER_AGE).describe.T_receptors;
                [contrasts(:,iter) postreceptoralContrasts(:,iter)] = ComputeAndReportContrastsFromSpds(['Iteration ' num2str(iter, '%02.0f')] ,theCanonicalPhotoreceptors,T_receptors,...
                    results.modulationBGMeas.meas.pr650.spectrum,results.modulationMaxMeas.meas.pr650.spectrum,'doPostreceptoral',true);
                
                % Save the information in a convenient form for keeping
                % later.
                bgSpdAll(:,iter) = results.modulationBGMeas.meas.pr650.spectrum;
                modSpdAll(:,iter) = results.modulationMaxMeas.meas.pr650.spectrum;
                backgroundPrimaryMeasuredAll(:,iter) = backgroundPrimaryMeasured;
                backgroundPrimaryCorrectedNotTruncatedAll(:,iter) = backgroundPrimaryCorrectedNotTruncated;
                backgroundPrimaryCorrectedAll(:,iter) = backgroundPrimaryCorrected;
                deltaBackgroundPrimaryInferredAll(:,iter) = deltaBackgroundPrimaryInferred;
                backgroundPrimaryInferredAll(:,iter) = backgroundPrimaryInferred;
                modulationPrimaryMeasuredAll(:,iter) = modulationPrimaryMeasured;
                modulationPrimaryCorrectedNotTruncatedAll(:,iter) = modulationPrimaryCorrectedNotTruncated;
                modulationPrimaryCorrectedAll(:,iter) = modulationPrimaryCorrected;
                deltaModulationPrimaryInferredAll(:,iter)= deltaModulationPrimaryInferred;
                modulationPrimaryInferredAll(:,iter) = modulationPrimaryInferred;
            end
    end
    
    %% Store information about corrected modulations for return.
    %
    % Since this routine only does the correction for one age, we set the data for that and zero out all
    % the rest, just to avoid accidently thinking we have corrected spectra where we do not.
    for ii = 1:length(cacheData.data)
        if ii == describe.OBSERVER_AGE;
            cacheData.data(ii).cal = cal;
            cacheData.data(ii).backgroundPrimary = backgroundPrimaryCorrectedAll(:, end);
            cacheData.data(ii).modulationPrimarySignedPositive = modulationPrimaryCorrectedAll(:, end);
            cacheData.data(ii).differencePrimary = modulationPrimaryCorrectedAll(:, end)-backgroundPrimaryCorrectedAll(:, end);
            cacheData.data(ii).correction.backgroundPrimaryMeasuredAll = backgroundPrimaryMeasuredAll;
            cacheData.data(ii).correction.backgroundPrimaryCorrectedNotTruncatedAll = backgroundPrimaryCorrectedNotTruncatedAll;
            cacheData.data(ii).correction.backgroundPrimaryCorrectedAll = backgroundPrimaryCorrectedAll;
            cacheData.data(ii).correction.deltaBackgroundPrimaryInferredAll = deltaBackgroundPrimaryInferredAll;
            cacheData.data(ii).correction.backgroundPrimaryInferredAll = backgroundPrimaryInferredAll;
            cacheData.data(ii).correction.bgDesiredSpd = bgDesiredSpd;
            cacheData.data(ii).correction.bgSpdAll = bgSpdAll;
            cacheData.data(ii).correction.kScale = kScale;
            cacheData.data(ii).correction.backgroundPrimaryInitial = backgroundPrimaryInitial;
            cacheData.data(ii).correction.differencePrimaryInitial = differencePrimaryInitial;
            cacheData.data(ii).correction.modulationPrimaryInitial =  modulationPrimaryInitial;
            cacheData.data(ii).correction.modulationPrimaryMeasuredAll = modulationPrimaryMeasuredAll;
            cacheData.data(ii).correction.modulationPrimaryCorrectedNotTruncatedAll = modulationPrimaryCorrectedNotTruncatedAll;
            cacheData.data(ii).correction.modulationPrimaryCorrectedAll = modulationPrimaryCorrectedAll;
            cacheData.data(ii).correction.deltaModulationPrimaryInferredAll = deltaModulationPrimaryInferredAll;
            cacheData.data(ii).correction.modulationPrimaryInferredAll = modulationPrimaryInferredAll;
            cacheData.data(ii).correction.modDesiredSpd =  modDesiredSpd;
            cacheData.data(ii).correction.modSpdAll = modSpdAll;
            cacheData.data(ii).correction.contrasts = contrasts;
            cacheData.data(ii).correction.postreceptoralContrasts = postreceptoralContrasts;
        else
            % DHB: THIS IS PROBABLY STORING MORE STUFF THAN NEEDED, SINCE
            % THIS PROGRAM NEVER PRODUCES ANYTHING FOR A NEGATIVE
            % MODULATION.
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
    
    if (takeTemperatureMeasurements)  
        cacheData.temperatureData = results.temperature;
    end
    
    if (measureStateTrackingSPDs)  
        cacheData.stateTrackingData = stateTrackingData;
    end
    
    % Turn the OneLight mirrors off.
    ol.setAll(false);
    
    
% Something went wrong, try to close radiometer gracefully
% catch e
%     if (~isempty(spectroRadiometerOBJ))
%         spectroRadiometerOBJ.shutDown();
%         openSpectroRadiometerOBJ = [];
%     end
%     rethrow(e)
% end
