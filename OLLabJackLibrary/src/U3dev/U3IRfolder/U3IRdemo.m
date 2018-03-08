function U3IRdemo

	compileMexFile = true;
    if (compileMexFile)
        [dirName, ~] = fileparts(which(mfilename()));
        cd(dirName);
        mex -v -output u3IR LDFLAGS="\$LDFLAGS -weak_library /usr/local/Cellar/exodriver/2.5.3/lib/liblabjackusb.dylib -weak_library /usr/local/Cellar/libusb/1.0.21/lib/libusb-1.0.dylib" CFLAGS="\$CFLAGS -Wall -g -std=c11 -Wno-nullability-completeness" -I/usr/include -I/usr/local/Cellar/exodriver/2.5.3/include -I/usr/local/Cellar/libusb/1.0.21/include/libusb-1.0 "u3IR.c"
          
    end
    pause
    
    % close the u3 in case it was open
    status = u3IR('close');
    
    % open and send the TTL pulse to the arduino
    status = u3IR('open_sendTTL');
    if (status == 0)
        error('Could not open U3 device. Is it connected ?\n');
        return;
    end
    
end

