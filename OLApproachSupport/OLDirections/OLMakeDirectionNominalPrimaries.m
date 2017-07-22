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

%% Get dictionary with direction-specific params for all directions
paramsDictionary = OLDirectionNominalParamsDictionary();

%% Loop over directions
for ii = 1:length(approachParams.directionNames)
    generateAndSaveBackgroundPrimaries(approachParams,paramsDictionary,approachParams.directionNames{ii});
end
end

function generateAndSaveBackgroundPrimaries(approachParams, paramsDictionary, directionName)
% Get background primaries
directionParams = OLMergeBaseParamsWithParamsFromDictionaryEntry(approachParams, paramsDictionary, directionName);

% The called routine checks whether the cacheFile exists, and if so and
% it isnt' stale, just returns the data.
[cacheDataDirection, olCacheDirection, wasRecomputed] = OLReceptorIsolateMakeDirectionNominalPrimaries(approachParams.approach,directionParams,false,'verbose',approachParams.verbose);

% Save the direction primaries in a cache file, if it was recomputed.
if (wasRecomputed)
    [~, cacheFileName] = fileparts(directionParams.cacheFile);
    olCacheDirection.save(cacheFileName, cacheDataDirection);
end
end


