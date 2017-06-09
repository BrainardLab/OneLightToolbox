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
% The cacheData struct that is passed must have a field called cal, which
% should be a OneLight calibration struct.  The calibrationType of this
% structure must match that used when the cache object was created with the
% call to OLCache. To save space, the cache file does not tuck away the full calibration
% structure, just its describe field.
%
% It can then contain any other fields that you like, which are typically
% the computed data that you are caching and perhaps information that was
% used to compute such data.
%
% As the cache file builds up, the actual .mat file contains cell arrays
% for each calibration type passed, with the name of the cell array
% matching the name of the calibration type. Each of these cell arrays is a
% history of the sequential order of variables saved.
%
% We do not explicitly check that the fields of cacheData are consistent
% across saves, but you would be wise to make this be the case just for
% your own sanity.
%
% Input:
% cacheFileName (string) - Name of the cache file.  This does NOT include
%                          the .mat extension of the actual file on disk.
% cacheData (struct) - The cache data to save.
%
% See also: OLCache.

% Validate the number of inputs.
narginchk(3, 3);

% Make sure that cacheData is a struct.
assert(isstruct(cacheData), 'OLCache:save:InvalidInput', 'cacheData must be a struct.');

% Make sure there is a field in cacheData called cal
assert(isfield(cacheData,'cal'),'OLCache:save:InvalidInput', 'cacheData must must have a ''cal'' field.');

% Sometimes the cacheData.cal.describe.calType ends up as a struct. Or at
% least this happened once.  We don't know why.  But this will check for
% it, and print a possibly useful error message if it happens again.
if (~isa(cacheData.cal.describe.calType,'OLCalibrationTypes'))
    fprintf('Field calType of cacheData.cal.describe is not an enumeration of class OLCalibrationTypes\n');
    fprintf('Probably it ended up as a struct.\n');
    fprintf('This should not happen, but has happened in the past for unknown reasons.\n');
    fprintf('The assertion that is about to run below will probably fail for this reason.\n');
    fprintf('Rebuilding the cache file may make the problem go away.\n');
end

% Might as well check the field in the stashed cal file as well
if (~isa(obj.CalibrationData.describe.calType,'OLCalibrationTypes'))
    fprintf('Field calType of obj.CalibrationData.describe is not an enumeration of class OLCalibrationTypes\n');
    fprintf('This is indicative of a problem, but one whose origin we do not completely understand.\n');
    fprintf('The assertion that is about to run below will probably fail for this reason.\n');
    fprintf('Try loading in the calibration file and making sure that the type is right when loaded directly\n');   
end

% Make sure the cache data were saving is of the same type as that of the
% OLCache object.
assert(cacheData.cal.describe.calType == obj.CalibrationData.describe.calType, ...
	'OLCache:save:CalTypeMismatch', 'Calibration type of the data being saved doesn''t match that of the OLCache object.');

% Adding a .mat ending to the passed filename.
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

% We just store the description field of the cal structure, because all we
% need to do in the future is check whether its type and whether it is stale.  This saves
% some space as cache file history gets longer.
tmp = cacheData.cal.describe;
cacheData.cal = [];
cacheData.cal.describe = tmp;

% Update the cache data structure.
%
% The code obj.CalibrationData.describe.calType.char gets us a string
% that matches the calibrationType that was specified when the cache file
% object was created, and we verified above that this also matches the
% calibration type of the cal field of the passed cacheData structure. 
%
% The cache file uses variables that match the calibration types as struct
% arrays that contain the history of the data cached for each calibration
% type.
%
% So either there is such a struct array already in the file (so it will
% show up as a field in the data variable that we loaded) or there isn't.
% If there is, we append the current data to the extant cell array.
% If there isn't, we create a new cell array with the appropriate name.
if isfield(data, obj.CalibrationData.describe.calType.char)
	data.(obj.CalibrationData.describe.calType.char){end+1} = cacheData;
else
	data.(obj.CalibrationData.describe.calType.char){1} = cacheData;
end

% Save the cache data.
%
% This syntax of Matlab's save command takes all of
% the fields of the passed variable and stores them in the .mat files as
% individual variables.  This basically inverts the fact that we initially
% loaded all of those variables into the struct data.
save(fullFileName, '-struct', 'data');
