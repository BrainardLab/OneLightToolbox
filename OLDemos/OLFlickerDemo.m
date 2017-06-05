function keyPress = OLFlickerDemo(varargin)
% OLFlickerDemo - Demonstrates how to flicker with the OneLight.
%
% Syntax:
% OLFlickerDemo
%
% Description:
% Demo that shows how to open the OneLight, use the cache, and flicker the
% light engine.  The cache let's us store precomputed spectra, primaries,
% and settings values so that they don't need to be computed everytime the
% program is run.  The cache system makes sure that the precomputed
% settings are in sync with the calibration file.  If the cache file
% doesn't exist, it will be created.
%
% Input (key, value):
% 'StimType' (string) - Takes any of the following values: 'ShowSpectrum', 
%     'BinaryFlicker', 'GaussianWindow', 'DriftGabor', 'DriftSine'.
% 'UseCache' (logical) - Toggles the use of the spectra cache.  Default: true
% 'Recompute' (logical) - Let's you force a recomputation of the spectra
%     and rewrite the cache file.  Only useful if using the cache.
%     Default: false
% 'ProcessOnly' (logical) - If true, then the program doesn't communicate
%     with the OneLight engine.  Default: false
% 'Hz' (scalar) - The rate at which the program cycles through the set of
%     spectra to display.  Default: 1
% 'GaussianWindowWidth' (scalar) - The number of cycles to window the set of
%     spectra in the 'GaussianWindow' stim type.  Default: 30.
% 'simulate' (logical) - Run in simulation mode? Default: false.
%
% Examples:
% % Don't use the cache.
% OLFlickerDemo('UseCache', false);
% 
% % Force a recompute of the spectra.
% OLFlickerDemo('Recompute', true);

% NOTE FROM DHB: I don't understand the GuassianWindow stimulus.

% Parse any input parameters.
p = inputParser;
p.addParamValue('UseCache', true);
p.addParamValue('Recompute', false);
p.addParamValue('StimType', 'ShowSpectrum');
p.addParamValue('GaussianWindowWidth', 30);
p.addParamValue('Hz', 1);
p.addParamValue('ProcessOnly', false);
p.addParamValue('simulate', false);
p.parse(varargin{:});
inputParams = p.Results;

% Select the cache file pased on the stim type.
switch lower(inputParams.StimType)
	case 'showspectrum'
		cacheFile = 'ShowSpectrum';
		
	case 'binaryflicker'
		cacheFile = 'BinaryFlicker';
		
	case 'gaussianwindow'
		cacheFile = 'GaussianWindow';
		
	case 'driftgabor'
		cacheFile = 'DriftGabor';
		
	case 'driftsine'
		cacheFile = 'DriftSine';
		
	otherwise
		error('OLFlickerDemo:Invalid stim type "%s".', inputParams.StimType);
end

% Setup some program variables.
cacheDir = fullfile(fileparts(which('OLFlickerDemo')), 'cache');
calFileName = 'OneLight';

% Create the OneLight object.
if ~inputParams.ProcessOnly
	ol = OneLight('simulate',inputParams.simulate);
end

% Load the calibration file.
oneLightCal = LoadCalFile(calFileName);

% This flags regular computing of the spectra and mirror settings.  By
% default, it will be the opposite of whether we're using the cache or not.
doCompute = ~inputParams.UseCache;

if inputParams.UseCache
	% Create a cache object.  This object encapsulates the cache folder and
	% the actions we can take on the cache files.  We pass it the
	% calibration data so it can validate the cache files we want to load.
	cache = OLCache(cacheDir, oneLightCal);
	
	% Look to see if the cache file exists.
	cacheFileExists = cache.exist(cacheFile);
	
	% Load the cache file if it exists and we're not forcing a recompute of
	% the target spectra.
	if cacheFileExists && ~inputParams.Recompute
		% Load the cache file.  This function will check to make sure the
		% cache file is in sync with the calibration data we loaded above.
		cacheData = cache.load(cacheFile);
	else
		if inputParams.Recompute
			fprintf('- Manual recompute toggled.\n');
		else
			fprintf('- Cache file does not exist, will be computed and saved.\n');
		end
		
		doCompute = true;
	end
end

if doCompute
	% Specify the spectra depending on our stim type.
	switch lower(inputParams.StimType)
		case {'binaryflicker', 'gaussianwindow', 'showspectrum'}
			switch lower(inputParams.StimType)
				case 'binaryflicker'
					gaussCenters = [400, 700];
                    bandwidth = 30;

				case 'gaussianwindow'
					gaussCenters = [480, 650];
                    bandwidth = 30;

				case 'showspectrum'
					gaussCenters = 400:2:700;
                    bandwidth = 10;

			end
			
			numSpectra = length(gaussCenters);
			scaleFactors = zeros(1, numSpectra);
			targetSpds = zeros(oneLightCal.describe.S(3), numSpectra);
			lambda = 0.1;
			for i = 1:numSpectra
				fprintf('- Computing spectra %d of %d...', i, numSpectra);
				
				center = gaussCenters(i);
				targetSpds(:,i) = normpdf(oneLightCal.computed.pr650Wls, center, bandwidth)';
				
				% Find the scale factor that leads to the maximum relative targetSpd that is within
				% the OneLight's gamut.
				[~, scaleFactors(i), ~] = OLFindMaxSpectrum(oneLightCal, targetSpds(:,i), lambda, false);
				
				fprintf('Done\n');
			end
			
			% Find the smallest scale factor to apply to all the targetSPDs.
			minScaleFactor = min(scaleFactors);
			targetSpds = targetSpds * minScaleFactor;
			
			% Convert the spectra into gamma corrected mirror settings.  We use the
			% static OLCache method "compute" so that we guarantee we calculate the
			% cache in the same way that an OLCache object's load method does.
			fprintf('- Calculating mirror settings...');
			
			% We refer to the compute method by its enumeration.  This lets us have
			% a standard way of referencing a compute method through the
			% OneLightToolbox.
			computeMethod = OLComputeMethods.Standard;
			
			cacheData = OLCache.compute(computeMethod, oneLightCal, targetSpds, lambda, false);
			fprintf('Done\n');
			
		case {'driftgabor', 'driftsine'}
			% Create the gaussian window.
			switch lower(inputParams.StimType)
				case 'driftgabor'
					sig = round(oneLightCal.describe.S(3) * 0.15);
					gaussWindow = CustomGauss([1 oneLightCal.describe.S(3)], sig, sig, 0, 0, 1, [0 0])';
					
				case 'driftsine'
					gaussWindow = ones(oneLightCal.describe.S(3), 1);
			end
			
			% Calculate 1 temporal cycle of the harmonic.  We'll subdivide
			% it into 100 steps to make it look smooth.  We'll also go
			% ahead and multiply by the Gaussian window to get our gabor.
			x = 0:(oneLightCal.describe.S(3)-1);
			numSteps = 100;
			spatialFrequency = 2;
			targetSpds = zeros(oneLightCal.describe.S(3), numSteps);
			for i = 0:(numSteps-1)
				targetSpds(:,i+1) = sin(2*pi*x/oneLightCal.describe.S(3)*spatialFrequency + 2*pi*i/numSteps)' .* gaussWindow;
				
				% Normalize to [0,1] range.
				targetSpds(:,i+1) = (targetSpds(:,i+1) + 1) / 2;
			end
			
			% Find the scale factor to maximize the spectra.
			scaleFactors = zeros(1, numSteps);
			lambda = 0.1;
			for i = 1:numSteps
				fprintf('- Computing spectra %d of %d...', i, numSteps);
				
				% Find the scale factor that leads to the maximum relative targetSpd that is within
				% the OneLight's gamut.
				[~, scaleFactors(i), ~] = OLFindMaxSpectrum(oneLightCal, targetSpds(:,i), lambda, false);
				
				fprintf('Done\n');
			end
			
			% Find the smallest scale factor to apply to all the targetSPDs.
			minScaleFactor = min(scaleFactors);
			targetSpds = targetSpds * minScaleFactor;
			
			% Convert the spectra into gamma corrected mirror settings.  We use the
			% static OLCache method "compute" so that we guarantee we calculate the
			% cache in the same way that an OLCache object's load method does.
			fprintf('- Calculating mirror settings...');
			
			% We refer to the compute method by its enumeration.  This lets us have
			% a standard way of referencing a compute method through the
			% OneLightToolbox.
			computeMethod = OLComputeMethods.Standard;
			
			cacheData = OLCache.compute(computeMethod, oneLightCal, targetSpds, lambda, false);
			fprintf('Done\n');
	end
end

% We want to save the spectra and mirror settings data if we're using the
% cache to make sure we update the cache file in case anything was
% recomputed.
if inputParams.UseCache && doCompute
	fprintf('- Saving cache file: %s\n', cacheFile);
	cache.save(cacheFile, cacheData, true);
end

% Pull out the settings to use below.
settings = cacheData.settings;

% Perform any post cache load operations.
switch lower(inputParams.StimType)
	% For the GaussianWindow stim type, we'll multiply the calculated mirror
	% settings by a Gaussian who's width is an integer multiple of the width of
	% a single cycle of mirror settings.  Note that this isn't they way you'd
	% want to do it if you wanted to make sure everything was calibrated.
	case 'gaussianwindow'
		if ~inputParams.ProcessOnly
			GaussianWindowWidth = abs(ceil(inputParams.GaussianWindowWidth));
			settings = repmat(settings, 1, GaussianWindowWidth);
			
			% Create the Gabor.
			windowSize = size(settings, 2);
			sig = round(windowSize * 0.15);
			gaborWindow = CustomGauss([1 windowSize], sig, sig, 0, 0, 1, [0 0]);
			gaborWindow = repmat(gaborWindow, ol.NumCols, 1);
			
			settings = settings .* gaborWindow;
			
			% Change the frequency to compensate for the fact we multiplied the
			% number of mirror settings.
			inputParams.Hz = inputParams.Hz / GaussianWindowWidth;
		end
end

% We will base the duration of each frame, i.e. length of time showing a
% particular set of mirrors, on the frequency, such that we will go through
% all the settings at the specified Hz value.
frameDurationSecs = 1 / inputParams.Hz / size(settings, 2);

% Here we specify how many iterations of the entire list of settings we
% want to go through.  Setting this to Inf has it go until a key is
% pressed.
numIterations = Inf;

if ~inputParams.ProcessOnly
	switch lower(inputParams.StimType)
		% The drift gabor/sine is interactive.
		case {'driftgabor', 'driftsine'}
			while true
				keyPress = OLFlicker(ol, settings, frameDurationSecs, numIterations);
				
				switch keyPress
					% Quit
					case 'q'
						break;
						
						% Reverse the direction.
					otherwise
						settings = fliplr(settings);
				end
			end
			
		otherwise
			% Do the flicker.
			keyPress = OLFlicker(ol, settings, frameDurationSecs, numIterations);
	end
end
