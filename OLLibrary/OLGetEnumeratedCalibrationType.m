function selectedCalType = OLGetEnumeratedCalibrationType
% selectedCalType = OLGetEnumeratedCalibrationType
%
% This function prompts the user for the calibration type to be used.
%
% Output:
%   selectedCalType - calibration type selected from enumeration.
%
% See also: OLGetAvailableCalibrationTypes, OLGetCalibrationStructure.

% 01/21/14  ms    Made as a function.
% 03/27/18  dhb   Get rid of enumerations.

% Enter calibration type
selectedCalType = GetWithDefault('Enter calibration type','BoxBRandomizedLongCableAEyePiece1');
