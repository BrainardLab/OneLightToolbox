function OLMeasureReferenceSettings
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
% 8/18/13  ms   Adapted from OLCalibrate

global g_useIOPort;
g_useIOPort = 1;

% We never use the Omni.
cal.describe.useOmni = 0;
meterToggle = [1 cal.describe.useOmni];
od = [];

% Parameters
theBandwidths = 2.^(0:7);
nBandwidths = length(theBandwidths);

try
    % Ask which type of calibration we're doing.
    calTypes = enumeration('OLCalibrationTypes');
    while true
        fprintf('- Available calibration types:\n');
        
        for i = 1:length(calTypes)
            fprintf('%d: %s\n', i, calTypes(i).char);
        end
        
        x = GetInput('Selection', 'number', 1);
        if x >= 1 && x <= length(calTypes)
            break;
        end
    end
    selectedCalType = calTypes(x);
    
    % Ask for email recipient
    emailRecipient = GetWithDefault('Send status email to','brainard@psych.upenn.edu');
    
    % Ask which PR-6xx radiometer to use
    % Some parameters are radiometer dependent.
    meterType = GetWithDefault('Enter PR-6XX radiometer type','PR-670');
    switch (meterType)
        case 'PR-650',
            meterType = 1;
            S = [380 4 101];
            nAverage = 1;
            cal.describe.gammaNumberWlUseIndices = 10;
        case 'PR-670',
            whichMeter = 'PR-670';
            meterType = 5;
            S = [380 2 201];
            nAverage = 3;
            cal.describe.gammaNumberWlUseIndices = 5;
            
        otherwise,
            error('Unknown meter type');
    end
    
    % Open up the radiometer.
    CMCheckInit(meterType);
    
    % Open the OneLight device.
    ol = OneLight;
    
    % Allocate memory for the starts.
    starts = zeros(1, ol.NumCols);
    
    % Find the center index. This is half of all columns, and we will go +
    % and - from this center index.
    theCenterIndex = ol.NumCols/2;
    
    % Ask for a keypress to continue.
    input('*** Press return to pause 5s then continue with the calibration***\n');
    pause(5);
    tic;
    
    for i = 1:nBandwidths
        stops = zeros(1, ol.NumCols);
        if theBandwidths(i) == 1
            stops(theCenterIndex) = ol.NumRows - 1;
        else
            stops(theCenterIndex-theBandwidths(i)/2:theCenterIndex+theBandwidths(i)/2) = ol.NumRows - 1;
        end

        fprintf('                                 %i/%i\n', i, nBandwidths);
        measTemp = OLTakeMeasurement(ol, od, starts, stops, S, meterToggle, meterType, nAverage);
        cal.raw.bandwidthMeas(:,i) = measTemp.pr650.spectrum;
    end
    fprintf('Done\n');
    
    % Store some measurement parameters.
    cal.describe.S = S;
    cal.describe.meterType = meterType;
    cal.describe.durationMinutes = toc / 60;
    cal.describe.date = datestr(now);
    cal.describe.numRowMirrors = ol.NumRows;
    cal.describe.numColMirrors = ol.NumCols;
    cal.describe.nBandwidths = nBandwidths;
    cal.describe.theBandwidths = theBandwidths;
    
    % Store the type of calibration.
    cal.describe.calType = selectedCalType;
    
    % Save the calibration file.
    oneLightCalSubdir = 'OneLight';
    SaveCalFile(cal, fullfile(oneLightCalSubdir,selectedCalType.CalFileName));
    
    fprintf('\n*** Calibration Complete ***\n\n');
    
    SendEmail(emailRecipient, 'OneLight Calibration Complete', ...
        'Finished!');
catch e
    SendEmail(emailRecipient, 'OneLight Calibration Failed', ...
        ['Calibration failed with the following error' 10 e.message]);
    
    rethrow(e);
    keyboard
end


