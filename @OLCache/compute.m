function cacheData = compute(computeMethod, varargin)
% compute - Computes cache data from target spectra.
%
% Syntax:
% cacheData = OLCache.compute(computeMethod, computeInputs)
%
% Description:
% Wrapper method for various ways to compute cache data from a set of
% target spectra.  This is the function that will be called by OLCache when
% loading a cache file in the event a recompute is needed.  Ideally, to
% keep compute methods consistent, a program using OLCache will use this
% program to calculate the mirror settings.
%
% Input:
% computeMethod (OLComputeMethods) - The method to compute the cache data.
% computeInputs (varargin) - The input required for the specified compute
%     method.
%
% Output:
% cacheData (struct) - The computed data.
%
% Compute Methods:
%     Method:
%     Standard - Uses OLSpdToSettings to calculate settings.
%
%     Input:
%     oneLightCal (struct) - OneLight calibration file after it has been
%         processed by OLInitCal.
%     targetSpds (Mx1) - Target spectra.  Should be on the same wavelength
%         spacing and power units as the PR-650 field of the calibration
%         structure.
%     lambda (scalar) - Determines how much smoothing we apply to the settings.
%         Needed because there are more columns than wavelengths on the PR-650.
%         Defaults to 0.1.
%     verbose (logical) - Enables/disables verbose diagnostic information.
%         Defaults to false.
%
% Examples:
% cacheData = OLCache.compute(OLComputeMethods.Standard, calData, targetSpds, lambda, verbose);

% Validate the number of inputs.
narginchk(1, Inf, );

% Set default parameters for 'lambda' and 'verbose'.
if (nargin < 3)
    lambda = 0.1;
elseif (nargin < 4)
    lambda = 0.1;
    verbose = false;
else
    lambda = varargin{3};
    verbose = varargin{4};
end

switch computeMethod
	case OLComputeMethods.Standard
		% Make sure we have enough parameters passed.  We leave it to the
		% subfunctions to validate the input.
		numArgs = length(varargin);
%		assert(numArgs <= 2, 'OLCache:compute:InvalidArgs', ...
%			'Invalid number of arguments for compute method OLComputeMethods.Standard');
		
		% Extract the method parameters.
		cacheData.cal = varargin{1};
		cacheData.targetSpds = varargin{2};
		cacheData.lambda = lambda;
		
		% Call the actual method to compute the settings.
		[cacheData.settings, cacheData.primaries, cacheData.predictedSpds] = ...
			OLSpdToSettings(cacheData.cal, cacheData.targetSpds, cacheData.lambda, verbose);

	otherwise
		error('OLCache:compute:Compute method not implemented.');
end

% Store the method we used to compute the cache.
cacheData.computeMethod = computeMethod;
		