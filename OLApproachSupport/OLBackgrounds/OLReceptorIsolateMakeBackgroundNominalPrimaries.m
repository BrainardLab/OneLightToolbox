function [cacheData, olCache, wasRecomputed] = OLReceptorIsolateMakeBackgroundNominalPrimaries(approach,backgroundParams,forceRecompute, varargin)
% OLReceptorIsolateMakeBackgroundNominalPrimaries  Finds backgrounds according to background parameters.
%
% Usage:
%     [cacheData, olCache, wasRecomputed] = OLReceptorIsolateMakeBackgroundNominalPrimaries(approach,backgroundParams,forceRecompute)
%
% Description:
%     Use calibration file information to make backgrounds with specified
%     properties.  Background properties are defined in the
%     BackgroundNominalPrimaries dictionary and passed as a parameter struct,
%     except for a few that are specifically named and that are calibration independent.
%
%     This checks the cache file, and if things have already been computed
%     for the current calibration, it just returns what is there.  Cache
%     files are stored in the BackgroundNominalPrimaries directory, specified
%     by the preferences for the current approach.
%
%     The parameters for the directions we know about are stored in the
%     background dictionary, so that each direction's parameters are
%     associated with a background name.
%
%     The background is just computed for a nominal (backgroundParams.backgroundObserverAge) observer age,
%     because we don't need perfection for this, just something about right.
%
%     This routine knows about different types of backgrounds:
%       named - a specific named background
%
%       lightfluxchrom - background of a specified chromaticity, scaled to allow a light flux modulation.
%
%       optimized - a background optimized for some modulation.
%
% Input:
%     approach (string)          Name of whatever approach is invoking this.
%
%     backgroundParams (struct)  Parameters struct for backgrounds.  See
%                                OLBackgroundParamsDictionary.
%
%     forceRecompute (logical)   If true, forces a recompute of the data found in the config file.
%                                Default: false
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

% 06/29/17   dhb         Cleaning up.
% 07/05/17   dhb         Better comments.

% 07/22/17   dhb         Enforce verbose

%% Parse input
p = inputParser;
p.addRequired('approach',@ischar);
p.addRequired('backroundParams',@isstruct);
p.addRequired('forceRecompute',@islogical);
p.addParameter('verbose',false,@islogical);
p.parse(approach,backgroundParams,forceRecompute,varargin{:});

%% Setup the directories we'll use. Backgrounds go in their special place under the materials path approach directory.
cacheDir = fullfile(getpref(approach, 'BackgroundNominalPrimariesPath'));
if ~isdir(cacheDir)
    mkdir(cacheDir);
end

%% Load the calibration file
cal = LoadCalFile(OLCalibrationTypes.(backgroundParams.calibrationType).CalFileName, [], fullfile(getpref(approach,'OneLightCalDataPath')));
assert(~isempty(cal), 'OLFlickerComputeModulationSpectra:NoCalFile', 'Could not load calibration file: %s', ...
    OLCalibrationTypes.(backgroundParams.calibrationType).CalFileName);

%% Pull out S
S = cal.describe.S;

%% Create the cache object and filename
olCache = OLCache(cacheDir, cal);
[~, cacheFileName] = fileparts(backgroundParams.cacheFile);

%% Need to check here whether we can just use the current cached data and do so if possible.
%
% If we don't need to recompute, we just return, cacheData in hand.  Otherwise we
% compute.
if (~forceRecompute)
    if (olCache.exist(cacheFileName))
        [cacheData,isStale] = olCache.load(cacheFileName);
        
        % Compare cacheData.describe.params against currently passed
        % parameters to determine if cache is stale.   Could recompute, but
        % we want the user to think about this case and make sure it wasn't
        % just an error.
        OLCheckCacheParamsAgainstCurrentParams(cacheData, backgroundParams);
 
        if (~isStale)
            wasRecomputed = false;
            return;
        else
            clear cacheData;
        end
    end
end

%% OK, need to recompute
backgroundPrimary = OLBackgroundNominalPrimaryFromParams(backgroundParams, cal, 'verbose', p.Results.verbose);

 %% Fill in the cache data for return
 % Fill in for all observer ages based on the nominal calculation.
 for observerAgeInYears = 20:60     
     % The background
     cacheData.data(observerAgeInYears).backgroundPrimary = backgroundPrimary;
 end
 
% Calibration file, and note that we recomputed the cache data.
cacheData.params = backgroundParams;
cacheData.cal = cal;
wasRecomputed = true;

end