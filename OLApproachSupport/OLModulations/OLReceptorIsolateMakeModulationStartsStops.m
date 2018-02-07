function OLReceptorIsolateMakeModulationStartsStops(trialType, waveformParams, directionName, protocolParams, varargin)
%%OLReceptorIsolateMakeModulationStartsStops  Creates the starts/stops cache data for a given config file
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
%     Calls OLAssembleModulation to do most of the work -- this is primarily
%     a wrapper for that routine that handles parameter massaging as well as multiple
%     frequencies, phases and contrasts.
%
% Input:
%     trialType (integer)           Which trial type of the protocol is this.

%     modulationName (string)       The name of the modulation in the modulations dictionary.

%     directionName (string)        The name of the direciton in the directions dictionary.
%
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
% See also: OLMakeModulationsStartsStops, OLCacluateStartsStopsModulation, OLWaveformParamsDictionary.

% 04/19/13   dhb, ms     Update for new convention for desired contrasts in routine ReceptorIsolate.
% 06/17/17   dhb         Merge with mab version and expand comments.
% 06/23/17   npc         No more config files, get modulation properties from OLModulationParamsDictionary
% 08/21/17   dhb         Save protocolParams in output.  Also, save modulationParams in field modulationParams, rather than just params.
%                        Delete some commented out code, and don't pass trialType to OLAssembleDirectionCacheAndStartsStopFileNames because it was not being used.

%% Parse input to get key/value pairs
p = inputParser;
p.addRequired('waveformParams',@isstruct);
p.addRequired('directionName',@isstr);
p.addRequired('protocolParams',@isstruct);
p.addParameter('verbose',true,@islogical);
p.parse(waveformParams, directionName, protocolParams, varargin{:});

%% Get the corrected direction primaries
%
% These are currently in a cache file. These particular files should never
% be stale, so the role of using a cache file is to allow us to keep things
% separate by calibration and to detect staleness.  But, given that these
% are written in subject/date/session specific directories, staleness is
% and multiple cal files are both unlikely.
%
% Setup the cache object for read, and do the read.
directionCacheDir = fullfile(getpref(protocolParams.protocol,'DirectionCorrectedPrimariesBasePath'), protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
directionOLCache = OLCache(directionCacheDir, waveformParams.oneLightCal);
[directionCacheFile, startsStopsFileName, waveformParams.direction] = OLAssembleDirectionCacheAndStartsStopFileNames(protocolParams, waveformParams, directionName);

% Load direciton data, check for staleness, and pull out what we want
[cacheData,isStale] = directionOLCache.load(directionCacheFile);
assert(~isStale,'Cache file is stale, aborting.');
directionParams = cacheData.directionParams;
directionData = cacheData.data(protocolParams.observerAgeInYrs);
clear cacheData

%% Get the background
backgroundPrimary = directionData.backgroundPrimary;

%% Put primary data for direction into canonical form
diffPrimaryPos = directionData.differentialPositive;
diffPrimaryNeg = directionData.differentialNegative;

%% Construct the waverform from parameters
[directionWaveform, timestep, waveformDuration] = OLWaveformFromParams(waveformParams);

%% Assemble modulation
modulation = OLAssembleModulation(directionWaveform, waveformParams.oneLightCal, backgroundPrimary, diffPrimaryPos, diffPrimaryNeg);
modulation.timestep = timestep;
modulation.stimulusDuration = waveformDuration;

% We're treating the background real special here.
modulation.background.primaries = backgroundPrimary;
[modulation.background.starts, modulation.background.stops] = OLPrimaryToStartsStops(backgroundPrimary,waveformParams.oneLightCal);

%% Put everything into a return strucure
modulationData.modulationParams = waveformParams;
modulationData.protocolParams = protocolParams;
modulationData.modulation = modulation;

%% Save out the modulation
startsStopsFileName = sprintf('%s_trialType_%d',startsStopsFileName,trialType);
save(startsStopsFileName, 'modulationData');
if (p.Results.verbose); fprintf(['\tSaved modulation to ' startsStopsFileName '\n']); end
end

%%OLAssembleDirectionCacheAndStartsStopFileNames
%
% Put together the modulation file name from the modulation name and the direction name, and also
% get the name of the cache file where we'll read the direction.
function [directionCacheFileName, startsStopsFileName, directionName] = OLAssembleDirectionCacheAndStartsStopFileNames(protocolParams, waveformParams, directionName)

fullDirectionName = sprintf('Direction_%s', directionName);
fullStartsStopsName = sprintf('ModulationStartsStops_%s_%s', waveformParams.name, directionName);
directionCacheFileName = fullfile(getpref(protocolParams.protocol,'DirectionCorrectedPrimariesBasePath'), protocolParams.observerID,protocolParams.todayDate,protocolParams.sessionName, fullDirectionName);
startsStopsFileName = fullfile(waveformParams.modulationDir, fullStartsStopsName);
end