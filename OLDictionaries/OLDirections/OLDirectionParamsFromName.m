function directionParams = OLDirectionParamsFromName(directionName)
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
%    directionParams - struct defining the parameters for a type of
%                       direction. Can be generated using
%                       OLDirectionParamsDefaults
%
% Optional key/value pairs:
%    None.
%
% Notes:
%    None.
%
% See also:
%    OLDirectionParamsDictionary,
%    OLDirectionNominalStructFromParams, OLDirectionParamsDefaults,
%    OLDirectionParamsValidate.

% History:
%    01/31/18  jv  Wrote it.
directionParamsDictionary = OLDirectionParamsDictionary;
directionParams = directionParamsDictionary(directionName);
end