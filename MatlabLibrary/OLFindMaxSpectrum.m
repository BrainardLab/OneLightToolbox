function [maxSpd, scaleFactor, maxVal] = OLFindMaxSpectrum(oneLightCal, targetSpd, lambda, verbose)
% OLFindMaxSpectrum - Finds the scale factor to maximize OneLight spectrum luminance.
%
% Syntax:
% [maxSpd, scaleFactor, maxVal] = OLFindMaxSpectrum(oneLightCal, targetSpd)
% [maxSpd, scaleFactor, maxVal] = OLFindMaxSpectrum(oneLightCal, targetSpd, lambda)
% [maxSpd, scaleFactor, maxVal] = OLFindMaxSpectrum(oneLightCal, targetSpd, lambda, verbose)
%
% Description:
% Takes the OneLight calibration and a target spectral power distribution
% and finds the scale factor that you multipy the target spd by to get an
% spd whose maximum primary value is as close as possible to 1.
%
% Input:
% oneLightCal (struct) - OneLight calibration file after it has been
%     processed by OLInitCal.
% targetSpd (Mx1) - Target spectrum.  Should be on the same wavelength
%     spacing and power units as the PR-650 field of the calibration
%     structure.
% lambda (scalar) - Determines how much smoothing we apply to the settings.
%     Needed because there are more columns than wavelengths on the PR-650.
%     Defaults to 0.1.
% verbose (logical) - Toggles verbose output. Default: true
%
% Output:
% maxSpd (Mx1) - Spectrum whose maximum primary value is as close as
%     possible to 1.
% scaleFactor (scalar) - Scale factor by which to multiply the target spd
%     to get the maximum luminance.
% maxVal (scalar) - The maximum primary value resulting from 'maxSpd'.

% Validate the number of input arguments.
error(nargchk(2, 4, nargin));

if ~exist('lambda', 'var')
	lambda = 0.1;
end
if ~exist('verbose', 'var')
	verbose = true;
end

% Make sure that the oneLightCal has been properly processed by OLInitCal.
assert(isfield(oneLightCal, 'computed'), 'OLSpdToPrimary:InvalidCalFile', ...
	'The calibration file needs to be processed by OLInitCal.');

% Use fsolve to find the right scale factor.  The advantage of this method
% is that it properly takes the ambient into account, to the extent that
% our core OLSpdToPrimary routine does that.
options = optimset('fsolve');
options = optimset(options,'Diagnostics','off','Display','off','LargeScale','off');
if ~verbose
	options = optimset(options, 'Display', 'off');
end
scaleFactor = fsolve(@(scaleFactor) OLFindMaxSpectrumFun(scaleFactor,oneLightCal,targetSpd,lambda),1,options);

maxSpd = scaleFactor*targetSpd;
primary = OLSpdToPrimary(oneLightCal,maxSpd,lambda);
maxVal = max(primary);


function f = OLFindMaxSpectrumFun(scaleFactor, oneLightCal, targetSpd, lambda)
% This is the function that fsolve tries to drive to 0 by varying its first
% argument.

primary = OLSpdToPrimary(oneLightCal, scaleFactor*targetSpd, lambda);
maxPrimary = max(primary);
f = maxPrimary-1;

% Another way one could try to do this.  We didn't fully code this
% because we were more into trying fsolve.
%
% % Setup our start point and some search parameters.
% maxSpd = targetSpd;
% tolerance = 0.001;
% maxIterations = 2;
% 
% % Loop for the max iterations or until we find a value that satisfies our
% % tolerance limit.
% for i = 1:maxIterations
% 	% Process the spd and see what it's max primary is.
%     primary = OLSpdToPrimary(oneLightCal, maxSpd, lambda, verbose);
%     maxVal = max(primary);
% 	
% 	% Recompute the spd scale factor based on the newly calculated maximum
% 	% primary.
%     scaleFactor = 1/maxVal;
% 	
% 	% If our maximum primary value is within our tolerance limit break out
% 	% of the loop.
% 	if (1 - maxVal) < tolerance
% 		break;
% 	end
% 	
% 	% Scale the spd in preparation to run in through OLSpdToPrimary.
% 	maxSpd = 0.99*targetSpd*scaleFactor;
% end
% 
% % Find the final scale factor
% scaleFactor = targetSpd\maxSpd;