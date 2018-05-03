function OLShowDirection(direction, oneLight)
% Sends direction to oneLight
%
% Syntax:
%   OLShowPrimary(primary, calibration, oneLight)
%
% Description:
%    Converts an OLDirection object to mirror column starts and stops
%    (using stored calibration), and sends these starts-stops to the
%    OneLight.
%
% Inputs:
%    direction   - an OLDirection object
%    calibration - OneLight calibration struct
%    oneLight    - OneLight object
%
% Outputs:
%    None.
%
% Optional key/value pairs:
%    None.
%
% See also:
%    OLShowPrimary

% History:
%    05/03/18  jv  wrote it.

%% Input validation
parser = inputParser;
parser.addRequired('direction',@(x) isa(x,'OLDirection'));
parser.addRequired('oneLight',@(x) isa(x,'OneLight'));
parser.parse(direction, oneLight);

%% Show
OLShowPrimary(direction.differentialPrimaryValues, direction.calibration, oneLight);

end