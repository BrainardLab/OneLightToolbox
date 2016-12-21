classdef LJTemperatureProbe < handle
    
    % Public properties
    properties
        verbosity = 0;
    end
    
    % Read-only properties
    properties (SetAccess = private)
        deviceID
    end
    
    % Private properties
    properties (Access = private)
        somePrivateProp
    end
    
    % Public methods
    methods
        % Constructor
        function obj = LJTemperatureProbe(varargin)
            % Parse optional arguments
            parser = inputParser;
            parser.addParameter('verbosity', 0, @isnumeric);
            %Execute the parser
            parser.parse(varargin{:});
            obj.verbosity = parser.Results.verbosity;
        end
        
        % Method to open a LabJackDevice
        function status = open(obj) 
            % First see if there is a UE9 connected
            isUE9 = LJTemperatureProbeUE9('identify');
            if (isUE9 == 1)
                obj.deviceID = 'UE9';
                LJTemperatureProbeUE9('close');
                LJTemperatureProbeUE9('open');
            else
                % Nope, let's see if there is a U3 connected
                isU3 = LJTemperatureProbeU3('identify');
                if (isU3 == 1)
                    obj.deviceID = 'U3';
                else
                    error('Did not find a UE9 or a U3 LabJack device. Is one connected ?/n');
                end
                LJTemperatureProbeU3('close');
                LJTemperatureProbeU3('open');
            end
            status = 1;
        end
        
        % Method to close a LabJackDevice
        function status = close(obj) 
            if strcmp(obj.deviceID, 'UE9')
                status = LJTemperatureProbeUE9('close');
            elseif strcmp(obj.deviceID, 'U3')
                status = LJTemperatureProbeU3('close');
            else
                error('Unknown deviceID: %s', obj.deviceID);
            end
            if (status == 1)
                fprintf('Closed LJdevice\n');
            end
        end
        
        % Method to measure the temperature (single point)
        function [status, temperature] = measure(obj)
            if strcmp(obj.deviceID, 'UE9')
                [status, temperature] = LJTemperatureProbeUE9('measure');
            elseif strcmp(obj.deviceID, 'U3')
                [status, temperature] = LJTemperatureProbeU3('measure');
            else 
                error('Unknown deviceID: %s', obj.deviceID);
            end
            if (status ~= 0)
                fprintf('Could not read from LJdevice\n');
            end
        end
    end  % Public methods
    
    methods (Access = private)
        
    end
    
end

