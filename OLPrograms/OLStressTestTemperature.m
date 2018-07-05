function OLStressTestTemperature(box)
% Stress-test OneLight while recording temperature

%% Open devices
% Open OneLight
oneLight = OneLight;

% Open temperature probe
temperatureProbe = LJTemperatureProbe();
temperatureProbe.open();

%% Open some file
bulbLogsDir = getpref('OneLightToolbox','BulbLogsDir');
filename = sprintf('TemperatureTest_Box%s_%s.csv',box,datestr(now,'YYYY-mm-DD-HH-MM-SS'));
fileID = fopen(fullfile(bulbLogsDir,filename),'a');

%% Loop
cleanupRoutine = onCleanup(@() cleanup(temperatureProbe, oneLight, fileID);
while true
    %% Cycle between all-on, all-off
    allOn = false;
    if ~allOn
        oneLight.setAll(true);
        allOn = true;
    else
        oneLight.setAll(false);
        allOn = false;
    end

    %% Measure temperature
    [~, temperature] = temperatureProbe.measure();

    %% Save measured temperature to some file
    onString = {'ALLON','ALLOFF'};
    fprintf(fileID,'%s,%s,%.2f,\n',datestr(now,'HH:MM:SS.FFF'),onString{allOn+1},temperature)

    %% Print measured temperature to console
    fprintf('\t%s\t%s\t%.2f\n',datestr(now,'HH:MM:SS.FFF'),onString{allOn+1},temperature)
end

end

function cleanup(temperatureProbe, oneLight, fileID)
    try fclose(fileID); end
    try temperatureProbe.close(); end
    try oneLight.close(); end
end