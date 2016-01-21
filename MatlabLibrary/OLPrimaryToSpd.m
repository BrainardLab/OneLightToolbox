function [spd] = OLPrimaryToSpd(oneLightCal, primary)
% OLSpdToPrimary - Converts a set of primary OneLight mirror settings to the predicted spd
%
% Syntax:
% [spd] = OLPrimaryToSpd(oneLightCal, primary)
% 
% Description:
% Convert a primary vector for the OneLight into a predicted spd.
%
% Input:
% oneLightCal (struct) - OneLight calibration file after it has been
%     processed by OLInitCal.
% primary - vector giving OneLight primary values.  Each should be in 
%     range [0-1].  Those values out of range are truncated to in range.
%
% Output:
% spd - What we think we'll produce with the passed primary settings,
%       in the same units as the PR-6XX mesurements in the calibration struct.
%
% 5/24/13  dhb  Wrote this.

% Validate the number of inputs.
error(nargchk(2, 2, nargin));

% Make sure that the calibration file has been processed by OLInitCal.
assert(isfield(oneLightCal, 'computed'), 'OLPrimaryToSpd:InvalidCalFile', ...
    'The calibration file needs to be processed by OLInitCal.');

% Make sure passed primary values are in range [0-1]
primary(primary < 0) = 0;
primary(primary > 1) = 1;

% Predict spd from calibration fields
spd = oneLightCal.computed.pr650M * primary + oneLightCal.computed.pr650MeanDark;
