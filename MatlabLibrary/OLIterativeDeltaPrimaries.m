function [deltaPrimaries,predictedSpd] = OLIterativeDeltaPrimaries(deltaPrimaries0,primariesUsed,spdMeasured,spdDesired,learningRate,cal)
% OLIterativeDeltaPrimaries
%   [deltaPrimaries,predictedSpd] = OLIterativeDeltaPrimaries(deltaPrimaries0,primariesUsed,spdMeasured,spdDesired,learningRate,cal)
%
% Use numerical search to find the deltaPrimaries that should be added to
% primariesUsed, given that the desired spectrum is spdDesired and the
% spectrum measued for primariesUsed is spdMeasured.
%
% If deltaPrimaries0 is passed as the empty matrix, the search starts at 0.
% Otherwise at the passed value of deltaPrimaries0.

% Options for fmincon, and reasonable bounds
if (verLessThan('matlab','2016a'))
    options = optimoptions('fmincon','Diagnostics','off','Display','iter','Algorithm','active-set');
    options.MaxFunEvals = 200;
    options.TolFun = 1e-3;
else
    options = optimoptions('fmincon','Diagnostics','off','Display','iter','Algorithm','active-set','OptimalityTolerance',1e-3,'MaxFunctionEvaluations',200);
end

% These bounds keep deltas in range 0-1.
vlb = -primariesUsed;
vub = 1-primariesUsed;

% Figure out target spd given learning rate
spdDesiredLearningRate =  spdMeasured + learningRate*(spdDesired - spdMeasured);

% Initialize starting point
if (isempty(deltaPrimaries0))
    deltaPrimaries0 = zeros(size(primariesUsed));
end

% Use fmincon to find the desired primaries
deltaPrimaries = fmincon(@(deltaPrimaries)OLIterativeDeltaPrimariesErrorFunction(deltaPrimaries,primariesUsed,spdMeasured,spdDesiredLearningRate,cal),...
    deltaPrimaries0,[],[],[],[],vlb,vub,[],options);

% When we search, we evaluate error based on the
% truncated version, so we just truncate here so that
% the effect matches that of the search.  Could enforce
% a non-linear constraint in the search to keep the
% searched on deltas within gamut, but not sure we'd
% gain anything by doing that.
deltaPrimaries = OLTruncatedDeltaPrimaries(deltaPrimaries,primariesUsed,cal);

% Get predicted Spd
predictedSpd = OLPredictSpdFromDeltaPrimaries(deltaPrimaries,primariesUsed,spdMeasured,cal);

end 

function f = OLIterativeDeltaPrimariesErrorFunction(deltaPrimaries,primariesUsed,spdMeasured,spdDesired,cal)
% OLIterativeDeltaPrimariesErrorFunction  Error function for delta primary iterated search
%   f = OLIterativeDeltaPrimariesErrorFunction(deltaPrimaries,primariesUsed,spdMeasured,spdDesired,cal)
%
% Figures out how close the passed delta primaries come to producing the
% desired spectrum, using small signal approximation and taking gamut
% limitations and gamma correction into account.

predictedSpd = OLPredictSpdFromDeltaPrimaries(deltaPrimaries,primariesUsed,spdMeasured,cal);
diff = spdDesired-predictedSpd;
f = 1000*sqrt(mean(diff(:).^2));
end