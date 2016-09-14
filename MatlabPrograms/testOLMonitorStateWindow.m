% Demos how to embed a call to OLMonitorStateWindow within an OL experiment
%
% 9/12/16   npc     Wrote it.
%

function testOLMonitorStateWindow

    % ----------- GLUE CODE - THIS IS DONE BY THE EXPERIMENTAL PROGRAM ----
    cal = OLGetCalibrationStructure;
    nAverage = 1; meterToggle = [1 0]; od = [];

    % Open up the OneLight
    ol = OneLight;
    
    % Generate the spectroradiometer object
    spectroRadiometerOBJ = generateSpectroRadiometerOBJ();
    % ----------- END OF GLUE CODE  ---------------------------------------

    
    % ------ CODE TO EMBED TO EXPERIMENTAL PROGRAM (BEFORE DATA COLLECTION BEGINS) --------------
    % Collect state data until the user closes the monitoring window
    saveFileName = sprintf('BoxD_MonitoredStateData_%s', strrep(strrep(strrep(datestr(now), '-', '_'), ' ', '_'), ':', '_'));
    monitoredStateData = OLMonitorStateWindow(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);

    % Save the monitoring data (optional)
    fprintf('Saving data to ''%s.mat''.\n', saveFileName);
    save(saveFileName, 'monitoredStateData');
    
    % Visualize monitoredData (optional)
    OLVisualizeMonitoredData(monitoredStateData);
    
    % ------- END OF CODE TO EMBED TO EXPERIMENTAL PROGRAM  -------------------------------------

    % Continue with experiment
    
    % ----------- GLUE CODE - THIS SHOULD BE DONE BY THE EXPERIMENTAL PROGRAM ----
    spectroRadiometerOBJ.shutDown();
    % ----------- END OF GLUE CODE ----------------------------------------
end

% --------------- GLUE CODE -----------------------------------------------
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

