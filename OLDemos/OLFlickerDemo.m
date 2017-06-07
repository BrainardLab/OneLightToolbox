function OLFlickerDemo(varargin)
% OLFlickerDemo - Demonstrates how to flicker with the OneLight.
%
% Examples:
%   OLFlickerDemo
%   OLFlickerDemo('simulate',true);
%   OLFlickerDemo('useCache',false);
%
% Description:
% Demo that shows how to open the OneLight, use the cache, and flicker the
% light engine.  The cache let's us store precomputed spectra, primaries,
% and settings values so that they don't need to be computed everytime the
% program is run.  The cache system makes sure that the precomputed
% settings are in sync with the calibration file.  If the cache file
% doesn't exist, it will be created.
%
% Optional key/value pairs:
% 'useCache' (logical) - Toggles the use of the spectra cache.  Default: true
% 'stimType' (string) - Takes any of the following values: 'ShowSpectrum', 
%                       'BinaryFlicker', 'GaussianWindow', 'DriftGabor', 'DriftSine'.
% 'recompute' (logical) - Let's you force a recomputation of the spectra
%                         and rewrite the cache file.  Only useful if using the cache.
%                         Default: false
% 'processOnly' (logical) - If true, then the program doesn't communicate
%                           with the OneLight engine.  Default: false
% 'hz' (scalar) - The rate at which the program cycles through the set of
%                 spectra to display.  Default: 1
% 'GaussianWindowWidth' (scalar) - The number of cycles to window the set of
%                                  spectra in the 'GaussianWindow' stim type.
%                                  Default: 30.
% 'simulate' (logical) - Run in simulation mode? Default: false.
% 'nIterations' (scalar) - Number of interations of modulation to show.
%                          Inf means keep going until key press.
%                          Default: Inf
% 'lambda' (scalar) - Smoothing parameter for OLSpdToPrimary.  Default 0.1.

% 6/5/17  dhb  Add simulation mode with mb.

%% Parse input parameters.
p = inputParser;
p.addParameter('useCache', true, @islogical);
p.addParameter('stimType', 'ShowSpectrum', @isstr);
p.addParameter('recompute', false, @islogical);
p.addParameter('gaussianWindowWidth', 30, @isscalar);
p.addParameter('hz', 1, @isscalar);
p.addParameter('processOnly', false, @islogical);
p.addParameter('simulate', true, @islogical);
p.addParameter('nIterations', Inf, @isscalar);
p.addParameter('lambda', 0.1, @isscalar);
p.parse(varargin{:});
params = p.Results;

%% Select the cache file pased on the stim type.
%
% These are precomputed and are part of the demo.
switch lower(params.stimType)
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
		error('OLFlickerDemo:Invalid stim type "%s".', params.stimType);
end

%% Setup some program variables.
cacheDir = fullfile(fileparts(which('OLFlickerDemo')), 'cache');
calFileName = 'OneLight';

%% Create the OneLight object.
%
% Simulate if desired, and don't do it at all if this is running in process
% only mode.
if ~params.processOnly
	ol = OneLight('simulate',params.simulate);
end

%% Load the calibration file.  Need to point at a current calibration.
whichCalType = 'OLDemoCal';
oneLightCal = OLGetCalibrationStructure('CalibrationType',whichCalType,'CalibrationDate','latest');

%% Compute spectra if necessary or requested
doCompute = ~params.useCache;
if params.useCache
	% Create a cache object.  This object encapsulates the cache folder and
	% the actions we can take on the cache files.  We pass it the
	% calibration data so it can validate the cache files we want to load.
	cache = OLCache(cacheDir, oneLightCal);
	
	% Look to see if the cache file exists.
	cacheFileExists = cache.exist(cacheFile);
	
	% Load the cache file if it exists and we're not forcing a recompute of
	% the target spectra.
	if cacheFileExists && ~params.recompute
		% Load the cache file.  This function will check to make sure the
		% cache file is in sync with the calibration data we loaded above.
		cacheData = cache.load(cacheFile);
	else
		if params.recompute
			fprintf('- Manual recompute toggled.\n');
		else
			fprintf('- Cache file does not exist, will be computed and saved.\n');
		end
		doCompute = true;
        
        % Initalize the cacheData to be computed with the calibration
        % structure.
        clear cacheData;
        cacheData.cal = oneLightCal;
	end
end

%% Compute modulations if necessary
%
% We do this either because we need to recompute a stale cache file, or
% because we decided not to use cache files.
if doCompute
	% Specify the spectra depending on our stim type.
	switch lower(params.stimType)
		case {'binaryflicker', 'gaussianwindow', 'showspectrum'}
			switch lower(params.stimType)
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
			for i = 1:numSpectra
				fprintf('- Computing spectra %d of %d...', i, numSpectra);
				center = gaussCenters(i);
				targetSpds(:,i) = normpdf(oneLightCal.computed.pr650Wls, center, bandwidth)';
				
				% Find the scale factor that leads to the maximum relative targetSpd that is within
				% the OneLight's gamut.
				[~, scaleFactors(i), ~] = OLFindMaxSpectrum(oneLightCal, targetSpds(:,i), params.lambda, false);

				fprintf('Done\n');
			end
			
			% Find the smallest scale factor to apply to all the targetSPDs.
			minScaleFactor = min(scaleFactors);
			targetSpds = targetSpds * minScaleFactor;
			
			% Convert the spectra into gamma corrected mirror settings.  We use the
			% static OLCache method "compute" so that we guarantee we calculate the
			% cache in the same way that an OLCache object's load method does.
			fprintf('- Calculating primaries, settigns, starts/stops ...');
            [cacheData.settings, cacheData.primaries, cacheData.predictedSpds] = ...
                OLSpdToSettings(oneLightCal, targetSpds, 'lambda', params.lambda);
            [cacheData.starts,cacheData.stops] = OLSettingsToStartsStops(oneLightCal,cacheData.settings)
			fprintf('Done\n');
			
		case {'driftgabor', 'driftsine'}
			% Create the gaussian window.
			switch lower(params.stimType)
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
			for i = 1:numSteps
				fprintf('- Computing scale factors %d of %d...', i, numSteps);
				[~, scaleFactors(i), ~] = OLFindMaxSpectrum(oneLightCal, targetSpds(:,i), lambda, false);
				fprintf('Done\n');
			end
			
			% Find the smallest scale factor to apply to all the targetSPDs.
			minScaleFactor = min(scaleFactors);
			targetSpds = targetSpds * minScaleFactor;
			
			% Convert the spectra into gamma corrected mirror settings.  We use the
			% static OLCache method "compute" so that we guarantee we calculate the
			% cache in the same way that an OLCache object's load method does.
			fprintf('- Calculating primaries, settigns, starts/stops ...');
            [cacheData.settings, cacheData.primaries, cacheData.predictedSpds] = ...
                OLSpdToSettings(oneLightCal, targetSpds, 'lambda', params.lambda);
            [cacheData.starts,cacheData.stops] = OLSettingsToStartsStops(oneLightCal,cacheData.settings)
			fprintf('Done\n');
	end
end

%% Save cacheData to cache file if necessary
%
% By the time we get here, the structure cacheData has the primaries,
% settings and starts/stops for each modulation, computed with respect to
% the current calibration time.
%
% We want to save the spectra and mirror settings data if we're using the
% cache to make sure we update the cache file in case anything was
% recomputed.
if params.useCache && doCompute
	fprintf('- Saving cache file: %s\n', cacheFile);
	cache.save(cacheFile, cacheData);
end

% Pull out the settings to use below.
settings = cacheData.settings;

% Perform any post cache load operations.
switch lower(params.stimType)
	% For the GaussianWindow stim type, we'll multiply the calculated mirror
	% settings by a Gaussian who's width is an integer multiple of the width of
	% a single cycle of mirror settings.  Note that this isn't they way you'd
	% want to do it if you wanted to make sure everything was calibrated.
	case 'gaussianwindow'
		if ~params.processOnly
			gaussianWindowWidth = abs(ceil(params.gaussianWindowWidth));
			settings = repmat(settings, 1, gaussianWindowWidth);
			
			% Create the Gabor.
			windowSize = size(settings, 2);
			sig = round(windowSize * 0.15);
			gaborWindow = CustomGauss([1 windowSize], sig, sig, 0, 0, 1, [0 0]);
			gaborWindow = repmat(gaborWindow, size(settings,1), 1);
			%gaborWindow = repmat(gaborWindow, ol.NumCols, 1);
            
			settings = settings .* gaborWindow;
			
			% Change the frequency to compensate for the fact we multiplied the
			% number of mirror settings.
			params.hz = params.hz / gaussianWindowWidth;
		end
end

% We will base the duration of each frame, i.e. length of time showing a
% particular set of mirrors, on the frequency, such that we will go through
% all the settings at the specified hz value.
frameDurationSecs = 1 / params.hz / size(settings, 2);

%% Actually talk to the OneLight (or its simulated version)
if ~params.processOnly
	switch lower(params.stimType)
		% The drift gabor/sine is interactive.
		case {'driftgabor', 'driftsine'}
			while true
				keyPress = OLFlicker(ol, cacheData.starts, cacheData.stops, frameDurationSecs, params.nIterations);
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
			keyPress = OLFlicker(ol, cacheData.starts, cacheData.stops, frameDurationSecs, params.nIterations);
    end
    
    % Close the one light
    ol.close;
end
