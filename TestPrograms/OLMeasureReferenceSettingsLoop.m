% OLMeasureReferenceSettingsLoop
%
% Repeat OLMeasureReferenceSettings to take repeated reference
% measurements. After a wait time defined below, the measurements are
% repeated. To stop the measurements, simply break by Ctrl+C.
%
% 1/21/14   ms      Wrote it.

% Define the wait time, in seconds, between measurements
waitTimeBetweenMeasurements = 60;

% Set a few parameters once, then re-use them in each iteration.
selectedCalType = OLGetEnumeratedCalibrationType;
bulbNumber = GetWithDefault('Enter bulb number',1);
emailRecipient = GetWithDefault('Enter email address for done notification', 'mspits@sas.upenn.edu');
meterType = GetWithDefault('Enter PR-6XX radiometer type','PR-670');

% Measure the reference settings for the first time
OLMeasureReferenceSettings(selectedCalType, bulbNumber, emailRecipient, meterType, true, false);
cacheDir = '/Users/Shared/Matlab/Experiments/OneLight/OLFlickerSensitivity/code/cache/stimuli';
OLValidateCacheFile(fullfile(cacheDir, ['Cache-MelanopsinDirected.mat']), 'mspits@sas.upenn.edu', 'PR-670', ...
    0, 0, 'FullOnMeas', true, 'ReducedPowerLevels', true, 'selectedCalType', 'LongCableAEyePiece1', 'CALCULATE_SPLATTER', true);

% Measure a specific set of settings also
%OLMeasureSpecificSettings(selectedCalType, bulbNumber, emailRecipient, meterType, false, false);

DONE = false;
while (~DONE)
    if CharAvail
        char = GetChar;
        switch (char)
            case 'q'
                DONE = true;
        end
    end
    % Do the work.
    OLMeasureReferenceSettings(selectedCalType, bulbNumber, emailRecipient, meterType, false, false);
    %OLMeasureSpecificSettings(selectedCalType, bulbNumber, emailRecipient, meterType, false, false);
    
    %% Validate
    cacheDir = '/Users/Shared/Matlab/Experiments/OneLight/OLFlickerSensitivity/code/cache/stimuli';
    theDirections = {'MelanopsinDirected', 'SDirected', 'Isochromatic', 'LMDirected', 'LMinusMDirected', 'MelanopsinDirectedRobust', 'RodDirected', 'OmniSilent'};
    theOnVector = [0 0 0 0 0 0 0 0];
    theOffVector = [0 0 0 0 0 0 0 0];
    for d = 1:length(theDirections)
        OLValidateCacheFile(fullfile(cacheDir, ['Cache-' theDirections{d} '.mat']), 'mspits@sas.upenn.edu', 'PR-670', ...
            theOnVector(d), theOffVector(d), 'FullOnMeas', true, 'ReducedPowerLevels', true, 'selectedCalType', 'LongCableAEyePiece1', 'CALCULATE_SPLATTER', true);
    end
    
    close all;
    % Wait for specified delay period.
    WaitSecs(waitTimeBetweenMeasurements);
end

CMClose(meterType);