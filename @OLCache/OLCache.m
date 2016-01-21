classdef OLCache
	% OLCache - Class to abstract the cache system for OneLight spectra.
	%
	% OLCache methods:
	% OLCache - Constructor.
	% compute - Function that computes the cache data.
	
	properties (SetAccess = protected)
		CacheDirectory;
		CalibrationData;
	end
	
	% Public methods
	methods
		function obj = OLCache(cacheDir, calibrationData)
			% OLCache - OLCache constructor.
			%
			% Syntax:
			% obj = OLCache(cacheDir, calibrationData)
			%
			% Description:
			% Creates an object that represents the cache directory containing
			% OneLight spectra data.  The constructor takes the calibration
			% data against which any data loaded will be compared against.
			%
			% Input:
			% cacheDir (string) - The directory containing the cache files.
			%     The cache directory must be an absolute path.
			% calibrationData (struct) - The calibration data to compare the
			%     cache data against.  Data out of sync with the calibration
			%     data will be recomputed using the OLCache.compute function.
			%
			% Output:
			% obj (OLCache) - The OLCache object.
			
			error(nargchk(2, 2, nargin));
			
			% Force the cache directory to be an absolute path instead of a
			% relative one in order to avoid false matches on the Matlab
			% path.  The regular expression looks for string that begins
			% with '/' or './'.
			m = regexp(cacheDir, '^(\.\/|\/).*', 'once');
			assert(~isempty(m), 'OLCache:InvalidPathDef', ...
				'Cache directory must be an absolute path.');
			
			% Make sure the cache directory exists.
			obj.CacheDirectory = cacheDir;
			assert(logical(exist(cacheDir, 'dir')), 'OLCache:InvalidCacheDir', ...
				'Cache directory "%s" not found.', cacheDir);
			
			% Store the calibration data.
			obj.CalibrationData = calibrationData;
		end
		
		cacheList = list(obj)
		[cacheData, wasRecomputed] = load(obj, cacheFileName, doRecompute)
		save(obj, cacheFileName, cacheData, force)
		cacheFileExists = exist(obj, cacheFileName)
	end
	
	properties (Constant = true)
		ComputeMethods = struct('Standard', 'standard');
	end
	
	% Static methods
	methods (Static = true)
		cacheData = compute(computeMethod, varargin)
		[cacheData, validationData] = find(cacheFileName, calibrationType, cacheDate);
	end
end
