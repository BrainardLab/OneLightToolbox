function testOLVisualizeMonitoredData

    % Load calibration file that we will u
    cal = OLGetCalibrationStructure;
    
    dataFile = selectMonitoredStateDatafile(cal);
    load(dataFile, 'monitoredStateData');
    
    % Plot relative to first combSPD of the monitoredStateDra
    % OLVisualizeMonitoredData(monitoredStateData);
    
    % Plot relative to last combSPD of the cal
    OLVisualizeMonitoredData(monitoredStateData, cal);
    
end


function dataFile = selectMonitoredStateDatafile(cal)
    d = strrep(cal.describe.date(1:11), ' ', '-');
    cal.describe.date(1:11) = d;
    cal.describe.date(12) = '_';
    outDir = fullfile(getpref('OneLight', 'OneLightCalData'), 'MonitoredStateData', char(cal.describe.calType), strrep(cal.describe.date, ':', '_'));
    outDir = uigetdir(outDir);
    dataFile = fullfile(outDir, 'MonitoredStateData');
end
