function truncatedPrimaryValues = OLTruncatePrimaryValues(primaryValues,gamutMinMax)
% Truncates primary values to be within specified gamut
%
% Syntax:
%   truncatedPrimaryValues = OLTruncatePrimaryValues(primaryValues, gamut)
%
% Description:
%    Truncate a matrix (or vector, scalar) of primary values to be within
%    specified gamut; after truncation min(primaryValues) >= gamut(1), and
%    max(primaryValues) <= gamut(2).
%
% Inputs:
%    primaryValues          - Numeric matrix (NxM), of primary values to be 
%                             truncated
%    gamutMinMax            - Numeric 1x2 vector specifying [min, max] of 
%                             gamut
%
% Outputs:
%    truncatedPrimaryValues - Numeric matrix (NxM) of primary values, now 
%                             truncated to be in gamut
%
% Optional keyword arguments:
%    None.
%
% Examples are provided in the source code.
%
% See also:
%    OLTruncatePrimaryTolerance, OLCheckPrimaryValues, OLCheckPrimaryGamut,
%    OLPrimaryToSpd

% History:
%    04/12/18  dhb  wrote OLCheckPrimaryGamut.
%    12/19/18  jv   extracted from OLCheckPrimaryGamut, as wrapper around
%                   OLTruncatePrimaryTolerance (with tolerance = Inf)

% Examples:
%{
    %% Truncate to gamut-max
    primaryValues = 2;
    gamut = [0 1];
    truncatedPrimaryValues = OLTruncatePrimaryValues(primaryValues, gamut);

    % Check
    assert(truncatedPrimaryValues == 1);
%}
%{
    %% Truncate to gamut-min
    primaryValues = -1;
    gamut = [0 1];
    truncatedPrimaryValues = OLTruncatePrimaryValues(primaryValues, gamut);

    % Check
    assert(truncatedPrimaryValues == 0);
%}
%{
    %% Truncate to gamut = [0 1]
    primaryValues = [-.5 0 .4 .8 1 1.6];
    gamut = [0 1];
    truncatedPrimaryValues = OLTruncatePrimaryValues(primaryValues, gamut);

    % Check
    assert(all(truncatedPrimaryValues == [0 0 .4 .8 1 1]));
%}
%{
    %% Truncate to gamut = [-1 1]
    primaryValues = [-1 1];
    gamut = [-1 1];
    truncatedPrimaryValues = OLTruncatePrimaryValues(primaryValues, gamut);

    % Check
    assert(all(truncatedPrimaryValues == primaryValues));
%}
%{
    %% Gamut is auto-sorted
    primaryValues = [-1 -1];
    gamut = [0 -1];
    truncatedPrimaryValues = OLTruncatePrimaryValues(primaryValues, gamut);

    % Check
    assert(all(truncatedPrimaryValues == primaryValues));
%}
%{
    %% Leave some 'headroom' on primaries:
    primaryValues = [0 .8 1];
    gamut = [0.005 .995];
    truncatedPrimaryValues = OLTruncatePrimaryValues(primaryValues, gamut);

    % Check
    assert(all(truncatedPrimaryValues == [.005 .8 .995]));    
%}

%%
truncatedPrimaryValues = OLTruncateGamutTolerance(primaryValues, gamutMinMax, Inf);
end