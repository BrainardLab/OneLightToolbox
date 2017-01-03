function [cacheData,cal,cacheFileName, cacheDir, cacheFileName] = OLGetModulationCacheData(cacheFileNameFullPath)
%%OLGetModulationCacheData  Open a modulation cache file and get the data for a particular calibration.
%    [cacheData,cal,cacheDir,cacheFileName] = OLGetModulationCacheData(cacheFileNameFullPath); 
%
%     User is prompoted for desired calibration file.

%% Open cache file and get data
%
% Force the file to be an absolute path instead of a relative one.  We do
% this because files with relative paths can match anything on the path,
% which may not be what was intended.  The regular expression looks for
% string that begins with '/' or './'.
m = regexp(cacheFileNameFullPath, '^(\.\/|\/).*', 'once');
assert(~isempty(m), 'OLValidateCacheFile:InvalidPathDef', ...
    'Cache file name must be an absolute path.');

%% Make sure the cache file exists.
assert(logical(exist(cacheFileNameFullPath, 'file')), 'OLValidateCacheFile:FileNotFound', ...
    'Cannot find cache file: %s', cacheFileNameFullPath);

%% Deduce the cache directory and load the cache file
[cacheDir,cacheFileName] = fileparts(cacheFileNameFullPath);
data = load(cacheFileNameFullPath);
assert(isstruct(data), 'OLValidateCacheFile:InvalidCacheFile', ...
    'Specified file doesn''t seem to be a cache file: %s', cacheFileNameFullPath);

%% List the available calibration types found in the cache file.
foundCalTypes = sort(fieldnames(data));

%% Check cache calibrations
%
% Make sure that at least one of the calibration types in the calibration file
% is current.
[~, validCalTypes] = enumeration('OLCalibrationTypes');
for i = 1:length(foundCalTypes)
    typeExists(i) = any(strcmp(foundCalTypes{i}, validCalTypes));
end
assert(any(typeExists), 'OLValidateCacheFile:InvalidCacheFile', ...
    'File contains does not contain at least one valid calibration type');

%% Select calibration type to validate
%
% Either it was passed and we select that one, or we ask the user.
while true
    % Check if 'selectedCalType' was passed.  Go with that if it was in the
    % calibration file.
    %
    % It might be clever to check that the passed type is valid.
    if (isfield(describe, 'selectedCalType')) && any(strcmp(foundCalTypes, describe.selectedCalType))
        selectedCalType = describe.selectedCalType;
        break;
    end
    
    % Prompt user, distinguishing currently valid types in menu.
    fprintf('\n- Calibration Types in Cache File (*** = valid)\n\n');   
    for i = 1:length(foundCalTypes)
        if typeExists(i)
            typeState = '***';
        else
            typeState = '---';
        end
        fprintf('%i (%s): %s\n', i, typeState, foundCalTypes{i});
    end
    fprintf('\n'); 
    t = GetInput('Select a Number', 'number', 1);
    if t >= 1 && t <= length(foundCalTypes) && typeExists(t);
        fprintf('\n');
        selectedCalType = foundCalTypes{t};
        break;
    else
        fprintf('\n*** Invalid selection try again***\n\n');
    end
end

%% Load the calibration file associated with this calibration type.
cal = LoadCalFile(OLCalibrationTypes.(selectedCalType).CalFileName, [], getpref('OneLight', 'OneLightCalData'));

%% Setup the OLCache object.
olCache = OLCache(cacheDir,cal);

%% Load the cached data for the desired calibration.
%
% We do it through the cache object so that we make sure that the cache is
% current against the latest calibration data.
[cacheData, wasRecomputed] = olCache.load(scacheFileName);

% If we recomputed the cache data, save it.  We'll load the cache data
% after we save it because cache data is uniquely time stamped upon save.
if wasRecomputed
    olCache.save(simpleCacheFileName, cacheData);
    cacheData = olCache.load(simpleCacheFileName);
end

end