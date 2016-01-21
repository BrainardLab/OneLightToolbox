function OLMeasureReferenceSettings(selectedCalType, bulbNumber, emailRecipient, meterType, initMeter, closeMeter)
% OLMeasureReferenceSettings - Takes full-on, half-on and off
% measurements
%
% Syntax:
% OLMeasureReferenceSettings
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
% initMeter (bool) - Initializes meters.
% closeMeter (bool) - closes meters.
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
nMeasurements = 5;

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
    
    % Take dark measurements.
    fprintf('- Measuring background...');
    starts = (ol.NumRows+1)*ones(1, ol.NumCols);
    stops = zeros(1, ol.NumCols);
    for i = 1:nMeasurements
        fprintf('                                 %i/%i\n', i, nMeasurements);
        measTemp = OLTakeMeasurement(ol, od, starts, stops, S, meterToggle, meterType, nAverage);
        cal.raw.darkMeas(:,i) = measTemp.pr650.spectrum;
        if (meterToggle(2))
            cal.raw.omniDriver.darkMeas(:,i) = measTemp.omni.spectrum;
        else
            cal.raw.omniDriver.darkMeas(:,i) = NaN;
        end
    end
    fprintf('Done\n');
    
    % Take half on measurements.
    fprintf('- Taking half on measurements...');
    starts = zeros(1, ol.NumCols);
    stops = round(ones(1, ol.NumCols) * (ol.NumRows - 1) * 0.5);
    for i = 1:nMeasurements
        fprintf('                                 %i/%i\n', i, nMeasurements);
        measTemp = OLTakeMeasurement(ol, od, starts, stops, S, meterToggle, meterType, nAverage);
        cal.raw.halfOnMeas(:,i) = measTemp.pr650.spectrum;
        if (meterToggle(2))
            cal.raw.omniDriver.halfOnMeas(:,i) = measTemp.omni.spectrum;
        else
            cal.raw.omniDriver.halfOnMeas(:,i) = NaN;
        end
    end
    fprintf('Done\n');
    
    % Take full on measurements.
    fprintf('- Taking full on measurements...');
    starts = zeros(1, ol.NumCols);
    stops = round(ones(1, ol.NumCols) * (ol.NumRows - 1) * 1);
    for i = 1:nMeasurements
        fprintf('                                 %i/%i\n', i, nMeasurements);
        measTemp = OLTakeMeasurement(ol, od, starts, stops, S, meterToggle, meterType, nAverage);
        cal.raw.fullOnMeas(:,i) = measTemp.pr650.spectrum;
        if (meterToggle(2))
            cal.raw.omniDriver.fullOnMeas(:,i) = measTemp.omni.spectrum;
        else
            cal.raw.omniDriver.fullOnMeas(:,i) = NaN;
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
    SaveCalFile(cal, fullfile(oneLightCalSubdir,[selectedCalType.CalFileName '_Reference_Bulb' num2str(cal.describe.bulbNumber,'%03d')]));
    
    fprintf('\n*** Measurements Complete ***\n\n');
    
    if closeMeter
        % Close PR-670 and Omni
        CMClose(meterType);
    end
    
    SendEmail(emailRecipient, '[OL] Reference setting measurements completed', ...
        'Finished!');
catch e
    SendEmail(emailRecipient, '[OL] Reference setting measurements failed', ...
        ['Measurements failed with the following error' 10 e.message]);
    
    rethrow(e);
    keyboard
end


