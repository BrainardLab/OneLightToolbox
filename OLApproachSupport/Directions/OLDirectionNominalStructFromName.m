function directionStruct = OLDirectionNominalStructFromName(directionName,calibration,varargin)
% Generate a parameterized direction from the given parameters
%
% Syntax:
%   directionStruct = OLDirectionNominalFromStruct(directionParameters, calibration)
%   directionStruct = OLDirectionNominalFromStruct(directionParameters, calibration, backgroundPrimary)
%   directionStruct = OLDirectionNominalFromStruct(..., 'verbose', true)
%
% Description:
%    For parameterized directions that are stored under their name in
%    OLDirectionParamsDictionary, this function will generate the
%    actual direction from parameters.
%
%    Pass-through function, does not check input but passes it on to
%    OLDirectionStructFromParams.
%
% Inputs:
%    directionName     - String name of a set of parameters for a direction
%                        stored in OLDirectionParamsDictionary.
%    calibration       - OneLight calibration struct
%    backgroundPrimary - [OPTIONAL] the primary values for the background.
%                        If not provided, will use background parameters
%                        specified in directionParams of dictionary entry
%
% Outputs:
%    directionStruct   - a 1x60 struct array (one struct per observer age
%                        1:60 yrs), with the following fields:
%                          * backgroundPrimary   : the primary values for
%                                                 the background.
%                          * differentialPositive: the difference in primary
%                                                 values to be added to the
%                                                 background primary to
%                                                 create the positive
%                                                 direction
%                          * differentialNegative: the difference in primary
%                                                 values to be added to the
%                                                 background primary to
%                                                 create the negative
%                                                 direction
%                          * describe            : Any additional
%                                                 (meta)-information that
%                                                 might be stored
%
% Optional key/value pairs:
%    observerAge       - (vector of) observer age(s) to generate direction
%                        struct for. Output directionStruct will be of 
%                        length(observerAge). Default is 1:60.
%    verbose           - boolean flag to print output. Default false.
%
% Notes:
%    None.
%
% See also:
%    OLDirectionNominalStructFromParams, OLDirectionParamsDictionary,
%    OLGetDirectionNames

% History:
%    01/31/18  jv  wrote it
directionParams = OLDirectionParamsFromName(directionName);
directionStruct = OLDirectionNominalStructFromParams(directionParams, calibration, varargin{:});
end