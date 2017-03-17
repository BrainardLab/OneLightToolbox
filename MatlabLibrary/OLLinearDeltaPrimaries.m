function [deltaPrimaries,predictedSpd] = OLLinearDeltaPrimaries(primariesUsed,spdMeasured,spdDesired,learningRate,smoothness,cal)
% OLIterativeDeltaPrimaries
%   [deltaPrimaries,predictedSpd] = OLILinearDeltaPrimaries(primariesUsed,spdMeasured,spdDesired,learningRate,smoothness,cal)
%
% Use device cal and basic device linearity assumptions to find the
% deltaPrimaries that should be added to primariesUsed, given that the
% desired spectrum is spdDesired and the spectrum measued for primariesUsed
% is spdMeasured.
%
% The deltaPrimaries we find might result in out of gamut values when added
% to the primariesUsed.  We adjust the deltaPrimaries so they will result
% in within gamut primaries.

% Linear calculation
deltaPrimaries = learningRate*OLSpdToPrimary(cal, spdDesired - spdMeasured, 'differentialMode', true, 'lambda', smoothness);

% Truncate the primaries we found
deltaPrimaries = OLTruncatedDeltaPrimaries(deltaPrimaries,primariesUsed,cal);

% Get predicted spd
predictedSpd = OLPredictSpdFromDeltaPrimaries(deltaPrimaries,primariesUsed,spdMeasured,cal);

end 
