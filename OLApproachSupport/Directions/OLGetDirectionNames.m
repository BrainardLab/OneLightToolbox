function directionNames = OLGetDirectionNames(varargin)
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
%    directionNames  - Nx1 cell array of names for the parameters in
%                      OLDirectionParamsDictionary
%
% Optional key/value pairs:
%    'alternateDictionaryFunc' - String with name of alternate dictionary
%                      function to call. This must be a function on the
%                      path. Default of empty results in using this
%                      function.
%
% Notes:
%    None.
%
% See also:
%    OLDirectionParamsDictionary.

% History:
%    01/31/18  jv  Wrote it.
%    03/31/18  dhb  Add alternateDictionaryFunc key/value pair.

directionNames = OLGetDictionaryEntryNames('Direction',varargin{:});
end