function predictedSpd = OLPrimaryToSpd(calibration, primary, varargin)
% Predict spectral power distribution from primar values
%
% Syntax:
%   predictedSpd = OLPrimaryToSpd(primary, calibration);
%   predictedSpd = OLPrimaryToSpd(primary, calibration, 'differentialMode', true);
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
%    predictedSpd - Spectral power distribution(s) predicted from the
%                  primary values and calibration information
%
% Optional key/value pairs:
%    'differentialMode' - Boolean. Do not add in the
%                         dark light and allow primaries to be in range
%                         [-1,1] rather than [0,1]. Default false.
%   'primaryHeadroom'   - Scalar.  Headroom to leave on primaries.  Default
%                         0. How much headroom to protect in definition of
%                         in gamut.  Range used for check and truncation is
%                         [primaryHeadroom 1-primaryHeadroom]. Do not change
%                         this default.  Sometimes assumed to be true by a
%                         caller.
%    'primaryTolerance' - Scalar (default 1e-6). Primaries can be this
%                         much out of gamut and it will truncate them
%                         into gamut without complaining.
%    'checkPrimaryOutOfRange' - Boolean (default true). Throw error if any passed
%                         primaries are out of the [0-1] range.
%    'skipAllChecks'    - Boolean (default false). The checks take time, and
%                         this routine is sometimes called in searches
%                         where we want it to go fast, and are doing
%                         relevant checking elsewhere.  Setting to true
%                         ignores checks and makes this run faster.
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

%% Parse input
p = inputParser;
p.addRequired('calibration',@isstruct);
p.addRequired('primary',@isnumeric);
p.addParameter('differentialMode', false, @islogical);
p.addParameter('primaryHeadroom', 0, @isscalar);
p.addParameter('primaryTolerance',1e-6, @isscalar);
p.addParameter('checkPrimaryOutOfRange', true, @islogical);
p.addParameter('skipAllChecks', false, @islogical);
p.parse(calibration,primary,varargin{:});

%% Checks, if not skipped for speed
if (~p.Results.skipAllChecks)
    % Make sure that the calibration file has been processed by OLInitCal.
    
    assert(isfield(calibration, 'computed'),...
        'OneLightToolbox:OLPrimaryToSpd:InvalidCalFile', ...
        'The calibration file needs to be processed by OLInitCal.');
    
    % Check input range
    primary = OLCheckPrimaryGamut(primary,...
        'primaryHeadroom',p.Results.primaryHeadroom, ...
        'primaryTolerance',p.Results.primaryTolerance, ...
        'checkPrimaryOutOfRange',p.Results.checkPrimaryOutOfRange, ...
        'differentialMode',p.Results.differentialMode);
end

% Predict spd from calibration fields
%
% Allowable primary range depends on whether differential mode is true or
% not.
if (p.Results.differentialMode)
    predictedSpd = calibration.computed.pr650M * primary;
else
    predictedSpd = calibration.computed.pr650M * primary + calibration.computed.pr650MeanDark;
end