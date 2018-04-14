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

% OLFindMaxSpd has been modified.  You need to provide it with
% initial primaries that produce the target spd.  This should be
% easy to do here, by moving up the code below that finds primaries
% and then passing those to OLFindMaxSpd.  OLFindMaxSpd will then
% return both the maximized spd and the maximized primaries.
error('Need to update call to OLFindMaxSpd. See comments in source here')
[maxSpd1, scaleFactor1] = OLFindMaxSpd(cal, spd1, 'lambda', lambda);

% Find the primaries for that
primary1 = OLSpdToPrimary(cal, maxSpd1, 'lambda', lambda);
settings1 = OLPrimaryToSettings(cal, primary1);
[starts1, stops1] = OLSettingsToStartsStops(cal, settings1);

% Open the OneLight
ol = OneLight;
ol.setMirrors(starts1, stops1);
