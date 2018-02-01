function [cacheData, directionOlCache, wasRecomputed] = OLReceptorIsolateMakeDirectionNominalPrimaries(approach,directionParams,forceRecompute,varargin)
% OLReceptorIsolateMakeDirectionNominalPrimaries  Computes nominal primaries for receptor-isolating directions.
%
% Usage:
%     [cacheData, olCache, wasRecomputed] = OLReceptorIsolateMakeDirectionNominalPrimaries(approach,directionParams,forceRecompute)
%
% Description:
%     Use the calibration file and observer age to find the nominal
%     primaries that will produce various receptor isolating modulations.
%     The directionParams structure contains all of the important
%     information, and is defined in the OLDirectionNominalPrimaries
%     dictionary.
%
%     This checks the cache file, and if things have already been computed
%     for the current calibration, it just returns what is there.  Cache
%     files are stored in the OLDirectionNominalPrimaries directory, specified
%     by the preferences for the current approach.
%
%     The parameters for the directions we know about are stored in the
%     direction dictionary, so that each direction's parameters are
%     associated with a direction name.
%
%     This routine knows about different types of directions:
%       bipolar - symmetric bipolar around a background.
%       unipolar - incremental positive unipolar relative to low end of swing around background.
%       lightfluxchrom - light flux pulse around a background of specified chromaticiity.
%
% Input:
%     approach (string)          Name of whatever approach is invoking this.
%
%     directionParams (struct)   Parameters struct for the direction.  See
%                                OLDirectionParamsDictionary.
%
%     forceRecompute (logical)   If true, forces a recompute of the data found in the config file.z
%                                Default: false
%
% Output:
%     cacheData (struct)         Cache data structure.  Contains background
%                                primaries and cal structure.
%
%     olCache (class)            Cache object for storing this.
%
%     wasRecomptued (boolean)    Was the cacheData recomputed?
%
% Optional key/value pairs
%     'verbose'                  Be chatty? (default, false).

% 04/19/13   dhb, ms     Update for new convention for desired contrasts in routine ReceptorIsolate.
% 02/25/14   ms          Modularized.
% 06/15/17   dhb et al.  Handle isStale return from updated cache code.
% 07/22/17   dhb         Enforce verbose
% 08/09/17   dhb, mab    Comment out code that stores difference, just return background and max modulations.
% 08/10/17   dhb         Return only postiive swing.  Because this is a nominal calculation, the negative swing is redundant.


%% Parse input
p = inputParser;
p.addRequired('approach',@ischar);
p.addRequired('directionParams',@isstruct);
p.addRequired('forceRecompute',@islogical);
p.addParameter('verbose',false,@islogical);
p.parse(approach,directionParams,forceRecompute,varargin{:});

%% Setup the directories we'll use. Directions go in their special place under the materials path approach directory.
cacheDir = fullfile(getpref(directionParams.approach, 'DirectionNominalPrimariesPath'));
if ~isdir(cacheDir)
    mkdir(cacheDir);
end

%% Load the calibration file
cal = LoadCalFile(OLCalibrationTypes.(directionParams.calibrationType).CalFileName, [], fullfile(getpref(approach, 'OneLightCalDataPath')));
assert(~isempty(cal), 'OLFlickerComputeModulationSpectra:NoCalFile', 'Could not load calibration file: %s', ...
    OLCalibrationTypes.(directionParams.calibrationType).CalFileName);

%% Create the direction cache object and filename
directionOlCache = OLCache(cacheDir, cal);
[~, directionCacheFileName] = fileparts(directionParams.cacheFile);

%% Need to check here whether we can just use the current cached data and do so if possible.
%
% If we don't need to recompute, we just return, cacheData in hand.  Otherwise we
% compute.
if (~forceRecompute)
    if (directionOlCache.exist(directionCacheFileName))
        [cacheData,isStale] = directionOlCache.load(directionCacheFileName);
        
        % Compare cacheData.describe.params against currently passed
        % parameters to determine if everything is hunky-dory.  This throws
        % an error if not.  Could recompute, but we want the user to
        % think about this case and make sure it wasn't just an error.
        OLCheckCacheParamsAgainstCurrentParams(cacheData, directionParams);
        
        if (~isStale)
            wasRecomputed = false;
            return;
        else
            clear cacheData;
        end
    end
end

%% OK, if we're here we need to compute.
% Grab the background from the cache file
backgroundCacheDir = fullfile(getpref(approach, 'BackgroundNominalPrimariesPath'));
backgroundOlCache = OLCache(backgroundCacheDir, cal);
backgroundCacheFile = ['Background_' directionParams.backgroundName '.mat'];
[backgroundCacheData,isStale] = backgroundOlCache.load(backgroundCacheFile);
assert(~isStale,'Background cache file is stale, aborting.');
backgroundPrimary = backgroundCacheData.data(directionParams.backgroundObserverAge).backgroundPrimary;

cacheData.data = OLDirectionNominalStructFromParams(directionParams,backgroundPrimary,cal);

%% Tuck in the calibration structure for return
cacheData.cal = cal;
cacheData.directionParams = directionParams;
wasRecomputed = true;

end
