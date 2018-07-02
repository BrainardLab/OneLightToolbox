% Print OneLight and room current temperature
%
% 7/2/18  npc    Wrote it.
function OLTemperature

    % Open Labjack
    [takeTemperatureMeasurements, quitNow, theLJdev] = OLCalibrator.OpenLabJackTemperatureProbe(true);
    if (quitNow)
       return;
    end
    
    % Take measurement
    [status, temperatureValue] = theLJdev.measure();
    
    % Print result
    fprintf('\nAt %s the OneLight/Room temperatures (degC) were measured to be: %2.1f and %2.1f, respectively.\n', ...
        datetime('now'), temperatureValue(1), temperatureValue(2));
    
    % Close Labjack
    if (takeTemperatureMeasurements)
        theLJdev.close();
    end 
end