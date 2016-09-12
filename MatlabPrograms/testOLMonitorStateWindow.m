function testOLMonitorStateWindow

   
    % Get the cal
    cal = OLGetCalibrationStructure;
    
    nAverage = 1;
    meterToggle = [1 cal.describe.useOmni];
    
    % Connect to the OceanOptics spectrometer.
    if (cal.describe.useOmni)
        od = OmniDriver;
        od.Debug = true;
        % Turn on some averaging and smoothing for the spectrum acquisition.
        od.ScansToAverage = 10;
        od.BoxcarWidth = 2;

        % Make sure electrical dark correction is enabled.
        od.CorrectForElectricalDark = true;

        % Set the OmniDriver integration time to match up with what's in the
        % calibration file.
        od.IntegrationTime = cal.describe.omniDriver.integrationTime;
    else
        od = [];
    end

    % Open up the OneLight
    ol = OneLight;
    
    % Generate the spectroradiometer object
    spectroRadiometerOBJ = generateSpectroRadiometerOBJ();
    
    
    % -------------- CODE TO ADD TO EXPERIMENTAL PROGRAM (BEFORE DATA COLLECTION BEGINS) ----------------------------

    % Collect state data until the user closes the monitoring window
    [hMonitoDataWindow, monitoredData] = OLMonitorStateWindow(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
    uiwait(hMonitoDataWindow);

    % Save the monitoring data
    save('WarmUpMonitoredData.mat', 'monitoredData');
    
    % ------------------------- END OF CODE TO ADD ------------------------
    
    
    % Continue with experiment
    spectroRadiometerOBJ.shutDown();
end


function spectroRadiometerOBJ = generateSpectroRadiometerOBJ()

    % Instantiate a PR670 object
    spectroRadiometerOBJ  = PR670dev(...
        'verbosity',        1, ...       % 1 -> minimum verbosity
        'devicePortString', [] ...       % empty -> automatic port detection)
        );

    % Set options Options available for PR670:
    spectroRadiometerOBJ.setOptions(...
        'verbosity',        1, ...
        'syncMode',         'OFF', ...      % choose from 'OFF', 'AUTO', [20 400];
        'cyclesToAverage',  1, ...          % choose any integer in range [1 99]
        'sensitivityMode',  'STANDARD', ... % choose between 'STANDARD' and 'EXTENDED'.  'STANDARD': (exposure range: 6 - 6,000 msec, 'EXTENDED': exposure range: 6 - 30,000 msec
        'exposureTime',     'ADAPTIVE', ... % choose between 'ADAPTIVE' (for adaptive exposure), or a value in the range [6 6000] for 'STANDARD' sensitivity mode, or a value in the range [6 30000] for the 'EXTENDED' sensitivity mode
        'apertureSize',     '1 DEG' ...   % choose between '1 DEG', '1/2 DEG', '1/4 DEG', '1/8 DEG'
        );
end

