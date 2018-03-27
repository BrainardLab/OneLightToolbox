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
%                         0.1
%

% 05/22/15  ms      Wrote it.
% 06/29/17  dhb     Clean up.
% 03/27/18  dhb     Add 'PrimaryHeadroom' key/value pair.

%% Input parser
p = inputParser;
p.addParameter('PrimaryHeadroom',0.1,@isscalar);
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

%% Get reference background -- half on
bgRef = 0.5*ones(nPrimaries, 1);

%% Get the maximum luminance for this calibration
maxLuminance = T_xyz(3, :)*mean(cal.raw.fullOn, 2);

%% Construct basis functions
%
% We'll look for backgrounds within this space of spectra
B1 = 0.5*ones(nPrimaries,1);            % Half-on
B2 = 1-linspace(0, 1, nPrimaries);      % Linear ramp
B3 = 1+-linspace(-1, 1, nPrimaries).^2; % Quadratic
B = [B1 B2' B3'];                       % Put them together

% Multiply with the B_primary matrix from the calibration and the relevant
% CIE functions
xy_s = (T_xyz(1:2, :)*B_primary*B)./repmat(sum(T_xyz*B_primary*B), 2, 1);
Y_s = (T_xyz(3, :)*B_primary*B);

% Put them together
xyY_s = [xy_s ; Y_s];

%% Define the target chromaticities and luminance
%
% Luminance set to be 1/5 of the max.  This is likely to be within gamut.
xyY_target = [desiredChromaticity(1) desiredChromaticity(2) maxLuminance/5]';
xy_target = xyY_target(1:2);

%% First step: Solve with a linear method
%
% Provides a starting point for optimization
w = inv(xyY_s)*xyY_target;

% Sanity check. Look at this and see if it
% comes out near xyY_target if you like.
xyY_targetCheck = xyY_s*w;

%% Second step: Maximize luminance while staying at chromaticity
% Stay within gamut constraints
options = optimset('fmincon');
options = optimset(options,'Diagnostics','off','Display','off','LargeScale','off','Algorithm','active-set', 'MaxIter', 10000, 'MaxFunEvals', 100000, 'TolFun', 1e-10, 'TolCon', 1e-10, 'TolX', 1e-10);
maxHeadroom = p.Results.PrimaryHeadroom;
vub = ones(size(B_primary, 2), 1)-maxHeadroom;
vlb = ones(size(B_primary, 2), 1)*maxHeadroom;
x = fmincon(@(x) ObjFunction(x, B_primary, ambientSpd, T_xyz),B*w,[],[],[],[],vlb,vub,@(x)ChromaticityNonlcon(x, B_primary, T_xyz, xy_target),options);

%% Pull the background out of the solution
backgroundPrimary = x;
if any(backgroundPrimary > 1)
    error('Primary values > 1');
end
if any(backgroundPrimary < 0)
    error('Primary values < 0');
end

%% Look at these to see if things came out right
checkChromaticityXY = (T_xyz(1:2, :)*B_primary*backgroundPrimary)./repmat(sum(T_xyz*B_primary*backgroundPrimary), 2, 1);
checkPhotopicLuminanceCdM2 = (T_xyz(3, :)*B_primary*x);

end

%% Objective function for the optimization
function f = ObjFunction(x, B_primary, ambientSpd, T_xyz)

% Ge luminance
backgroundSpd = B_primary*x + ambientSpd;
photopicLuminanceCdM2 = T_xyz(2,:)*backgroundSpd;

% Maximize the luminance
f = -photopicLuminanceCdM2;

end

%% Constraint function for the optimization
function [c ceq] = ChromaticityNonlcon(x, B_primary, T_xyz, xy_target)
% Calculate chromaticity
xy_s = (T_xyz(1:2, :)*B_primary*x)./repmat(sum(T_xyz*B_primary*x), 2, 1);

c = [];
ceq = [(xy_target-xy_s).^2];

end