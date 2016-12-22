function OLPrintTemperature
% OLPrintTemperature
% Infinite temperature measurement loop with printing on the command window
% Press ^C to exit. Upon exiting from the loop, the user is asked whether 
% the data are to be saved to the disk.
%
% Example output:
%          Time             OneLightTemp    RoomTemp
% ______________________    ____________    ________
% 
% '21-Dec-2016 11:17:01'    30.74469        20.18896
% '21-Dec-2016 11:17:02'    30.68678        20.18351
% '21-Dec-2016 11:17:02'    30.36848        20.62562
% '21-Dec-2016 11:17:03'    30.78023        20.08112
% '21-Dec-2016 11:17:03'    30.92939        20.77571
%    
% 12/21/16 npc      Wrote it

    % Go into the measurement loop
    temperatureLoop();
end


function temperatureLoop()
    % Instantiate a class to handle the UE9 or the U3 labJack device
    theLJdev = LJTemperatureProbe();
    
    % Open the device
	theLJdev.open();
    finishup = onCleanup(@() closeLabJackAndSaveData(theLJdev));
    
    % Measure temperature and print it
    timeSeries = {};
    while (1)
        % Measure the data
        [~, temperature] = theLJdev.measure();
        % Add it to the timeSeries
        timeSeries = cat(1, timeSeries, {datestr(now), temperature(1), temperature(2)});
        % Display it as a table
        cell2table(timeSeries, 'VariableNames', {'Time' 'OneLightTemp' 'RoomTemp'})
        % Pause and re-measure, until user presses ^c
        pause(0.5);
    end
    
    % Close the device
	theLJdev.close();
    fprintf('Closed LabJack\n');
    
    function closeLabJackAndSaveData(theLJdev)
        % Close the device
        theLJdev.close();
        fprintf('Closed LabJack (on controlC)\n');
        % Query user whether he/she wants to save the temperature data
        d = GetWithDefault('Save the temperature data', 'Y');
        dataFileName = 'TemperatureData.mat';
        if (strcmp(d, 'y'))
            RecordedTemps = timeSeries;
            save(dataFileName, sprintf('%s_RecordedTemps', datestr(now, 30)));
            fprintf('Data saved in %s/%s.\n\n', pwd, dataFileName);
        end
       
    end
end


