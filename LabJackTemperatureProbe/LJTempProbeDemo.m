function LJTempProbeDemo

    compileMexFile = true;
    if (compileMexFile)
        [dirName, ~] = fileparts(which(mfilename()));
        cd(dirName);
        mex -v -output LJTemperatureProbe LDFLAGS="\$LDFLAGS -weak_library /usr/local/Cellar/exodriver/2.5.3/lib/liblabjackusb.dylib -weak_library /usr/local/Cellar/libusb/1.0.20/lib/libusb-1.0.dylib" CFLAGS="\$CFLAGS -Wall -g" -I/usr/include -I/usr/local/Cellar/exodriver/2.5.3/include -I/usr/local/Cellar/libusb/1.0.20/include/libusb-1.0 "LJTemperatureProbe.c"
    end
    
	status = LJTemperatureProbe('open');
    if (status == 0)
        error('Could not open UE9 device. Is it connected ?\n');
        return;
    end
    
    figure(1); clf;
    timeSeriesTemperature = [];
    
    for k = 1:500   
        hold off;
        [status, tempData] = LJTemperatureProbe('measure');
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
    
    status = LJTemperatureProbe('close');
	
end

