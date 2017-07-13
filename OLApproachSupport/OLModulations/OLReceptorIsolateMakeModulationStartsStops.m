function OLReceptorIsolateMakeModulationStartsStops(modulationName, protocolParams, varargin)
%OLReceptorIsolateMakeModulationStartsStops  Creates the starts/stops cache data for a given config file.
%
% Usage:
%     OLReceptorIsolateMakeModulationStartsStops(modulationName, fileSuffix, topLevelParams)
%
% Description:
%     Converts primary settings for modulations into starts/stops arrays and
%     stores them in a cache file.  Included in this is filling in the
%     intermediate contrasts, as the input primaries are generally for the
%     maximum modulation.
%
%     The information in the modulations parameter in the dictionary includes modulation
%     directions.  These are read from the corrected versions of the primary files, which
%     are located in directory.
%
% Input:
%     configName (string)       The name of config for retrieving the appropriate modulation params
%     protocolParams (struct)   Provides some needed information.  Relevant fields are:
%                                 GIVE OR POINT TO THE RELEVANT FIELDS HERE.
%
% Output:
%     Creates file with starts/stops needed to produce the desired modulation inside.
%     NEED TO SAY WHERE THESE GO.
%
% Optional key/value pairs
%     'verbose' (boolean)    Print out diagnostic information?
%
% See also:

% 4/19/13   dhb, ms     Update for new convention for desired contrasts in routine ReceptorIsolate.
% 6/17/18   dhb         Merge with mab version and expand comments.
% 6/23/17   npc         No more config files, get modulation properties from ModulationParamsDictionary

%% Parse input to get key/value pairs
p = inputParser;
p.addRequired(modulationName,@isstring);
p.addRequired(fileSuffix,@istring);
p.addRequired(protocolParams,@isstruct);
p.addParameter('verbose',true,@isstring);
p.parse(modulationName, fileSuffix, protocolParams, varargin{:});

%% Get params from modulation params dictionary
d = ModulationParamsDictionary();
modulationParams = d(modulationName);

%% Setup the directories we'll use.
% We count on the standard relative directory structure that we always use
% in our (Aguirre/Brainard Lab) experiments.
%
% Corrected Primaries

% Get where the corrected direction files live
directionCacheDir = fullfile(getpref(protocolParams.approach,'DirectionCorrectedPrimariesBasePath'), protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
if (~exist(directionCacheDir,'dir'))
    error('Corrected direction primaries directory does not exist');
end

% Output for starts/stops
modulationParams.modulationDir = fullfile(getpref(protocolParams.approach, 'ModulationStartsStopsBasePath'),protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
if(~exist(modulationParams.modulationDir,'dir'))
    mkdir(modulationParams.modulationDir)
end

%% Load the calibration file.
cType = OLCalibrationTypes.(protocolParams.calibrationType);
modulationParams.oneLightCal = LoadCalFile(cType.CalFileName, [], fullfile(getpref(protocolParams.approach, 'MaterialsPath'), 'Experiments',protocolParams.approach,'OneLightCalData'));

%% Get the corrected direction primaries
%
% Setup the cache.
directionOLCache = OLCache(directionCacheDir, modulationParams.oneLightCal);
file_names = allwords(modulationParams.directionCacheFile,',');
for i = 1:length(file_names)
    % Create the cache file name.
    [~, modulationParams.cacheFileName{i}] = fileparts(file_names{i});
end

%% Iterate over the direction cache files to be loaded in.
for i = 1:length(modulationParams.cacheFileName)
    % Load the cached direction data.
    [cacheData{i},isStale] = directionOLCache.load(modulationParams.cacheFileName{i});
    assert(~isStale,'Cache file is stale, aborting.');
end
directionData = cacheData{end}.data(protocolParams.observerAgeInYrs);
clear cacheData

%% Set up output file name
[~, fileNameSave] = fileparts(modulationName);
fileNameSave = [fileNameSave '.mat'];
if (p.Results.verbose); fprintf(['\n* Running precalculations for ' fileNameSave '\n']); end;

% Get the background
backgroundPrimary = directionData.backgroundPrimary;

% SOME HORRIBLE STUFF.
BIPOLAR_CORRECTION = false; % Assume that the correction hasn't been done for both excursions by default
if strfind(fileNameSave, 'Background') % Background case
    modulationPrimary = backgroundPrimary;
    modulationPrimary(:) = 0;
    diffPrimaryPos = modulationPrimary;
else
    if isfield(directionData, 'correction')
        if isfield(directionData.correction, 'modulationPrimaryPositiveCorrectedAll') & isfield(directionData.correction, 'modulationPrimaryNegativeCorrectedAll')
            BIPOLAR_CORRECTION = true;
            modulationPrimary = directionData.modulationPrimarySignedPositive;
            diffPrimaryPos = directionData.modulationPrimarySignedPositive-backgroundPrimary;
            diffPrimaryNeg = directionData.modulationPrimarySignedNegative-backgroundPrimary;
        else
            BIPOLAR_CORRECTION = false;
            modulationPrimary = directionData.modulationPrimarySignedPositive;
            diffPrimaryPos = modulationPrimary-backgroundPrimary;
        end
    else
        modulationPrimary = directionData.modulationPrimarySignedPositive;
        diffPrimaryPos = modulationPrimary-backgroundPrimary;
    end
end

% Save to specific file
if ~exist('fileSuffix', 'var') || isempty(fileSuffix)
    [~, fileName, fileSuffix] = fileparts(fileNameSave);
else
    [~, fileName] = fileparts(fileNameSave);
end
fileNameSave = [fileName '-' num2str(protocolParams.observerAgeInYrs) fileSuffix];

% Set up a few flags here
[~, describe.modulationName] = fileparts(fileNameSave);
describe.direction = modulationParams.direction;
describe.date = datestr(now);
describe.cal = modulationParams.oneLightCal;
describe.calID = OLGetCalID(modulationParams.oneLightCal);
describe.cacheDate = modulationParams.cacheDate;
describe.params = modulationParams;
describe.theFrequenciesHz = describe.params.carrierFrequency;
describe.thePhasesDeg = describe.params.carrierPhase;
describe.theContrastRelMax = describe.params.contrastScalars;

for f = 1:modulationParams.nFrequencies
    for p = 1:modulationParams.nPhases
        for c = 1:modulationParams.nContrastScalars
            % Construct the time vector
            if strcmp(modulationParams.modulationMode, 'AM')
                waveform.theEnvelopeFrequencyHz = modulationParams.modulationFrequencyTrials(1); % Modulation frequency
                waveform.thePhaseDeg = modulationParams.modulationPhase(p);
                waveform.thePhaseRad = deg2rad(modulationParams.modulationPhase(p));
                waveform.theFrequencyHz = modulationParams.carrierFrequency(f);
            elseif ~isempty(strfind(modulationParams.modulationMode, 'pulse'))
                waveform.phaseRandSec = modulationParams.phaseRandSec(p);
                waveform.stepTimeSec = modulationParams.stepTimeSec(f);
                waveform.preStepTimeSec = modulationParams.preStepTimeSec(f);
                waveform.theFrequencyHz = -1;
                waveform.thePhaseDeg = -1;
            else
                waveform.thePhaseDeg = modulationParams.carrierPhase(p);
                waveform.thePhaseRad = deg2rad(modulationParams.carrierPhase(p));
                waveform.theFrequencyHz = modulationParams.carrierFrequency(f);
            end
            
            waveform.direction = modulationParams.direction;
            waveform.modulationPrimary = modulationPrimary;
            waveform.backgroundPrimary = backgroundPrimary;
            waveform.modulationWaveform = modulationParams.modulationWaveForm;
            waveform.modulationMode = modulationParams.modulationMode;
            
            waveform.theContrastRelMax = modulationParams.contrastScalars(c);
            waveform.duration = modulationParams.trialDuration;      % Trial duration
            waveform.cal = modulationParams.oneLightCal;
            waveform.calID = OLGetCalID(modulationParams.oneLightCal);
            waveform.t = 0:modulationParams.timeStep:waveform.duration-modulationParams.timeStep;  % Time vector
            
            waveform.window.cosineWindowIn = modulationParams.cosineWindowIn;
            waveform.window.cosineWindowOut = modulationParams.cosineWindowOut;
            waveform.window.cosineWindowDurationSecs = modulationParams.cosineWindowDurationSecs;
            waveform.window.type = 'cosine';
            waveform.window.nWindowed = modulationParams.cosineWindowDurationSecs/modulationParams.timeStep;
            
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

modulationParams = rmfield(modulationParams, 'olCache'); % Throw away the olCache field

% Put everything into a modulation
modulationObj.modulation = modulation;
modulationObj.describe = describe;
modulationObj.waveform = waveform;
modulationObj.params = modulationParams;

%% Save out the modulation

if (p.Params.verbose); fprintf(['* Saving full pre-calculated settings to ' fileNameSave '\n']); end;
save(fullfile(modulationParams.modulationDir, fileNameSave), 'modulationObj', '-v7.3');
if (p.Params.verbose); fprintf('  - Done.\n'); end;
end

