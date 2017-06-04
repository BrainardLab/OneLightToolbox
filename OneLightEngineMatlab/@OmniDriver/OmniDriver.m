classdef OmniDriver < handle
	% OmniDriver - Class to control an OceanOptics spectrometer(s).
	%
	% OmniDriver Properties:
	%	BoxcarWidth - Number of pixels on either side of a given pixel to average together when obtaining a spectrum.
	%	CorrectForElectricalDark - Toggles the electrical dark correction to spectrum acquisitions.
	%   Debug - Toggles debug mode, which prints out debug information.
	%	FirmwareVersion - Firmware version.
	%	IntegrationTime - Current integration time setting. (µs)
	%	IsOpen - Indicates if we're connected to the spectrometer.
	%	MaxIntegrationTime - Maximum allowed integration time. (µs)
	%	MinIntegrationTime - Minimum allowed integration time. (µs)
	%	MaxIntensity - Maximum value for a CCD pixel, i.e. saturation point.
	%	NumPixels - Total number of pixels (ie. CCD elements) provided.
	%	NumDarkPixels - The number of dark pixels.
	%	NumSpectrometers - Number of attached spectrometers.
	%	ScansToAverage - Numer of scans to average.
	%	SerialNumber - Serial number of the spectrometer.
	%	SpectrometerType - Type of spectrometer.
	%	TargetSpectrometer - ID of the spectrometer to control.
	%
	% OmniDriver Methods:
	%	getSpectrum - Acquire the next available spectrum from the spectrometer.
    %   findIntegrationTime - Find a good non-saturating integration time.
	
	properties
		Debug = false;
	end
	
	properties (Dependent = true)
		IntegrationTime;
		BoxcarWidth;
		CorrectForElectricalDark;
		ScansToAverage;
	end
	
	properties (Dependent = true, SetAccess = private)
		NumPixels;
		NumDarkPixels;
		FirmwareVersion;
		MaxIntegrationTime;
		MinIntegrationTime;
		MaxIntensity;
		SerialNumber;
		SpectrometerType;
		Wavelengths;
	end
	
	properties (SetAccess = protected)
		% Number of attached spectrometers.
		NumSpectrometers = [];		
		IsOpen = false;
	end
	
	properties (SetAccess = protected, Dependent = true)
		TargetSpectrometer = 0;
	end
	
	properties (SetAccess = protected, Transient = true)
		Wrapper;
	end
	
	% Private properties that shadow dependent ones.
	properties (Access = protected)
		PrivateTargetSpectrometer = 0;
	end
	
	% Public methods.
	methods
		function obj = OmniDriver(targetSpectrometer)
			% Check that number of input arguments.
			error(nargchk(0, 1, nargin));
			
			if nargin == 1
				obj.TargetSpectrometer = targetSpectrometer;
			end
			
			% Get the Java pointer to the Wrapper object.
			obj.Wrapper = OmniDriver.GetWrapperObject;
			
			obj.open;
		end
		
		[specData,isSaturated] = getSpectrum(obj,ignoreSaturationError)
		integrationTime = findIntegrationTime(obj, increment, factor, minTime, maxTime)
	end
	
	methods (Access = private)
		open(obj)
		
		% This function seems to cause trouble.  Will probably delete it
		% soon.
		close(obj)
	end
	
	% Get/Set functions for class properties.
	methods
		% Wavelengths
		function value = get.Wavelengths(obj)
			if obj.IsOpen
				value = obj.Wrapper.getWavelengths(obj.TargetSpectrometer);
			else
				value = [];
			end
		end
		
		% CorrectForElectricalDark
		function value = get.CorrectForElectricalDark(obj)
			if obj.IsOpen
				value = obj.Wrapper.getCorrectForElectricalDark(obj.TargetSpectrometer);
			else
				value = [];
			end
		end
		function set.CorrectForElectricalDark(obj, value)
			if obj.IsOpen
				% Turn the value into a boolean.
				value = logical(value);
				
				obj.Wrapper.setCorrectForElectricalDark(obj.TargetSpectrometer, value);
			else
				throw(MException('OmniDriver:Device:NotOpen', 'Not connected to the spectrometer.'));
			end
		end
		
		% ScansToAverage
		function value = get.ScansToAverage(obj)
			if obj.IsOpen
				value = obj.Wrapper.getScansToAverage(obj.TargetSpectrometer);
			else
				value = [];
			end
		end
		function set.ScansToAverage(obj, value)
			if obj.IsOpen
				% Force the value to an integer.
				value = round(value);
				
				assert(value >= 1, 'ScansToAverage must be >= 1.');
				
				obj.Wrapper.setScansToAverage(obj.TargetSpectrometer, value);
			else
				throw(MException('OmniDriver:Device:NotOpen', 'Not connected to the spectrometer.'));
			end
		end
		
		% NumDarkPixels
		function value = get.NumDarkPixels(obj)
			if obj.IsOpen
				value = obj.Wrapper.getNumberOfDarkPixels(obj.TargetSpectrometer);
			else
				value = [];
			end
		end
		
		% BoxcarWidth
		function value = get.BoxcarWidth(obj)
			if obj.IsOpen
				value = obj.Wrapper.getBoxcarWidth(obj.TargetSpectrometer);
			else
				value = [];
			end
		end
		function set.BoxcarWidth(obj, value)
			if obj.IsOpen
				assert(value >= 0, 'BoxcarWidth must be an integer >= 0.');
				
				obj.Wrapper.setBoxcarWidth(obj.TargetSpectrometer, value);
			else
				throw(MException('OmniDriver:Device:NotOpen', 'Not connected to the spectrometer.'));
			end
		end
		
		% NumPixels
		function value = get.NumPixels(obj)
			if obj.IsOpen
				value = obj.Wrapper.getNumberOfPixels(obj.TargetSpectrometer);
			else
				value = [];
			end
		end
		
		% IntegrationTime
		function value = get.IntegrationTime(obj)
			if obj.IsOpen
				value = obj.Wrapper.getIntegrationTime(obj.TargetSpectrometer);
			else
				value = [];
			end
		end
		function set.IntegrationTime(obj, value)
			if obj.IsOpen
				minTime = obj.MinIntegrationTime;
				maxTime = obj.MaxIntegrationTime;
				
				assert(value >= minTime && value <= maxTime, ...
					'OmniDriver:IntegrationTime:InvalidRange', ...
					'IntegrationTime %d outside the valid range of [%d,%d]', value, minTime, maxTime);
				
				obj.Wrapper.setIntegrationTime(obj.TargetSpectrometer, value);
			else
				throw(MException('OmniDriver:Device:NotOpen', 'Not connected to the spectrometer.'));
			end
		end
		
		% FirmwareVersion
		function value = get.FirmwareVersion(obj)
			if obj.IsOpen
				value = obj.Wrapper.getFirmwareVersion(obj.TargetSpectrometer).toCharArray';
			else
				value = [];
			end
		end
		
		% MaxIntensity
		function value = get.MaxIntensity(obj)
			if obj.IsOpen
				value = obj.Wrapper.getMaximumIntensity(obj.TargetSpectrometer);
			else
				value = [];
			end
		end
		
		% MaxIntegrationTime
		function value = get.MaxIntegrationTime(obj)
			if obj.IsOpen
				value = obj.Wrapper.getMaximumIntegrationTime(obj.TargetSpectrometer);
			else
				value = [];
			end
		end
		
		% MinIntegrationTime
		function value = get.MinIntegrationTime(obj)
			if obj.IsOpen
				value = obj.Wrapper.getMinimumIntegrationTime(obj.TargetSpectrometer);
			else
				value = [];
			end
		end
		
		% TargetSpectrometer
		function set.TargetSpectrometer(obj, value)
			if obj.IsOpen
				assert(value >= 0 && value < obj.NumSpectrometers, ...
					'OmniDriver:TargetSpectrometer:InvalidSpectrometer', ...
					'Invalid target spectrometer %d.\n', value);
			end
			
			obj.PrivateTargetSpectrometer = value;
		end
		function value = get.TargetSpectrometer(obj)
			value = obj.PrivateTargetSpectrometer;
		end
		
		% SerialNumber
		function value = get.SerialNumber(obj)
			if obj.IsOpen
				value = obj.Wrapper.getSerialNumber(obj.TargetSpectrometer).toCharArray';
			else
				value = [];
			end
		end
		
		% SpectrometerType
		function value = get.SpectrometerType(obj)
			if obj.IsOpen
				value = obj.Wrapper.getName(obj.TargetSpectrometer).toCharArray';
			else
				value = [];
			end
		end
	end
	
	% Protected static methods.
	methods (Static = true, Access = protected)
		function w = GetWrapperObject
			persistent wrapper;
            javaclasspath('/Users/melanopsin/Documents/MATLAB/Toolboxes/OneLightDriver/xOceanOpticsJava/OmniDriver.jar');
			
			% Lock the class so that we can reuse the Wrapper object.
			% Communication with the spectrometer is flaky if we start
			% screwing around too much with the Wrapper object.  I'm not
			% sure this is even strictly necessary, but doesn't hurt.
			mlock;
			
			if isempty(wrapper)
                wrapper = com.oceanoptics.omnidriver.api.wrapper.Wrapper;
			end
			
			w = wrapper;
		end
	end
end
