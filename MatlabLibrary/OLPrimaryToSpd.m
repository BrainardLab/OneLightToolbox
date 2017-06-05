function [spd] = OLPrimaryToSpd(oneLightCal, primary, varargin)
%OLPrimaryToSpd  Converts a set of primary OneLight mirror settings to the predicted spd
% 
%   Convert a primary vector for the OneLight into a predicted spd.
%
%   Examples:
%   spd = OLPrimaryToSpd(oneLightCal, primary);
%   spd = OLPrimaryToSpd(oneLightCal, primary, 'differentialMode', true);
%
%   Inputs:
%   oneLightCal (struct) - OneLight calibration file after it has been
%                          processed by OLInitCal.
%   primary - nPrimaries by 1 column vector giving OneLight primary values.  Each should be in
%             range [0-1] for normal mode and [-1,1] for differential mode.
%             Those values out of range are truncated to be in range.
%
%   Outputs:
%   spd - What we think we'll produce with the passed primary settings,
%         in the same units as the PR-6XX mesurements in the calibration
%         struct.
%
%   Optional key/value pairs::
%     'differentialMode' - true/false (default false).  Do not add in the dark light
%                          and allow primaries to be in range [-1,1] rather
%                          than [0,1].
%
% See also OLSpdToPrimary, OLPrimaryToSettings, OLSettingsToStartsStops, OLSpdToPrimaryTest

% 5/24/13  dhb  Wrote this.
% 6/5/17   dhb  Clean up comments.  Differential mode was enforcing
%               primaries into range [0,1] which was wrong.  Fixed.

% Parse input
p = inputParser;
p.addRequired('oneLightCal',@isstruct);
p.addRequired('primary',@isnumeric);
p.addParameter('differentialMode', false, @islogical);
p.parse(oneLightCal,primary,varargin{:});

% Make sure that the calibration file has been processed by OLInitCal.
assert(isfield(oneLightCal, 'computed'), 'OLPrimaryToSpd:InvalidCalFile', ...
    'The calibration file needs to be processed by OLInitCal.');

% Predict spd from calibration fields
% 
% Allowable primary range depends on whether differential mode is true or
% not.
if (p.Results.differentialMode)
    primary(primary < -1) = -1;
    primary(primary > 1) = 1;
    spd = oneLightCal.computed.pr650M * primary;
else
    primary(primary < 0) = 0;
    primary(primary > 1) = 1;
    spd = oneLightCal.computed.pr650M * primary + oneLightCal.computed.pr650MeanDark;
end
