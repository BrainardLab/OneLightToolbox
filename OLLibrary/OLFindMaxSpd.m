function [maxSpd, maxPrimary, scaleFactor] = OLFindMaxSpd(oneLightCal, targetSpd, varargin)
% Finds the scale factor to maximize OneLight spectrum luminance.
%
% Syntax:
%     [maxSpd, maxPrimary, scaleFactor] = OLFindMaxSpd(oneLightCal, targetSpd)
%     [maxSpd, maxPrimary, scaleFactor] = OLFindMaxSpd(oneLightCal, targetSpd, 'lambda', 0.001)
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
%  'lambda'           - Scalar  (default 0.005). Value of smoothing parameter.
%                       Smaller lead to less smoothing, with 0 doing no
%                       smoothing at all. This gets passed through to
%                       OLSpdToPrimary.
%   'primaryHeadroom' - Scalar.  Headroom to leave on primaries.  Default
%                       0.0
%   'primaryTolerance - Scalar. Truncate to range [0,1] if primaries are
%                       within this tolerance of [0,1]. Default 1e-6, and
%                       'checkPrimaryOutOfRange' value is true.
%   'checkPrimaryOutOfRange'  - Boolean. Perform tolerance check.  Default true.
%   'checkSpd'        - Boolean (default false). Because of smoothing and
%                       gamut limitations, this is not guaranteed to
%                       produce primaries that lead to the predictedSpd
%                       matching the targetSpd.  Set this to true to check.
%                       Tolerance is given by spdFractionTolerance.
%   'spdToleranceFraction' - Scalar (default 0.01). If checkSpd is true, the
%                       tolerance to avoid an error message is this
%                       fraction times the maximum of targetSpd, with the
%                       comparison begin made on maxSpd scaled back to
%                       targetSpd.
%   'findMin'         - Boolean (default false). Find minimum rather than
%                       maximum, with everything else the same.
%   'maxSearchIter'   - Control how long the search goes for.
%                       Default, 100000.  Reduce if you don't need
%                       to go that long and things will get faster.
%
% See also: OLPrimaryInvSolveChrom, OLFindMinSpectrum.

% History:
%  04/02/18  dhb   Change to key/value pairs.


%% Parse the input
p = inputParser;
p.addParameter('verbose', false, @islogical);
p.addParameter('lambda', 0.005, @isscalar);
p.addParameter('primaryHeadroom', 0.0, @isscalar);
p.addParameter('primaryTolerance', 1e-6, @isscalar);
p.addParameter('checkPrimaryOutOfRange', true, @islogical);
p.addParameter('checkSpd', false, @islogical);
p.addParameter('spdToleranceFraction', 0.01, @isscalar);
p.addParameter('findMin', false, @islogical);
p.addParameter('maxSearchIter',10000,@isscalar);
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

%% Maximize luminance while staying at same relative spd
minScaleFactor = 1e-4;
options = optimset('fmincon');
options = optimset(options,'Diagnostics','off','Display','iter','LargeScale','off','Algorithm','active-set', 'MaxIter', p.Results.maxSearchIter, 'MaxFunEvals', 1000, 'TolFun', 1e-10, 'TolCon', 1e-10, 'TolX', 1e-10);
vlb = minScaleFactor;
vub = 1e4;
scaleFactor = fmincon(@(x) OLFindMaxSpdFun(x,oneLightCal,targetSpd,p.Results.lambda,p.Results.findMin,p.Results.spdToleranceFraction),1,[],[],[],[], ...
    vlb,vub,@(x) OLFindMaxSpdCon(x, oneLightCal, targetSpd, p.Results.lambda,p.Results.primaryHeadroom,p.Results.primaryTolerance,p.Results.spdToleranceFraction),...
    options);
maxSpd = scaleFactor*targetSpd;
maxPrimary = OLSpdToPrimary(oneLightCal, maxSpd, 'lambda', p.Results.lambda,...
    'primaryHeadroom',p.Results.primaryHeadroom, ...
    'primaryTolerance',p.Results.primaryTolerance, ...
    'checkPrimaryOutOfRange',p.Results.checkPrimaryOutOfRange);

% Check tolerance between predicted spd and target, in a relative sense
predictedRelSpd = OLPrimaryToSpd(oneLightCal,maxPrimary)/scaleFactor;
OLCheckSpdTolerance(targetSpd,predictedRelSpd, ...
    'checkSpd',p.Results.checkSpd,'spdToleranceFraction',p.Results.spdToleranceFraction);
% figure; clf; hold on
% plot(targetSpd,'r','LineWidth',2);
% plot(predictedRelSpd,'g','LineWidth',1);
% plot(maxSpd,'b');

end

% This is the function that fmincon tries to drive to minimize argument.
function f = OLFindMaxSpdFun(scaleFactor, oneLightCal, targetSpd, lambda, findMin, spdToleranceFraction)

maxPrimary = OLSpdToPrimary(oneLightCal, scaleFactor*targetSpd, 'lambda', lambda);

% Scale factor not acceptable if we don't get a properly scaled version of
% the target.  Can try to enforce this here in the search error function
% if the constraint function is not doing the job properly.
%
% predTargetSpd = OLPrimaryToSpd(oneLightCal,maxPrimary)/scaleFactor;
% spdOK = OLCheckSpdTolerance(targetSpd,predictedRelSpd, ...
%     'checkSpd',false,'spdToleranceFraction',p.Results.spdToleranceFraction);
% if (~spdOK)
%     f = realmax;
% end

% Now do the right thing depending on whether we are maximizing or minimizing
if (findMin)
    f = max(maxPrimary(:));
else
    f = -max(maxPrimary(:));
end

end

% This is the constraint function that keeps the relative spectrum correct
function [c, ceq] = OLFindMaxSpdCon(scaleFactor, oneLightCal, targetSpd, lambda, ...
    primaryHeadroom, primaryTolerance, spdToleranceFraction)


% Constraint that found primaries stay within gamut, according to the
% parameters
[maxPrimary,~,gamutDeviation] = OLSpdToPrimary(oneLightCal, scaleFactor*targetSpd, 'lambda', lambda, ...
    'primaryHeadroom',primaryHeadroom, ...
    'primaryTolerance',primaryTolerance, ...
    'checkPrimaryOutOfRange',false);
c1 = gamutDeviation - 0.9*primaryTolerance;

% Scale factor not acceptable if we don't get a properly scaled version of
% the target.
%
% Multiplying the desired tolerance faction by 0.999 keeps us enough within
% constraint so that the check after the search does not fail.
predictedTargetSpd = OLPrimaryToSpd(oneLightCal,maxPrimary)/scaleFactor;
[~, errorFraction] = OLCheckSpdTolerance(targetSpd,predictedTargetSpd, ...
    'checkSpd', false, 'spdToleranceFraction', spdToleranceFraction);
c2 = errorFraction-0.6*spdToleranceFraction;  

% Return values
c = [c1(:) ; c2(:)];
ceq = 0;


end

