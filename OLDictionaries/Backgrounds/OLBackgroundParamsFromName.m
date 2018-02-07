function backgroundParams = OLBackgroundParamsFromName(backgroundName)
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
%    None.
%
% Notes:
%    None.
%
% See also:
%    OLBackgroundParamsDictionary, OLBackgroundParams,
%    OLBackgroundNominalPrimaryFromParams, OLBackgroundParamsValidate

% History:
%    01/31/18  jv  Wrote it.

backgroundParamsDictionary = OLBackgroundParamsDictionary;
backgroundParams = backgroundParamsDictionary(backgroundName);
end