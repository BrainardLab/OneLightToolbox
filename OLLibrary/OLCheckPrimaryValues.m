function inGamut = OLCheckPrimaryValues(primaryValues,gamutMinMax)
% Check whether primary values are within gamut
%
% Syntax:
%   inGamut = OLCheckPrimaryValues(primaryValues, gamut)
%   [inGamut, gamutMargins] = OLCheckPrimaryValues(...)
%
% Description:
%    Compare given primary values to given gamut, and see whether primary
%    values fall completely within gamut, i.e., is the lowest primary value
%    greater than the bottom of the gamut, and the highest primary value
%    lower than the top of the gamut.
%
% Inputs:
%    primaryValues - Numeric matrix (NxM), of primary values to be 
%                    truncated
%    gamutMinMax   - Numeric 1x2 vector specifying [min, max] of 
%                    gamut
%
% Outputs:
%    inGamut       - Boolean scalar, are primary values within gamut
%
% Optional keyword arguments:
%    None.
%
% Examples are provided in the source code.
%
% See also:
%    OLCheckPrimaryGamut, OLGamutMargins

% History:
%    04/12/18  dhb  wrote OLCheckPrimaryGamut.
%    12/19/18  jv   extracted OLGamutMargins from OLCheckPrimaryGamut and
%                   wrote OLCheckPrimaryValues as wrapper (checks if all
%                   margins are >= 0)

% Examples:
%{
    %% .9 is in gamut = [0, 1]
    primaryValues = .9;
    gamut = [0 1];
    inGamut = OLCheckPrimaryValues(primaryValues, gamut);
    assert(inGamut);
%}
%{
    %% 1.1 is not in gamut = [0, 1]
    primaryValues = 1.1;
    gamut = [0 1];
    inGamut = OLCheckPrimaryValues(primaryValues, gamut);
    assert(~inGamut);
%}
%{
    %% -.9 is not in gamut = [0,1]
    primaryValues = -.9;
    gamut = [0 1];
    inGamut = OLCheckPrimaryValues(primaryValues, gamut);
    assert(~inGamut);
%}
%{
    %% -.9 is in gamut = [-1,1]
    primaryValues = -.9;
    gamut = [-1 1];
    inGamut = OLCheckPrimaryValues(primaryValues, gamut);
    assert(inGamut);
%}

%%
gamutMargins = OLGamutMargins(primaryValues,gamutMinMax); 
    
inGamut = all(gamutMargins >= 0);
end