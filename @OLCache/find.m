function [cacheData, validationData] = find(cacheFileName, calibrationType, cacheDate)
% find - Finds specific cache and validation data in a cache file.
%
% Syntax:
% [cacheData, validationData] = OLCache.find(cacheFileName, calibrationType, cacheDate)
%
% Description:
% Typically, the cache data returned from OLCache is the most recent.  This
% function lets you look within the cache history to find the cache data
% identified by its unique time stamp.  This function can optionally
% retrieve the validation data associated with the cache data assuming it
% exists.  If there are multiple validation data sets associated with the
% cache data, then the most recent validation is returned.
%
% Input:
% cacheFileName (string) - The cache file name.  Must be an absolute path.
% calibrationType (OLCalibrationTypes) - The type of calibration the cache
%     file was created against.
% cacheDate (string) - The date of the cache data.  This is a unique
%     identifier stored with every set of cache data.
%
% Output:
% cacheData (struct) - The cache data or empty if nothing was found.
% validationData (struct) - The validation data associated with the cache
%     data.  Empty if nothing was found.

% Validate the number of inputs.
narginchk(3, 3);

% Force the file to be an absolute path instead of a relative one.  We do
% this because files with relative paths can match anything on the path,
% which may not be what was intended.  The regular expression looks for
% string that begins with '/' or './'.
m = regexp(cacheFileName, '^(\.\/|\/).*', 'once');
assert(~isempty(m), 'OLCache.find:InvalidPathDef', ...
	'Cache file name must be an absolute path.');

% Load the data from the cache file.
data = load(cacheFileName);

cacheData = [];
validationData = {};

% Look to see if there is a field of the specified calibration type.
dataExists = any(strcmp(calibrationType.char, fieldnames(data)));

if dataExists
	% Now look to see if we can find cache data that matches the specified
	% date.
	for i = 1:length(data.(calibrationType.char))
		if strcmp(cacheDate, data.(calibrationType.char){i}.date)
			cacheData = data.(calibrationType.char){i};
			break;
		end
	end
	
	% Look for the validation data if its output was requested.
	if nargout == 2
		% Figure out the name of the validation file.
		[d, valSimpleName] = fileparts(cacheFileName);
		valDir = fullfile(d, 'validation/');
		valName = sprintf('%s-%s', valSimpleName, calibrationType.char);
		fullValName = sprintf('%s.mat', fullfile(valDir, valName));
		
		% Look to see if it exists.
		if exist(fullValName, 'file')
			% Load all the data from the validation file.
			[~, vdata] = LoadCalFile(valName, [], valDir);
			
			% Find the most recent validation data associated with the
			% cache data.  It's possible that the validation was run
			% multiple times on the same cache data.  Newer validations
			% exist at higher indices in the cell array.
			for i = 1:length(vdata)
				if strcmp(cacheData.date, vdata{i}.cacheDate)
					validationData = vdata{i};
				end
			end
		end
	end
end
