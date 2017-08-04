function OLReceptorIsolateMakeModulationStartsStops(trialType, modulationName, directionName, protocolParams, varargin)
%OLReceptorIsolateMakeModulationStartsStops  Creates the starts/stops cache data for a given config file
%
% Usage:
%     OLReceptorIsolateMakeModulationStartsStops(trialType, modulationName, directionName, topLevelParams)
%
% Description:
%     Converts primary settings for modulations into starts/stops arrays and
%     stores them in a cache file.  Included in this is filling in the
%     intermediate contrasts, as the input primaries are generally for the
%     modulation extrema.
%
%     Calls OLCalculateStartsStopsModulation to do most of the work -- this is primarily
%     a wrapper for that routine that handles parameter massaging as well as multiple
%     frequencies, phases and contrasts.
%
% Input:
%     trialType (integer)           Which trial type of the protocol is this.
%     modulationName (string)       The name of the modulation in the modulations dictionary.
%     directionName (string)        The name of the direciton in the directions dictionary.
%     protocolParams (struct)       Provides some needed information.  Relevant fields are:
%                                   [DHB NOTE: GIVE OR POINT TO THE RELEVANT FIELDS HERE.]
%
% Output:
%     Creates file with starts/stops needed to produce the desired modulation inside and
%     puts this into the protocol's ModulationStartsStops directory, with subfolder by
%     subject, date and session.
%
% Optional key/value pairs
%     'verbose' (boolean)    Print out diagnostic information?
%
% See also: OLMakeModulationsStartsStops, OLCacluateStartsStopsModulation, OLModulationParamsDictionary.

% 4/19/13   dhb, ms     Update for new convention for desired contrasts in routine ReceptorIsolate.
% 6/17/18   dhb         Merge with mab version and expand comments.
% 6/23/17   npc         No more config files, get modulation properties from OLModulationParamsDictionary

%% Parse input to get key/value pairs
p = inputParser;
p.addRequired('modulationName',@isstr);
p.addRequired('directionName',@isstr);
p.addRequired('protocolParams',@isstruct);
p.addParameter('verbose',true,@islogical);
p.parse(modulationName, directionName, protocolParams, varargin{:});

%% Say hello
if (p.Results.verbose); fprintf('\n* Computing modulation %s+%s\n',modulationName,directionName); end;

%% Get modulation params from modulation params dictionary
d = OLModulationParamsDictionary;
modulationParams = d(modulationName);

% Override with trialTypeParams passed by the current protocol
modulationParams = UpdateStructWithStruct(modulationParams,protocolParams.trialTypeParams(trialType));

%% Set up the input and output directories
% We count on the standard relative directory structure that we always use
% in our (Aguirre/Brainard Lab) experiments.
%
% Get where the input corrected direction files live.  This had better exist.
directionCacheDir = fullfile(getpref(protocolParams.protocol,'DirectionCorrectedPrimariesBasePath'), protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
if (~exist(directionCacheDir,'dir'))
    error('Corrected direction primaries directory does not exist');
end

% Output for starts/stops. Create if it doesn't exist.
modulationParams.modulationDir = fullfile(getpref(protocolParams.protocol, 'ModulationStartsStopsBasePath'),protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
if(~exist(modulationParams.modulationDir,'dir'))
    mkdir(modulationParams.modulationDir)
end

%% Load the calibration file and tack it onto the modulationParams structure.
%
% Not entirely sure whether that structure is the right place for the calibration information
% but leaving it be for now.
cType = OLCalibrationTypes.(protocolParams.calibrationType);
modulationParams.oneLightCal = LoadCalFile(cType.CalFileName, [], fullfile(getpref(protocolParams.approach, 'OneLightCalDataPath')));

%% Get the corrected direction primaries
%
% These are currently in a cache file. These particular files should never
% be stale, so the role of using a cache file is to allow us to keep things
% separate by calibration and to detect staleness.  But, given that these
% are written in subject/date/session specific directories, staleness is
% and multiple cal files are both unlikely.
%
% Setup the cache object for read, and do the read.
directionOLCache = OLCache(directionCacheDir, modulationParams.oneLightCal);
[directionCacheFile, startsStopsFileName, modulationParams.direction] = OLAssembleDirectionCacheAndStartsStopFileNames(protocolParams, modulationParams, directionName);

% Load direciton data, check for staleness, and pull out what we want
[cacheData,isStale] = directionOLCache.load(directionCacheFile);
assert(~isStale,'Cache file is stale, aborting.');
directionParams = cacheData.directionParams;
directionData = cacheData.data(protocolParams.observerAgeInYrs);
clear cacheData

%% Get the background
backgroundPrimary = directionData.backgroundPrimary;

%% Put primary data for direction into canonical form
switch (directionParams.type)
    case 'modulation'
        modulationPrimary = directionData.modulationPrimarySignedPositive;
        diffPrimaryPos = directionData.modulationPrimarySignedPositive-backgroundPrimary;
        diffPrimaryNeg = directionData.modulationPrimarySignedNegative-backgroundPrimary;
    case {'pulse' 'lightfluxpulse'}
        modulationPrimary = directionData.modulationPrimarySignedPositive;
        diffPrimaryPos = modulationPrimary-backgroundPrimary;
        diffPrimaryNeg = [];
    otherwise
        error('Unknown direction type specified')
end

%% Here compute the modulation and waveform as specified in the modulation file.
%
% Some parameters are common to all modulation types, and some are specific to specific types.
% We set these up here for all into OLCaclulateStartsStopsModulations.

% Construct the waverform parameters for the particular type of modulation we
% are constructing.
switch (modulationParams.type)
    case 'AM'
        % Amplitude modulation of an underlying carrier frequency
        error('Not yet implemented.  Harmonize the dictionary, the protocolParams.trialTypeParams, and this code.');
        waveformParams.theEnvelopeFrequencyHz = modulationParams.modulationFrequencyTrials(1); % Modulation frequency
        waveformParams.thePhaseDeg = modulationParams.modulationPhase;
        waveformParams.thePhaseRad = deg2rad(modulationParams.modulationPhase);
        waveformParams.theFrequencyHz = modulationParams.carrierFrequency;
        waveformParams.contrast = modulationParams.contrast;
        if (p.Results.verbose)
            fprintf('*   Calculating %0.f s of %s, %.2f Hz, %.2f deg, %.1f pct contrast (of max)\n', waveformParams.duration, waveformParams.direction, waveformParams.theFrequencyHz, waveformParams.thePhaseDeg, 100*waveformParams.contrast);
        end
    case 'pulse'
        % A unidirectional pulse
        % Frequency and phase parameters are meaningless here, and ignored.
        waveformParams.stepTimeSec = modulationParams.stepTimeSec;
        waveformParams.contrast = modulationParams.contrast;
        waveformParams.duration = modulationParams.trialDuration;
        waveformParams.type = modulationParams.type;
        if (p.Results.verbose)
            fprintf('*   Calculating pulse: %0.f s of %s, %.1f pct contrast (of max)\n', waveformParams.duration, waveformParams.direction, 100*waveformParams.contrast);
        end
    case 'sinusoid'
        % A sinuloidal modulation
        error('Not yet implemented.  Harmonize the dictionary, the protocolParams.trialTypeParams, and this code.');
        waveformParams.thePhaseDeg = modulationParams.carrierPhase;
        waveformParams.thePhaseRad = deg2rad(modulationParams.carrierPhase);
        waveformParams.theFrequencyHz = modulationParams.carrierFrequency;
        waveformParams.contrast = modulationParams.contrast;
        if (p.Results.verbose)
            fprintf('*   Calculating %0.f s of %s, %.2f Hz, %.2f deg, %.1f pct contrast (of max)\n', waveformParams.duration, waveformParams.direction, waveformParams.theFrequencyHz, waveformParams.thePhaseDeg, 100*waveformParams.contrast);
        end
    otherwise
        error('Unknown modulation type specified');
end

% Waveform timebase
waveformParams.t = 0:modulationParams.timeStep:waveformParams.duration-modulationParams.timeStep;

% Parameters common to all modulation types
%
% Windowing.  At present all windows are half-cosine.
waveformParams.window.type = 'cosine';
waveformParams.window.cosineWindowIn = modulationParams.cosineWindowIn;
waveformParams.window.cosineWindowOut = modulationParams.cosineWindowOut;
waveformParams.window.cosineWindowDurationSecs = modulationParams.cosineWindowDurationSecs;
waveformParams.window.nWindowed = modulationParams.cosineWindowDurationSecs/modulationParams.timeStep;

% Exactly how we call the underlying routine depends on the modulation type, so handle that here.
switch (modulationParams.type)
    case {'AM', 'sinusoid'}
        modulation = OLCalculateStartsStopsModulation(waveformParams, modulationParams.oneLightCal, backgroundPrimary, diffPrimaryPos, diffPrimaryNeg);
    case {'pulse'}
        modulation = OLCalculateStartsStopsModulation(waveformParams, modulationParams.oneLightCal, backgroundPrimary, diffPrimaryPos, []);
    otherwise
        error('Unknown direction type specified.');
end
if (p.Results.verbose); fprintf('  - Done.\n'); end;


%% Put everything into a return strucure
modulationData.params = modulationParams;
modulationData.modulation = modulation;

%% Save out the modulation
if (p.Results.verbose); fprintf(['* Saving modulation to ' startsStopsFileName '\n']); end;
save(startsStopsFileName, 'modulationData', '-v7.3');
if (p.Results.verbose); fprintf('  - Done.\n'); end;
end

%%OLAssembleDirectionCacheAndStartsStopFileNames
%
% Put together the modulation file name from the modulation name and the direction name, and also
% get the name of the cache file where we'll read the direction.
function [directionCacheFileName, startsStopsFileName, directionName] = OLAssembleDirectionCacheAndStartsStopFileNames(protocolParams, modulationParams, directionName)

% Hack to get the direction type
% for k = 1:numel(protocolParams.directionNames)
%     if (strcmp(protocolParams.directionNames{k}, directionName))
%         protocolParams.type = protocolParams.directionTypes{k};
%     end
% end

fullDirectionName = sprintf('Direction_%s', directionName);
fullStartsStopsName = sprintf('ModulationStartsStops_%s_%s', modulationParams.name, directionName);
directionCacheFileName = fullfile(getpref(protocolParams.protocol,'DirectionCorrectedPrimariesBasePath'), protocolParams.observerID,protocolParams.todayDate,protocolParams.sessionName, fullDirectionName);
startsStopsFileName = fullfile(modulationParams.modulationDir, fullStartsStopsName);
end



