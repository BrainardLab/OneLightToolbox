function [deltaPrimaries,predictedSpd] = OLIterativeDeltaPrimariesContrast(deltaPrimaries0,primariesUsed,targetContrasts,measuredSPD,backgroundSPD,T_receptors,learningRate,cal)
% OLIterativeDeltaPrimaries
%   [deltaPrimaries,predictedSpd] = OLIterativeDeltaPrimariesContrast(deltaPrimaries0,primariesUsed,targetContrasts,measuredSPD,backgroundSPD,T_receptors,learningRate,cal)
%
% Use numerical search to find the deltaPrimaries that should be added to
% primariesUsed, given that the desired contrasts are contrastDesired and the
% contrasts measued for primariesUsed are contrastMeasured.
%
% If deltaPrimaries0 is passed as the empty matrix, the search starts at 0.
% Otherwise at the passed value of deltaPrimaries0.

% Options for fmincon, and reasonable bounds
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

% Figure out target contrast given learning rate
contrastDesiredLearningRate =  contrastMeasured + learningRate*(targetContrasts - contrastMeasured);

% Figure out background contrast
receptorsContrast = T_receptors*backgroundSpd;

% Initialize starting point
if (isempty(deltaPrimaries0))
    deltaPrimaries0 = zeros(size(primariesUsed));
end

% Use fmincon to find the desired primaries
deltaPrimaries = fmincon(@(deltaPrimaries)OLIterativeDeltaPrimariesErrorFunction(deltaPrimaries,primariesUsed,targetContrasts,measuredSPD,backgroundSPD,T_receptors,contrastDesiredLearningRate,cal),...
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

function f = OLIterativeDeltaPrimariesErrorFunction(deltaPrimaries,primariesUsed,targetContrasts,measuredSPD,backgroundSPD,T_receptors,contrastDesiredLearningRate,cal)
% OLIterativeDeltaPrimariesErrorFunction  Error function for delta primary iterated search
%   f = OLIterativeDeltaPrimariesErrorFunction(deltaPrimaries,primariesUsed,targetContrasts,measuredSPD,backgroundSPD,T_receptors,contrastDesiredLearningRate,cal)
%
% Figures out how close the passed delta primaries come to producing the
% desired contrasts, using small signal approximation and taking gamut
% limitations and gamma correction into account.

% Get small signal predicted SPD
predictedSPD = OLPredictSpdFromDeltaPrimaries(deltaPrimaries,primariesUsed,measuredSPD,cal);

% Get predicted contrasts
backgroundReceptors = T_receptors*backgroundSPD;
predictedReceptors = T_receptors*predictedSPD;
predictedContrasts = (predictedReceptors - backgroundReceptors) ./ backgroundReceptors;

% Compute error
diffContrasts = targetContrasts-predictedContrasts;
f = sqrt(mean(diffContrasts(:).^2));
end