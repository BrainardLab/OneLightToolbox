function predictedSpd = OLPrimaryToSpdFastAndDirty(calibration, primary)
% Predict spectral power distribution from primary values
%
% Syntax:
%   predictedSpd = OLPrimaryToSpdFastAndDirty(primary, calibration);
%
% Description:
%    This does the same thing as OLPrimaryToSpd in non-differential
%    mode, but skips all checks. It is mean to be called in circumstances
%    (e.g., from the error function used by fmincon) where speed really
%    matters, and where we can do any needed checking outside of the
%    search.
%
%    If you want to do differential mode using this routine, doctor the
%    passed calibration so that the field calibration.computed.pr650MeanDark
%    is all zeros.
%
%    The reason I wrote this was that the profiler indicated that even with
%    'skipAllChecks' set to true in OLPrimaryToSpd, the bulk of the time
%    was being spent evaluating the if statements required to do the
%    skipping.
%
% Inputs:
%    primary     - PxN matrix, where P is the number of primaries, and N is
%                  the number of vectors of primary values. Each should be
%                  in range [0-1] for normal mode and [-1,1] for
%                  differential mode (see  below). Those values out of
%                  range are truncated to be in range.
%    calibration - OneLight calibration struct (must be valid, i.e., been
%                  processed by OLInitCal)
%
% Outputs:
%    predictedSpd - Spectral power distribution(s) predicted from the
%                  primary values and calibration information
%
% See also:
%    OLSpdToPrimary, OLPrimaryToSettings, OLSettingsToStartsStops,
%    OLSpdToPrimaryTest
%

% History:
%    04/23/18  dhb  Wrote this.


% Predict spd from calibration fields
predictedSpd = calibration.computed.pr650M * primary + calibration.computed.pr650MeanDark;
