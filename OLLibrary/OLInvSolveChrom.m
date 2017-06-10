function x = OLInvSolveChrom(cal, desiredChromaticity);
% Program to find background spectrum of a desired chromaticity and
% luminance.
%
% 5/22/15   ms      Wrote it.

%% Set up some parameters
S = [380 2 201];
wls = SToWls(S);

%% Load CIE functions
load T_xyz1931
T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);

B_primary = cal.computed.pr650M;
nPrimaries = size(B_primary, 2);
ambientSpd = cal.computed.pr650MeanDark;
bgRef = 0.5*ones(nPrimaries, 1);
chromaticityXY_ref = (T_xyz(1:2, :)*B_primary*bgRef)./repmat(sum(T_xyz*B_primary*bgRef), 2, 1);
photopicLuminanceCdM2_ref = (T_xyz(3, :)*B_primary*bgRef);;

% Get the max luminance for this calibration
maxLuminance = T_xyz(3, :)*mean(cal.raw.fullOn, 2);

%% Construct basis functions
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
% Luminance set to be 1/5 of the max. luminance of this calibration
xyY_target = [desiredChromaticity(1) desiredChromaticity(2) maxLuminance/5]';

%% First step: Solve with this method
w = inv(xyY_s)*xyY_target;

% Sanity check
xyY_s*w;

%% Second step: Optimize smoothness of the spectra subject to the
% chromaticity constraints
targetLum = maxLuminance;
xy_target = xyY_target(1:2);

% Set up the optimization
options = optimset('fmincon');
options = optimset(options,'Diagnostics','off','Display','off','LargeScale','off','Algorithm','active-set', 'MaxIter', 10000, 'MaxFunEvals', 100000, 'TolFun', 1e-10, 'TolCon', 1e-10, 'TolX', 1e-10);
maxHeadroom = 0.1;
vub = ones(size(B_primary, 2), 1)-maxHeadroom;
vlb = ones(size(B_primary, 2), 1)*maxHeadroom;
x = fmincon(@(x) ObjFunction(x, B_primary, ambientSpd, T_xyz, targetLum),B*w,[],[],[],[],vlb,vub,@(x)ChromaticityNonlcon(x, B_primary, T_xyz, xy_target),options);

%problem = createOptimProblem('fmincon', 'objective', @(x) ObjFunction(x, B_primary, ambientSpd, T_xyz, maxLuminance/2), 'x0', B*w, 'lb', vlb, 'ub', vub, 'nonlcon', @(x)ChromaticityNonlcon(x, B_primary, T_xyz, xy_target), 'options', options);
%gs = GlobalSearch;
%[x,f] = run(gs,problem)

isolatingPrimary = x;

if any(isolatingPrimary > 1)
    error('Primary values > 1');
end

if any(isolatingPrimary < 0)
    error('Primary values < 0');
end
chromaticityXY = (T_xyz(1:2, :)*B_primary*x)./repmat(sum(T_xyz*B_primary*x), 2, 1)
photopicLuminanceCdM2 = (T_xyz(3, :)*B_primary*x)

function f = ObjFunction(x, B_primary, ambientSpd, T_xyz, targetLum)
backgroundSpd = B_primary*x + ambientSpd;
photopicLuminanceCdM2 = T_xyz(2,:)*backgroundSpd;

% Maximize the luminance
f = -photopicLuminanceCdM2;

function [c ceq] = ChromaticityNonlcon(x, B_primary, T_xyz, xy_target)
% Calculate chromaticity
xy_s = (T_xyz(1:2, :)*B_primary*x)./repmat(sum(T_xyz*B_primary*x), 2, 1);

c = [];
ceq = [(xy_target-xy_s).^2];