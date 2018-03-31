function backgroundNames = OLGetBackgroundNames
% Returns list of all named backgrounds in BackgroundParamsDictionary
%
% Syntax:
%   backgroundNames = OLGetBackgroundNames
%
% Description:
%    For all parameterized backgrounds that are stored under their name in
%    OLBackgroundParamsDictionary, this function will return the name of
%    the parameter set.
%
% Inputs:
%    None.
%
% Outputs:
%    backgroundNames - Nx1 cell array of names for the parameters in
%                      OLBackgroundParamsDictionary
%
% Optional key/value pairs:
%    None.
%
% Notes:
%    None.
%
% See also:
%    OLBackgroundParamsDictionary,

% History:
%    01/31/18  jv  Wrote it.

backgroundNames = OLGetDictionaryEntryNames('Background');
end