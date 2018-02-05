function [cacheData,adjustedCal] = OLGetCacheAndCalData(cacheFileNameFullPath, params, varargin)
%OLGetCacheAndCalData  Open a modulation cache file and get the data for a particular calibration, as well as the cal data.
%
% Usage:
%    [cacheData, adjustedCal] = OLGetCacheAndCalData(cacheFileNameFullPath, params);
%
% Description:
%    Get the cached data and associated calibration file.
%
%    The calibration file can be adjusted according to the parameters.  We probably do not
%    want to adjust very often - better to set the parameters appropriately for each box
%    at calibration time.  But adjusting is useful when experimenting with spectrum seeking
%    methods.  At some point, might want to force no adjustment here by throwing an error.
%
% Input:
%     cacheFileNameFullPath           - Full path to cache file.
%     params                          - Parameter struct with the following fields:
%                                         approach - Name of approach
%                                         calibrationType - Type of calibration. 
% 
% Output:
%    cacheData                        - The nominal direction cache data structure.
%    adjustedCal                      - The corresponding calibration structure, after adjustment.
%
% Optional key/value pairs:
%     None

% 07/28/17  dhb  Put cal adjutment in here, improve comments.

%% Open cache file and get data
%
% Force the file to be an absolute path instead of a relative one.  We do
% this because files with relative paths can match anything on the path,
% which may not be what was intended.  The regular expression looks for
% string that begins with '/' or './'.
m = regexp(cacheFileNameFullPath, '^(\.\/|\/).*', 'once');
assert(~isempty(m), 'InvalidPathDef', 'Cache file name must be an absolute path.');

%% Make sure the cache file exists.
assert(logical(exist(cacheFileNameFullPath, 'file')), 'FileNotFound', 'Cannot find cache file: %s', cacheFileNameFullPath);

%% Deduce the cache directory and load the cache file
[cacheDir,cacheFileName] = fileparts(cacheFileNameFullPath);
data = load(cacheFileNameFullPath);
assert(isstruct(data), 'InvalidCacheFile','Specified file doesn''t seem to be a cache file: %s', cacheFileNameFullPath);

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
assert(any(typeExists), 'InvalidCacheFile', 'File contains does not contain at least one valid calibration type');

%% Got to have a type available, check
assert(isfield(params, 'calibrationType'),'No calibration type','Must provide params.calibraitionType'); 

%% Get the calibration type 
%
% If it is crashing here,  make sure you have deleted the current nominal
% primaries and run SetupTrialSequenceMRApproach.m
if (any(strcmp(foundCalTypes, params.calibrationType)))
    selectedCalType = params.calibrationType;
else
    error('No calibration of specified type available');
end

%% Load the calibration file associated with this calibration type, and adjust.
adjustedCal = LoadCalFile(OLCalibrationTypes.(selectedCalType).CalFileName, [], fullfile(getpref(params.approach, 'OneLightCalDataPath')));

%% Setup the OLCache object.
olCache = OLCache(cacheDir,adjustedCal);

%% Load the cached data for the desired calibration.
%
% We do it through the cache object so that we make sure that the cache is
% current against the latest calibration data.
[cacheData, isStale] = olCache.load(cacheFileName);
assert(~isStale,'Cache file is stale, aborting.');

end