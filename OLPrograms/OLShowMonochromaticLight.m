% OLMonochromaticLight.m
% 
% Shows a monochromatic nm light.

% Get the calibration structure
cal = OLGetCalibrationStructure;

% Define the spd
%
% If you use the demo cal structure and divide what comes
% back by three, experience says you'll get something in 
% gamut.  We used to have code that would help do that more
% automatically, but it seems to have stopped working and 
% needs attention.
wl1 = GetWithDefault('>>> Peak wavelength in nm?', 630);
fullWidthHalfMax = 20;
lambda = 0.001;
targetSpd = OLMakeMonochromaticSpd(cal, wl1, fullWidthHalfMax)/3;

% Find the primaries for that
primary1 = OLSpdToPrimary(cal, targetSpd, 'lambda', lambda);
predictedSpd = OLPrimaryToSpd(cal,primary1);

% Plot what we want and what we think we'll get
figure; hold on
plot(SToWls(cal.describe.S),targetSpd,'r');
plot(SToWls(cal.describe.S),predictedSpd,'b');

% OLFindMaxSpd has been modified.  You need to provide it with
% initial primaries that produce the target spd.  This should be
% easy to do here, by moving up the code below that finds primaries
% and then passing those to OLFindMaxSpd.  OLFindMaxSpd will then
% return both the maximized spd and the maximized primaries.
%
% error('Need to update call to OLFindMaxSpd. See comments in source here')

% Gamma correct
settings1 = OLPrimaryToSettings(cal, primary1);
[starts1, stops1] = OLSettingsToStartsStops(cal, settings1);

% Open the OneLight
ol = OneLight;
ol.setMirrors(starts1, stops1);
