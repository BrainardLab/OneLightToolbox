function OLMakeBackgroundNominalPrimaries(approachParams,varargin)
% OLMakeBackgroundNominalPrimaries - Calculate the background nominal primaries
%
% Usage:
%     OLMakeBackgroundNominalPrimaries(approachParams)
%
% Description:
%     This function calculations background nominal primaries and saves them in
%     cache files.  Typically, these are then incorporated into calculation
%     of nominal direction primaries.
%
%     The primaries depend on the calibration file and on parameters of
%     field size and pupil size, and also observer age.  The whole range of
%     ages is computed inside a cache file, with the cache file name giving
%     field size and pupil size info.
%
%     The output is cached in the directory specified by
%     getpref(approachParams.approach,'BackgroundNominalPrimariesPath');
%
% Input:
%     approachParams (struct)   Structure defining key approach parameters.
%
% Output:
%     Creates nominal background files in the right place (specified by approach prefs).
%
% Optional key/value pairs:
%     verbose (logical)    Be chatty? (default false)

% 6/18/17  dhb  Added header comment.
% 6/22/17  npc  Dictionarized direction params, cleaned up.
% 07/22/17 dhb  Enforce verbose flag

%% Parse 
p = inputParser;
p.addRequired('approachParams',@isstruct);
p.addOptional('verbose',false,@islogical);
p.parse(approachParams,varargin{:});
approachParams.verbose = p.Results.verbose;

%% Setup the directories we'll use. 
% Backgrounds go in their special place under the materials path approach
% directory.
cacheDir = fullfile(getpref(approachParams.approach, 'BackgroundNominalPrimariesPath'));
if ~isdir(cacheDir)
    mkdir(cacheDir);
end

%% Load the calibration file
cal = OLGetCalibrationStructure('CalibrationType',approachParams.calibrationType,'CalibrationDate','latest');

%% Make dictionary with direction-specific params for all directions
paramsDictionary = OLBackgroundParamsDictionary();

%% Loop over directions
for ii = 1:length(approachParams.backgroundNames)
    backgroundName = approachParams.backgroundNames{ii};
    % Get background parameters out of the dictionary.
    %
    % The approach parameters structure specifies some background independent
    % information, such as the calibration names to be used.
    backgroundParams = OLMergeBaseParamsWithParamsFromDictionaryEntry(approachParams, paramsDictionary, backgroundName);

    % Create the cache object and filename
    olCache = OLCache(cacheDir, cal);
    [~, cacheFileName] = fileparts(backgroundParams.cacheFile);

    % Check if exist && if stale
    if (olCache.exist(cacheFileName))
        [cacheData,isStale] = olCache.load(cacheFileName);
        % Compare cacheData.describe.params against currently passed
        % parameters to determine if cache is stale.   Could recompute, but
        % we want the user to think about this case and make sure it wasn't
        % just an error.
        OLCheckCacheParamsAgainstCurrentParams(cacheData, backgroundParams);
    end
    
    % If not, recompute
    if ~exist('isStale','var') || isStale
        backgroundPrimary = OLBackgroundNominalPrimaryFromParams(backgroundParams, cal, 'verbose', p.Results.verbose);

        % Fill in for all observer ages based on the nominal calculation.
        for observerAgeInYears = 20:60     
            cacheDataBackground.data(observerAgeInYears).backgroundPrimary = backgroundPrimary;
        end
        cacheDataBackground.params = backgroundParams;
        cacheDataBackground.cal = cal;
    end
    
    % Save out
    olCache.save(cacheFileName, cacheDataBackground);
end