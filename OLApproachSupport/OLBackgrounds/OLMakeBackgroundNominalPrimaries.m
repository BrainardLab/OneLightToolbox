function OLMakeBackgroundNominalPrimaries(approachParams,varargin)
% Create the background nominal primaries, if they don't exist.
%
% Syntax:
%   OLMakeBackgroundNominalPrimaries(approachParams)
%
% Description:
%    This function calculations background nominal primaries and saves them in
%    cache files.  Typically, these are then incorporated into calculation
%    of nominal direction primaries.
%
%    The primaries depend on the calibration file and on parameters of
%    field size and pupil size, and also observer age.  The whole range of
%    ages is computed inside a cache file, with the cache file name giving
%    field size and pupil size info.
%
%    The output is cached in the directory specified by
%    getpref(approachParams.approach,'BackgroundNominalPrimariesPath');
%
% Inputs:
%    approachParams - Structure defining key approach parameters.
%
% Outputs:
%    None.          - Creates nominal background files in the directory
%                     specified by getpref(approachParams.approach,'BackgroundNominalPrimariesPath');
%
% Optional key/value pairs:
%    verbose        - Boolean flag for printing information to console.
%                     Default is false.

% History:
%    06/18/17  dhb  Added header comment.
%    06/22/17  npc  Dictionarized direction params, cleaned up.
%    07/22/17  dhb  Enforce verbose flag
%    01/31/18  jv   Absorbed 
%                   OLReceptorIsolateMakeBackgroundNominalPrimaries, use
%                   new OLBackgroundNominalPrimaryFromParams

%% Input validation 
parser = inputParser;
parser.addRequired('approachParams',@isstruct);
parser.addParameter('verbose',false,@islogical);
parser.parse(approachParams,varargin{:});

%% Setup the directories we'll use. 
% Backgrounds go in their special place under the materials path approach
% directory.
cacheDir = fullfile(getpref(approachParams.approach, 'BackgroundNominalPrimariesPath'));
if ~isdir(cacheDir)
    mkdir(cacheDir);
end

%% Load the calibration file
calibration = OLGetCalibrationStructure('CalibrationType',approachParams.calibrationType,'CalibrationDate','latest');

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
    olCache = OLCache(cacheDir, calibration);
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
        backgroundPrimary = OLBackgroundNominalPrimaryFromParams(backgroundParams, calibration, 'verbose', parser.Results.verbose);

        % Fill in for all observer ages based on the nominal calculation.
        for observerAgeInYears = 20:60     
            cacheDataBackground.data(observerAgeInYears).backgroundPrimary = backgroundPrimary;
        end
        cacheDataBackground.params = backgroundParams;
        cacheDataBackground.cal = calibration;
    end
    
    % Save out
    olCache.save(cacheFileName, cacheDataBackground);
end