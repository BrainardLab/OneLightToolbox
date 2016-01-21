classdef PowerMeter < handle
	% PowerMeter - Class to control the P-Link power meter.
	%
	% PowerMeter Properties:
	%   IsOpen - Returns whether we're connected to the power meter.
	%
	% PowerMeter Methods:
	%   PowerMeter - Creates the PowerMeter object and connects to the device.
	
	properties (SetAccess = protected, Dependent = true)
		IsOpen;
	end
	
	properties (Access = protected)
		SerialPort;
	end
	
	methods
		function obj = PowerMeter
			% Create the serial port object.
			obj.SerialPort = serial('/dev/tty.usbserial-A700fpqE', ...
				'BaudRate', 57600);

			% If the serial port isn't open try to open it.
			if strcmp(obj.SerialPort.Status, 'closed')
				fopen(obj.SerialPort);
			end
		end
	end
	
	methods
		function value = get.IsOpen(obj)
			if strcmp(obj.SerialPort.Status, 'open')
				value = true;
			else
				value = false;
			end
		end
	end
	
	methods (Static = true)
		eString = errorString(errorCode)
	end
end
