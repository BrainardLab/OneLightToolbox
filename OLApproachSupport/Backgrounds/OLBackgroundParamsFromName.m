function backgroundParams = OLBackgroundParamsFromName(backgroundName,varargin)
% Returns parameters stored in under name in dictionary
%
% Syntax:
%   backgroundParams = OLBackgroundParamsFromName(backgroundName)
%
% Description:
%    For parameterized backgrounds that are stored under their name in
%    OLBackgroundParamsDictionary, this function will return the
%    parameters.
%
% Inputs:
%    backgroundName   - String name of a set of parameters for a background
%                       stored in OLBackgroundNominalStructParamsDictionary
%
% Outputs:
%    backgroundParams - OLBackgroundParams object defining the parameters
%                       for a type of background.
%
% Optional key/value pairs:
%    'alternateDictionaryFunc' - String with name of alternate dictionary
%                       function to call. This must be a function on the
%                       path. Default of empty results in using this
%                       function.
%
% Notes:
%    None.
%
% See also:
%    OLBackgroundParamsDictionary, OLBackgroundParams,
%    OLBackgroundNominalPrimaryFromParams, OLBackgroundParamsValidate

% History:
%    01/31/18  jv  Wrote it.
%    03/31/18  dhb  Add alternateDictionaryFunc key/value pair.

backgroundParamsDictionary = OLBackgroundParamsDictionary(varargin{:});
backgroundParams = backgroundParamsDictionary(backgroundName);
end