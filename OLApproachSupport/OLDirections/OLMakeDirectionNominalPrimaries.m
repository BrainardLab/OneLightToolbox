function OLMakeDirectionNominalPrimaries(approachParams,varargin)
% OLMakeDirectionNominalPrimaries - Calculate the nominal direction primaries for the experiment
%
% Usage:
%     OLMakeDirectionNominalPrimaries(approachParams)
%
% Description:
%     This function calculations the nominal direction primaries required for the
%     this approach, for the extrema of the modulations.  Typically,
%     these will be tuned up by spectrum seeking on the day of the experiment.
%
%     The primaries depend on the calibration file, on the parameters of
%     the direction, and on the observer age.  Some of the direction parameters
%     (e.g. field size, pupil size) are denoted in the direction name, while others
%     (e.g. primary headroom) are implicit.  Varying the latter should be accompanied
%     by a change in direction name, or at least done with great caution.
%
%     When the cache is created, it is done for all observer ages, so these can be looked up.
%
%     Different calibration files are handled by the cache file mechanism.
%
%     The output is cached in the directory specified by
%     getpref(approachParams.approach,'DirectionNominalPrimariesPath');
%
% Input:
%
% Output:
%     Creates nominal direction files in the right place (specified by approach prefs).
%
% Optional key/value pairs:
%     verbose (logical)    Be chatty? (default false)

% 6/18/17  dhb  Added header comment.
% 6/22/17  npc  Dictionarized direction params, cleaned up.
% 7/05/17  dhb  Big rewrite.
% 07/22/17 dhb  Enforce verbose flag

%% Parse 
p = inputParser;
p.addRequired('approachParams',@isstruct);
p.addOptional('verbose',false,@islogical);
p.parse(approachParams,varargin{:});
approachParams.verbose = p.Results.verbose;

%% Setup the directories we'll use. 
% Directions go in their special place under the materials path approach
% directory.
cacheDir = fullfile(getpref(approachParams.approach, 'DirectionNominalPrimariesPath'));
if ~isdir(cacheDir)
    mkdir(cacheDir);
end

%% Load the calibration file
cal = OLGetCalibrationStructure('CalibrationType',approachParams.calibrationType,'CalibrationDate','latest');

%% Get dictionary with direction-specific params for all directions
paramsDictionary = OLDirectionParamsDictionary();

%% Loop over directions
for ii = 1:length(approachParams.directionNames)
    directionName = approachParams.directionNames{ii};
    % Get direction parameters out of the dictionary.
    %
    % The approach parameters structure specifies some direction independent
    % information, such as the calibration names to be used.
    directionParams = OLMergeBaseParamsWithParamsFromDictionaryEntry(approachParams, paramsDictionary, directionName);

    % Create the cache object and filename
    olCache = OLCache(cacheDir, cal);
    [~, cacheFileName] = fileparts(directionParams.cacheFile);

    % Check if exist && if stale
    if (olCache.exist(cacheFileName))
        [cacheData,isStale] = olCache.load(cacheFileName);
        % Compare cacheData.describe.params against currently passed
        % parameters to determine if cache is stale.   Could recompute, but
        % we want the user to think about this case and make sure it wasn't
        % just an error.
        OLCheckCacheParamsAgainstCurrentParams(cacheData, directionParams);
        if isStale
            recompute = true;
        else
            recompute = false;
        end
    else
        recompute = true;
    end
    
    % If not, recompute
    if recompute
        % Grab the background from the cache file
        backgroundCacheDir = fullfile(getpref(approachParams.approach, 'BackgroundNominalPrimariesPath'));
        backgroundOlCache = OLCache(backgroundCacheDir, cal);
        backgroundCacheFile = ['Background_' directionParams.backgroundName '.mat'];
        [backgroundCacheData,isStale] = backgroundOlCache.load(backgroundCacheFile);
        assert(~isStale,'Background cache file is stale, aborting.');
        backgroundPrimary = backgroundCacheData.data(directionParams.backgroundObserverAge).backgroundPrimary;
        
        % Generate direction struct
        directionStruct = OLDirectionNominalStructFromParams(directionParams,backgroundPrimary,cal);
        
        cacheDataDirection.data = directionStruct;
        cacheDataDirection.directionParams = directionParams;
        cacheDataDirection.cal = cal;
    end
    
    % Save out
    olCache.save(cacheFileName, cacheDataDirection);   
end