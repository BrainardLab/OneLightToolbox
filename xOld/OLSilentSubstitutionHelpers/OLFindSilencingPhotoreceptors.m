function [x contrast] = OLFindSilencingPhotoreceptors(backgroundSpd, modulationSpd, observerAgeInYears, fractionBleachedLMS, fieldSizeDegrees, pupilDiameterMm)
% OLFindSilencingPhotoreceptors - WHAT DO I DO?
%
% Description:
%   THIS ROUTINE NEEDS HEADER COMMENTS SO BAD IT HURTS

% 6/17/18  dhb  Added plea for header comments.

S = [380 2 201];
options = optimoptions('fmincon', 'Display', 'off', 'Algorithm','sqp', 'MaxFunEvals', 100000, 'TolFun', 1e-10, 'TolCon', 1e-10, 'TolX', 1e-10);

GLOBAL_OPTIM = false;
if GLOBAL_OPTIM
problem = createOptimProblem('fmincon', 'objective', @(x) SilencingPhotoreceptorsOptimFunc(x, backgroundSpd, modulationSpd, S, fieldSizeDegrees, pupilDiameterMm, fractionBleachedLMS), ...
    'x0', [observerAgeInYears 0 0 0 fractionBleachedLMS], 'lb', [20 0 0 0 fractionBleachedLMS], 'ub', [60 0 0 0 fractionBleachedLMS], 'options', options)
gs = GlobalSearch('Display', 'iter');
[x, f]= run(gs, problem);
else
    
  x = fmincon(@(x) SilencingPhotoreceptorsOptimFunc(x, backgroundSpd, modulationSpd, S, fieldSizeDegrees, pupilDiameterMm, fractionBleachedLMS), [observerAgeInYears 0 0 0 fractionBleachedLMS], [], [], [], [], [20 0 0 0 fractionBleachedLMS], [60 0 0 0 fractionBleachedLMS], [], options);
end

% Construct the fundamentals
CMF_SOURCE = 'SS';
switch CMF_SOURCE
    case 'CIE'
        [T_LCone] = GetHumanPhotoreceptorSS(S, {'LCone'}, fieldSizeDegrees, x(1), pupilDiameterMm, ...
            x(2), x(5), [], []);
        [T_MCone] = GetHumanPhotoreceptorSS(S, {'MCone'}, fieldSizeDegrees, x(1), pupilDiameterMm, ...
            x(3), x(6), [], []);
        [T_SCone] = GetHumanPhotoreceptorSS(S, {'SCone'}, fieldSizeDegrees, x(1), pupilDiameterMm, ...
            x(4), x(7), [], []);
        T_receptors = [T_LCone ; T_MCone; T_SCone];
    case 'SS'
        T_receptors = ComputeCIEConeFundamentals(S,10,x(1),3);
end

% Calculate the contrast

bgReceptors = T_receptors * backgroundSpd;
modReceptors = T_receptors * modulationSpd;
contrast = (modReceptors - bgReceptors)./bgReceptors;

% load T_cones_ss10
% T_cones_ss10 = SplineCmf(S_cones_ss10, T_cones_ss10, S);
% bgReceptors = T_cones_ss10 * backgroundSpd;
% modReceptors = T_cones_ss10 * modulationSpd;
% contrastNew = (modReceptors - bgReceptors)./bgReceptors

%plot(T_receptors'); drawnow;

function e = SilencingPhotoreceptorsOptimFunc(x, backgroundSpd, modulationSpd, S, fieldSizeDegrees, pupilDiameterMm, fractionBleachedLMS);

% Pull out the values
ageInYears = x(1);
lConeShift = x(2);
mConeShift = x(3);
sConeShift = x(4);
lBleached = x(5);
mBleached = x(6);
sBleached = x(7);

% Construct the fundamentals
[T_LCone] = GetHumanPhotoreceptorSS(S, {'LCone'}, fieldSizeDegrees, ageInYears, pupilDiameterMm, ...
    lConeShift, lBleached, [], []);
[T_MCone] = GetHumanPhotoreceptorSS(S, {'MCone'}, fieldSizeDegrees, ageInYears, pupilDiameterMm, ...
    mConeShift, mBleached, [], []);
[T_SCone] = GetHumanPhotoreceptorSS(S, {'SCone'}, fieldSizeDegrees, ageInYears, pupilDiameterMm, ...
    sConeShift, sBleached, [], []);

% Calculate the contrast
T_receptors = [T_LCone ; T_MCone; T_SCone];
bgReceptors = T_receptors * backgroundSpd;
modReceptors = T_receptors * modulationSpd;
contrast = (modReceptors - bgReceptors)./bgReceptors;

e = sum((100*contrast).^2);