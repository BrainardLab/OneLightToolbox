function results = OLValidateCacheFileOOC(cacheFileName, meterType, varargin)
%OLValidateCacheFileOOC  Validate spectra in a cache fiel
%
% Usage:
%     results = OLValidateCacheFileOOC(cacheFileName, meterType, varargin)
%
% Description:
%     Measures the primaries in a cache file so we can see how well they are doing
%     waht they are supposed to.
%
% Input:
%     cacheFileName (string)    - Absolute full name of the cache file to validate.
%     meterType (string)        - Meter type to use.
%
% Output:
%     results (struct)          - Results struct.
%
% Optional key/value pairs:
%      Keyword                         Default                          Behavior
%
%     'approach'                       ''                               What approach is calling us?
%     'calStateMeas'                   true                             State measurements
%     'observerAgeInYrs'               32                               Observer age to correct for.
%     'noRadiometerAdjustment '        true                             Does not pause  to allow aiming of radiometer.
%     'calibrationType'                ''                               Calibration type
%     'doValidation'                   true                             Actually do the validation?
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

% 1/21/14  dhb, ms  Convert to use OLSettingsToStartsStops.
% 1/30/14  ms       Added keyword parameters to make this useful.
% 7/06/16  npc      Adapted to use PR650dev/PR670dev objects
% 9/2/16   ms       Updated with new CalStateMeas option
% 10/20/16 npc      Added ability to record temperature measurements
% 12/21/16 npc      Updated for new class @LJTemperatureProbe
% 06/05/17 dhb      Remove old verbose arg to OLSettingsToStartsStops
% 07/27/17 dhb      Massive interface redo.

% Parse the input
p = inputParser;
p.addParameter('approach','', @isstr);
p.addParameter('calStateMeas', false, @islogical);
p.addParameter('noRadiometerAdjustment', false, @islogical);
p.addParameter('observerAgeInYrs', 32, @isscalar);
p.addParameter('calibrationType','', @isstr);
p.addParameter('doValidation', true, @islogical);
p.addParameter('postreceptoralCombinations', [], @isnumeric);
p.addParameter('takeTemperatureMeasurements', false, @islogical);
p.addParameter('powerLevels', [0 1.0000], @isnumeric);
p.addParameter('useAverageGamma', false, @islogical);
p.addParameter('zeroPrimariesAwayFromPeak', false, @islogical);
p.addParameter('emailRecipient','igdalova@mail.med.upenn.edu', @isstr);
p.addParameter('verbose',false,@islogical);
p.parse(varargin{:});
validateDescribe = p.Results;
powerLevels = validateDescribe.powerLevels;
takeTemperatureMeasurements = validateDescribe.takeTemperatureMeasurements;

%% Get cached direction data as well as calibration file
[cacheData,adjustedCal] = OLGetCacheAndCalData(cacheFileNameFullPath, validateDescribe);

%% Need to check whether we're validating, and do something simple for simulation

%% Force useAverageGamma?
if (validateDescribe.useAverageGamma)
    adjustedCal.validateDescribe.useAverageGamma = 1;
end

%% Clean up cal file primaries by zeroing out light we don't think is really there?
if (validateDescribe.zeroPrimariesAwayFromPeak)
    zeroItWLRangeMinus = 100;
    zeroItWLRangePlus = 100;
    adjustedCal = OLZeroCalPrimariesAwayFromPeak(adjustedCal,zeroItWLRangeMinus,zeroItWLRangePlus);
end

%% Open up a radiometer object
%
% Set meterToggle so that we don't use the Omni radiometer in various measuremnt calls below.
[spectroRadiometerOBJ,S,nAverage] = OLOpenSpectroRadiometerObj(meterType);
meterToggle = [true false]; od = [];

%% Attempt to open the LabJack temperature sensing device
%
% If quitNow is true, the user has responded to a prompt in the called routine
% saying to give up.  Throw an error in that case.
if (validateDescribe.takeTemperatureMeasurements)
    % Gracefully attempt to open the LabJack.  If it doesn't work and the user OK's the
    % change, then the takeTemperature measurements flag is set to false and we proceed.
    % Otherwise it either worked (good) or we give up and throw an error.
    [validateDescribe.takeTemperatureMeasurements, quitNow, theLJdev] = OLCalibrator.OpenLabJackTemperatureProbe(validateDescribe.takeTemperatureMeasurements);
    if (quitNow)
        error('Unable to get temperature measurements to work as requested');
    end
else
    theLJdev = [];
end

% Open up the OneLight
ol = OneLight;

% Turn the mirrors full on so the user can focus the radiometer.
if validateDescribe.noRadiometerAdjustment
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
    
    if validateDescribe.calStateMeas
        fprintf('- State measurements \n');
        [~, calStateMeas] = OLCalibrator.TakeStateMeasurements(adjustedCal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, 'standAlone',true);
        OLCalibrator.SaveStateMeasurements(adjustedCal, calStateMeas, protocolParams);
    else
        calStateMeas = [];
    end
    
    
    % Loop over the stimuli in the cache file and take a measurement
    
    
    % Refactor the cache data spectrum primaries to the power level.
    backgroundPrimary = cacheData.data(validateDescribe.observerAgeInYrs).backgroundPrimary;
    differencePrimary = cacheData.data(validateDescribe.observerAgeInYrs).differencePrimary;
    
    for i = 1:nPowerLevels
        fprintf('- Measuring spectrum %d, level %g...\n', i, powerLevels(i));
        primaries = backgroundPrimary+powerLevels(i).*differencePrimary;
        
        % Convert the primaries to mirror settings.
        settings = OLPrimaryToSettings(adjustedCal, primaries);
        
        % Compute the stop mirrors.
        [starts,stops] = OLSettingsToStartsStops(adjustedCal, settings);
        
        % Take the measurements
        results.modulationAllMeas(i).meas = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, S, meterToggle, nAverage);
        
        % Save out information about this.
        results.modulationAllMeas(i).powerLevel = powerLevels(i);
        results.modulationAllMeas(i).primaries = primaries;
        results.modulationAllMeas(i).settings = settings;
        results.modulationAllMeas(i).starts = starts;
        results.modulationAllMeas(i).stops = stops;
        results.modulationAllMeas(i).predictedSpd = adjustedCal.computed.pr650M*primaries + adjustedCal.computed.pr650MeanDark;
        
        % Take temperature
        if (takeTemperatureMeasurements)
            [status, results.temperature.modulationAllMeas(i, :)] = theLJdev.measure();
        end
        
    end
    
    % For convenience we pull out the max., min. and background.
    theMaxIndex = find([results.modulationAllMeas(:).powerLevel] == 1);
    theMinIndex = find([results.modulationAllMeas(:).powerLevel] == -1);
    theBGIndex = find([results.modulationAllMeas(:).powerLevel] == 0);
    if ~isempty(theMaxIndex)
        results.modulationMaxMeas = results.modulationAllMeas(theMaxIndex);
    end
    
    if ~isempty(theBGIndex)
        results.modulationMinMeas = results.modulationAllMeas(theMinIndex);
    else % Some times there's no negative excursion. We set it to BG
        results.modulationMinMeas = results.modulationAllMeas(theBGIndex);
    end
    
    if ~isempty(theBGIndex)
        results.modulationBGMeas = results.modulationAllMeas(theBGIndex);
    end
    
    %         case 'Standard'
    %             % For each spectrum we'll measure a range of fractional power levels
    %             % defined by the vector below.
    %             results.powerLevels = [0.5 1];
    %             numPowerLevels = length(results.powerLevels);
    %
    %             % If the cacheData has a field called 'whichSettingIndexToValidate',
    %             % iterate only over these
    %             if isfield(cacheData, 'whichSettingIndexToValidate');
    %                 iter = cacheData.whichSettingIndexToValidate;
    %             else
    %                 iter = 1:size(cacheData.targetSpds, 2);
    %             end
    %             for i = iter
    %                 for j = 1:numPowerLevels
    %                     fprintf('- Measuring spectrum %d, Power level %g...', i, results.powerLevels(j));
    %
    %                     % Refactor the cache data spectrum primaries to the power level.
    %                     primaries = cacheData.primaries(:,i) * results.powerLevels(j);
    %
    %                     % Convert the primaries to mirror settings.
    %                     settings = OLPrimaryToSettings(cal, primaries);
    %
    %                     % Compute the start/stop mirrors.
    %                     [starts,stops] = OLSettingsToStartsStops(cal,settings);
    %                     results.meas(j, i) = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, S, meterToggle, nAverage);
    %
    %                     if (takeTemperatureMeasurements)
    %                         [status, results.temperature.meas(j, i, :)] = theLJdev.measure();
    %                     end
    %                     fprintf('Done\n');
    %                 end
    %             end
    %     end
    stopMeas = GetSecs;
    
    % Turn the OneLight mirrors off.
    ol.setAll(false);
    
    % Close the radiometer
    if (~isempty(spectroRadiometerOBJ))
        spectroRadiometerOBJ.shutDown();
    end
    
    % Save out useful information
    [calID, calIDTitle] = OLGetCalID(adjustedCal);
    results.validateDescribe.calID = calID;
    results.validateDescribe.calIDTitle = calIDTitle;
    results.validateDescribe.cal = adjustedCal;
    results.validateDescribe.cache.data = cacheData.data;
    results.validateDescribe.cache.cacheFileName = cacheFileName;
    results.validateDescribe.cache.observerAgeInYrs = validateDescribe.observerAgeInYrs;
    results.validateDescribe.validationDate = validationDate;
    results.validateDescribe.validationTime = validationTime;
    results.validateDescribe.startMeas = startMeas;
    results.validateDescribe.stopMeas = stopMeas;
    results.validateDescribe.calibrationType = char(OLCalibrationTypes.(calibrationType));
    results.validateDescribe.meterType = theMeterTypeID;
    results.validateDescribe.meterToggle = meterToggle;
    results.validateDescribe.observerAgeInYrs = validateDescribe.observerAgeInYrs;
    results.validateDescribe.S = S;
    results.validateDescribe.calStateMeas = calStateMeas;
    results.validateDescribe.takeTemperatureMeasurements = takeTemperatureMeasurements;
    
    % Check if we want to do splatter calculations
    OLAnalyzeValidationReceptorIsolate(validationPath, validateDescribe.postreceptoralCombinations);
    
catch e
    if (~isempty(spectroRadiometerOBJ))
        spectroRadiometerOBJ.shutDown();
    end
    
    SendEmail(emailRecipient, ['[OL] ' cacheFileName '/Validation failed'], e.message);
    rethrow(e)
end
