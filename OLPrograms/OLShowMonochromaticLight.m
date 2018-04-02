% OLMonochromaticLight.m
% 
% Shows a monochromatic nm light.

% Get the calibration structure
cal = OLGetCalibrationStructure;

% Define the spd
wl1 = GetWithDefault('>>> Peak wavelength in nm?', 630);
fullWidthHalfMax = 15;
lambda = 0.001;
spd1 = OLMakeMonochromaticSpd(cal, wl1, fullWidthHalfMax);
[maxSpd1, scaleFactor1] = OLFindMaxSpectrum(cal, spd1, 'lambda', lambda);

% Find the primaries for that
primary1 = OLSpdToPrimary(cal, maxSpd1, lambda);
settings1 = OLPrimaryToSettings(cal, primary1);
[starts1, stops1] = OLSettingsToStartsStops(cal, settings1);

% Open the OneLight
ol = OneLight;
ol.setMirrors(starts1, stops1);
