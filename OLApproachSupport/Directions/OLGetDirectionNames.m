function directionNames = OLGetDirectionNames
% Returns list of all named directions in DirectionParamsDictionary
%
% Syntax:
%   directionNames = OLGetDirectionNames
%
% Description:
%    For all parameterized directions that are stored under their name in
%    OLDirectionParamsDictionary, this function will return the name of
%    the parameter set.
%
% Inputs:
%    None.
%
% Outputs:
%    directionNames - Nx1 cell array of names for the parameters in
%                      OLDirectionParamsDictionary
%
% Optional key/value pairs:
%    None.
%
% Notes:
%    None.
%
% See also:
%    OLDirectionParamsDictionary,

% History:
%    01/31/18  jv  Wrote it.
directionNames = OLGetDictionaryEntryNames('Direction');
end