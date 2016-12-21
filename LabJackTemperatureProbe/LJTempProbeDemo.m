% Shows how to use the LJTemperatureProbe class
function LJTempProbeDemo

    % Note: To recompile the mexfiles run CompileMexfiles in the src subdirectory;
    
    % Instantiate a class to handle the UE9 or the U3 labJack device
    theLJdev = LJTemperatureProbe();
    
    % Open the device
	theLJdev.open()
    
    figure(1); clf;
    timeSeriesTemperature = [];
    
    nMeasurements = 250;
    for k = 1:nMeasurements  
        hold off;
        [status, tempData] = theLJdev.measure();
        timeSeriesTemperature = cat(2, timeSeriesTemperature, tempData(:));
        
        subplot(1,2,1);
        plot((1:size(timeSeriesTemperature,2)), timeSeriesTemperature(1,:), 'ks-');
        set(gca, 'YLim', [20 110]);
        title('temperature, Celsius (sensor probe)')
        
        subplot(1,2,2);
        plot((1:size(timeSeriesTemperature,2)), timeSeriesTemperature(2,:), 'ks-');
        set(gca, 'YLim', [20 40]);
        title('temperature, Celsius (ambient)')
        drawnow
    end
    
    % Close the device
	status = theLJdev.close();
end

