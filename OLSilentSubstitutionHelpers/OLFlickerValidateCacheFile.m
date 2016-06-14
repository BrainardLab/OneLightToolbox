function results = OLFlickerValidateCacheFile(cacheFileName, varargin)
%function results = OLFlickerValidateCacheFile(cacheFileName, validationState, meterType, notificationEmail, doPlots)
% OLFlickerValidateCacheFile - Validates a OneLight cache file.
%
% Syntax:
% OLFlickerValidateCacheFile(cacheFileName)
% OLFlickerValidateCacheFile(cacheFileName, options)
%
% Description:
% Validates a OneLight cache file and measures the data it contains in
% order to see how our computed and predicted spectra compare with the
% actual spectra as seen by the PR-650 and OmniDriver spectrometers.
%
% Input:
% cacheFileName (string) - The name of the cache file to validate.  The
%                          file name must be an absolute path.  This is
%                          because relative path can match anything on the
%                          Matlab path, which could lead to unintended
%                          results.
% validationState (double) - The validation/meter state. Depending on
%                            whether we have already validated some files
%                            previously, we do different things. In a
%                            sequence of cache validations, we want to open
%                            the meter only once, and also close it once.
%                            - 0: Open meter, run validation, close meter
%                            - 1: Open and initialize the meter & run
%                              validation
%                            - 2: Run a validation
%                            - -1: Run validation and end validation sequence
% meterType (string) - Meter type to be used. This is defined outside this
%                      function so that we can have sequences of validations.
% notificationEmail (string) - Email to send notification to
% doPlots (logical) - plots out the validation results
%
%
% Output:
% results (struct) - A struct containing the following fields.
%     1. targetSpds (101xN) - The target spectra.
%     2. predictedSpds (1xN) - The predicted spectra for both the PR-650
%            and the OmniDriver.
%     3. cal (struct) - The calibration data used.
%     4. meas (1xN struct) - The measurements for the PR-650 and OmniDriver
%            spectrometers for each of the target spectra.
%     5. date (string) - The date and time of the validation.
% notificationEmail - Email address for the notification. This is usually, and then reused.

defaultEmail = 'mspits@sas.upenn.edu';

% Validate the number of inputs.
error(nargchk(1, 5, nargin));

switch nargin
    case 1
        validationState = 0;
        meterType = GetWithDefault('Enter PR-6XX radiometer type','PR-670');
        notificationEmail = GetWithDefault('Enter email address for done notification', defaultEmail);
        doPlots = 0; % Don't do plots by default
    case 2
        validationState = varargin{1};
        meterType = GetWithDefault('Enter PR-6XX radiometer type','PR-670');
        notificationEmail = GetWithDefault('Enter email address for done notification', defaultEmail);
        doPlots = 0;
    case 3
        validationState = varargin{1};
        meterType = varargin{2};
        notificationEmail = GetWithDefault('Enter email address for done notification', defaultEmail);
        doPlots = 0;
    case 4
        validationState = varargin{1};
        meterType = varargin{2};
        notificationEmail = varargin{3};
        doPlots = 0;
    case 5
        validationState = varargin{1};
        meterType = varargin{2};
        notificationEmail = varargin{3};
        doPlots =  varargin{4};
end

% Open up the radiometer if this is the first cache file we validate
switch (meterType)
    case 'PR-650',
        meterType = 1;
        S = [380 4 101];
        nAverage = 3;
        
    case 'PR-670',
        whichMeter = 'PR-670';
        meterType = 5;
        S = [380 2 201];
        nAverage = 3;
        
    otherwise,
        error('Unknown meter type');
end


global g_useIOPort;
% Open up the radiometer.
g_useIOPort = 1;

% Open up the radiometer.
CMCheckInit(meterType);

% Get the file dir
baseDir = fileparts(fileparts(which('OLFlickerValidateCacheFile')));
configDir = fullfile(baseDir, 'config', 'modulations');
cacheDir = fullfile(baseDir, 'cache', 'stimuli');
modulationDir = fullfile(baseDir, 'cache', 'modulations');

% The validation checks will be stored in a subfolder of the cache
% directory.  If it doesn't exist, make it.
validationDir = fullfile(cacheDir, 'validation');
if ~exist(validationDir, 'dir')
    mkdir(validationDir);
end

% Load the cache file.
data = load(fullfile(cacheDir, cacheFileName));
assert(isstruct(data), 'OLFlickerValidateCacheFile:InvalidCacheFile', ...
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
assert(any(typeExists), 'OLFlickerValidateCacheFile:InvalidCacheFile', ...
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
    
    t = GetInput('Select a Number', 'number', 1);
    
    if t >= 1 && t <= length(foundCalTypes) && typeExists(t);
        fprintf('\n');
        break;
    else
        fprintf('\n*** Invalid selection try again***\n\n');
    end
end
selectedCalType = foundCalTypes{t};

% Load the calibration file associated with this calibration type.
cal = LoadCalFile(OLCalibrationTypes.(selectedCalType).CalFileName);

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

% Define which ache variant we want to validate. We need to do this because
% we make observer age-specific cache variants.
theDefaultObserverAge = 32;

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
    od.IntegrationTime = cacheData.cal.describe.omniDriver.integrationTime;
else
    od = [];
end

% Open up the OneLight
ol = OneLight;

% Turn the mirrors full on so the user can focus the radiometer.
ol.setAll(true);
pauseDuration = 5;

fprintf('- Focus the radiometer and press enter to pause %d seconds and start measuring.\n', pauseDuration);

input('');
ol.setAll(false);
pause(pauseDuration);

try
    fprintf('- Performing radiometer measurements.\n');
    
    % For each spectrum we'll measure a range of fractional power levels
    % defined by the vector below.
    results.powerLevels = 1;
    numPowerLevels = length(results.powerLevels);
    
    % We'll use the same starts vector for all measurements.
    starts = zeros(1, ol.NumCols);
    
    % Take a completely off and half on set of measurements.
    maxStops = ones(1, ol.NumCols) * (ol.NumRows - 1);
    halfStops = round(maxStops/2);
    results.offMeas(1) = OLTakeMeasurement(ol, od, starts, starts, S, meterToggle, meterType, nAverage);
    results.halfOnMeas(1) = OLTakeMeasurement(ol, od, starts, halfStops, S, meterToggle, meterType, nAverage);
    
    % Loop over the stimuli in the cache file and take a measurement with
    % both the PR-650 and the OmniDriver.
    
    % Measure the background
    fprintf('Measuring background ...');
    backgroundPrimary = cacheData.data(theDefaultObserverAge).backgroundPrimary;
    primaries = backgroundPrimary;
    
    % Convert the primaries to mirror settings.
    settings = OLPrimaryToSettings(cacheData.cal, cal.computed.D*primaries);
    % Compute the stop mirrors.
    stops = round(settings * (ol.NumRows - 1));
    
    % Take the measurement
    results.background.meas = OLTakeMeasurement(ol, od, starts, stops, S, meterToggle, meterType, nAverage);
    results.background.predicted(i).spectrum = cal.computed.pr650M*primaries;
    results.background.predicted(i).M = cal.computed.pr650M;
    results.background.predicted(i).D = cal.computed.D;
    fprintf('Done\n');
    
    % If the cacheData has a field called 'whichSettingIndexToValidate',
    % iterate only over these
    nMeas = 41;
    theSamplingSpace = linspace(-1, 1, nMeas);
    theBlendingFunction = theSamplingSpace'; % We're centered around a 0.5 background.
    
    % Refactor the cache data spectrum primaries to the power level.
    modulationPrimary = cacheData.data(theDefaultObserverAge).modulationPrimary;
    
    for i = 1:length(theBlendingFunction)
        fprintf('- Measuring spectrum %d, level %g...', i, theSamplingSpace(i));
        
        primaries = backgroundPrimary+theBlendingFunction(i).*(modulationPrimary-backgroundPrimary);
        
        % Convert the primaries to mirror settings.
        settings = OLPrimaryToSettings(cacheData.cal, cal.computed.D*primaries);
        
        % Compute the stop mirrors.
        stops = round(settings * (ol.NumRows - 1));
        
        results.modulation.meas(i) = OLTakeMeasurement(ol, od, starts, stops, S, meterToggle, meterType, nAverage);
        results.modulation.predicted(i).spectrum = cal.computed.pr650M*primaries;
        results.modulation.predicted(i).M = cal.computed.pr650M;
        results.modulation.predicted(i).D = cal.computed.D;
        fprintf('Done\n');
    end
    
    % Take another set of completely off and half on measurements.
    results.offMeas(2) = OLTakeMeasurement(ol, od, starts, starts, S, meterToggle, meterType, nAverage);
    results.halfOnMeas(2) = OLTakeMeasurement(ol, od, starts, ...
        round(ones(1, ol.NumCols) * (ol.NumRows - 1) / 2), S, meterToggle, meterType, nAverage);
    
    % Turn the OneLight mirrors off.
    ol.setAll(false);
    
    % Close the radiometer
    % Close radiometer
    CMClose(meterType);
    
    % Store the cache data date with the measurements.  This lets us pull the
    % cache data from the cache history when we want to analyze the results
    % later.
    results.cacheDate = cacheData.date;
    results.validationDate = datestr(now);
    
    % Also store the calibration type of this file.
    results.calibrationType = OLCalibrationTypes.(selectedCalType);
    results.theObserverAge = theDefaultObserverAge;
    results.theBlendingFunction = theBlendingFunction;
    
    % Save the data to the validation folder.
    resultsFileName = sprintf('%s-%s', simpleCacheFileName, selectedCalType);
    SaveCalFile(results, resultsFileName, [validationDir '/']);
    
    if doPlots
        % Plot the validation results.
        OLPlotCacheValidationResults(fullfile(validationDir, resultsFileName), cacheFileName);
    end
    
    % Let me know it's done.
    SendEmail(notificationEmail, ['[OL] ' cacheFileName '/Validation done'], 'Validation successfully');
catch e
    SendEmail(notificationEmail, ['[OL] ' cacheFileName '/Validation failed'], e.message);
    rethrow(e)
end
