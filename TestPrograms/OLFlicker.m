function keyPress = OLFlicker(ol, settings, frameDurationSecs, numIterations)
% OLFlicker - Flickers the OneLight.
%
% Syntax:
% keyPress = OLFlicker(ol, settings, frameDurationSecs, numIterations)
%
% Description:
% Flickers the OneLight using the passed settings matrix until a key is
% pressed or the number of iterations is reached.
%
% Input:
% ol (OneLight) - The OneLight object.
% settings (1024xN) - The normalized [0,1] mirror settings to loop through.
% frameDurationSecs (scalar) - The duration to hold each setting until the
%     next one is loaded.
% numIterations (scalar) - The number of iterations to loop through the
%     settings.  Passing Inf causes the function to loop forever.
%
% Output:
% keyPress (char|empty) - If in continuous mode, the key the user pressed
%     to end the script.  In regular mode, this will always be empty.

% We always use the same start mirrors (all zeros).
starts = zeros(1, ol.NumCols);

try
	% Suppress keypresses going to the Matlab window.
	ListenChar(2);
	
	% Flush our keyboard queue.
	mglGetKeyEvent;
	keyPress = [];
	
	% Flag whether we're checking the keyboard during the flicker loop.
	checkKB = isinf(numIterations);
	
	% Make sure our input and output pattern buffers are setup right.
	ol.InputPatternBuffer = 0;
	ol.OutputPatternBuffer = 0;
	
	% Convert the settings from [0,1] to [0,NumRows-1].
	settings = round(settings * (ol.NumRows-1));

	% Send over the first settings.
	ol.setMirrors(starts, settings(:,1));
	
	% Counters to keep track of which of the settings to display and which
	% iteration we're on.
	iterationCount = 0;
	setCount = 0;
	
	numSettings = size(settings, 2);
	
	t = zeros(1, 10000);
	i = 1;
	
	% This is the time of the settings change.  It gets updated everytime
	% we apply new mirror settings.
	mileStone = mglGetSecs + frameDurationSecs;
	
	while iterationCount < numIterations
		if mglGetSecs >= mileStone;
			t(i) = mglGetSecs;
			i = i + 1;
			
			% Update the time of our next switch.
			mileStone = mileStone + frameDurationSecs;

			% Update our settings counter.
			setCount = mod(setCount + 1, numSettings);
			
			% If we've reached the end of the settings list, iterate the
			% counter that keeps track of how many times we've gone through
			% the list.
			if setCount == 0
				iterationCount = iterationCount + 1;
			end
			
			% Send over the new settings.
			ol.setMirrors(starts, settings(:, setCount+1));
		end
		
		% If we're using keyboard mode, check for a keypress.
		if checkKB
			key = mglGetKeyEvent;
			
			% If a key was pressed, get the key and exit.
			if ~isempty(key)
				keyPress = key.charCode;
				break;
			end
		end
	end
	
	% Turn the mirrors off.
	ol.setAll(false);
	
	%plot(diff(t(1:(i-1))));
	
	ListenChar(0);
catch e
	ListenChar(0);
	rethrow(e);
end
