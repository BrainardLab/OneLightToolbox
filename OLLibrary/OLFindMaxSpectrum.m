function [maxSpd, maxPrimary, scaleFactor] = OLFindMaxSpectrum(oneLightCal, targetSpd, varargin)
% Finds the scale factor to maximize OneLight spectrum luminance.
%
% Syntax:
%     [maxSpd, maxPrimary, scaleFactor] = OLFindMaxSpectrum(oneLightCal, targetSpd)
%     [maxSpd, maxPrimary, scaleFactor] = OLFindMaxSpectrum(oneLightCal, targetSpd, 'lambda', 0.001)
%
% Description:
%     Takes the OneLight calibration and a target spectral power distribution
%     and finds the scale factor that you multipy the target spd by to get an
%     spd whose maximum primary value is as close as possible to 1.
%
%     Can also find min instead of max, by setting value for key 'findMin'
%     to true.
%
% Input:
%     oneLightCal          - Struct. OneLight calibration file after it has been
%                            processed by OLInitCal.
%     targetSpd            - Column vector giving target spectrum.  Should be
%                            on the same wavelength spacing and power units
%                            as the PR-650 field of the calibration
%                            structure.
%     lambda               - Scalar. Determines how much smoothing we apply to the settings.
%                            Needed because we have enough primaries that the xform
%                            matrix is not well-conditioned.
%                            Default  0.1.
%     verbose              - Logical. Toggles verbose output. Default true.
%
% Output:
%     maxSpd               - Column vector giving spectrum whose maximum primary value is as close as
%                            possible to 1.
%     maxPrimary           - Primaries that produce max spectrum.
%     scaleFactor          - Scale factor by which to multiply the target spd
%                            to get maxSpd.
%     maxVal               - The maximum primary value resulting from 'maxSpd'.
%
%
% Optional Key-Value Pairs:
%  'verbose'          - Boolean (default false). Provide more diagnostic output.
%  'lambda'           - Scalar  (default 0.1). Value of smoothing parameter.  Smaller
%                       lead to less smoothing, with 0 doing no
%                       smoothing at all. This gets passed through to
%                       OLSpdToPrimary.
%  'checkSpd'         - Boolean (default false). Because of smoothing and
%                       gamut limitations, this is not guaranteed to
%                       produce primaries that lead to the predictedSpd
%                       matching the targetSpd.  Set this to true to check.
%                       Tolerance is given by spdFractionTolerance.
%  'spdToleranceFraction' - Scalar (default 0.01). If checkSpd is true, the
%                       tolerance to avoid an error message is this
%                       fraction times the maximum of targetSpd, with the
%                       comparison begin made on maxSpd scaled back to
%                       targetSpd.
%  'findMin'          - Boolean (default false). Find minimum rather than
%                       maximum, with everything else the same.
%
% See also: OLPrimaryInvSolveChrom, OLFindMinSpectrum.

% History:
%  04/02/18  dhb   Change to key/value pairs.


%% Parse the input
p = inputParser;
p.addParameter('verbose', false, @islogical);
p.addParameter('lambda', 0.1, @isscalar);
p.addParameter('checkSpd', false, @islogical);
p.addParameter('spdToleranceFraction', 0.01, @isscalar);
p.addParameter('findMin', false, @islogical);
p.parse(varargin{:});

% Make sure that the oneLightCal has been properly processed by OLInitCal.
assert(isfield(oneLightCal, 'computed'), 'OLSpdToPrimary:InvalidCalFile', ...
    'The calibration file needs to be processed by OLInitCal.');

% Make sure input target isn't insane
if (min(targetSpd(:) < 0))
    error('No no no you cannot have negative light');
end
if (all(targetSpd(:) == 0))
    error('Cannot run this with target all zeros');
end

% Use fsolve to find the right scale factor.  The advantage of this method
% is that it properly takes the ambient into account, to the extent that
% our core OLSpdToPrimary routine does that.
options = optimset('fsolve');
options = optimset(options,'Diagnostics','off','Display','off','LargeScale','off');
if ~p.Results.verbose
    options = optimset(options, 'Display', 'off');
end
scaleFactor = fsolve(@(scaleFactor) OLFindMaxSpectrumFun(scaleFactor,oneLightCal,targetSpd,p.Results.lambda,p.Results.findMin,p.Results.spdToleranceFraction),1,options);

maxSpd = scaleFactor*targetSpd;
maxPrimary = OLSpdToPrimary(oneLightCal, maxSpd, 'lambda', p.Results.lambda);

if (p.Results.checkSpd)
    predTargetSpd = OLPrimaryToSpd(oneLightCal,maxPrimary)/scaleFactor;
    if (max(abs(targetSpd(:)-predTargetSpd(:))) > p.Results.spdToleranceFraction*max(targetSpd(:)))
        error('Spd predicted from primaries not sufficently close to target max spd');
    end
    
    % figure; clf; hold on
    % plot(targetSpd,'r','LineWidth',2);
    % plot(predTargetSpd,'g','LineWidth',1);
    % plot(maxSpd,'b');
end

end

% This is the function that fsolve tries to drive to 0 by varying its first
% argument.
function f = OLFindMaxSpectrumFun(scaleFactor, oneLightCal, targetSpd, lambda, findMin, spdToleranceFraction)

% Scale factor not acceptable if we don't get a properly scaled version of
% the target
maxPrimary = OLSpdToPrimary(oneLightCal, scaleFactor*targetSpd, 'lambda', lambda);
predTargetSpd = OLPrimaryToSpd(oneLightCal,maxPrimary)/scaleFactor;
if (max(abs(targetSpd(:)-predTargetSpd(:))) > spdToleranceFraction*max(targetSpd(:)))
    f = Inf;
    return;
end

% Negative light makes no sense, don't allow negative scale factors.
% Actually, don't allow ridiculously small scale factors, as that gets us
% into a world of numerical hurt.
if (scaleFactor <= 1e-4)
    f = Inf;
    return;
end

% Now do the right thing depending on whether we are maximizing or minimizing
if (findMin)
    f = abs(min(maxPrimary(:)));
else
    maxPrimary = max(maxPrimary(:));
    f = maxPrimary-1;
end

end

