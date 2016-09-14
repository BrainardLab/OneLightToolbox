function save(obj, cacheFileName, cacheData)
% save - Saves cache data to a cache file in the stored cache folder.
%
% Syntax:
% obj.save(cacheFileName, cacheData)
%
% Description:
% Takes the data contained in "cacheData" and saves it to the cache folder.
% Cache files keep a history of cache data saved to them, so if the file
% already exists, the old data is saved along with it.
%
% Input:
% cacheFileName (string) - Name of the cache file.
% cacheData (struct) - The cache data to save.

% Validate the number of inputs.
error(nargchk(3, 3, nargin));

% Make sure that cacheData is a struct.
assert(isstruct(cacheData), 'OLCache:save:InvalidInput', 'cacheData must be a struct.');

% Make sure the cache data were saving is of the same type as that of the
% OLCache object.
assert(cacheData.cal.describe.calType == obj.CalibrationData.describe.calType, ...
	'OLCache:save:CalTypeMismatch', 'Calibration type of the data being saved doesn''t match that of the OLCache object.');

% Force a .mat ending.
[~, cacheFileName] = fileparts(cacheFileName);
cacheFileName = [cacheFileName, '.mat'];

fullFileName = fullfile(obj.CacheDirectory, cacheFileName);

% If the cache file exists, we want to load it and append the data so
% we don't trash any data from other calibration types.
if exist(fullFileName, 'file');
	% Load the file.
	data = load(fullFileName);
else
	data = [];
end

% Append a date so that this cache data has a unique identifier.
cacheData.date = datestr(now);
tmp = cacheData.cal.describe;
cacheData.cal = [];
cacheData.cal.describe = tmp;

% Update the cache data structure.
if isfield(data, obj.CalibrationData.describe.calType.char)
	data.(obj.CalibrationData.describe.calType.char){end+1} = cacheData;
else
	data.(obj.CalibrationData.describe.calType.char){1} = cacheData;
end

% Save the cache data.
save(fullFileName, '-struct', 'data');
