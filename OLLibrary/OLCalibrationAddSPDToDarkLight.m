function calibration = OLCalibrationAddSPDToDarkLight(calibration,SPD)
% Add an SPD the dark light stored in an OL calibration structure
%
% Syntax:
%   calibration = OLCalibrationAddSPDToDarkLight(calibration,SPD)
%
% Description:
%    Adds the given SPD to the dark light already stored in the calibration
%    (calibration.computed.pr650MeanDark). Used when admixing light to the
%    OneLight output, e.g. through a beamsplitter setup. 
%
%    If the given SPD contains negative values, these are truncated to 0,
%    under the assumption that whatever light is admixed in obeys physics.
%
% Input:
%    calibration - struct containing calibration information for a OneLight
%                  device (see OLCalibrateOOC)
%    SPD         - SPD to be added to the dark level. Must be in the same
%                  wavelength specification as the calibration. Any
%                  negative values will be truncated to 0.
% Output:
%    calibration - struct containing calibration information with updated
%                  dark level.
%
% Optional keyword arguments:
%    None.

% History:
%    2018-09-08  jv   wrote UpdateOLCalibrationWithProjectorSPD in
%                     OLApproach_Psychophysics
%    2018-09-09  jv   truncate negative values in output
%    2018-10-07  jv   extracted OLCalibrationAddSPDToDarkLight
%                     truncate negative values in input
%                     wrote testOLCalibrationAddSPDToDarkLight unittests

%% Input validation
parser = inputParser;
parser.addRequired('calibration',@(x) isstruct(x) && isfield(x,'computed') && isfield(x.computed,'pr650MeanDark'));
parser.parse(calibration);
parser.addRequired('SPD',@(x)validateattributes(x,{'numeric'},{'column','size',size(calibration.computed.pr650MeanDark),'nonempty','nonnan'}));
parser.parse(calibration,SPD);

%% Truncate
SPD(SPD < 0) = 0;

%% Add to calibration
calibration.computed.pr650MeanDark = calibration.computed.pr650MeanDark + SPD;
end