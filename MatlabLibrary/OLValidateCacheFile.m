function [results, validationDir, validationPath] = OLValidateCacheFile(cacheFileName, emailRecipient, meterType, initMeter, closeMeter, varargin)
% results = OLValidateCacheFile(cacheFileName, emailRecipient, meterType, initMeter, closeMeter, varargin)
% OLValidateCacheFile - Validates a OneLight cache file.
%
% Syntax:
% OLValidateCacheFile(cacheFileName)
%
% Description:
% Validates a OneLight cache file and measures the data it contains in
% order to see how our computed and predicted spectra compare with the
% actual spectra as seen by the PR-650 and OmniDriver spectrometers.
%
% Input:
% cacheFileName (string)    - The name of the cache file to validate.  The
%                             file name must be an absolute path.  This is
%                             because relative path can match anything on the
%                             Matlab path, which could lead to unintended
%                             results.
% emailRecipient (string)   - Email address to receive notifications
% meterType (string)        - Meter type to use.
% initMeter (bool)          - Initializes meters.
% closeMeter (bool)         - Closes meters.
% varargin (keyword-value)  - A few keywords which determine the behavior
%                             of the routine.
%                             Keyword               Default   Behavior
%                             'ReferenceMode'       true      Adds suffix
%                                                             to file name
%                             'FullOnMeas'          true      Full-on
%                             'HalfOnMeas'          false     Half-on
%                             'DarkMeas'            false     Dark
%                             'SkipBackground'      false     Background
%                             'ReducedPowerLevels'  true      Only 3 levels
%                             'NoAdjustment      '  true      Does not pause
%                             'REFERENCE_OBSERVER_AGE'         32        Standard obs.
%                             'selectedCalType'     'EyeTrackerLongCableEyePiece1'
%                                                             Calibration
%                                                             type
%                             'powerLevels'         scalar    Which power levels
%
% Output:
% results (struct) - Results struct. This is different depending on which
% mode is used.
% validationDir (str) - Validation directory.
%
% 1/21/14  dhb, ms  Convert to use OLSettingsToStartsStops.
% 1/30/14  ms       Added keyword parameters to make this useful.
tic;

% Parse the input
p = inputParser;
p.addOptional('ReferenceMode', true, @islogical);
p.addOptional('FullOnMeas', true, @islogical);
p.addOptional('HalfOnMeas', false, @islogical);
p.addOptional('DarkMeas', false, @islogical);
p.addOptional('SkipBackground', false, @islogical);
p.addOptional('ReducedPowerLevels', true, @islogical);
p.addOptional('NoAdjustment', false, @islogical);
p.addOptional('REFERENCE_OBSERVER_AGE', 32, @isscalar);
p.addOptional('selectedCalType', [], @isstr);
p.addOptional('CALCULATE_SPLATTER', true, @islogical);
p.addOptional('powerLevels', 32, @isscalar);

p.parse(varargin{:});
describe = p.Results;

% Open up the radiometer if this is the first cache file we validate
switch (meterType)
    case 'PR-650',
        meterType = 1;
        S = [380 4 101];
        nAverage = 1;
    case 'PR-670',
        whichMeter = 'PR-670';
        meterType = 5;
        S = [380 2 201];
        nAverage = 1;
    otherwise,
        error('Unknown meter type');
end

if initMeter
    global g_useIOPort;
    % Open up the radiometer.
    g_useIOPort = 1;
    
    % Open up the radiometer.
    CMCheckInit(meterType);
end

% Force the file to be an absolute path instead of a relative one.  We do
% this because files with relative paths can match anything on the path,
% which may not be what was intended.  The regular expression looks for
% string that begins with '/' or './'.
m = regexp(cacheFileName, '^(\.\/|\/).*', 'once');
assert(~isempty(m), 'OLValidateCacheFile:InvalidPathDef', ...
    'Cache file name must be an absolute path.');

% Make sure the file exists.
assert(logical(exist(cacheFileName, 'file')), 'OLValidateCacheFile:FileNotFound', ...
    'Cannot find cache file: %s', cacheFileName);

% Deduce the cache directory.
cacheDir = fileparts(cacheFileName);
% Load the cache file.
data = load(cacheFileName);
assert(isstruct(data), 'OLValidateCacheFile:InvalidCacheFile', ...
    'Specified file doesn''t seem to be a cache file: %s', cacheFileName);

% List the available calibration types found in the cache file.
foundCalTypes = sort(fieldnames(data));

% Make sure the all the calibration types loaded seem legit. We want to
% make sure that we have at least one calibration type which we know of.
% Otherwise, we abort.
[~, validCalTypes] = enumeration('OLCalibrationTypes');
for i = 1:length(foundCalTypes)
    typeExists(i) = any(strcmp(foundCalTypes{i}, validCalTypes));
end
assert(any(typeExists), 'OLValidateCacheFile:InvalidCacheFile', ...
    'File contains does not contain at least one valid calibration type');

% Display a list of all the calibration types contained in the file and
% have the user select one to validate.
while true
    fprintf('\n- Calibration Types in Cache File (*** = valid)\n\n');
    
    for i = 1:length(foundCalTypes)
        if typeExists(i)
            typeState = '***';
        else
            typeState = '---';
        end
        fprintf('%i (%s): %s\n', i, typeState, foundCalTypes{i});
    end
    fprintf('\n');
    
    % Check if 'selectedCalType' was passed.
    if (isfield(describe, 'selectedCalType')) && any(strcmp(foundCalTypes, describe.selectedCalType))
        selectedCalType = describe.selectedCalType;
        break;
    end
    
    t = GetInput('Select a Number', 'number', 1);
    
    if t >= 1 && t <= length(foundCalTypes) && typeExists(t);
        fprintf('\n');
        selectedCalType = foundCalTypes{t};
        break;
    else
        fprintf('\n*** Invalid selection try again***\n\n');
    end
end

% Load the calibration file associated with this calibration type.
cal = LoadCalFile(OLCalibrationTypes.(selectedCalType).CalFileName);

% Pull out the file name
[~, cacheFileName] = fileparts(cacheFileName);

% We also create a folder hierarchy, in which we store validations.
% Identified by measurement.
validationDate = datestr(now);
validationTime = GetSecs;
validationDir = fullfile(cacheDir, cacheFileName, char(cal.describe.calType), strrep(strrep(cal.describe.date, ' ', '_'), ':', '_'), 'validation', strrep(strrep(validationDate, ' ', '_'), ':', '_'));
if ~exist(validationDir)
    mkdir(validationDir);
end

%% Determine which meters to measure with
% It is probably a safe assumption that we will not validate a cache file
% with the Omni with respect to a calibration that was done without the
% Omni. Therefore, we read out the toggle directly from the calibration
% file.
% First entry is PR-6xx and is always true.
% Second entry is omni and can be on or off, depending on content of
% calibration.
meterToggle = [1 cal.describe.useOmni];

% Setup the OLCache object.
olCache = OLCache(cacheDir, cal);

% Load the calibration data.  We do it through the cache object so that we
% make sure that the cache is current against the latest calibration data.
[~, simpleCacheFileName] = fileparts(cacheFileName);
[cacheData, wasRecomputed] = olCache.load(simpleCacheFileName);

% If we recomputed the cache data, save it.  We'll load the cache data
% after we save it because cache data is uniquely time stamped upon save.
if wasRecomputed
    olCache.save(simpleCacheFileName, cacheData);
    cacheData = olCache.load(simpleCacheFileName);
end

% Connect to the OceanOptics spectrometer.
if (cal.describe.useOmni)
    od = OmniDriver;
    od.Debug = true;
    % Turn on some averaging and smoothing for the spectrum acquisition.
    od.ScansToAverage = 10;
    od.BoxcarWidth = 2;
    
    % Make sure electrical dark correction is enabled.
    od.CorrectForElectricalDark = true;
    
    % Set the OmniDriver integration time to match up with what's in the
    % calibration file.
    od.IntegrationTime = cal.describe.omniDriver.integrationTime;
else
    od = [];
end

% Open up the OneLight
ol = OneLight;

% Turn the mirrors full on so the user can focus the radiometer.
if describe.NoAdjustment
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
    
    % Take reference measurements
    if describe.FullOnMeas
        [starts,stops] = OLSettingsToStartsStops(cal,1*ones(cal.describe.numWavelengthBands, 1));
        results.fullOnMeas.meas = OLTakeMeasurement(ol, od, starts, stops, S, meterToggle, meterType, nAverage);
        results.fullOnMeas.starts = starts;
        results.fullOnMeas.stops = stops;
        results.fullOnMeas.predictedFromCal = cal.raw.fullOn(:, 1);
    end
    
    if describe.HalfOnMeas
        [starts,stops] = OLSettingsToStartsStops(cal,0.5*ones(cal.describe.numWavelengthBands, 1));
        results.halfOnMeas.meas = OLTakeMeasurement(ol, od, starts, stops, S, meterToggle, meterType, nAverage);
        results.halfOnMeas.starts = starts;
        results.halfOnMeas.stops = stops;
        results.halfOnMeas.predictedFromCal = cal.raw.halfOnMeas(:, 1);
    end
    
    if describe.DarkMeas
        [starts,stops] = OLSettingsToStartsStops(cal,0*ones(cal.describe.numWavelengthBands, 1));
        results.offMeas.meas = OLTakeMeasurement(ol, od, starts, stops, S, meterToggle, meterType, nAverage);
        results.offMeas.starts = starts;
        results.offMeas.stops = stops;
        results.offMeas.predictedFromCal = cal.raw.darkMeas(:, 1);
    end
    
    % Loop over the stimuli in the cache file and take a measurement with
    % both the PR-650 and the OmniDriver.
    switch cacheData.computeMethod
        case 'ReceptorIsolate'
            % Set up the power levels to use.
            if describe.ReducedPowerLevels
                % Only take three measurements
                if describe.SkipBackground
                    nPowerLevels = 2
                    powerLevels = [-1 1];
                else
                    if strcmp(cacheData.data(32).describe.params.receptorIsolateMode, 'PIPR')
                        nPowerLevels = 2;
                        powerLevels = [0 1];
                    else
                        nPowerLevels = 3;
                        powerLevels = [-1 0 1];
                    end
                end
            else
                % Take a full set of measurements
                nPowerLevels = length(powerLevels);
            end
            
            % Refactor the cache data spectrum primaries to the power level.
            backgroundPrimary = cacheData.data(describe.REFERENCE_OBSERVER_AGE).backgroundPrimary;
            differencePrimary = cacheData.data(describe.REFERENCE_OBSERVER_AGE).differencePrimary;
            
            for i = 1:nPowerLevels
                fprintf('- Measuring spectrum %d, level %g...\n', i, powerLevels(i));
                primaries = backgroundPrimary+powerLevels(i).*differencePrimary;
                
                % Convert the primaries to mirror settings.
                settings = OLPrimaryToSettings(cal, primaries);
                
                % Compute the stop mirrors.
                [starts,stops] = OLSettingsToStartsStops(cal, settings);
                
                % Take the measurements
                results.modulationAllMeas(i).meas = OLTakeMeasurement(ol, od, starts, stops, S, meterToggle, meterType, nAverage);
                
                % Save out information about this.
                results.modulationAllMeas(i).powerLevel = powerLevels(i);
                results.modulationAllMeas(i).primaries = primaries;
                results.modulationAllMeas(i).settings = settings;
                results.modulationAllMeas(i).starts = starts;
                results.modulationAllMeas(i).stops = stops;
                results.modulationAllMeas(i).predictedSpd = cal.computed.pr650M*primaries + cal.computed.pr650MeanDark;
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
            
        case 'Standard'
            % For each spectrum we'll measure a range of fractional power levels
            % defined by the vector below.
            results.powerLevels = [0.5 1];
            numPowerLevels = length(results.powerLevels);
            
            % If the cacheData has a field called 'whichSettingIndexToValidate',
            % iterate only over these
            if isfield(cacheData, 'whichSettingIndexToValidate');
                iter = cacheData.whichSettingIndexToValidate;
            else
                iter = 1:size(cacheData.targetSpds, 2);
            end
            for i = iter
                for j = 1:numPowerLevels
                    fprintf('- Measuring spectrum %d, Power level %g...', i, results.powerLevels(j));
                    
                    % Refactor the cache data spectrum primaries to the power level.
                    primaries = cacheData.primaries(:,i) * results.powerLevels(j);
                    
                    % Convert the primaries to mirror settings.
                    settings = OLPrimaryToSettings(cal, primaries);
                    
                    % Compute the start/stop mirrors.
                    [starts,stops] = OLSettingsToStartsStops(cal,settings);
                    results.meas(j, i) = OLTakeMeasurement(ol, od, starts, stops, S, meterToggle, meterType, nAverage);
                    
                    fprintf('Done\n');
                end
            end
    end
    stopMeas = GetSecs;
    
    % Turn the OneLight mirrors off.
    ol.setAll(false);
    
    % Close the radiometer
    if closeMeter
        % Close radiometer
        CMClose(meterType);
    end
    
    % Save out useful information
    [calID calIDTitle] = OLGetCalID(cal);
    results.describe.calID = calID;
    results.describe.calIDTitle = calIDTitle;
    results.describe.cal = cal;
    results.describe.cache.data = cacheData.data;
    results.describe.cache.cacheFileName = cacheFileName;
    results.describe.cache.REFERENCE_OBSERVER_AGE = describe.REFERENCE_OBSERVER_AGE;
    results.describe.validationDate = validationDate;
    results.describe.validationTime = validationTime;
    results.describe.startMeas = startMeas;
    results.describe.stopMeas = stopMeas;
    results.describe.calibrationType = char(OLCalibrationTypes.(selectedCalType));
    results.describe.referenceMode = describe.ReferenceMode;
    results.describe.meterType = meterType;
    results.describe.meterToggle = meterToggle;
    results.describe.REFERENCE_OBSERVER_AGE = describe.REFERENCE_OBSERVER_AGE;
    results.describe.S = S;
    
    % Save the data to the validation folder.
    if results.describe.referenceMode
        resultsFileName = sprintf('%s-%s-%s', simpleCacheFileName, selectedCalType, 'SpotCheck');
    else
        resultsFileName = sprintf('%s-%s', simpleCacheFileName, selectedCalType);
    end
    SaveCalFile(results, resultsFileName, [validationDir '/']);
    
    validationPath = fullfile(validationDir, resultsFileName);
    
    % Check if we want to do splatter calculations
    OLAnalyzeValidationReceptorIsolate(validationPath, 'short');
    
    if describe.CALCULATE_SPLATTER
        OLAnalyzeValidationReceptorIsolate(validationPath, 'full');
    end
    
    % Let me know it's done.
    %SendEmail(emailRecipient, ['[OL] ' cacheFileName '/Validation done'], 'Validation successfully');
    toc;
catch e
    %SendEmail(emailRecipient, ['[OL] ' cacheFileName '/Validation failed'], e.message);
    rethrow(e)
end
