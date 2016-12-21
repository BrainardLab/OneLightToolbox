% [takeTemperatureMeasurements, quitNow, theLJdev] = OpenLabJackTemperatureProbe(takeTemperatureMeasurements0)
% Open a LabJack device (UE9 or U3) for temperature measurements
%
% 12/21/16  npc     Updated for new class @LJTemperatureProbe

function [takeTemperatureMeasurements, quitNow, theLJdev] = OpenLabJackTemperatureProbe(takeTemperatureMeasurements0)
    
    takeTemperatureMeasurements = takeTemperatureMeasurements0;
    quitNow = false;
    
    % Instantiate a class to handle the UE9 or the U3 labJack device
    theLJdev = LJTemperatureProbe();
    % Open the device
	status = theLJdev.open();
    
    if (status == 0)
        fprintf('<strong>Could not open the LabJack device.</strong>\n');
        selection = input(sprintf('Continue without temperature measurements <strong>[Y]</strong> or try again after making sure it is connected <strong>[A]</strong>? '), 's');
        if (isempty(selection) || strcmpi(selection, 'y'))
            takeTemperatureMeasurements = false;
        else
            fprintf('Trying to open the LabJack device once more ...\n');
            % Instantiate a class to handle the UE9 or the U3 labJack device
            theLJdev = LJTemperatureProbe();
            % Open the device
            status = theLJdev.open();
            if (status == 1)
                fprintf('Sucessfully opened the LabJack device!!\n');
            else
                fprintf('Failed to open the LabJack device again. Quitting.\n');
                quitNow = true;
            end
        end
    end
end
