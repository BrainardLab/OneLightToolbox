function OLMeasureSpecificSettings(selectedCalType, bulbNumber, emailRecipient, meterType, initMeter, closeMeter)
% OLMeasureSpecificSettings - Takes full-on, half-on and off
% measurements
%
% Syntax:
% OLMeasureSpecificSettings
%
% Description:
% Calibrates a OneLight device using a PR-650 radiometer and the OneLight
% supplied spectrometer (OmniDriver).  The goal is to bypass the
% several pieces of hardware and mathematics used by the software supplied
% by the OneLight people.
%
% Input:
% selectedCalType (enumeration) - Calibration type to be used.
% bulbNumber (integer) - Bulb number to be used.
% emailRecipient (string) - Email address to receive notifications
% meterType (string) - Meter type to use.
%
% 8/18/13  ms   Adapted from OLCalibrate
% 1/21/14  ms   Cleaned up, made us of varargin to allow for opts.


cal.describe.bulbNumber = bulbNumber;

% Set up IO port
global g_useIOPort;
g_useIOPort = 1;

% We never use the Omni.
cal.describe.useOmni = 0;

% Connect to the OceanOptics spectrometer.
if (cal.describe.useOmni)
    try
        od = OmniDriver;
        od.Debug = true;
        % Turn on some averaging and smoothing for the spectrum acquisition.
        od.ScansToAverage = 10;
        od.BoxcarWidth = 2;
        
        % Make sure electrical dark correction is enabled.
        od.CorrectForElectricalDark = true;
    catch
        cal.describe.useOmni = 0;
        od = [];
    end
else
    od = [];
end
meterToggle = [1 cal.describe.useOmni];

% How many measurements to be taken
nMeasurements = 1;

% Load in a cache file that we want to check, we're hard coding it in here.
load('/Users/Shared/Matlab/Experiments/OneLight/OLPupilDiameter/code/cache/SSPM-SIsolatingRobust.mat')
settings(:, 1) = EyeTrackerLongCableEyePiece2{end}.settings(:, 1);
settings(:, 2) = EyeTrackerLongCableEyePiece2{end}.settings(:, 51);

load('/Users/Shared/Matlab/Experiments/OneLight/OLPupilDiameter/code/cache/SSPM-MelanopsinDirected.mat')
settings(:, 3) = EyeTrackerLongCableEyePiece2{end}.settings(:, 51);

for i = 1:3
    [starts(:, i), stops(:, i)] = OLSettingsToStartsStops(EyeTrackerLongCableEyePiece2{end}.cal, EyeTrackerLongCableEyePiece2{end}.cal.computed.D*settings(:, i));
end;

try
    % Set up radiometers
    % Some parameters are radiometer dependent.
    switch (meterType)
        case 'PR-650',
            meterType = 1;
            S = [380 4 101];
            nAverage = 1;
        case 'PR-670',
            whichMeter = 'PR-670';
            meterType = 5;
            S = [380 2 201];
            nAverage = 1;
        otherwise,
            error('Unknown meter type');
    end
    
    if initMeter
        % Open up the radiometer.
        CMCheckInit(meterType);
    end
    
    % Open the OneLight device.
    ol = OneLight;
    
    % Ask for a keypress to continue.
    %input('*** Press return to pause 5s then continue with the calibration***\n');
    pause(5);
    tic;
    
    % If using omni, find integration time
    % Find and set the optimal integration time.  Subtract off a couple
    % thousand microseconds just to give it a conservative value.
    %
    % Depending on cables and light levels, the args to od.findIntegrationTime may
    % need to be fussed with a little.
    ol.setAll(true); WaitSecs(0.2);
    if (cal.describe.useOmni)
        od.IntegrationTime = od.findIntegrationTime(100, 2, 1000);
        od.IntegrationTime = round(0.95*od.IntegrationTime);
        fprintf('- Using integration time of %d microseconds.\n', od.IntegrationTime);
    end
    ol.setAll(false); WaitSecs(0.2);
    
    % Record now
    cal.describe.date = datestr(now);
    cal.describe.startMeasTime = GetSecs;
    
    % Take full on measurements.
    fprintf('- Taking specific measurements...');
    for n = 1:size(settings, 2)
        fprintf('                                 %i/%i\n', n, size(settings, 2));
        measTemp = OLTakeMeasurement(ol, od, starts(:, n), stops(:, n), S, meterToggle, meterType, nAverage);
        cal.raw.meas(:,n) = measTemp.pr650.spectrum;
        if (meterToggle(2))
            cal.raw.omniDriver.meas(:,n) = measTemp.omni.spectrum;
        else
            cal.raw.omniDriver.meas(:,n) = NaN;
        end
    end
    fprintf('Done\n');
    
    % Store some measurement parameters.
    cal.describe.S = S;
    cal.describe.meterType = meterType;
    cal.describe.durationMinutes = toc / 60;
    cal.describe.numRowMirrors = ol.NumRows;
    cal.describe.numColMirrors = ol.NumCols;
    cal.describe.finishMeasTime = GetSecs;
    
    % Store the type of calibration.
    cal.describe.calType = selectedCalType;
    
    % Save the calibration file.
    oneLightCalSubdir = 'OneLight';
    SaveCalFile(cal, fullfile(oneLightCalSubdir,[selectedCalType.CalFileName '_SpecificSettings_Bulb' num2str(cal.describe.bulbNumber,'%03d')]));
    
    fprintf('\n*** Measurements Complete ***\n\n');
    
    if closeMeter
        % Close PR-670 and Omni
        CMClose(meterType);
    end
    
    SendEmail(emailRecipient, '[OL] Specific setting measurements completed', ...
        'Finished!');
catch e
    SendEmail(emailRecipient, '[OL] Specific setting measurements failed', ...
        ['Measurements failed with the following error' 10 e.message]);
    
    rethrow(e);
    keyboard
end


