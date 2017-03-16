function [truncatedDeltaPrimaries,truncatedPrimaries] = OLTruncatedDeltaPrimaries(deltaPrimaries,primariesUsed,cal)
% OLTruncatedDeltaPrimaries  Figure out truncated delta primaries
%  [truncatedDeltaPrimaries,truncatedPrimaries] = OLTruncatedDeltaPrimaries(primariesUsed,deltaPrimaries,cal)
%
% Determine what deltaPrimaries will actually be added to primariesUsed,
% given input deltaPrimaries and the fact that the OneLight primaries need
% to go between 0 and 1.
%
% Also does a PrimaryToSettings and SettingsToPrimaries to account for any
% effects of gamma correction, although this shouldn't matter much.

truncatedPrimaries = primariesUsed + deltaPrimaries;
truncatedPrimaries(truncatedPrimaries < 0) = 0;
truncatedPrimaries(truncatedPrimaries > 1) = 1;
truncatedPrimaries = OLSettingsToPrimary(cal,OLPrimaryToSettings(cal,truncatedPrimaries));
truncatedDeltaPrimaries = truncatedPrimaries - primariesUsed;
end