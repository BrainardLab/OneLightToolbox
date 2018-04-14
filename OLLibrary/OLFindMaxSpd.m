function [maxSpd, maxPrimary, maxLum] = OLFindMaxSpd(cal, targetSpd, initialPrimary, T_xyz, varargin)
% Maximize (or minimize) luminance while keeping relative spectrum matched to target. 
%
% Syntax:
%     [maxSpd, maxPrimary, scaleFactor] = OLFindMaxSpd(oneLightCal, targetSpd, initialPrimary)
%     [maxSpd, maxPrimary, scaleFactor] = OLFindMaxSpd(oneLightCal, targetSpd, initialPrimary, 'lambda', 0.001)
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
%     cal                  - Struct. OneLight calibration file after it has been
%                            processed by OLInitCal.
%     targetSpd            - Column vector giving target spectrum.  Should be
%                            on the same wavelength spacing and power units
%                            as the the calibration structure.
%     initialPrimaries     - Primary values that produce target spd.  These
%                            need to pass primary checks and produce the
%                            targetSpd within tolerance.
%     T_xyz                - XYZ color matching functions, on same
%                            wavelength sampling as targetSpd.
%     verbose              - Logical. Toggles verbose output. Default true.
%
% Output:
%     maxSpd               - Column vector giving spectrum whose maximum primary value is as close as
%                            possible to 1.
%     maxPrimary           - Primaries that produce max spectrum.
%     maxLum               - Luminance of max spectrum%
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
%                       Default, 50.  Reduce if you don't need
%                       to go that long and things will get faster.
%
% See also: OLPrimaryInvSolveChrom, OLFindMinSpectrum.
%

% History:
%  04/02/18  dhb   Change to key/value pairs.
%  04/13/18  dhb   Bite bullet. Change to searching on primaries.


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
p.addParameter('maxSearchIter',300,@isscalar);
p.parse(varargin{:});

%% Parameters
if (p.Results.verbose)
    fminconDisplaySetting = 'iter';
else
    fminconDisplaySetting = 'off';
end

%% Make sure that the oneLightCal has been properly processed by OLInitCal.
assert(isfield(cal, 'computed'), 'OLSpdToPrimary:InvalidCalFile', ...
    'The calibration file needs to be processed by OLInitCal.');

%% Make sure input target isn't insane
if (min(targetSpd(:) < 0))
    error('No no no you cannot have negative light');
end
if (all(targetSpd(:) == 0))
    error('Cannot run this with target all zeros');
end

% Check on initial primaries
checkSpd = OLPrimaryToSpd(cal,initialPrimary, ...
    'primaryHeadroom',p.Results.primaryHeadroom, ...
    'primaryTolerance',p.Results.primaryTolerance, ...
    'checkPrimaryOutOfRange',p.Results.checkPrimaryOutOfRange, ...
    'differentialMode',false);
OLCheckSpdTolerance(targetSpd,checkSpd, ...
    'checkSpd',p.Results.checkSpd,'spdToleranceFraction',p.Results.spdToleranceFraction);

%% Maximize luminance while staying at same relative spd
%
% This seems to work robustly, and thus we use it for helping to
% start other options.
options = optimset('fmincon');
options = optimset(options,'Diagnostics','off','Display',fminconDisplaySetting,'LargeScale','off','Algorithm','active-set', 'MaxIter', p.Results.maxSearchIter, 'MaxFunEvals', 100000, 'TolFun', 1e-3, 'TolCon', 1e-10, 'TolX', 1e-4);
vub = ones(size(initialPrimary))  - p.Results.primaryHeadroom;
vlb = zeros(size(initialPrimary)) + p.Results.primaryHeadroom;
x = fmincon(@(x) OLFindMaxSpdFun(x, cal, T_xyz, p.Results.lambda, p.Results.findMin), ... 
    initialPrimary,[],[],[],[],vlb,vub, ...
    @(x)OLFindMaxSpdCon(x, cal, targetSpd, p.Results.lambda, p.Results.primaryHeadroom, p.Results.primaryTolerance, p.Results.spdToleranceFraction), ...
    options);

%{
[c, ceq] = OLFindMaxSpdCon(x, oneLightCal, targetSpd, p.Results.lambda,p.Results.primaryHeadroom,p.Results.primaryTolerance,p.Results.spdToleranceFraction)    
%}

% Pick up and check values from search
maxPrimary = OLCheckPrimaryGamut(x, ...
    'primaryHeadroom',p.Results.primaryHeadroom, ...
    'primaryTolerance',p.Results.primaryTolerance, ...
    'checkPrimaryOutOfRange',p.Results.checkPrimaryOutOfRange, ...
    'differentialMode',false);
maxSpd = OLPrimaryToSpd(cal,maxPrimary, ...
    'primaryHeadroom',p.Results.primaryHeadroom, ...
    'primaryTolerance',p.Results.primaryTolerance, ...
    'checkPrimaryOutOfRange',p.Results.checkPrimaryOutOfRange, ...
    'differentialMode',false);
predictedTargetSpd = (maxSpd\targetSpd)*maxSpd;
OLCheckSpdTolerance(targetSpd,predictedTargetSpd, ...
    'checkSpd',p.Results.checkSpd,'spdToleranceFraction',p.Results.spdToleranceFraction);
maxLum = T_xyz(2,:)*maxSpd;

%{
figure; clf; hold on
plot(targetSpd,'r','LineWidth',2);
plot((maxSpd\targetSpd)*maxSpd,'g','LineWidth',1);
plot(maxSpd,'b');
%}

end

% This is the function that fmincon tries to drive to max/minimize
% luminance
function f = OLFindMaxSpdFun(primary, cal, T_xyz, lambda, findMin)

% Get the prediction.  Constraint checking is done in the constraint
% function, skipped here
predictedSpd = OLPrimaryToSpd(cal, primary,'skipAllChecks',true);
predictedLum = T_xyz(2,:)*predictedSpd;

% Fix sign depending on whether we are maximizing or minimizing
if (findMin)
    f = predictedLum;
else
    f = -predictedLum;
end

end

% This is the constraint function that keeps the relative spectrum correct
function [c, ceq] = OLFindMaxSpdCon(primary, cal, targetSpd, lambda, ...
    primaryHeadroom, primaryTolerance, spdToleranceFraction)

% Check primary margin
[primary,~,gamutMargin] = OLCheckPrimaryGamut(primary, ...
    'primaryHeadroom',primaryHeadroom, ...
    'primaryTolerance',primaryTolerance, ...
    'checkPrimaryOutOfRange',false);
c1 = gamutMargin + 0.001*primaryTolerance;

% Get spd from current primaries
predictedSpd = OLPrimaryToSpd(cal,primary,'skipAllChecks',true);
    
% Check how well we are doing on relative spd
%
% Multiplying the desired tolerance faction by 0.999 keeps us enough within
% constraint so that the check after the search does not fail.
predictedRelativeSpd = (predictedSpd\targetSpd)*predictedSpd;
[~, errorFraction] = OLCheckSpdTolerance(targetSpd,predictedRelativeSpd, ...
    'checkSpd', false, 'spdToleranceFraction', spdToleranceFraction);
c2 = errorFraction-0.9*spdToleranceFraction;  

% Return values
c = [c2(:)];
ceq = [];

end

