function OLWarmUpOOC(cal, ol, od, spectroRadiometerOBJ, meterToggle)

    nPrimaries = cal.describe.numWavelengthBands;
    nAverage = 1;
    
    theWarmUpSettings = zeros(nPrimaries, nPrimaries+1);
    warmUpStimIndex = 1;
    theWarmUpSettings(:,warmUpStimIndex) = ones(nPrimaries,1);
    for k = 1:nPrimaries
        warmUpStimIndex = warmUpStimIndex + 1;
        theWarmUpSettings(k,warmUpStimIndex) = 1;
    end
    
    warmUpStimIndex = 0; stimPresentations = 0;
    keepLooping = true; tic;
    while (keepLooping)
        % Present stimulus
        warmUpStimIndex = mod(warmUpStimIndex, size(theWarmUpSettings,2))+1;
        [starts,stops] = OLSettingsToStartsStops(cal,theWarmUpSettings(:,warmUpStimIndex));
        measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
        if (~isempty(measTemp.pr650))
            figure(1);
            plot(SToWls(cal.describe.S), measTemp.pr650.spectrum, 'k-');
            drawnow;
        end
        
        % Check for a keypress and act upon it
        key = mglGetKeyEvent;
        if (~isempty(key)) 
            switch key.keyCode
                % 'q', quit demo
                case 13
                    keepLooping = false; 
            end % switch
        else
            stimPresentations = stimPresentations + 1;
            fprintf('OneLight has been warming up for %2.1f minutes (%d stimuli). Enter q to exit the loop.\n', toc, stimPresentations);
            pause(0.2);
        end
    end  % whileKeepLooping
    fprintf('\n');
end

