function lightlevelScalar = OLMeasureLightlevelScalar(oneLight, calibration, radiometer)
% Measure scalar to bring measured lightlevel into calibration range
%
% Syntax:
%    lightlevelScalar = OLMeasureLightlevelScalar(oneLight, calibration, radiometer);
%
% Description:
%    Over time, OneLights lose overall light output, meaning that measuring
%    an SPD might differ from the predicted SPD by an overall light level
%    reduction. To correct for such a light level drop, we bring measured
%    SPDs back into the light level calibration range, by multiplying with
%    a light level scaling factor. 
%
%    This function measures a full on SPD, compares it to prediction from
%    the calibration, and returns a single scaling factor. Multiplying a
%    measured SPD by this scaling factor, brings the SPD back into the
%    range of the calibration, i.e., as if we hadn't lost overall light
%    output.
%
% Inputs:
%    oneLight         - OneLight object to control a OneLight device. If
%                       the oneLight object is simulated, the returned SPD
%                       is predicted from just the calibration information.
%    calibration      - struct containing calibration information for 
%                       oneLight
%    radiometer       - Radiometer object to control a spectroradiometer. 
%                       Can be passed empty when simulating
%
% Outputs:
%    lightlevelScalar - numeric scalar, factor by which to increase
%                       measured SPDs to bring them into same regime as
%                       calibration.
% 
% Optional keyword arguments:
%    None.
%
% See also:
%    OLPrimaryToSpd, OLMeasurePrimaryValues
%

% History:
%    08/28/18  jv   wrote OLGetLightlevelScalar

% Define full on primaries
fullOnPrimaries = ones(calibration.describe.numWavelengthBands,1);

% Full On SPD according to calibration
predictedFullOnSPD = OLPrimaryToSpd(calibration, fullOnPrimaries);

% Full on SPD, actually measured
measuredFullOnSPD = OLMeasurePrimaryValues(fullOnPrimaries, calibration, oneLight, radiometer);

% Scale factor to go from measured to calibration
lightlevelScalar = measuredFullOnSPD \ predictedFullOnSPD;
end