function OLSpdToPrimaryTest
% OLSpdToPrimaryTest
%
% Tests OLSpdToPrimary and OLPrimaryToSpd.
%
% This could be expanded to test differential mode and to include a
% spectrum that requires smoothing to come back sensibly.
%
% 6/2/17  dhb  Wrote this in order to start cleaning.

%% Clear
clear; close all;

%% Load a test OL calibration file
theCalType = 'BoxDRandomizedLongCableAStubby1_ND02';
cal = OLGetCalibrationStructure('CalibrationType','BoxDRandomizedLongCableAStubby1_ND02','CalibrationDate','latest');

%% Let's generate a spectrum to try to find the primaries for
%
% The function hard coded below returns some primaries as a starting point.
% This could be expanded to take an argument and to return a wider range of primaries for
% a more extensive test.  
primaryTarget = GenerateTestPrimary;
spdTargetRaw = OLPrimaryToSpd(cal,primaryTarget);

% Add a little noise to the target spectrum, just so it isn't so smooth.
fractionNoise = 0.01;
spdTarget = spdTargetRaw + normrnd(zeros(size(spdTargetRaw)),fractionNoise*max(spdTargetRaw));

%% Plot of the target
theFigure = figure; clf; hold on;
plot(SToWls(cal.describe.S),spdTarget,'k','LineWidth',4);

%% Let's try to find good primaries with default smoothness
primaryFound1 = OLSpdToPrimary(cal,spdTarget);
spdPredicted1 = OLPrimaryToSpd(cal,primaryFound1);
plot(SToWls(cal.describe.S),spdPredicted1,'r','LineWidth',2);

%% Let's try to find good primaries with less smoothing
primaryFound2 = OLSpdToPrimary(cal,spdTarget,'lambda',0.05);
spdPredicted2 = OLPrimaryToSpd(cal,primaryFound2);
plot(SToWls(cal.describe.S),spdPredicted2,'g','LineWidth',2);

%% And very little smoothing
primaryFound3 = OLSpdToPrimary(cal,spdTarget,'lambda',0.001);
spdPredicted3 = OLPrimaryToSpd(cal,primaryFound3);
plot(SToWls(cal.describe.S),spdPredicted3,'c','LineWidth',2);

%% Make sure OLSpdToSettings and OLSettingsToStartsStops don't crash
[settingsTest, primariesTest, spdsPredictedTest] = OLSpdToSettings(cal,[spdTargetRaw spdTarget]);
[startsTest,stopsTest] = OLSettingsToStartsStops(cal,settingsTest);
if (any(primariesTest(:,2) ~= primaryFound1))
    error('Inconsistency in primary computations');
end
if (any(spdsPredictedTest(:,2) ~= spdPredicted1))
    error('Inconsistency in spd predictions');
end
    

end

% Generate some primaries that are probably within gamut
function primary = GenerateTestPrimary

primary = [
      0.39493
      0.39422
       0.3926
      0.38982
      0.38572
      0.38014
      0.37313
      0.36494
      0.35574
      0.34566
      0.33491
      0.32375
      0.31237
      0.30094
      0.28962
      0.27863
      0.26813
      0.25822
      0.24897
       0.2406
      0.23329
      0.22722
      0.22249
      0.21913
      0.21716
      0.21651
      0.21707
       0.2188
      0.22161
      0.22536
      0.22986
        0.235
      0.24071
       0.2469
      0.25347
      0.26028
      0.26718
      0.27405
      0.28085
      0.28751
      0.29395
      0.30008
      0.30582
      0.31115
      0.31616
      0.32084
      0.32513
      0.32893
      0.33213
      0.33474
      0.33678
      0.33835
      0.33942
      0.33995];
end