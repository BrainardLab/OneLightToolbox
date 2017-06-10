% OLSpecifiedBackgroundCalTest

%% Clear
clear; close all;

%% Get a calibration structure to work with
if ~exist('cal', 'var');
    cal = OLGetCalibrationStructure; % 1/12: BoxDRandomizedLongCableAEyePiece2_ND06 @  25-Aug-2016 11:35:23`
end

%% Initialize that sucker with the background method
cal = OLInitCalBG(cal);

%% Get primary settings for the shift corrected specified background used in the calibration.
%
% This is the one that everything is referred to, and it should produce the
% specified background settings.
specifiedBackgroundSettingsInferred = OLPrimaryToSettings(cal, OLSpdToPrimary(cal, cal.computed.pr650MeanSpecifiedBackground));

%% Plot inferred settings and the actual settings used to produce the specfied background
figure; clf; hold on
plot(1:length(specifiedBackgroundSettingsInferred),specifiedBackgroundSettingsInferred,...
    'ro','MarkerSize',12,'MarkerFaceColor','r');
plot(1:length(cal.describe.specifiedBackgroundSettings),cal.describe.specifiedBackgroundSettings,...
    'bo','MarkerSize',10,'MarkerFaceColor','b');
ylim([0 1]);
xlabel('Effective Primary');
ylabel('Settings Value');
title('Inferred and actual background settings');