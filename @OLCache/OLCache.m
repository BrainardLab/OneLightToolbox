classdef OLCache
	% OLCache - Class to abstract the cache system for OneLight spectra.
    %
    % The idea here is to precompute calibration dependent quantities in
    % advance of when we need them, because some of the computations can be
    % quite time consuming.  At the same time, there is a danger in
    % pre-computing and caching, because when you recalibrate the computed
    % quantities are stale.  So, this object stores the calibration data at
    % the time of precomputation and then checks to make sure the data
    % aren't stale.  When the data are stale, it triggers a recomputation
    % and stores updated quantities.
    %
    % The object is set up to be somewhat general and extensible in terms
    % of what can be computed.  The compute function takes a computeMethod
    % argument which then determines what it does and what is stored.  The
    % computeMethods are set up to match things we commonly want to do.
    %
    % Cache files also keep a history of all cached versions, allowing one
    % to go back and look at older versions if desired.
    %
    % The available compute methods are enumerated in routine
    % OLComptueMethods.  That simply lets us use symbolic names to refer to
    % the available compute methods.  So, when you want to introduce a new
    % computation to the cache system, you need to add a new compute method
    % to OLComputeMethods.
    %
    % See also: OlComputeMethods.
	%
	% OLCache methods:
	%   OLCache - Constructor.
	%   compute - Function that computes the cache data.  The cache data is
	%             simply a structure with fields that depend on the compute
	%             method.
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
