% Demos how to embed a call to OLMonitorStateWindow within an OL experiment
%
% 9/12/16   npc     Wrote it.
% 9/29/16   npc     Optionally record temperature
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
takeTemperatureMeasurements = GetWithDefault('Take Temperature Measurements ?', false);
if (takeTemperatureMeasurements ~= true)
    takeTemperatureMeasurements = false;
end
monitoredStateData = OLMonitorStateWindow(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, 'takeTemperatureMeasurements', takeTemperatureMeasurements);

% Save the monitored state data (optional)
outDir = fullfile(getpref('OneLight', 'OneLightCalData'), 'MonitoredStateData', char(cal.describe.calType), strrep(strrep(cal.describe.date, ' ', '_'), ':', '_'), datestr(now, 'mmddyy'));
if ~exist(outDir)
    mkdir(outDir);
end
fprintf('Saving data to ''%s.mat''.\n', fullfile(outDir, 'MonitoredStateData'));
save(fullfile(outDir, 'MonitoredStateData'), 'monitoredStateData');

% Visualize monitored state data (visualize data with respect the last combSpectra in the calfile)
OLVisualizeMonitoredData(monitoredStateData, cal);

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

