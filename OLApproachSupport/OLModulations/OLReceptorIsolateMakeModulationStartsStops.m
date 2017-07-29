function OLReceptorIsolateMakeModulationStartsStops(modulationName, directionName, protocolParams, varargin)
%OLReceptorIsolateMakeModulationStartsStops  Creates the starts/stops cache data for a given config file.
%
% Usage:
%     OLReceptorIsolateMakeModulationStartsStops(modulationName, directionName, topLevelParams)
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
% 6/23/17   npc         No more config files, get modulation properties from OLModulationParamsDictionary

%% Parse input to get key/value pairs
p = inputParser;
p.addRequired('modulationName',@isstr);
p.addRequired('directionName',@isstr);
p.addRequired('protocolParams',@isstruct);
p.addParameter('verbose',true,@islogical);
p.parse(modulationName, directionName, protocolParams, varargin{:});

%% Get params from modulation params dictionary
d = OLModulationParamsDictionary;
modulationParams = d(modulationName);

%% Setup the directories we'll use.
% We count on the standard relative directory structure that we always use
% in our (Aguirre/Brainard Lab) experiments.
%
% Get where the corrected direction files live.  This had better exist.
directionCacheDir = fullfile(getpref(protocolParams.approach,'DirectionCorrectedPrimariesBasePath'), protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
if (~exist(directionCacheDir,'dir'))
    error('Corrected direction primaries directory does not exist');
end

% Output for starts/stops. Create if it doesn't exist.
modulationParams.modulationDir = fullfile(getpref(protocolParams.approach, 'ModulationStartsStopsBasePath'),protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
if(~exist(modulationParams.modulationDir,'dir'))
    mkdir(modulationParams.modulationDir)
end

%% Load the calibration file.
cType = OLCalibrationTypes.(protocolParams.calibrationType);
modulationParams.oneLightCal = LoadCalFile(cType.CalFileName, [], fullfile(getpref(protocolParams.approach, 'OneLightCalDataPath')));

%% Get the corrected direction primaries
% 
% These are currently in a cache file.  Perhaps someday we will uncache them,
% and perhaps not.  These particular files should never be stale, so the
% only role of using a cache file is that we could detect staleness.  But,
% given that these are written in subject/date/session specific directories,
% staleness is not really a problem we need to worry about.
%
% Setup the cache object for read, and do the read.
directionOLCache = OLCache(directionCacheDir, modulationParams.oneLightCal);
%directionFilenames{1} = modulationParams.directionCacheFile;
% for i = 1:length(directionFilenames)
%     % Create the cache file name for each direction specified as part of the
%     % modulation.
%     [~, directionCacheFilename] = fileparts(directionFilenames{i});
%     
%     % Load the cached direction data.
%     [cacheData,isStale] = directionOLCache.load(directionCacheFilename);
%     assert(~isStale,'Cache file is stale, aborting.');  
%     directionParams(i) = cacheData.params;
%     directionData(i) = cacheData.data(protocolParams.observerAgeInYrs);
% end

% Currently we can only handle one direction, so break at this point if more
% than one specified in the modulation parameters.  
%
% Because we currently only handle one direction, map it to a nonconfusing variable
% name.  If there is someday a reason to allow more than one, this is where the code
% would start having to deal with it.

[directionCacheFile, startsStopsFileName, modulationParams.direction] = OLAssembleDirectionCacheAndStartsStopFileNames(protocolParams, modulationParams, directionName);

[cacheData,isStale] = directionOLCache.load(directionCacheFile);
assert(~isStale,'Cache file is stale, aborting.');  
directionParams = cacheData.directionParams;
directionData = cacheData.data(protocolParams.observerAgeInYrs);
clear cacheData

%% Say hello
if (p.Results.verbose); fprintf('\n* Computing modulation %s\n',modulationName); end;

%% Get the background
backgroundPrimary = directionData.backgroundPrimary;

% Get the modulation background and differences.
switch (directionParams.type)
    case 'modulation'
        modulationPrimary = directionData.modulationPrimarySignedPositive;
        diffPrimaryPos = directionData.modulationPrimarySignedPositive-backgroundPrimary;
        diffPrimaryNeg = directionData.modulationPrimarySignedNegative-backgroundPrimary;
    case {'pulse' 'lightfluxpulse'}
        modulationPrimary = directionData.modulationPrimarySignedPositive;
        diffPrimaryPos = modulationPrimary-backgroundPrimary;
    otherwise
        error('Unknown direction type specified')
end

%% Here compute the modulation and waveform as specified in the modulation file.
%
% IT WOULD BE NICE IF WE UNDERSTOOD THIS A LITTLE BETTER.
for f = 1:modulationParams.nFrequencies
    for pp = 1:modulationParams.nPhases
        for c = 1:modulationParams.nContrastScalars
            % Construct the time vector
            if strcmp(modulationParams.modulationMode, 'AM')
                waveform.theEnvelopeFrequencyHz = modulationParams.modulationFrequencyTrials(1); % Modulation frequency
                waveform.thePhaseDeg = modulationParams.modulationPhase(pp);
                waveform.thePhaseRad = deg2rad(modulationParams.modulationPhase(pp));
                waveform.theFrequencyHz = modulationParams.carrierFrequency(f);
            elseif ~isempty(strfind(modulationParams.modulationMode, 'pulse'))
                waveform.phaseRandSec = modulationParams.phaseRandSec(pp);
                waveform.stepTimeSec = modulationParams.stepTimeSec(f);
                waveform.preStepTimeSec = modulationParams.preStepTimeSec(f);
                waveform.theFrequencyHz = -1;
                waveform.thePhaseDeg = -1;
            else
                waveform.thePhaseDeg = modulationParams.carrierPhase(pp);
                waveform.thePhaseRad = deg2rad(modulationParams.carrierPhase(pp));
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
            
            if (p.Results.verbose)
                fprintf('*   Calculating %0.f s of %s, %.2f Hz, %.2f deg, %.1f pct contrast (of max)\n         ', waveform.duration, waveform.direction, waveform.theFrequencyHz, waveform.thePhaseDeg, 100*waveform.theContrastRelMax); 
            end;
            switch (directionParams.type)
                case 'modulation'
                    modulation(f, pp, c) = OLCalculateStartsStopsModulation(waveform, modulationParams.oneLightCal, backgroundPrimary, diffPrimaryPos, diffPrimaryNeg);
                case {'pulse' 'lightfluxpulse'}
                    modulation(f, pp, c) = OLCalculateStartsStopsModulation(waveform, modulationParams.oneLightCal, backgroundPrimary, diffPrimaryPos, []);
                otherwise
                    error('Unknown direction type specified.');
            end
            if (p.Results.verbose); fprintf('  - Done.\n'); end;
        end
    end
end

%% Put everything into a return strucure
modulationData.params = modulationParams;
modulationData.modulation = modulation;
modulationData.waveform = waveform;

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
    for k = 1:numel(protocolParams.directionNames)
        if (strcmp(protocolParams.directionNames{k}, directionName))
            protocolParams.type = protocolParams.directionTypes{k};
        end
    end

    fullDirectionName = sprintf('Direction_%s', directionName);
    fullStartsStopsName = sprintf('ModulationStartsStops_%s_%s', modulationParams.name, directionName);
    directionCacheFileName = fullfile(getpref(protocolParams.approach,'DirectionCorrectedPrimariesBasePath'), protocolParams.observerID,protocolParams.todayDate,protocolParams.sessionName, fullDirectionName);
    startsStopsFileName = fullfile(modulationParams.modulationDir, fullStartsStopsName);
end



