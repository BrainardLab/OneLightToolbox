classdef OneLight < hgsetget
	% OneLight - Class to control and abstract a OneLight device.
	%
	% OneLight Properties:
	%    DeviceID - The numerical ID of the OneLight device.
    %    LampStatus - Status of lamp
	%    InputPatternBuffer - Index of the pattern buffer being written to.
	%    InputTriggerStatus - Gets the input trigger status.
	%    IsOpen - Indicates if the device is open or not.
	%    LampCurrent - Nominal (0-255) lamp current.
    %    CurrentMonitor - Measured current (amps, I think).
    %    VoltageMonitor - Measured voltage (volts, I think).
    %    FanSpeed - Speed of fan 0
    %    SerialNumber - Device serial number
	%    NumCols - Number of columns of mirrors in the device.
	%    NumRows - Number of rows of mirrors in the device.
	%    OutputPatternBuffer - Buffer whose pattern is to displayed.
	%
	% OneLight Methods:
	%    OneLight - Constructor.
	%    open - Opens the device.
	%    close - Closes the device.
	%    closeAll - Closes any detected devices.
	%    setMirrors - Sets the mirrors on the device.
	%    shutdown - Shuts down the device.
    %
    % 1/2/14  dhb  Made this a hgsetget object, which seems to make the
    %              get/set features work.
    % 6/5/17  dhb  Add simulation mode.  Made up a lot of return values for
    %              features we don't generally use, so this may not be
    %              totally robust.
	
	properties (Dependent = true)
        LampStatus;
		LampCurrent;
        CurrentMonitor;
        VoltageMonitor;
        FanSpeed;
        SerialNumber;
		InputTriggerMode;
		InputTriggerHold;
		InputPatternBuffer;
		InputTriggerDelay;
		InputTriggerStatus;
		OutputPatternBuffer;
	end
	
	properties (SetAccess = private)
		DeviceID;
		NumPatternBuffers;
		NumCols;
		NumRows;
        Simulate;
        SimFig;
	end
	
	properties (SetAccess = private, Dependent = true)
		IsOpen;
	end
	
	% Public methods.
	methods
		function obj = OneLight(varargin)
			% OneLight - OneLight class constructor.
			%
			% Syntax:
			% obj = OneLight
			% obj = OneLight(deviceID)
			%
			% Description:
			% Creates a hardware abstraction to a OneLight device.  When
			% created, the constructor attempts to open the device.
			%
			% Input:
			% deviceID (scalar) - Integer device ID number in the range of
			%   [0,n-1] where n is the number of attached OneLight devices.
			%   Defaults to 0.
            
            % Parse key/value pairs
            p = inputParser;
            p.addOptional('deviceID', 0, @isscalar);
            p.addOptional('simulate', false, @islogical);
            p.parse(varargin{:});
            params = p.Results;
			
            % Check if we're simulating
            if (params.simulate)
                obj.Simulate = true;
                obj.DeviceID = params.deviceID;
                obj.LampCurrent = 240;
                obj.NumPatternBuffers = 4;
                obj.InputPatternBuffer = 0;
                obj.OutputPatternBuffer = 0;
                obj.NumRows = 768;
                obj.NumCols = 1024;
                obj.open;
                return;
            else
                obj.Simulate = false;
            end
            
			% Get the number of attached devices.  This call throws an
			% error if no devices are connected so we catch it to make the
			% error a bit more informative.
			try
				numDevices = OneLightEngine(OneLightFunctions.GetDeviceCount.UInt32);
			catch e
				error('No devices detected, turn the OneLight device on or make sure the cable is connected.');
			end
			
			% Make sure the deviceID is in range.
			assert(params.deviceID >= 0 && params.deviceID < numDevices, 'OneLight:DeviceID', ...
				'The specified device ID %d is out of range', deviceID);
			
			obj.DeviceID = params.deviceID;
			
			% Go ahead an open the device.
			obj.open;
			
			% Set the device to use full lamp current.
			%obj.LampCurrent = 255;
            
            % Set the device to the current that we think gives us 500W.
            obj.LampCurrent = 240;
			
			% Get the number of pattern buffers on the device.
			obj.NumPatternBuffers = OneLightEngine(OneLightFunctions.GetMaxPatternBuffers.UInt32, obj.DeviceID);
			
			% Make pattern buffer 0 to be the starting input and output.
			obj.InputPatternBuffer = 0;
			obj.OutputPatternBuffer = 0;
			
			% Get the number of mirror rows and columns.
			obj.NumRows = OneLightEngine(OneLightFunctions.GetNumRows.UInt32, obj.DeviceID);
			obj.NumCols = OneLightEngine(OneLightFunctions.GetNumCols.UInt32, obj.DeviceID);
		end
		
		open(obj)
		close(obj)
		shutdown(obj)
		setMirrors(obj, starts, stops)
		setAll(obj, allOn)
		%timingData = flickerBuffers(obj, bufferSettings, bufferPattern, flickerRate, duration)
	end
	
	% Static methods.
	methods (Static = true)
		closeAll
		codeString = errorString(errorCode)
	end
	
	% Get/set methods for class properties.
	methods
		% InputTriggerStatus
		function value = get.InputTriggerStatus(obj)
            if (~obj.Simulate)
                if obj.IsOpen
                    value = OneLightEngine(OneLightFunctions.GetInputTrgrStatus.UInt32, obj.DeviceID);
                else
                    value = [];
                end
            else
                value = 0;
            end
		end
		
		% InputTriggerMode
		function value = get.InputTriggerMode(obj)
            if (~obj.Simulate)
                if obj.IsOpen
                    value = OneLightEngine(OneLightFunctions.GetInputTrgrMode.UInt32, obj.DeviceID);
                else
                    value = [];
                end
            else
                value = 0;
            end
		end
		
		% OutputPatternBuffer
		function value = get.OutputPatternBuffer(obj)
            if (~obj.Simulate)
                if obj.IsOpen
                    value = OneLightEngine(OneLightFunctions.GetOutputPatternBuffer.UInt32, obj.DeviceID);
                else
                    value = [];
                end
            else
                value = 0;
            end
        end
        
        function set.OutputPatternBuffer(obj, value)
            % Validate the input.
            assert(value >= 0 && value < obj.NumPatternBuffers, ...
                'Onelight:OutputPatternBuffer:InvalidBuffer', ...
                'OutputPatternBuffer value of %d is invalid.  Valid range is [0,%d].', ...
                value, obj.NumPatternBuffers);         
            if (~obj.Simulate)
                if obj.IsOpen
                    OneLightEngine(OneLightFunctions.SetOutputPatternBuffer.UInt32, obj.DeviceID, value);
                end   
            end
        end
		
		% IsOpen
		function value = get.IsOpen(obj)
            if (~obj.Simulate)
                value = logical(OneLightEngine(OneLightFunctions.IsOpen.UInt32, obj.DeviceID));
            else
                value = 1;
            end
		end
		
		% InputTriggerDelay
        function value = get.InputTriggerDelay(obj)
            if (~obj.Simulate)
                if obj.IsOpen
                    value = OneLightEngine(OneLightFunctions.GetInputTrgrDelay.UInt32, obj.DeviceID);
                else
                    value = [];
                end
            else
                value = 0;
            end
        end
		
        % InputTriggerHold
        function value = get.InputTriggerHold(obj)
            if (~obj.Simulate)
                if obj.IsOpen
                    value = OneLightEngine(OneLightFunctions.GetInputTrgrHold.UInt32, obj.DeviceID);
                else
                    value = [];
                end
            else
                value = 0;
            end
        end
        
        function set.InputTriggerHold(obj, value)
            % Validate the input.
            assert(value >= 0 && value <= 16000000, 'OneLight:InputTriggerHold', ...
                'Input trigger hold value %d is out of the allowable range [0,16000000]', value);  
            if (~obj.Simulate)
                if obj.IsOpen
                    OneLightEngine(OneLightFunctions.SetInputTrgrHold.UInt32, obj.DeviceID, value);
                end
            end
        end
					
		% LampCurrent
		function value = get.LampCurrent(obj)
			% If we're connected to the device we'll get the lamp current
			% directly from it.  If we're not we get the value from the
			% stored requested value.
            if (~obj.Simulate)
                if obj.IsOpen
                    value = OneLightEngine(OneLightFunctions.GetLampCurrent.UInt32, obj.DeviceID);
                else
                    value = [];
                end
            else
                value = 240;
            end
        end
        
        function set.LampCurrent(obj, value)
            % Validate the requested value.  It needs to be in the range
            % [0, 255].
            assert(value >= 0 && value <= 255, 'OneLight:LampCurrent', ...
                'Lamp current value of %d is out the allowable range of [0,255].', value);
            if (~obj.Simulate)
                if obj.IsOpen
                    OneLightEngine(OneLightFunctions.SetLampCurrent.UInt32, obj.DeviceID, value);
                end
            end
        end
        
        % Get Lamp Status
        function value = get.LampStatus(obj)
			% If we're connected to the device we'll get the lamp status
			% directly from it.  If we're not we get the value from the
			% stored requested value.
            %   dmdLampStatusInitial = 0,
            %   dmdLampStatusIgnition = 1,
            %   dmdLampStatusIgnitionFailed = 2,
            %   dmdLampStatusOn = 3,
            %   dmdLampStatusCooldownFP = 4,
            %   dmdLampStatusCooldownNoFan = 5,
            %   dmdLampStatusCooldownPC = 6,
            %   dmdLampStatusSleep = 7,
            %   dmdLampStatusLostLamp = 8
            if (~obj.Simulate)
                if obj.IsOpen
                    value = OneLightEngine(OneLightFunctions.GetLampStatus.UInt32, obj.DeviceID);
                else
                    value = [];
                end
            else
                value = true;
            end
        end
        
        % Get Fan Speed
        function value = get.FanSpeed(obj)
			% If we're connected to the device we'll get the lamp status
			% directly from it.  If we're not we get the value from the
			% stored requested value.
            %   dmdFan1 = 0,
            %   dmdFan2 = 1,
            %   dmdFan3 = 2
            if (~obj.Simulate)
                if obj.IsOpen
                    value0 = OneLightEngine(OneLightFunctions.GetFanSpeed.UInt32, obj.DeviceID, 0);
                    %value1 = OneLightEngine(OneLightFunctions.GetFanSpeed.UInt32, obj.DeviceID, 1);
                    %value2 = OneLightEngine(OneLightFunctions.GetFanSpeed.UInt32, obj.DeviceID, 2);
                    value = [value0];
                else
                    value = [];
                end
            else
                value = 0;
            end
            
        end
        
        % Get Serial Number
        function value = get.SerialNumber(obj)
            if (~obj.Simulate)
                if obj.IsOpen
                    value = OneLightEngine(OneLightFunctions.GetSerialNumber.UInt32, obj.DeviceID);
                else
                    value = [];
                end
            else
                value = 1001;
            end
        end
        
        % Get Current/VoltageMonitor
        function value = get.CurrentMonitor(obj)
            % If we're connected to the device we'll get the lamp current
            % directly from it.  If we're not we get the value from the
            % stored requested value.
            if (~obj.Simulate)
                if obj.IsOpen
                    value = OneLightEngine(OneLightFunctions.GetCurrentMonitor.UInt32, obj.DeviceID);
                else
                    value = [];
                end
            else
                value = 240;
            end
        end
        
        function value = get.VoltageMonitor(obj)
            % If we're connected to the device we'll get the lamp voltage
            % directly from it.  If we're not we get the value from the
            % stored requested value.
            if (~obj.Simulate)
                if obj.IsOpen
                    value = OneLightEngine(OneLightFunctions.GetVoltageMonitor.UInt32, obj.DeviceID);
                else
                    value = [];
                end
            else
                value = 5;
            end
		end
        
		% InputPatternBuffer
		function value = get.InputPatternBuffer(obj)
            if (~obj.Simulate)
                if obj.IsOpen
                    value = OneLightEngine(OneLightFunctions.GetInputPatternBuffer.UInt32, obj.DeviceID);
                else
                    value = [];
                end
            else
                value = 0;
            end
        end
        
		function set.InputPatternBuffer(obj, value)			
			% Validate the input.
			assert(value >= 0 && value < obj.NumPatternBuffers, ...
                'Onelight:InputPatternBuffer:InvalidBuffer', ...
                'InputPatternBuffer value of %d is invalid.  Valid range is [0,%d].', ...
            value, obj.NumPatternBuffers);
            if (~obj.Simulate)
                if obj.IsOpen
                    OneLightEngine(OneLightFunctions.SetInputPatternBuffer.UInt32, obj.DeviceID, value);
                end
            end
		end
	end
end
