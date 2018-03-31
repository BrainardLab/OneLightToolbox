function backgroundNames = OLGetBackgroundNames(varargin)
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
%    'alternateDictionaryFunc' - String with name of alternate dictionary
%                      function to call. This must be a function on the
%                      path. Default of empty results in using this
%                      function.
%
% See also:
%    OLBackgroundParamsDictionary

% History:
%    01/31/18  jv  Wrote it.
%    03/31/18  dhb  Add alternateDictionaryFunc key/value pair.

backgroundNames = OLGetDictionaryEntryNames('Background',varargin{:});
end