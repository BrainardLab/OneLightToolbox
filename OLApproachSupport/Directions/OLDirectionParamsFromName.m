function directionParams = OLDirectionParamsFromName(directionName,varargin)
% Returns parameters stored in under name in dictionary
%
% Syntax:
%   directionParameters = OLDirectionParamsFromName(directionName)
%
% Description:
%    For parameterized directions that are stored under their name in
%    OLDirectionParamsDictionary, this function will return the
%    parameters.
%
% Inputs:
%    directionName   - String name of a set of parameters for a direction
%                      stored in OLDirectionNominalStructParamsDictionary.
%
% Outputs:
%    directionParams - Struct defining the parameters for a type of
%                      direction. Can be generated using
%                      OLDirectionParamsDefaults
%
% Optional key/value pairs:
%    'alternateDictionaryFunc' - String with name of alternate dictionary
%                      function to call. This must be a function on the
%                      path. Default of empty string results in using the
%                      OneLightToolbox dictionary.
%
% Notes:
%    None.
%
% See also:
%    OLDirectionParamsDictionary.

% History:
%    01/31/18  jv   Wrote it.
%    03/31/18  dhb  Add alternateDictionaryFunc key/value pair.

directionParamsDictionary = OLDirectionParamsDictionary(varargin{:});
directionParams = directionParamsDictionary(directionName);
end