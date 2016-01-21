function OLPrismDemo
% OLPrismDemo

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
	fprintf('- Num Rows: %d, Num Columns: %d\n', numRows, numCols);
	fprintf('- Serial #%d\n', serialNumber);
	
	for i = 1:5
		% This loop essentially runs through the range of all columns of the
		% device and actives all rows.
		for col = 1:numCols
			% These arrays will define our pattern.  They MUST be the
			% length of the number of columns.  Each element defines the
			% start or stop row for the pattern.  All values are 0 indexed.
			starts = zeros(1, numCols);
			stops = zeros(1, numCols);
			
			% Use all rows in the column.
			starts(col) = 0;
			stops(col) = numRows - 1;
			
			% We must convert the pattern values to unsigned 16-it
			% integers.
			OneLight('SendPattern', targetDevice, uint16(starts), uint16(stops));
		end
		
		% Wait for a bit before running through another loop.
		pause(1);
	end
	
	% Close the device.
	OneLight('Close', targetDevice);
catch e
	OneLight('CloseAll');
	rethrow(e);
end