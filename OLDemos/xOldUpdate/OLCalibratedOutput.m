function OLCalibratedOutput

% See how many devices we have attached to the computer.
numDevices = OneLight('GetDeviceCount');
fprintf('- %d OneLight devices detected.\n', numDevices);

% We'll select the first device connected.  Devices are number for 0 to n,
% so our first device will always be reference by 0.
targetDevice = 0;

% Open the device.
fprintf('- Opening device %d.\n', targetDevice);
OneLight('Open', targetDevice);

try
	% Get some info about the connected device.
	numRows = OneLight('GetNumRows', targetDevice);
	numCols = OneLight('GetNumCols', targetDevice);
	serialNumber = OneLight('GetSerialNumber', targetDevice);
	fprintf('*** OneLight Device Info ***\n');
	fprintf('- Num Rows: %d, Num Columns: %d\n', numRows, numCols);
	fprintf('- Serial #%d\n\n', serialNumber);
	
	% Open up the spectrometer and print out some info about it.
	omniDriver = OmniDriver;
	fprintf('\n*** Spectrometer Device Info ***\n');
	fprintf('- Type: %s\n', omniDriver.SpectrometerType);
	fprintf('- Serial #%s\n', omniDriver.SerialNumber);
	fprintf('- Firmware Version: %s\n', omniDriver.FirmwareVersion);
	
	% Flush the keyboard buffer.
	mglGetKeyEvent;
	
	% Initialize our light pattern.
	starts = zeros(1, numCols, 'uint16');
	stops = starts + numRows - 1;
	
	keepListening = true;
	while keepListening
		key = mglGetKeyEvent;
		
		if ~isempty(key)
			switch key.charCode
				case 'q'
					fprintf('- Exiting\n');
					keepListening = false;
					
				otherwise
					% Flush the keyboard buffer.
					mglGetKeyEvent;
			end
			
			if keepListening
				% Send the pattern over.
				OneLight('SendPattern', targetDevice, starts, stops);
				
				[specData, isSaturated] = omniDriver.getSpectrum;
			end
		else
			mglWaitSecs(0.001);
		end
	end
	
	% Close the device.
	OneLight('Close', targetDevice);
catch e
	OneLight('CloseAll');
	rethrow(e);
end
