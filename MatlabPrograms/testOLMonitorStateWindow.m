function testOLMonitorStateWindow

    % ----------- GLUE CODE - THIS IS DONE BY THE EXPERIMENTAL PROGRAM ----
    cal = OLGetCalibrationStructure;
    nAverage = 1; meterToggle = [1 0]; od = [];

    % Open up the OneLight
    ol = OneLight;
    
    % Generate the spectroradiometer object
    spectroRadiometerOBJ = generateSpectroRadiometerOBJ();
    % ----------- END OF GLUE CODE  ----

    
    % -------------- CODE TO ADD TO EXPERIMENTAL PROGRAM (BEFORE DATA COLLECTION BEGINS) ----------------------------
    % Collect state data until the user closes the monitoring window
    [hMonitoDataWindow, monitoredData] = OLMonitorStateWindow(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
    uiwait(hMonitoDataWindow);

    fprintf('Saving data \n');
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

