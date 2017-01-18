function [spd] = OLPrimaryToSpd(oneLightCal, primary, varargin)
%OLPRIMARYTOSPD Converts a set of primary OneLight mirror settings to the predicted spd
%   [spd] = OLPRIMARYTOSPD(oneLightCal, primary, vargin)
% 
%   Convert a primary vector for the OneLight into a predicted spd.
%
%   Inputs:
%   oneLightCal (struct) - OneLight calibration file after it has been
%   processed by OLInitCal.
%   primary - vector giving OneLight primary values.  Each should be in
%   range [0-1].  Those values out of range are truncated to in range.
%
%   Outputs:
%   spd - What we think we'll produce with the passed primary settings,
%   in the same units as the PR-6XX mesurements in the calibration
%   struct.
%
%   Optional parameter name/value pairs chosen from the following:
%
%   'differentialMode'    Do not add in the dark light (default false). 
%
% See also OLSPDTOPRIMARY

% 5/24/13  dhb  Wrote this.

% Parse input
p = inputParser;
p.addRequired('oneLightCal',@isstruct);
p.addRequired('primary',@isnumeric);
p.addParameter('differentialMode', false, @islogical);
p.parse(oneLightCal,primary,varargin{:});

% Make sure that the calibration file has been processed by OLInitCal.
assert(isfield(oneLightCal, 'computed'), 'OLPrimaryToSpd:InvalidCalFile', ...
    'The calibration file needs to be processed by OLInitCal.');

% Make sure passed primary values are in range [0-1]
primary(primary < 0) = 0;
primary(primary > 1) = 1;

% Predict spd from calibration fields
if (p.Results.differentialMode)
    spd = oneLightCal.computed.pr650M * primary;
else
    spd = oneLightCal.computed.pr650M * primary + oneLightCal.computed.pr650MeanDark;
end
