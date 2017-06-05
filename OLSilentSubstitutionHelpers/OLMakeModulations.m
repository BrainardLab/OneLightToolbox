function OLMakeModulations(configFileName, observerAgeInYears, calType1, calType0, fileSuffix)
% OLMakeModulations - Creates the cache data for a given config file.
%
% Syntax:
% OLMakeModulations(configFileName)
% OLMakeModulations(configFileName, forceRecompute)
%
% Description:
%
%
% Input:
% configFileName (string) - The name of the config file, e.g.
%     flickerconfig.cfg.  Only the simple name of the config file needs to
%     be specified.  The path to the config directory will be inferred.
% forceRecompute (logical) - If true, forces a recompute of the data found
%     in the config file.  Only do this if the target spectra were changed.
%     Default: false
%
% Use:
%
% OLMakeModulations('OLFlickerSensitivity-Background-OLEyeTrackerLongCableEyePiece1.cfg')
%
% 4/19/13   dhb, ms     Update for new convention for desired contrasts in routine ReceptorIsolate.

%% Housekeeping
% Validate the number of inputs.
%narginchk(1, 3, );

% Setup the directories we'll use.  We count on the
% standard relative directory structure that we always
% use in our (BrainardLab) experiments.
baseDir = getpref('OneLight', 'OLFlickerSensitivityBaseDir');
configDir = fullfile(baseDir, 'config', 'modulations');
cacheDir = fullfile(getpref('OneLight', 'cachePath'), 'stimuli');
modulationDir = fullfile(getpref('OneLight', 'modulationPath'));

[~, fileNameSave] = fileparts(configFileName);
fileNameSave = [fileNameSave '.mat'];

% Make sure the config file is a fully qualified name including the parent
% path.
configFileName = fullfile(configDir, configFileName);

% Make sure the config file exists.
assert(logical(exist(configFileName, 'file')), 'OLMakeModulations:InvalidCacheFile', ...
    'Could not find config file: %s', configFileName);

% Read the config file and convert it to a struct.
cfgFile = ConfigFile(configFileName);

% Convert all the ConfigFile parameters into simple struct values.
params = convertToStruct(cfgFile);
params.cacheDir = cacheDir;
params.modulationDir = modulationDir;

% Load the calibration file.
    params.calibrationType0 = calType0;
     params.calibrationType1 = calType1;
cType0 = OLCalibrationTypes.(params.calibrationType0);
cType1 = OLCalibrationTypes.(params.calibrationType1);
params.oneLightCal = LoadCalFile(cType0.CalFileName, [], getpref('OneLight', 'OneLightCalData'));
params.oneLightCal1 = LoadCalFile(cType1.CalFileName, [], getpref('OneLight', 'OneLightCalData'));

% Setup the cache.
params.olCache = OLCache(params.cacheDir, params.oneLightCal1);

file_names = allwords(params.directionCacheFile,',');
for i = 1:length(file_names)
    % Create the cache file name.
    [~, params.cacheFileName{i}] = fileparts(file_names{i});
end

%% Iterate over the cache files to be loaded in.
for i = 1:length(params.cacheFileName)
    % Load the cache data.
    if ~exist('fileSuffix', 'var') || isempty(fileSuffix)
        cacheData{i} = params.olCache.load(params.cacheFileName{i});
    else
        cacheData{i} = params.olCache.load([params.cacheFileName{i} fileSuffix]);
    end
    % Store the internal date of the cache data we're using.  The cache
    % data date is a unique timestamp identifying a specific set of cache
    % data. We want to save that to associate data sets to specific
    % versions of the cache file.
    params.cacheDate{i} = cacheData{i}.date;
end

cacheData = cacheData{end}.data(observerAgeInYears);
params.cacheData = cacheData;

%% Store out the primaries from the cacheData into a cell.  The length of
% cacheData corresponds to the number of different stimuli that are being
% shown
fprintf(['\n* Running precalculations for ' fileNameSave '\n']);

% Get the background
backgroundPrimary = cacheData.backgroundPrimary;

% Get the modulation primary
BIPOLAR_CORRECTION = false; % Assume that the correction hasn't been done for both excursions by default
if strfind(fileNameSave, 'Background') % Background case
    modulationPrimary = backgroundPrimary;
    modulationPrimary(:) = 0;
    diffPrimaryPos = modulationPrimary;
else
    if isfield(cacheData, 'correction')
        if isfield(cacheData.correction, 'modulationPrimaryPositiveCorrectedAll') & isfield(cacheData.correction, 'modulationPrimaryNegativeCorrectedAll')
            BIPOLAR_CORRECTION = true;
            modulationPrimary = cacheData.modulationPrimarySignedPositive;
            diffPrimaryPos = cacheData.modulationPrimarySignedPositive-backgroundPrimary;
            diffPrimaryNeg = cacheData.modulationPrimarySignedNegative-backgroundPrimary;
        else
            BIPOLAR_CORRECTION = false;
            modulationPrimary = cacheData.modulationPrimarySignedPositive;
            diffPrimaryPos = modulationPrimary-backgroundPrimary;
        end
    else
        modulationPrimary = cacheData.modulationPrimarySignedPositive;
        diffPrimaryPos = modulationPrimary-backgroundPrimary;
    end
end
% Save to specific file
params.observerAgeInYears = observerAgeInYears;
if ~exist('fileSuffix', 'var') || isempty(fileSuffix)
    [~, fileName, fileSuffix] = fileparts(fileNameSave);
else
    [~, fileName] = fileparts(fileNameSave);
end
fileNameSave = [fileName '-' num2str(params.observerAgeInYears) fileSuffix];

% Set up a few flags here
[~, describe.modulationName] = fileparts(fileNameSave);
describe.direction = params.direction;
describe.date = datestr(now);
describe.cal = params.oneLightCal;
describe.calID = OLGetCalID(params.oneLightCal);
describe.cacheDate = params.cacheDate;
describe.params = params;
describe.theFrequenciesHz = describe.params.carrierFrequency;
describe.thePhasesDeg = describe.params.carrierPhase;
describe.theContrastRelMax = describe.params.contrastScalars;

for f = 1:params.nFrequencies
    for p = 1:params.nPhases
        for c = 1:params.nContrastScalars
            % Construct the time vector
            if strcmp(params.modulationMode, 'AM')
                waveform.theEnvelopeFrequencyHz = params.modulationFrequencyTrials(1); % Modulation frequency
                waveform.thePhaseDeg = params.modulationPhase(p);
                waveform.thePhaseRad = deg2rad(params.modulationPhase(p));
                waveform.theFrequencyHz = params.carrierFrequency(f);
            elseif ~isempty(strfind(params.modulationMode, 'pulse'))
                waveform.phaseRandSec = params.phaseRandSec(p);
                waveform.stepTimeSec = params.stepTimeSec(f);
                waveform.preStepTimeSec = params.preStepTimeSec(f);
                waveform.theFrequencyHz = -1;
                waveform.thePhaseDeg = -1;
            else
                waveform.thePhaseDeg = params.carrierPhase(p);
                waveform.thePhaseRad = deg2rad(params.carrierPhase(p));
                waveform.theFrequencyHz = params.carrierFrequency(f);
            end
            
            waveform.direction = params.direction;
            waveform.modulationPrimary = modulationPrimary;
            waveform.backgroundPrimary = backgroundPrimary;
            waveform.modulationWaveform = params.modulationWaveForm;
            waveform.modulationMode = params.modulationMode;
            
            waveform.theContrastRelMax = params.contrastScalars(c);
            waveform.duration = params.trialDuration;      % Trial duration
            waveform.cal = params.oneLightCal;
            waveform.calID = OLGetCalID(params.oneLightCal);
            waveform.t = 0:params.timeStep:waveform.duration-params.timeStep;  % Time vector
            
            waveform.window.cosineWindowIn = params.cosineWindowIn;
            waveform.window.cosineWindowOut = params.cosineWindowOut;
            waveform.window.cosineWindowDurationSecs = params.cosineWindowDurationSecs;
            waveform.window.type = 'cosine';
            waveform.window.nWindowed = params.cosineWindowDurationSecs/params.timeStep;
            
            fprintf('* Calculating %0.f s of %s, %.2f Hz, %.2f deg, %.1f pct contrast (of max)\n         ', waveform.duration, waveform.direction, waveform.theFrequencyHz, waveform.thePhaseDeg, 100*waveform.theContrastRelMax);
            % Calculate it.
            if BIPOLAR_CORRECTION % pass both arms of the modulation if both were corrected
                modulation(f, p, c) = OLCalculateStartsStopsModulation(waveform, describe.cal, backgroundPrimary, diffPrimaryPos, diffPrimaryNeg);
            else
                modulation(f, p, c) = OLCalculateStartsStopsModulation(waveform, describe.cal, backgroundPrimary, diffPrimaryPos, []);
            end
            fprintf('  - Done.\n');
        end
    end
end

params = rmfield(params, 'olCache'); % Throw away the olCache field

% Put everything into a modulation
modulationObj.modulation = modulation;
modulationObj.describe = describe;
modulationObj.waveform = waveform;
modulationObj.params = params;

fprintf(['* Saving full pre-calculated settings to ' fileNameSave '\n']);
save(fullfile(modulationDir, fileNameSave), 'modulationObj', '-v7.3');
fprintf('  - Done.\n');
params = [];
