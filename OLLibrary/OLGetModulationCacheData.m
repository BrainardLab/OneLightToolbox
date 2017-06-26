function [olCache, cacheData,cal, cacheDir, cacheFileName] = OLGetModulationCacheData(cacheFileNameFullPath, params)
%%OLGetModulationCacheData  Open a modulation cache file and get the data for a particular calibration.
%    [olCache, cacheData,cal,cacheDir,cacheFileName] = OLGetModulationCacheData(cacheFileNameFullPath, describe);
%
% DHB: NEED TO FIGURE OUT WHAT FIELDS OF DESCRIBE ARE NEEDED AND DOCUMENT
% THEM HERE.
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
    if (isfield(params, 'calibrationType')) && any(strcmp(foundCalTypes, params.calibrationType))
        selectedCalType = params.calibrationType;
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
cal = LoadCalFile(OLCalibrationTypes.(selectedCalType).CalFileName, [], fullfile(getpref(params.theApproach, 'MaterialsPath'), 'Experiments',params.theApproach,'OneLightCalData'));

%% Setup the OLCache object.
olCache = OLCache(cacheDir,cal);

%% Load the cached data for the desired calibration.
%
% We do it through the cache object so that we make sure that the cache is
% current against the latest calibration data.
[cacheData, isStale] = olCache.load(cacheFileName);
assert(~isStale,'Cache file is stale, aborting.');

end