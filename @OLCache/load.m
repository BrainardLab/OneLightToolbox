function [cacheData, wasRecomputed] = load(obj, cacheFileName, doRecompute)
% load - Loads a cache file.
%
% Syntax:
% [cacheData, wasRecomputed] = obj.load(cacheFileName)
% [cacheData, wasRecomputed] = obj.load(cacheFileName, doRecompute)
%
% Description:
% Loads a cache file from the cache folder stored in the OLCache object.
% Compares the calibration data stored in the case against the calibration
% stored in the OLCache object to make sure that cache is in sync with the
% desired calibration data.  If out of sync, the user is queried whether or
% not they want to recompute the data.  A recompute can also be flagged by
% the user using the 'doRecompute' parameter.  If a cache file doesn't
% contain any mirror settings or primaries, the primaries and setting are
% automatically calculated.  The computing of cacheData is performed by the
% OLCache.compute function.  Note that this function does not save the data
% for you.  If you want to save recomputed data, you must do that in your
% program.
%tb
% Input:
% cacheFileName (string) - Name of the cache file in the cache directory to
%     load.
% doRecompute (logical) - Toggles a forced recompute assuming the cache is
%     up to date.  Default: false.
%
% Output:
% cacheData (struct) - The cache file data.
% wasRecomputed (logical) - True if the cache data was recomputed.

% Validate the number of inputs.
narginchk(2, 3);

if nargin == 2
	doRecompute = false;
end

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

% There are 2 situations where we do a recompute of the targetSpds.
% 1. The cache is out of sync with the current calibration data passed to
%    OLCache.
% 2. The user requests a recompute.
if ~strcmp(cacheData.cal.describe.date, obj.CalibrationData.describe.date) && ~doRecompute
	doRecompute = GetWithDefault(['Cache out of sync with desired calibration, recompute according to ' char(cacheData.computeMethod) '?'], 1);
end

if doRecompute
	fprintf('- Recomputing cache\n');
	
	% Recalculate the settings and primaries.
	switch cacheData.computeMethod
		case OLComputeMethods.Standard
			cacheData = OLCache.compute(OLComputeMethods.Standard, obj.CalibrationData, cacheData.targetSpds, cacheData.lambda, true);
			
		otherwise
			error('Unknown compute method.');
	end
	
	wasRecomputed = true;
else
	wasRecomputed = false;
end
