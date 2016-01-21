function OLCalibrate_Factory
% OLCalibrate_Factory - Calibrates the OneLight device.
%
% Description:
% The goal of this script is to step through the exact sequences as listed
% in the "OneLight Spectra User Guide" to perform a calibration of the
% OneLight device.  For further reference look in the document starting at
% section 10.4 Manual Calibration.  I will try to label the steps in the
% code to be the same ones in the document.

% The numerical ID of the OneLight device.  Unless we have multiple devices
% attached, this will always be zero.
targetDevice = 0;

try
	%% Spectral Range Calibration
	
	%% Steps 1-5
	% We assume the user has turned the equipment on prior to running this
	% program.  This code merely connects to the devices.
	
	% Connect to the OneLight device.
	fprintf('- Connecting to the OneLight device.\n');
	OneLight('Open', targetDevice);
	
	% Make sure everything is running at full power.
	OneLight('SetLampCurrent', targetDevice, 255);
	
	% Get some info about the connected device.
	numRows = OneLight('GetNumRows', targetDevice);
	numCols = OneLight('GetNumCols', targetDevice);
	
	% Connect to the OceanOptics spectrometer.
	od = OmniDriver;
	
	% Turn on some averaging and smoothing for the spectrum acquisition.
	od.ScansToAverage = 10;
	od.BoxcarWidth = 2;
	
	%% Step 6
	% Make sure electrical dark correction is enabled.
	od.CorrectForElectricalDark = true;
	
	%% Step 7
	% Turn all the mirrors on.
	
	% These arrays will define our pattern.  They MUST be the
	% length of the number of columns.  Each element defines the
	% start or stop row for the pattern.  All values are 0 indexed.
	starts = zeros(1, numCols);
	stops = zeros(1, numCols) + numRows - 1;
	
	% We must convert the pattern values to unsigned 16-bit integers.
	OneLight('SendPattern', targetDevice, uint16(starts), uint16(stops));
	
	%% Step 8
	% Record the source spectrum.
	
	% We'll iterate over increasing integration times to see where we
	% saturate the spectrometer.
	fprintf('- Determining optimal integration time...');
	od.IntegrationTime = 20000;
	while true
		try
			sourceSpectrum = od.getSpectrum; %#ok<NASGU>
		catch se
			% If we've gotten to the saturation point, drop the integration
			% time back down a little bit then take another measurement.
			if strcmp(se.identifier, 'OmniDriver:GetSpectrum:Saturated')
				od.IntegrationTime = od.IntegrationTime - 1000;
				break;
			else
				rethrow(se);
			end
		end
		
		od.IntegrationTime = od.IntegrationTime + 1000;
	end
	fprintf('%d microseconds\n', od.IntegrationTime);
	
	% Take our final measurement.
	disp('- Recording source spectrum.');
	sourceSpectrum = od.getSpectrum;
	
	%% Step 9
	% Turn off all the mirrors.
	stops = zeros(1, numCols);
	OneLight('SendPattern', targetDevice, uint16(starts), uint16(stops));
	
	%% Steps 10-11
	% Measure and record the background spectrum.
	disp('- Recording background spectrum.');
	backgroundSpectrum = od.getSpectrum;
	
	%% Step 12
	% Subtract the background spectrum from the source.
	specData = sourceSpectrum - backgroundSpectrum;
	
	%% Step 13
	% Find the start of the spectral range.  This is done by finding the
	% x-intercept of the line between 0.5 and 1% of the spectral max.
	
	% Max value.
	maxSpectra = max(specData);
	
	% 0.5% value.
	lv = maxSpectra * 0.005;
	
	% 1% value.
	hv = maxSpectra * 0.01;
	
	% Find the points on the both sides of the spectrum corresponding to the
	% 0.5 and 1% values.
	lowVals = find(specData - lv > 0);
	highVals = find(specData - hv > 0);
	
	% Calculate the y-intercept.
	x1 = lowVals(1);
	x2 = highVals(1);
	y1 = specData(x1);
	y2 = specData(x2);
	slope = (y2 - y1) / (x2 - x1);
	yIntercept = y1 - slope * x1;
	
	% Find the x-intercept.  Round the x-intercept so that it corresponds
	% to an actual spectrometer pixel.
	xIntercept1 = round(-yIntercept / slope);
	
	%% Step 14
	% Find the end of the spectral range using the same method as above.
	
	% Calculate the y-intercept.
	x2 = lowVals(end);
	x1 = highVals(end);
	y1 = specData(x1);
	y2 = specData(x2);
	slope = (y2 - y1) / (x2 - x1);
	yIntercept = y1 - slope * x1;
	
	% Find the x-intercept.  Round the x-intercept so that it corresponds
	% to an actual spectrometer pixel.
	xIntercept2 = round(-yIntercept / slope);
	
	%% Step 15
	% Store the start and end wavelengths, which defines our spectral
	% range.
	wavelengths = od.Wrapper.getWavelengths(od.TargetSpectrometer);
	spectralRange.start = wavelengths(xIntercept1);
	spectralRange.end = wavelengths(xIntercept2);
	
	%% Wavelength Calibration
	
	%% Steps 16-20
	% Loop over bands of mirror columns and take wavelength measurents for
	% each set.
	
	% Number of columns in a band.
	bandWidth = 32;
	
	% Number of columns to step at each iteration.
	stepSize = 16;
	
	% We will always start from the 0th row for each column.
	starts = zeros(1, numCols, 'uint16');
	
	% Calculate the start columns for all measurements.
	startCols = 0:stepSize:numCols-bandWidth;
	
	fprintf('- Measurement wavelengths (this might take a minute)...');
	index = 1;
	for i = startCols
		stops = zeros(1, numCols);
		
		% Set the target columns to the max height.
		stops(i+1 : i+bandWidth) = numRows - 1;
		
		% Record the band start and end.
		wavelengthMeasurements(index).bandRange = [i+1, i+bandWidth]; %#ok<*AGROW>
		
		% Turn on the mirrors.
		OneLight('SendPattern', targetDevice, starts, uint16(stops));
		
		% Acquire the light spectrum.
		wavelengthMeasurements(index).lightSpectrum = od.getSpectrum;
		
		% Turn off the mirrors.
		OneLight('SendPattern', targetDevice, starts, zeros(1, numCols, 'uint16'));
		
		% Take a reading for the background spectrum.
		wavelengthMeasurements(index).backgroundSpectrum = od.getSpectrum;
		
		index = index + 1;
	end
	fprintf('Done\n');
	
	%% Steps 21-24
	% Loop over all the measurements and figure out the center wavelength
	% for the nominal center column of each band.
	for i = 1:length(wavelengthMeasurements)
		% Calculate the nominal center column.
		wavelengthMeasurements(i).nominalCenter = mean(wavelengthMeasurements(i).bandRange);
		
		% Subtract the background spectrum from the light one.
		wavelengthMeasurements(i).spectrum = wavelengthMeasurements(i).lightSpectrum - ...
			wavelengthMeasurements(i).backgroundSpectrum;
		
		% Smooth the crap out of the spectrum and find the index location
		% of the max.  This will be the wavelength for the nominal center.
		[~, mi] = max(smooth(wavelengthMeasurements(i).spectrum, 15));
		wavelengthMeasurements(i).nominalWavelength = wavelengths(mi);
	end
	
	%% Cleanup
	OneLight('Close', targetDevice);
	
catch e
	OneLight('Close', targetDevice);
	
	rethrow(e);
end
