function U3TempProbeDemo

	compileMexFile = true;
    if (compileMexFile)
        [dirName, ~] = fileparts(which(mfilename()));
        cd(dirName);
        mex -v -output U3TemperatureProbeU3 LDFLAGS="\$LDFLAGS -weak_library /usr/local/Cellar/exodriver/2.5.3/lib/liblabjackusb.dylib -weak_library /usr/local/Cellar/libusb/1.0.20/lib/libusb-1.0.dylib" CFLAGS="\$CFLAGS -Wall -g" -I/usr/include -I/usr/local/Cellar/exodriver/2.5.3/include -I/usr/local/Cellar/libusb/1.0.20/include/libusb-1.0 "U3TempNew.c"
        
        % Compile the UE6 mexfile
        %mex -v -output LJTemperatureProbeUE6 LDFLAGS="\$LDFLAGS -weak_library /usr/local/Cellar/exodriver/2.5.3/lib/liblabjackusb.dylib -weak_library /usr/local/Cellar/libusb/1.0.20/lib/libusb-1.0.dylib" CFLAGS="\$CFLAGS -Wall -g" -I/usr/include -I/usr/local/Cellar/exodriver/2.5.3/include -I/usr/local/Cellar/libusb/1.0.20/include/libusb-1.0 "UE6.c"
        
    end
pause

    % isU3orUE9 =1 means it is U3
    % isU3orUE9 =2 means it is UE9
    isU3orUE9 = U3TemperatureProbe('identify');
 
    if (isU3orUE9 == 0)
        error('Could not open U3 device. Is it connected ?/n');
        return;
    end
    
    status = U3TemperatureProbe('open');
    if (status == 0)
        error('Could not open U3 device. Is it connected ?\n');
        return;
    end
    
    figure(1); clf;
    timeSeriesTemperature = [];
    
    for k = 1:100
        hold off;
        [status, tempData] = U3TemperatureProbe('measure');
        size(tempData)
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
    
    status = U3TemperatureProbe('close');
    
end

