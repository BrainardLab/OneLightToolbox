function backgroundPrimary = OLBackgroundInvSolveChrom(cal, desiredChromaticity, varargin)
% Find OneLight background of desired chromaticity
%
% Syntax:
%   backgroundPrimary = OLBackgroundInvSolveChrom(cal, desiredChromaticity)
%
% Describe:
%   Function to find a OneLight background spectrum of a desired
%   chromaticity.  Target luminance is as much as possible within
%   gamut.
%
% Inputs:
%   cal                   OneLight calibration structure
%   desiredChrmaticity    Vector with desired CIE 1931 chromaticity.
%
% Outputs:
%   backgroundPrimary     Primary settings for the obtained background.
%
% Optional key/value pairs:
%   'PrimaryHeadroom'     Scalar.  Headroom to leave on primaries.  Default
%                         0.1.
%   'PrimaryTolerance     Scalar. Truncate to range [0,1] if primaries are
%                         within this tolerance of [0,1]. Default 1e-6, and
%                         'CheckOutOfRange' value is true.
%   'CheckOutOfRange'     Boolean. Perform tolerance check.  Default true.
%

% 05/22/15  ms      Wrote it.
% 06/29/17  dhb     Clean up.
% 03/27/18  dhb     Add 'PrimaryHeadroom' key/value pair.
% 04/01/18  dhb     Primary range stuff.

%% Input parser
p = inputParser;
p.addParameter('PrimaryHeadroom',0.1,@isscalar);
p.addParameter('PrimaryTolerance',1e-6,@isscalar);
p.addParameter('CheckOutOfRange',true,@islogical);
p.parse(varargin{:});

%% Set up some parameters
S = cal.describe.S;

%% Load 1931 CIE functions
load T_xyz1931
T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);

%% Pull out key properties of OneLight cal
B_primary = cal.computed.pr650M;
nPrimaries = size(B_primary, 2);
ambientSpd = cal.computed.pr650MeanDark;

%% Get the maximum luminance for this calibration
maxSpd = B_primary*ones(size(B_primary,2),1) + ambientSpd;
maxLuminance = T_xyz(3, :)*maxSpd;

%% Construct basis functions for primaries
%
% We'll look for backgrounds within this space of primary weights.
B1 = 0.5*ones(nPrimaries,1);            % Half-on
B2 = 1-linspace(0, 1, nPrimaries);      % Linear ramp
B3 = 1-linspace(-1, 1, nPrimaries).^2;  % Quadratic
primaryBasis = [B1 B2' B3'];                       % Put them together

% % Multiply with the B_primary matrix from the calibration and the relevant
% % CIE functions
% xy_s = (T_xyz(1:2, :)*B_primary*primaryBasis)./repmat(sum(T_xyz*B_primary*primaryBasis), 2, 1);
% Y_s = (T_xyz(3, :)*B_primary*primaryBasis);
% 
% % Put them together
% xyY_s = [xy_s ; Y_s];

%% Define the target chromaticities and luminance
%
% Luminance set to be 1/10 of the max.  This is likely to be within gamut.
xyY_target = [desiredChromaticity(1) desiredChromaticity(2) maxLuminance/10]';
xy_target = xyY_target(1:2);
XYZ_target = xyYToXYZ(xyY_target);

%% Construct matrix that goes between primary basis weights w and XYZ
M_weightsToXYZ = T_xyz*B_primary*primaryBasis;
M_XYZToWeights = inv(M_weightsToXYZ);

%% First step: solve with a linear method
%
% Provides a starting point for optimization
%w = inv(xyY_s)*xyY_target;
initialWeights = M_XYZToWeights*XYZ_target;

%% Are initial primaries in range?
initialPrimaries = primaryBasis*initialWeights;
if (any(initialPrimaries < 0 | initialPrimaries > 1))
    error('Cannot find within gamut primaries for guess at initial luminance');
end

% Sanity check. Look at this and see if it
% comes out near xyY_target if you like.
initialxyYTolerance = 1e-5;
initialXYZ = T_xyz*B_primary*initialPrimaries;
initialxyY = XYZToxyY(initialXYZ);
if (any( max(abs(xy_target-initialxyY(1:2))) > initialxyYTolerance))
    error('Initial primaries do not have desired chromaticity');
end

%% Second step: maximize luminance while staying at chromaticity
options = optimset('fmincon');
options = optimset(options,'Diagnostics','off','Display','off','LargeScale','off','Algorithm','active-set', 'MaxIter', 10000, 'MaxFunEvals', 100000, 'TolFun', 1e-10, 'TolCon', 1e-10, 'TolX', 1e-10);
maxHeadroom = p.Results.PrimaryHeadroom;
vub = ones(size(B_primary, 2), 1)-maxHeadroom;
vlb = ones(size(B_primary, 2), 1)*maxHeadroom;
x = fmincon(@(x) ObjFunction(x, B_primary, ambientSpd, T_xyz),initialPrimaries,[],[],[],[],vlb,vub,@(x)ChromaticityNonlcon(x, B_primary, ambientSpd, T_xyz, xy_target),options);
backgroundPrimary = x;

%% Pull the background out of the solution
backgroundPrimary(backgroundPrimary > 1 & backgroundPrimary < 1 + p.Results.PrimaryTolerance) = 1;
backgroundPrimary(backgroundPrimary < 0 & backgroundPrimary > -p.Results.PrimaryTolerance) = 0;
if (p.Results.CheckOutOfRange && (any(backgroundPrimary(:) > 1) || any(backgroundPrimary(:) < 0) ))
    error('At one least primary value is out of range [0,1]');
end

%% Can look at these to see if things came out right
% checkXYZ = T_xyz*B_primary*backgroundPrimary;
% checkxyY = XYZToxyY(checkXYZ)


end

%% Objective function for the optimization
function f = ObjFunction(x, B_primary, ambientSpd, T_xyz)

% Get spectrum and luminance
backgroundSpd = B_primary*x + ambientSpd;
photopicLuminanceCdM2 = T_xyz(2,:)*backgroundSpd;

% Maximize the luminance
f = -photopicLuminanceCdM2;

end

%% Constraint function for the optimization
function [c ceq] = ChromaticityNonlcon(x, B_primary, ambientSpd, T_xyz, xy_target)

% Calculate spectrum and chromaticity
backgroundSpd = B_primary*x + ambientSpd;
xy_now = (T_xyz(1:2, :)*backgroundSpd)./repmat(sum(T_xyz*backgroundSpd), 2, 1);

c = [];
ceq = [(xy_target-xy_now).^2];

end