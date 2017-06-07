function keyPress = OLFlicker(ol, starts, stops, frameDurationSecs, numIterations)
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

	% Send over the first settings.
    numSettings = size(starts, 1);
    if (size(stops,1) ~= numSettings)
        error('starts and stops matrices must have same number of rows');e
    end
	ol.setMirrors(starts(1,:), stops(1,:));
	
	% Counters to keep track of which of the settings to display and which
	% iteration we're on.
	iterationCount = 0;
	setCount = numSettings;
	
 
	
	t = zeros(1, 10000);
	i = 1;
	
	% Loop and flicker
    %
    % Start by initializing when we change the spectrum and then drop into 
    % the loop.
	theTimeToUpdateSpectrum = mglGetSecs + frameDurationSecs;
	while iterationCount < numIterations
        
        % Is it time to update spectrum yet?  If so, do it.  If not, carry
        % on.
		if mglGetSecs >= theTimeToUpdateSpectrum;
			t(i) = mglGetSecs;
			i = i + 1;

			% Update our settings counter.
			setCount = 1 + mod(setCount, numSettings);
                 			
			% Send over the new settings.
			ol.setMirrors(starts(setCount,:), stops(setCount,:));
			
			% If we've reached the end of the settings list, iterate the
			% counter that keeps track of how many times we've gone through
			% the list.
			if setCount == numSettings
				iterationCount = iterationCount + 1;
            end
            
            % Update the time of our next switch.
			theTimeToUpdateSpectrum = theTimeToUpdateSpectrum + frameDurationSecs;
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
