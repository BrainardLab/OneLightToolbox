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

%% Make dictionary with direction-specific params for all directions
paramsDictionary = OLBackgroundNominalParamsDictionary();

%% Loop over directions
for ii = 1:length(approachParams.backgroundNames)
    generateAndSaveBackgroundPrimaries(approachParams,paramsDictionary,approachParams.backgroundNames{ii});
end
end

function generateAndSaveBackgroundPrimaries(approachParams, paramsDictionary, backgroundName)

% Get background primaries
backgroundParams = OLMergeBaseParamsWithParamsFromDictionaryEntry(approachParams, paramsDictionary, backgroundName);

% The called routine checks whether the cacheFile exists, and if so and
% it isnt' stale, just returns the data.
[cacheDataBackground, olCacheBackground, wasRecomputed] = OLReceptorIsolateMakeBackgroundNominalPrimaries(approachParams.approach,backgroundParams, false, 'verbose', approachParams.verbose);

% Save the background primaries in a cache file, if it was recomputed.
if (wasRecomputed)
    [~, cacheFileName] = fileparts(backgroundParams.cacheFile);
    olCacheBackground.save(cacheFileName, cacheDataBackground);
end
end


