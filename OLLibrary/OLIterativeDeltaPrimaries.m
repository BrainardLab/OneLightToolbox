function [deltaPrimaries,predictedSpd] = OLIterativeDeltaPrimaries(deltaPrimaries0,primariesUsed,measuredSPD,targetSPD,learningRate,cal)
% Use small signal approximation to estimate primaries that attain target spd.
%
% Syntax:
%     [deltaPrimaries,predictedSpd] = OLIterativeDeltaPrimaries(deltaPrimaries0,primariesUsed,measuredSPD,targetSPD,learningRate,cal)
%
% Description:
%     Use numerical search to find the deltaPrimaries that should be added to
%     primariesUsed, given that the desired spectrum is targetSPD and the
%     spectrum measued for primariesUsed is measuredSPD.
%
%     If deltaPrimaries0 is passed as the empty matrix, the search starts at 0.
%     Otherwise at the passed value of deltaPrimaries0.
%
% Inputs:
%    deltaPrimaries0         - nPrimariesx1 column vector with initial
%                              guess as to deltaPrimaires.  Passing empty
%                              matrix sets this to all zeros.
%    primairesUsed           - nPrimariesx1 column vector with primaries
%                              used to produce measuredSPD.
%    measuredSPD             - nWlsx1 column vector with measured spectral
%                              power distribution when primariesUsed was used.
%                              This should be scaled to correct for any
%                              overall change in the OneLight's output
%                              relative to the calibration structure.
%    targetSPD               - nWlsx1 column vector, with target
%                              spectral power distribution. This should be
%                              the target derived from the calibration
%                              structure, without any scaling.
%    T_receptors             - nReceptorsxnWls matrix specifying receptor
%                              fundamentals.
%    learningRate            - Number betweenn 0 and 1. Aim this fraction
%                              from current contrasts towards target contrasts.
%    cal                     - struct containing calibration for OneLight
%
% Outputs:
%    deltaPrimaries          - nPrimariesx1 column vector column vector of delta
%                              primary values,
%    predictedSPD            - nWlsx1 column vector with the spectral power
%                              distribution predicted when deltaPrimaries is
%                              added to primariesUsed. This is obtained
%                              through the calibration structure, and thus
%                              is scaled like the passed measuredSPD and
%                              targetSPD.

% Options for fmincon
if (verLessThan('matlab','2016a'))
    options = optimoptions('fmincon','Diagnostics','off','Display','off','Algorithm','active-set');
    options.MaxFunEvals = 200;
    options.TolFun = 1e-3;
else
    options = optimoptions('fmincon','Diagnostics','off','Display','off','Algorithm','active-set','OptimalityTolerance',1e-3,'MaxFunctionEvaluations',200);
end

% These bounds on deltas keep primaries in range 0-1.
vlb = -primariesUsed;
vub = 1-primariesUsed;

% Figure out target spd given learning rate
targetSPDLearningRate =  measuredSPD + learningRate*(targetSPD - measuredSPD);

% Initialize starting point
if (isempty(deltaPrimaries0))
    deltaPrimaries0 = zeros(size(primariesUsed));
end

% Use fmincon to find the desired primaries
deltaPrimaries = fmincon(@(deltaPrimaries)OLIterativeDeltaPrimariesErrorFunction(deltaPrimaries,primariesUsed,measuredSPD,targetSPDLearningRate,cal),...
    deltaPrimaries0,[],[],[],[],vlb,vub,[],options);

% When we search, we evaluate error based on the
% truncated version, so we just truncate here so that
% the effect matches that of the search.  Could enforce
% a non-linear constraint in the search to keep the
% searched on deltas within gamut, but not sure we'd
% gain anything by doing that.
deltaPrimaries = OLTruncatedDeltaPrimaries(deltaPrimaries,primariesUsed,cal);

% Get predicted Spd
predictedSpd = OLPredictSpdFromDeltaPrimaries(deltaPrimaries,primariesUsed,measuredSPD,cal);

end 

function f = OLIterativeDeltaPrimariesErrorFunction(deltaPrimaries,primariesUsed,measuredSPD,targetSPD,cal)
% OLIterativeDeltaPrimariesErrorFunction  Error function for delta primary iterated search
%   f = OLIterativeDeltaPrimariesErrorFunction(deltaPrimaries,primariesUsed,measuredSPD,targetSPD,cal)
%
% Figures out how close the passed delta primaries come to producing the
% desired spectrum, using small signal approximation and taking gamut
% limitations and gamma correction into account.

predictedSpd = OLPredictSpdFromDeltaPrimaries(deltaPrimaries,primariesUsed,measuredSPD,cal);
diff = targetSPD-predictedSpd;
f = 1000*sqrt(mean(diff(:).^2));
end