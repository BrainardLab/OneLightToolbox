function backgroundPrimary = OLBackgroundNominalPrimaryFromName(backgroundName, calibration, varargin)
% Generate a parameterized nominal backgroundPrimary from the parameter name
%
% Syntax:
%   backgroundPrimary = OLBackgroundNominalPrimaryFromName(backgroundName)
%
% Description:
%    For parameterized backgrounds that are stored under their name in
%    OLBackgroundParamsDictionary, this function will pull out the
%    parameters and return the actual nominal backgroundPrimary.
%
% Inputs:
%    backgroundName    - String name of a set of parameters for a 
%                        background stored in 
%                        OLBackgroundNominalPrimaryParamsDictionary.
%    calibration       - OneLight calibration struct
%
% Outputs:
%    backgroundPrimary - column vector of primary values for the background
%
% Optional key/value pairs:
%    'verbose'         - boolean flag to print output. Default false.
%
% Notes:
%    None.
%
% See also:
%    OLBackgroundParamsDictionary,
%    OLBackgroundNominalPrimaryFromParams, OLBackgroundParamsDefaults,
%    OLBackgroundParamsValidate.

% History:
%    01/31/18  jv  Created as wrapper around
%                  OLBackgroundNominalPrimaryFromParams and
%                  OLBackgroundNominalPrimaryFromName.
backgroundParams = OLBackgroundParamsFromName(backgroundName);
backgroundPrimary = OLBackgroundNominalPrimaryFromParams(backgroundParams, calibration, varargin{:});
end