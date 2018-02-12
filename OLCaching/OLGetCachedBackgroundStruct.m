function backgroundStruct = OLGetCachedBackgroundStruct(approach, backgroundName, calibration, varargin)
% Tries to get a backgroundStruct from cachefile, can attempt recompute.
%
% Syntax:
%   OLMakeBackgroundNominalPrimaries(approachParams)
%
% Description:
%    This function gets a background struct, consisting of primary values
%    for the background and metadata, from cache files. The background
%    struct to find is indicated by a name, which must be the name of the
%    background in the corresponding cachefile. If the background needs
%    does not exist and should be computed, backgroundName must also
%    correspond to an entry in the OLBackgroundParamsDictionary. A list can
%    be obtained through OLGetBackgroundNames.
%
%    The primaries depend on the calibration and on parameters of field
%    size and pupil size, and also observer age.  The whole range of ages
%    is computed inside a cache file, with the cache file name giving field
%    size and pupil size info.
%
%    The output is cached in the directory specified by
%    getpref(approachParams.approach,'BackgroundNominalPrimariesPath');
%
% Inputs:
%    approach         - Name of the current approach. Cache directory
%                       depends on this.
%    backgroundName   - Name corresponding to a background in a cachefile. 
%                       If the background needs does not exist and should
%                       be computed, backgroundName must also correspond to
%                       an entry in the OLBackgroundParamsDictionary. A
%                       list can be obtained through OLGetBackgroundNames.
%    calibration      - OneLight calibration struct
%
% Outputs:
%    backgroundStruct - a 1x60 struct array (one struct per observer age
%                       1:60 yrs), with the following fields:
%                          * backgroundPrimary   : the primary values for
%                                                 the background.
%                          * describe            : Any additional
%                                                 (meta)-information that
%                                                 might be stored
%
% Optional key/value pairs:
%    compute        - Boolean flag, compute if not found in cache, or if 
%                     stale. If false and background cannot be found in
%                     cache, throws an error. If true, gives a warning and
%                     tries to recompute. Default is true.
%    verbose        - Boolean flag for printing information to console.
%                     Default false. 
%
% See also:
%    OLGetBackgroundNames

% History:
%    01/31/18  jv  wrote it, based on OLMakeBackgroundNominalPrimaries.

%% Input validation
parser = inputParser;
parser.addRequired('approach',@ischar);
parser.addRequired('backgroundName',@ischar);
parser.addRequired('calibration',@isstruct);
parser.addParameter('compute',true,@islogical);
parser.addParameter('verbose',false,@islogical);
parser.parse(approach,backgroundName,calibration,varargin{:});

%% Find cache directory
% Backgrounds go in their special place under the materials path approach
% directory.
cacheDir = fullfile(getpref(approach, 'BackgroundNominalPrimariesPath'));
if ~isdir(cacheDir)
    if ~parser.Results.compute
        error('Background not found in cache');
    else
        mkdir(cacheDir);
    end
end

%% Create the cache object and filename
olCache = OLCache(cacheDir, calibration);
cacheFileName = sprintf('Background_%s',backgroundName);

%% Check if exist && if stale
if olCache.exist(cacheFileName)
    [cacheData,isStale] = olCache.load(cacheFileName);   
    if ~isStale
        isCached = true; % Not stale, so we have cacheData
    else
        isCached = false; % stale data
    end
else
    isCached = false; % no cachefile
end

%% Generate output struct;
if ~isCached
    if ~parser.Results.compute
        % user doesn't want to compute
        error('OneLightToolbox:Cache:NotFound','Cached background not found, not recomputing');
    else
        % try to recompute
        if parser.Results.verbose
            warning('OneLightToolbox:Cache:NotFound','Cached background not found. Attempt to recompute.');  
        end
        
        % Get params
        backgroundParams = OLBackgroundParamsFromName(backgroundName);
        
        if exist('cacheData','var') && ~isempty(cacheData)
            % if cacheData exist, parameters might be different than
            % dictionary, we should respect this. If compatible.
            OLCheckCacheParamsAgainstCurrentParams(cacheData, backgroundParams);
            backgroundParams = cacheData.params;
        end
        
        % Make background
        backgroundPrimary = OLBackgroundNominalPrimaryFromParams(backgroundParams, calibration, 'verbose', parser.Results.verbose);

        % Fill in for all observer ages based on the nominal calculation.
        for observerAgeInYears = 20:60     
            backgroundStruct(observerAgeInYears).backgroundPrimary = backgroundPrimary;
        end     
        
        % Save out
        cacheDataBackground.data = backgroundStruct;
        cacheDataBackground.params = backgroundParams;
        cacheDataBackground.cal = calibration;
        olCache.save(cacheFileName, cacheDataBackground);
        
        % Return
        backgroundStruct = cacheDataBackground;
    end
else
    backgroundStruct = cacheData.data;
end

end