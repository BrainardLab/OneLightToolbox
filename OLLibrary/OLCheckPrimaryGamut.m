function [primary, inGamut] = OLCheckPrimaryGamut(primary,varargin)
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
p.parse(varargin{:});

%% Initialize
inGamut = true;

%% Check that primaries are within gamut to tolerance.
%
% Truncate and call it good if so, throw error conditionally on checking if
% not.
primary(primary < p.Results.primaryHeadroom & primary > p.Results.primaryHeadroom - p.Results.primaryTolerance) = p.Results.primaryHeadroom;
primary(primary > 1-p.Results.primaryHeadroom & primary < 1 -p.Results.primaryHeadroom + p.Results.primaryTolerance) = 1-p.Results.primaryHeadroom;
if ( (any(primary(:) > 1-p.Results.primaryHeadroom) || any(primary(:) < p.Results.primaryHeadroom) ))
    if (p.Results.checkPrimaryOutOfRange)  
        error('At one least primary value is out of gamut');
    else
        inGamut = false;
    end
end

end