function [deltaPrimaries,predictedSpd] = OLLinearDeltaPrimaries(deltaPrimaries0,primariesUsed,spdMeasured,spdDesired,learningRate,cal)
% OLIterativeDeltaPrimaries
%   [deltaPrimaries,predictedSpd] = OLILinearDeltaPrimaries(deltaPrimaries0,primariesUsed,spdMeasured,spdDesired,learningRate,cal)
%
% Use numerical search to find the deltaPrimaries that should be added to
% primariesUsed, given that the desired spectrum is spdDesired and the
% spectrum measued for primariesUsed is spdMeasured.

% Options for fmincon, and reasonable bounds
options = optimset('fmincon');
options = optimset(options,'Diagnostics','off','Display','iter','LargeScale','off','Algorithm','active-set');
vlb = -1*ones(size(primariesU));
vub = ones(size(deltaPrimaries0));

% Figure out target spd given learning rate
spdDesiredLearningRate =  spdMeasured + learningRate*(spdDesired - spdMeasured);

% Use fmincon to find the desired primaries
deltaPrimaries = fmincon(@(x)OLIterativeDeltaPrimariesErrorFunction(deltaPrimaries0,primariesUsed,spdMeasured,spdDesiredLearningRate,cal),...
    x0,[],[],[],[],vlb,vub,[],options);

% When we search, we evaluate error based on the
% truncated version, so we just truncate here so that
% the effect matches that of the search.  Could enforce
% a non-linear constraint in the search to keep the
% searched on deltas within gamut, but not sure we'd
% gain anything by doing that.
deltaPrimaries = OLTruncatedDeltaPrimaries(deltaPrimaries,backgroundPrimaryUsed,cal);

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