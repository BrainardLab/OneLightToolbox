function theSpd = OLPrimaryToSpd(calibration, primary, varargin)
% Predict spectral power distribution from primar values
%
% Syntax:
%   theSpd = OLPrimaryToSpd(primary, calibration);
%   theSpd = OLPrimaryToSpd(primary, calibration, 'differentialMode', true);
%
% Description:
%    Takes in vectors of primary values, and a OneLight calibration, and
%    returns the spectral power distribution predicted from the calibration
%    for each vector of primary values.
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
%    theSpd      - Spectral power distribution(s) predicted from the
%                  primary values and calibration information
%
% Optional key/value pairs:
%    'differentialMode' - Boolean. Do not add in the
%                  dark light and allow primaries to be in range
%                  [-1,1] rather than [0,1]. Default false.
%
% See also:
%    OLSpdToPrimary, OLPrimaryToSettings, OLSettingsToStartsStops,
%    OLSpdToPrimaryTest

% History:
%    05/24/13  dhb  Wrote this.
%    06/05/17  dhb  Clean up comments.  Differential mode was enforcing
%                   primaries into range [0,1] which was wrong.  Fixed.
%    12/08/17  jv   put header comment in ISETBIO convention.
%    03/08/18  jv   clarified header comment.

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
    theSpd = calibration.computed.pr650M * primary;
else
    primary(primary < 0) = 0;
    primary(primary > 1) = 1;
    theSpd = calibration.computed.pr650M * primary + calibration.computed.pr650MeanDark;
end