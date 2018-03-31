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
%    'alternateDictionaryFunc' - String with name of alternate dictionary
%                        function to call. This must be a function on the
%                        path. Default of empty results in using this
%                        function.
%
% Notes:
%    None.
%
% See also:
%    OLBackgroundParamsDictionary, OLBackgroundParams,
%    OLBackgroundNominalPrimaryFromParams, OLBackgroundParamsValidate

% History:
%    01/31/18  jv  Created as wrapper around
%                  OLBackgroundNominalPrimaryFromParams and
%                  OLBackgroundNominalPrimaryFromName.
%    03/31/18  dhb Add alternateDictionaryFunc key/value pair.

backgroundParams = OLBackgroundParamsFromName(backgroundName,varargin{:});
backgroundPrimary = OLBackgroundNominalPrimaryFromParams(backgroundParams, calibration, varargin{:});
end