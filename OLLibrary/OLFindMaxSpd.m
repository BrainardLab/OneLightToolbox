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
p.addParameter('lambda', 0.005, @isscalar);
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

%% Maximize luminance while staying at same relative spd
minScaleFactor = 1e-4;
options = optimset('fmincon');
options = optimset(options,'Diagnostics','off','Display','off','LargeScale','off','Algorithm','active-set', 'MaxIter', 10000, 'MaxFunEvals', 1000, 'TolFun', 1e-10, 'TolCon', 1e-10, 'TolX', 1e-10);
vlb = minScaleFactor;
vub = 1e4;
scaleFactor = fmincon(@(x) OLFindMaxSpdFun(x,oneLightCal,targetSpd,p.Results.lambda,p.Results.findMin,p.Results.spdToleranceFraction),1,[],[],[],[], ...
    vlb,vub,@(x) OLFindMaxSpdCon(x, oneLightCal, targetSpd, p.Results.lambda,p.Results.spdToleranceFraction),...
    options);

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

% This is the function that fmincon tries to drive to minimize
% argument.
function f = OLFindMaxSpdFun(scaleFactor, oneLightCal, targetSpd, lambda, findMin, spdToleranceFraction)

maxPrimary = OLSpdToPrimary(oneLightCal, scaleFactor*targetSpd, 'lambda', lambda);


% % Scale factor not acceptable if we don't get a properly scaled version of
% % the target
% predTargetSpd = OLPrimaryToSpd(oneLightCal,maxPrimary)/scaleFactor;
% if (max(abs(targetSpd(:)-predTargetSpd(:))) > spdToleranceFraction*max(targetSpd(:)))
%     f = realmax;
%     return;
% end

% Now do the right thing depending on whether we are maximizing or minimizing
if (findMin)
    f = max(maxPrimary(:));
else
    f = -max(maxPrimary(:));
end

end

% This is the constraint function that keeps the relative spectrum correct
function [c, ceq] = OLFindMaxSpdCon(scaleFactor, oneLightCal, targetSpd, lambda, spdToleranceFraction)

% Scale factor not acceptable if we don't get a properly scaled version of
% the target
maxPrimary = OLSpdToPrimary(oneLightCal, scaleFactor*targetSpd, 'lambda', lambda);
predTargetSpd = OLPrimaryToSpd(oneLightCal,maxPrimary)/scaleFactor;
diffSpd = abs(targetSpd(:)-predTargetSpd(:));

% Multiplying by 0.999 keeps us enough within constraint so that the check
% after the search does not fail.
cVec = diffSpd - 0.999*spdToleranceFraction*max(targetSpd(:));
c = cVec;

ceq = 0;

end

