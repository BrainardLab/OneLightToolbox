function [cacheData, isStale] = load(obj, cacheFileName)
% load - Loads cacheData structure from a cache file.
%
% Syntax:
% [cacheData, isStale] = obj.load(cacheFileName)
%
% Description:
% Loads a cache file from the cache folder stored in the OLCache object.
% Compares the calibration data stored in the case against the calibration
% stored in the OLCache object to make sure that cache is in sync with the
% desired calibration data.
%
% If the stored cache data is stale (that is, if the passed calibration
% structure doesn't match the stored one), then cacheData is returned as
% the empty matrix and the isStale return variable is set to true. The
% calling routine can check for this and do a recompute and save, if
% desired.
%
% Input:
% cacheFileName (string) - Name of the cache file in the cache directory to
%                          load.   This does NOT include the .mat extension
%                          of the actual file on disk.
%
% Output:
% cacheData (struct) - The cache file data.  
% isStale (logical) - True if the cache data should be recomputed.
%
% See also: OlCache.

% 06/09/17  dhb, mab  Updating for no more compute method era.

% Validate the number of inputs.
narginchk(2, 2);

% Force a .mat ending.
[~, cacheFileName] = fileparts(cacheFileName);
cacheFileName = [cacheFileName, '.mat'];

% Check if the cache file and the desired data exist.  Note that I'm using
% the OLCache object function "exist" to check this, not the built in
% Matlab version.
assert(obj.exist(cacheFileName), 'OLCache:load:InvalidCacheFile', ...
	'Cannot find cache in file "%s"', cacheFileName);

% Load the file.
fullFileName = fullfile(obj.CacheDirectory, cacheFileName);
data = load(fullFileName);

% The cache data is stored in a subfield with the same name as the
% calibration type.  This way we can have multiple types of calibrated data
% in the same file.  The data is stored as a cell array so as to keep a
% history of all the cache data we save.
cacheHistory = data.(obj.CalibrationData.describe.calType.char);
cacheData = cacheHistory{end};

% Make sure that cacheData is a struct.
assert(isstruct(cacheData), 'OLCache:load:BadCacheData', 'cacheData must be a struct.');

% Make sure there is a field in cacheData called cal
assert(isfield(cacheData,'cal'),'OLCache:load:BadCacheData', 'cacheData must must have a ''cal'' field.');

% Check whether cached data is out of sync with the current calibration data passed to
% OLCache when the cache object was created.  If so, set isStale return
% to true and return empty cacheData.  Otherwise set isStale return to
% false.
if ~strcmp(cacheData.cal.describe.date, obj.CalibrationData.describe.date) 
	cacheData = [];
    isStale = true;
else
    isStale = false;
end

end
