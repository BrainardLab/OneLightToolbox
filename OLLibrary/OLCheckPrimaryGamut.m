function [primary, inGamut, gamutDeviation] = OLCheckPrimaryGamut(primary,varargin)
% Check whether primaries are sufficiently in gamut, guarantee return in 0-1
%
% Syntax:
%     [primary, inGamut = OLCheckPrimaryGamut(primary)   
%
% Description:
%     If primaries are very close to in gamut, truncate to gamut.  If they
%     are too far out of gamut, throw an error.
%
%     This routine respects a set of key/value pairs that are common to
%     many of our routines for finding and dealing with primaries.  These
%     allow it to, for example, enforce headroom as part of what it means
%     to be in gamut. See below for details.
%
% Inputs:
%     primary                 - A scalar, vector or matrix containing
%                               primary values. 
%
% Outputs:
%     primary                 - Same as input, after truncation and check.
%     inGamut                 - Boolean. True if returned primaries are in
%                               gamut, false if not.  You can only get
%                               false if checkPrimaryOutOfRange is false.
%     gamutDeviation          - Negative if primaries are in gamut, amount negative
%                               tells you magnitude of margin. Otherwise this is the
%                               magnitude of the largest deviation.
% 
% Optional key/value pairs:
%   'primaryHeadroom'         - Scalar.  Headroom to leave on primaries.  Default
%                               0. How much headroom to protect in
%                               definition of in gamut.  Range used for
%                               check and truncation is [primaryHeadroom
%                               1-primaryHeadroom]. Do not change this
%                               default.  Sometimes assumed to be true by a
%                               caller.
%   'primaryTolerance         - Scalar. Truncate to range [0,1] if primaries are
%                               within this tolerance of [0,1]. Default 1e-6, and
%                               'checkPrimaryOutOfRange' value is true.
%   'checkPrimaryOutOfRange'  - Boolean. Perform primary tolerance check. Default true.
%                               Do not change this default.  Sometimes
%                               assumed to be true by a caller.
%   'differentialMode'        - Boolean. If true, allowable gamut starts at [-1,1] not at
%                               [0,1], and then is adjusted by
%                               primaryHeadroom. Default false.
%
% See also: OLSpdToPrimary, OLPrimaryInvSolveChrom, OLFindMaxSpd,
%           OLPrimaryToSpd.
%

% History:
%   04/12/18  dhb  Wrote it.

%% Parse input
%
% Don't change defaults.  Some calling routines count on them.
p = inputParser;
p.addParameter('primaryHeadroom', 0, @isscalar);
p.addParameter('primaryTolerance', 1e-6, @isscalar);
p.addParameter('checkPrimaryOutOfRange', true, @islogical);
p.addParameter('differentialMode', false, @islogical);
p.parse(varargin{:});

%% Initialize
inGamut = true;
gamutDeviation = 0;

%% Handle differential mode
if (p.Results.differentialMode)
    lowerGamut = -1;
else
    lowerGamut = 0;
end
upperGamut = 1;

%% Check that primaries are within gamut to tolerance.
%
% Truncate and call it good if so, throw error conditionally on checking if
% not.
primary(primary < lowerGamut + p.Results.primaryHeadroom & primary > lowerGamut + p.Results.primaryHeadroom - p.Results.primaryTolerance) = lowerGamut + p.Results.primaryHeadroom;
primary(primary > upperGamut - p.Results.primaryHeadroom & primary < upperGamut - p.Results.primaryHeadroom + p.Results.primaryTolerance) = upperGamut - p.Results.primaryHeadroom;
if ( (any(primary(:) > upperGamut - p.Results.primaryHeadroom) || any(primary(:) < lowerGamut + p.Results.primaryHeadroom) ))
    if (p.Results.checkPrimaryOutOfRange)  
        error('At one least primary value is out of gamut');
    else
        inGamut = false;
        upperGamutDeviation = abs(max(primary(:)) - (upperGamut-p.Results.primaryHeadroom));
        lowerGamutDeviation = abs(min(primary(:)) - (lowerGamut+p.Results.primaryHeadroom));
        gamutDeviation = max([upperGamutDeviation lowerGamutDeviation]);
    end
end

end