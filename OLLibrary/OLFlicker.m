function keyPress = OLFlicker(ol, starts, stops, frameDurationSecs, numIterations)
% OLFlicker - Flickers the OneLight.
%
% Syntax:
%   keyPress = OLFlicker(ol, settings, frameDurationSecs, numIterations)
%
% Description:
%   Flickers the OneLight using the passed settings matrix until the number
%   of iterations is reached.  If numIterations is Inf, flickers until a
%   keypress.
%
% Input:
%   ol -                         The OneLight object.
%   starts (1024xN)-             The starts matrix
%   stops  (1024xN)-             The stops matrix.
%   frameDurationSecs (scalar) - The duration to hold each setting until the
%                                next one is loaded.
%   numIterations (scalar) -     The number of iterations to loop through the
%                                set of starts/stops.
%                                Passing Inf causes the function to loop forever.
%
%
% Output:
%   keyPress (char|empty) -      If numIterations is Inf, the key the user pressed
%                                to end the script is returned.  Otherwise, this
%                                is returend as empty.

% 6/28/17  dhb  Don't do any key related stuff unless keyboard is being checked.

% Checking keyboard?
checkKB = isinf(numIterations);

try	
	% Flag whether we're checking the keyboard during the flicker loop.
    if (checkKB)
        % Suppress keypresses going to the Matlab window.
        ListenChar(2);

        % Flush our keyboard queue.
        mglGetKeyEvent;
        keyPress = [];
    end

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
	
	% Loop and flicker
    %
    % Start by initializing when we change the spectrum and then drop into 
    % the loop.
	theTimeToUpdateSpectrum = mglGetSecs + frameDurationSecs;
	while iterationCount < numIterations
        
        % Is it time to update spectrum yet?  If so, do it.  If not, carry
        % on.
		if mglGetSecs >= theTimeToUpdateSpectrum;
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
    if checkKB
        ListenChar(0);
    end
catch e
    if checkKB
        ListenChar(0);
    end
	rethrow(e);
end
