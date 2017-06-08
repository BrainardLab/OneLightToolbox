classdef OLCache
	% OLCache - Class to abstract the cache system for OneLight spectra.
    %
    % The idea here is to precompute calibration dependent quantities in
    % advance of when we need them, because some of the computations can be
    % quite time consuming.  At the same time, there is a danger in
    % pre-computing and caching, because when you recalibrate the computed
    % quantities are stale.  So, this object stores the calibration data at
    % the time of precomputation and then checks to make sure the data
    % aren't stale
    %
    % Cache files also keep a history of all cached versions, allowing one
    % to go back and look at older versions if desired.  Finally, they can
    % maintain separate precomputed quantities for different calibration
    % types, so that you can have one cache file that will work generally
    % across calibration types.
    %
    % When you interact with a cache file, you basically either save or
    % load a struct.  What's in the struct is up to the caller, but it is
    % generally something that depends on a OneLight calibration file.
	%
	% OLCache methods:
	%   OLCache - Constructor.
    %   save - Save the cache data to the cache file.
    %   load - Load the cache data from the cache file. This includes a
    %          check for staleness.
    %   exist - Check of cache file exists.
    %   list - List cache files in a directory.
    %   find - Find what versions of things are in a cache file.
	
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
			
			narginchk(2, 2);
			
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
		
        % These methods are declared here but implemented in their own
        % files.
		[cacheData, wasRecomputed] = load(obj, cacheFileName, doRecompute)
		save(obj, cacheFileName, cacheData, force)
        cacheList = list(obj)
		cacheFileExists = exist(obj, cacheFileName)
    end
	
	% Static methods
	methods (Static = true)
		[cacheData, validationData] = find(cacheFileName, calibrationType, cacheDate);
	end
end
