function [predictedSpd,truncatedDeltaPrimaries] = OLPredictSpdFromDeltaPrimaries(deltaPrimaries,primariesUsed,spdMeasured,cal)
% OLPredictSpdFromDeltaPrimaries  Predict spectrum from primary change
%   predictedSpd,truncatedDeltaPrimaries] = OLPredictSpdFromDeltaPrimaries(deltaPrimaries,primariesUsed,spdMeasured,cal)
%
% Takes current primary values and measured spd and makes the small signal
% prediction for the effect of changing the primaries by deltaPrimaries,
% taking gamut limits and gamma correction into account.

    truncatedDeltaPrimaries = OLTruncatedDeltaPrimaries(deltaPrimaries,primariesUsed,cal);
    predictedSpd = spdMeasured + OLPrimaryToSpd(cal,truncatedDeltaPrimaries,'differentialMode',true);
end