function timingData = OneLightFlickerTest(varargin)
% OneLightFlickerTest - Program to test flicker speed of the OneLight.
%
% Syntax:
% OneLightFlickerTest
% OneLightFlickerTest(options)
%
% Description:
% This program turns all mirrors off/on at an adjustable rate.  The goal is
% to determine how fast we can reliably control the mirrors.
%
% Input:
% options (key,value) - Key/value variable argument list.  See Options:
%     below.
%
% Options:
% FlickerRate (scalar) - Flicker rate (Hz).  Default: 5
%
% Examples:
% OneLightFlickerTest('FlickerRate', 10)

p = inputParser;
p.addParamValue('FlickerRate', 5);
p.addParamValue('Verbose', false);
p.addParamValue('FlickerType', 1);
p.parse(varargin{:});
params = p.Results;

% Open the OneLight device.
ol = OneLight;

% We'll use the same starts vector through the program.
starts = zeros(1, ol.NumCols);

% Flicker default in Hz.
params.FlickerRate;
timeDelta = 1 / params.FlickerRate / 2;

% Timing variables.
maxTimingVals = 10000;
timingData = zeros(1, maxTimingVals);

switch params.FlickerType
	case 1
		% Make the first buffer to be the off state.
		ol.InputPatternBuffer = 0;
		ol.OutputPatternBuffer = 0;
		ol.setAll(false);

		% Settings we want to flicker between.
		numSettings = 5;
		settings = zeros(numSettings, ol.NumCols);
		xOffset = linspace(-ol.NumCols/4, ol.NumCols/4, numSettings);
		for i = 1:numSettings
			settings(i,:) = round(CustomGauss([1 ol.NumCols], 100, 100, 0, 0, 1, [0 xOffset(i)]) * ol.NumRows);
		end

		% Set the second buffer to contain the on state.
		ol.InputPatternBuffer = 1;
		ol.setMirrors(starts, settings(1,:));
		
	case 2
		% Settings we want to flicker between.
		numSettings = 2;
		settings = zeros(numSettings, ol.NumCols);
		settings(2,:) = round(CustomGauss([1 ol.NumCols], 100, 100, 0, 0, 1, [0 0]) * ol.NumRows);
		
		% Set the initial output buffer.
		ol.InputPatternBuffer = 0;
		ol.OutputPatternBuffer = 0;
		ol.setMirrors(starts, settings(1,:));
	otherwise
		error('Invalid flicker type %d.\n', params.FlickerType);
end

% Use a running value to switch between the buffers.
bufferIndex = 0;

% Keeps track of which spectrum we're using.
settingsIndex = 0;

try
	% Suppress keypresses going to the Matlab window.
	ListenChar(2);
	
	% Flush our keyboard queue.
	mglGetKeyEvent;
	
	keepGoing = true;
	mileStone = mglGetSecs + timeDelta;
	while keepGoing
		% Look to see if we've passed a time milestone to change the mirror
		% state.
		currentTime = mglGetSecs;
		if currentTime >= mileStone;
			% Update the time of our next switch.
			mileStone = mileStone + timeDelta;
			
			bufferIndex = bufferIndex + 1;
			
			switch params.FlickerType
				case 1
					% Select which output pattern buffer to use.
					ol.OutputPatternBuffer = mod(bufferIndex, 2);
		
				case 2
					% Send over a new pattern.
					settingsIndex = mod(bufferIndex, numSettings) + 1;
					ol.setMirrors(starts, settings(settingsIndex,:));
			end
			
			% Store the switch time up to the first N values.
			if bufferIndex <= maxTimingVals
				timingData(bufferIndex) = currentTime;
			end
		end
		
		% Look for keypresses.
		key = mglGetKeyEvent;
		
		% If a key was pressed handle it.
		if ~isempty(key)
			switch (key.charCode)
				% Exit the program.
				case 'q'
					keepGoing = false;
					
					% Cut off unused timing data slots.
					if bufferIndex < maxTimingVals
						timingData = timingData(1:bufferIndex);
					end
					
				% Adjust the flicker rate.
				case 'f'
					ListenChar(1);
					params.FlickerRate = GetInput('New flicker rate (Hz)', 'number');
					ListenChar(2);
					timeDelta = 1 / params.FlickerRate / 2;
					
				% Switch to another spectrum.
				case 's'
					settingsIndex = settingsIndex + 1;
					settingsIndex = mod(settingsIndex, numSettings) + 1;
					ol.setMirrors(starts, settings(settingsIndex,:));
			end
		end
	end
	
	ListenChar(0);
catch e
	ListenChar(0);
	rethrow(e);
end
