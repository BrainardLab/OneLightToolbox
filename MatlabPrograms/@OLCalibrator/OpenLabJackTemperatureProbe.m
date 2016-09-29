function [takeTemperatureMeasurements, quitNow] = OpenLabJackTemperatureProbe(takeTemperatureMeasurements0)
    
    takeTemperatureMeasurements = takeTemperatureMeasurements0;
    quitNow = false;
    
    % Init temperature probe
    LJTemperatureProbe('close');
    status = LJTemperatureProbe('open');
    if (status == 0)
        fprintf('<strong>Could not open the UE9 device.</strong>\n');
        selection = input(sprintf('Continue without temperature measurements <strong>[Y]</strong> or try again after making sure it is connected <strong>[A]</strong>? '), 's');
        if (isempty(selection) || strcmpi(selection, 'y'))
            takeTemperatureMeasurements = false;
        else
            fprintf('Trying to open the UE9 device once more ...\n');
            status = LJTemperatureProbe('open');
            if (status == 1)
                fprintf('Sucessfully opened the UE9 device!!\n');
            else
                fprintf('Failed to open the UE9 device again. Quitting.\n');
                quitNow = true;
            end
        end
    end
end
