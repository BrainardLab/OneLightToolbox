function [primary, inGamut, gamutMargin] = OLCheckPrimaryGamut(primary,varargin)
% Check whether primaries are sufficiently in gamut, guarantee return in 0-1
%
% Syntax:
%   truncatedPrimaryValues = OLCheckPrimaryGamut(primaryValues)
%   [truncatedPrimaryValues, inGamut] = OLCheckPrimaryGamut(primaryValues)
%   [truncatedPrimaryValues, inGamut, gamutMargin] = OLCheckPrimaryGamut(primaryValues)
%   [...] = OLCheckPrimaryGamut(...,'differentialMode',true);
%   [...] = OLCheckPrimaryGamut(...,'primaryHeadroom',.005);
%   [...] = OLCheckPrimaryGamut(...,'primaryTolerance',1e-6);
%   [...] = OLCheckPrimaryGamut(...,'checkPrimaryOutOfRange',true);
%
% Description:
%    If primaries are very close to in gamut, truncate to gamut.  If they
%    are too far out of gamut, throw an error.
%
%    This routine respects a set of keyword arguments that are common to
%    many of our routines for finding and dealing with primaries.  These
%    allow it to, for example, enforce headroom as part of what it means
%    to be in gamut. See below for details.
%
% Inputs:
%    primary                  - Numeric matrix (NxM), of primary values to
%                               be checked
%
% Outputs:
%    primary                  - Numeric matrix (NxM) of primary values, 
%                               after truncation and check
%    inGamut                  - Boolean scalar. True if returned primaries
%                               are in gamut, false if not.  You can only
%                               get false if checkPrimaryOutOfRange is
%                               false.
%    gamutMargin              - Numeric scalar. Negative if primaries are
%                               in gamut, amount negative tells you
%                               magnitude of margin. Otherwise this is the
%                               magnitude of the largest deviation
% 
% Optional keyword arguments:
%    'differentialMode'       - Boolean scalar. If true, allowable gamut
%                               starts at [-1,1] not at [0,1], and then is
%                               adjusted by primaryHeadroom. Default false
%    'primaryHeadroom'        - Numeric scalar.  Headroom to leave on
%                               primaries. How much headroom to protect in
%                               definition of in gamut.  Range used for
%                               check and truncation is [primaryHeadroom
%                               1-primaryHeadroom]. Default 0; do not
%                               change this default
%    'primaryTolerance'       - Numeric scalar. Truncate to range [0,1] if
%                               primaries are within this tolerance of
%                               [0,1]. Default 1e-6; do not change this
%                               default
%    'checkPrimaryOutOfRange' - Boolean scalar. Throw error if primary
%                               (after tolerance truncation) is out of
%                               gamut. When false, the inGamut flag is set
%                               true and the returned primaries are
%                               truncated into range. Default true; Do not
%                               change this default, Sometimes assumed to
%                               be true by a caller
%
% Examples are provided in the source code.
%
% See also: OLSpdToPrimary, OLPrimaryInvSolveChrom, OLFindMaxSpd,
%           OLPrimaryToSpd.
%

% History:
%   04/12/18  dhb  Wrote it.

% Examples:

%{
    %% Out of gamut; throw error
    try
        OLCheckPrimaryGamut(1.1);
    catch e
        disp('Threw an error');
    end
%}
%{
    %% Out of gamut, but within tolerance. Get truncated to gamut.
    [outputPrimary,inGamut,gamutMargin] = OLCheckPrimaryGamut(1+1e-7);

    % Check
    assert(round(outputPrimary,5) == 1);
    assert(inGamut);
    assert(round(gamutMargin,5) == 0);

    %% Out of gamut, but within tolerance. Get truncated to gamut.
    [outputPrimary,inGamut,gamutMargin] = OLCheckPrimaryGamut(1+1e-8,...
        'primaryTolerance',1e-7);

    % Check
    assert(round(outputPrimary,5) == 1);
    assert(inGamut);
    assert(round(gamutMargin,5) == 0);
%}
%{
    %% Out of gamut, but force truncate
    [outputPrimary,inGamut,gamutMargin] = OLCheckPrimaryGamut(1.1,...
        'checkPrimaryOutOfRange',false);

    % Check
    assert(~inGamut);
    assert(round(outputPrimary,5) == 1);
    assert(round(gamutMargin,5) == .1);
%}
%{
    %% Truncate to gamut max
    [outputPrimary,inGamut,gamutMargin] = OLCheckPrimaryGamut(1.01, ...
        'checkPrimaryOutOfRange',false);

    % Check
    assert(round(outputPrimary,5) == 1);
    assert(~inGamut);
    assert(round(gamutMargin,5) == .01);
%}
%{
    %% Truncate to gamut min
    [outputPrimary,inGamut,gamutMargin] = OLCheckPrimaryGamut(-0.01, ...
        'checkPrimaryOutOfRange',false);

    % Check
    assert(round(outputPrimary,5) == 0);
    assert(~inGamut);
    assert(round(gamutMargin,5) == .01);
%}
%{
    %% Truncate to gamut
    [outputPrimary,inGamut,gamutMargin] = OLCheckPrimaryGamut([-0.01 .4 1.005], ...
        'checkPrimaryOutOfRange',false);

    % Check
    assert(all(round(outputPrimary,5) == [0 .4 1]));
    assert(~inGamut);
    assert(round(gamutMargin,5) == .01);
%}
%{
    %% In gamut, but out of headroom. Throw error
    try
        OLCheckPrimaryGamut(.98,'primaryHeadroom',.05);
    catch e
        disp('Threw an error');
    end
%}
%{
    %% Truncate up to headroom
    [outputPrimary,inGamut,gamutMargin] = OLCheckPrimaryGamut(-0.01, ...
        'checkPrimaryOutOfRange',false,'primaryHeadroom',0.005);

    % Check
    assert(round(outputPrimary,5) == 0.005);
    assert(~inGamut);
    assert(round(gamutMargin,5) == .0150);
%}
%{
    %% Truncate down to headroom
    [outputPrimary,inGamut,gamutMargin] = OLCheckPrimaryGamut(1.01, ...
        'checkPrimaryOutOfRange',false,'primaryHeadroom',0.005);

    % Check
    assert(round(outputPrimary,5) == 0.9950);
    assert(~inGamut);
    assert(round(gamutMargin,5) == .0150);
%}

%% Parse input
%
% Don't change defaults.  Some calling routines count on them.
p = inputParser;
p.addParameter('differentialMode', false, @islogical);
p.addParameter('primaryHeadroom', 0, @isscalar);
p.addParameter('primaryTolerance', 1e-6, @isscalar);
p.addParameter('checkPrimaryOutOfRange', true, @islogical);
p.parse(varargin{:});

%% Initialize
inGamut = true;
gamutMargin = 0;

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

% Compute gamut deviation as a positive number meaning deviation
upperGamutMargin = max(primary(:) - (upperGamut-p.Results.primaryHeadroom));
lowerGamutMargin = -(min(primary(:)) - (lowerGamut+p.Results.primaryHeadroom));
gamutMargin = max([upperGamutMargin lowerGamutMargin]);

if ( (any(primary(:) > upperGamut - p.Results.primaryHeadroom) || any(primary(:) < lowerGamut + p.Results.primaryHeadroom) ))
    if (p.Results.checkPrimaryOutOfRange)  
        error('At one least primary value is out of gamut');
    else
        % In this case, force primaries to be within gamut
        inGamut = false;
        primary(primary > upperGamut - p.Results.primaryHeadroom) = upperGamut - p.Results.primaryHeadroom;
        primary(primary < lowerGamut + p.Results.primaryHeadroom) = lowerGamut + p.Results.primaryHeadroom;
    end
end

end