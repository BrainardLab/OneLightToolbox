function cacheExists = exist(obj, cacheFileName)
% exist - Checks if a cache file and its data exist.
%
% Syntax:
% cacheFileExists = obj.exist(cacheFileName)
%
% Description:
% Checks to see if the specified cache file exists in the cache directory,
% and that the cache data corresponding to the calibration type also
% exists.
%
% Input:
% cacheFileName (string) - Name of the cache file in the cache directory to
%                          load.   This does NOT include the .mat extension
%                          of the actual file on disk.
%
% Output:
% cacheExists (logical) - True if the cache file and data exist, false
%     if either condition is not true.
%
% See also: OLCache.

% Validate the number of inputs.
narginchk(2, 2);

% Force a .mat ending.
[~, cacheFileName] = fileparts(cacheFileName);
cacheFileName = [cacheFileName, '.mat'];

% Look to see if the .mat file exists.
fullFileName = fullfile(obj.CacheDirectory, cacheFileName);
cacheExists = logical(exist(fullFileName, 'file'));

% If the file exists, we need to make sure it has a subfield containing the
% data of the same type as the calibration type.
if cacheExists
    % Load the cache file.
    data = load(fullFileName);
    
    % Look to see if it has the required subfield.
    if ~any(strcmp(obj.CalibrationData.describe.calType.char, fieldnames(data)))
        cacheExists = false;
    end
end
