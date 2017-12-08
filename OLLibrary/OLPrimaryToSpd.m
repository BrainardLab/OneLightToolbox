function spd = OLPrimaryToSpd(calibration, primary, varargin)
% Converts a set of OneLight primary values to the predicted spd
% 
% Syntax:
%   spd = OLPrimaryToSpd(primary, calibration);
%   spd = OLPrimaryToSpd(primary, calibration, 'differentialMode', true);
%
% Description:
%    Convert a primary for the OneLight into a predicted SPD
%
% Inputs:
%    primary     - PxN matrix, where P is the number of primaries, and N is
%                  the number of vectors of primary values. Each should be 
%                  in range [0-1] for normal mode and [-1,1] for 
%                  differential mode (see  below). Those values out of 
%                  range are truncated to be in range.
%    calibration - OneLight calibration file (must be valid, i.e., been 
%                  processed by OLInitCal)
%
% Outputs:
%    spd         - Spectral power distribution(s) predicted from the 
%                  primary values and calibration information
%
% Optional key/value pairs:
%    'differentialMode' - (true/false). Do not add in the
%                         dark light and allow primaries to be in range
%                         [-1,1] rather than [0,1]. Default false.
%
% See also:
%    OLSpdToPrimary, OLPrimaryToSettings, OLSettingsToStartsStops, 
%    OLSpdToPrimaryTest

% History:
%    05/24/13  dhb  Wrote this.
%    06/05/17  dhb  Clean up comments.  Differential mode was enforcing
%                   primaries into range [0,1] which was wrong.  Fixed.
%    12/08/17  jv   put header comment in ISETBIO convention.

% Parse input
p = inputParser;
p.addRequired('calibration',@isstruct);
p.addRequired('primary',@isnumeric);
p.addParameter('differentialMode', false, @islogical);
p.parse(calibration,primary,varargin{:});

% Make sure that the calibration file has been processed by OLInitCal.
assert(isfield(calibration, 'computed'),...
    'OneLightToolbox:OLPrimaryToSpd:InvalidCalFile', ...
    'The calibration file needs to be processed by OLInitCal.');

% Predict spd from calibration fields
% 
% Allowable primary range depends on whether differential mode is true or
% not.
if (p.Results.differentialMode)
    primary(primary < -1) = -1;
    primary(primary > 1) = 1;
    spd = calibration.computed.pr650M * primary;
else
    primary(primary < 0) = 0;
    primary(primary > 1) = 1;
    spd = calibration.computed.pr650M * primary + calibration.computed.pr650MeanDark;
end
