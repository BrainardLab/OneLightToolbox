function OLShowPrimary(primaryValues, calibration, oneLight)
% Sends primary to oneLight
%
% Syntax:
%   OLShowPrimary(primary, calibration, oneLight)
%
% Description:
%    Converts vector of primary values to mirror column starts and stops
%    (using calibration), and sends these starts-stops to the OneLight.
%
% Inputs:
%    primaryValues - numeric column vector (Px1) of weight on each device
%                    primary P, to be displayed on the OneLight.
%    calibration   - OneLight calibration struct
%    oneLight      - OneLight object
%
% Outputs:
%    None.
%
% Optional key/value pairs:
%    None.
%
% See also:
%    OneLight, OneLight.setMirrors, OLPrimaryToStartsStops 

% History:
%    04/30/18  jv  wrote it.

%% Input validation
parser = inputParser;
parser.addRequired('primaryValues',@isnumeric);
parser.addRequired('calibration',@isstruct);
parser.addRequired('oneLight',@(x) isa(x,'OneLight'));
parser.parse(primaryValues, calibration, oneLight);

%% Convert
[starts, stops] = OLPrimaryToStartsStops(primaryValues, calibration);

%% Show
oneLight.setMirrors(starts, stops);

end