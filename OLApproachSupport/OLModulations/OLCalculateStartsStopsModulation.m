function waveform = OLCalculateStartsStopsModulation(waveform, cal, backgroundPrimary, diffPrimaryPos, diffPrimaryNeg)
%% Pull out what we want
dbstop if error

% Figure out the power levels
switch waveform.modulationMode
    case {'pulse' 'pulsenoise'}
        powerLevels = zeros(size(waveform.t));
        pulseStartIndx = find(waveform.t == waveform.preStepTimeSec+waveform.phaseRandSec);
        pulseEndIndx = find(waveform.t == waveform.preStepTimeSec+waveform.phaseRandSec+waveform.stepTimeSec)-1;
        
        powerLevels(pulseStartIndx:pulseEndIndx) = waveform.theContrastRelMax;
        cosineWindow = ((cos(pi + linspace(0, 1, waveform.window.nWindowed)*pi)+1)/2);
        cosineWindowReverse = cosineWindow(end:-1:1);
        
        powerLevels(pulseStartIndx-waveform.window.nWindowed:pulseStartIndx-1) = waveform.theContrastRelMax*cosineWindow;
        powerLevels(pulseEndIndx+1:pulseEndIndx+waveform.window.nWindowed) = waveform.theContrastRelMax*cosineWindowReverse;
        
    case 'AM'
        waveModulation = 0.5+0.5*sin(2*pi*waveform.theEnvelopeFrequencyHz*waveform.t - waveform.thePhaseRad);
        eval(['waveCarrier = waveform.theContrastRelMax*' waveform.modulationWaveform '(2*pi*waveform.theFrequencyHz*waveform.t);']);
        powerLevels = waveModulation .* waveCarrier;
    case 'FM'
        eval(['powerLevels = waveform.theContrastRelMax*' waveform.modulationWaveform '(2*pi*waveform.theFrequencyHz*waveform.t - waveform.thePhaseRad);'])
    case 'asym_duty'
        eval(['powerLevels = waveform.theContrastRelMax*' waveform.modulationWaveform '(2*pi*waveform.theFrequencyHz*waveform.t - waveform.thePhaseRad);'])
        powerLevels = powerLevels.*rectify(square(2*pi*waveform.theEnvelopeFrequencyHz*waveform.t, 2/3*100), 'half');
end


switch waveform.modulationMode
    case {'pulse' 'pulsenoise'}
        nSettings = length(waveform.t);
        waveform.powerLevels = powerLevels;
        % Allocate memory
        waveform.starts = zeros(nSettings, cal.describe.numColMirrors);
        waveform.stops = zeros(nSettings, cal.describe.numColMirrors);
        waveform.settings = zeros(nSettings, length(backgroundPrimary));
        waveform.primaries = zeros(nSettings, length(backgroundPrimary));
        % Figure out the weight of the background and modulation primary
        w = [ones(1, nSettings) ; powerLevels];
        if strcmp(waveform.modulationMode, 'pulse')
            waveform.primaries = [backgroundPrimary diffPrimaryPos]*w;
        elseif strcmp(waveform.modulationMode, 'pulsenoise')
            waveform.primaries = [backgroundPrimary diffPrimaryPos]*w + waveform.noise.noisePrimary;
        end
        
        % Find the unique primary settings up to a tolerance value
        [uniqPrimariesBuffer, ~, IC] = unique(waveform.primaries', 'rows');
        uniqPrimariesBuffer = uniqPrimariesBuffer';
        
        % Convert the unique primaries to starts and stops
        settingsBuffer = OLPrimaryToSettings(cal, uniqPrimariesBuffer);
        for si = 1:size(settingsBuffer, 2)
            [startsBuffer(:, si), stopsBuffer(:, si)] = OLSettingsToStartsStops(cal, settingsBuffer(:, si));
        end
        waveform.settings = settingsBuffer(:, IC);
        waveform.starts = startsBuffer(:, IC);
        waveform.stops = stopsBuffer(:, IC);
        waveform.spd = (cal.computed.pr650M * waveform.primaries + repmat(cal.computed.pr650MeanDark, 1, size(waveform.primaries, 2)));
    otherwise
        if waveform.window.cosineWindowIn
            % Cosine window the modulation
            cosineWindow = ((cos(pi + linspace(0, 1, waveform.window.nWindowed)*pi)+1)/2);
            cosineWindowReverse = cosineWindow(end:-1:1);
            
            % Replacing vaalues
            powerLevels(1:waveform.window.nWindowed) = cosineWindow.*powerLevels(1:waveform.window.nWindowed);
        end
        
        if waveform.window.cosineWindowOut
            powerLevels(end-waveform.window.nWindowed+1:end) = cosineWindowReverse.*powerLevels(end-waveform.window.nWindowed+1:end);
        end
        
        nSettings = length(waveform.t);
        % If we have a frequency of 0 Hz, simply give back the
        % background, otherwise compute the appropriate modulation
        waveform.powerLevels = powerLevels;
        % Allocate memory
        waveform.starts = zeros(nSettings, cal.describe.numColMirrors);
        waveform.stops = zeros(nSettings, cal.describe.numColMirrors);
        waveform.settings = zeros(nSettings, length(backgroundPrimary));
        waveform.primaries = zeros(nSettings, length(backgroundPrimary));
        
        if waveform.theFrequencyHz == 0
            w = [ones(1, nSettings) ; zeros(1, nSettings)];
        else
            w = [ones(1, nSettings) ; powerLevels];
        end
        if isempty(diffPrimaryNeg)
            waveform.primaries = [backgroundPrimary diffPrimaryPos]*w;
        else
            posIdx = [find(sign(w(2, :)) == 0) find(sign(w(2, :)) == 1)];
            negIdx = find(sign(w(2, :)) == -1);
            tmp(:, posIdx) = [backgroundPrimary diffPrimaryPos]*w(:, posIdx);
            tmp(:, negIdx) = [backgroundPrimary -diffPrimaryNeg]*w(:, negIdx);
            waveform.primaries = tmp;
        end
        
        % Find the unique primary settings up to a tolerance value
        [uniqPrimariesBuffer, ~, IC] = unique(waveform.primaries', 'rows');
        uniqPrimariesBuffer = uniqPrimariesBuffer';
        
        % Convert the unique primaries to starts and stops
        settingsBuffer = OLPrimaryToSettings(cal, uniqPrimariesBuffer);
        for si = 1:size(settingsBuffer, 2)
            [startsBuffer(:, si), stopsBuffer(:, si)] = OLSettingsToStartsStops(cal, settingsBuffer(:, si));
        end
        waveform.settings = settingsBuffer(:, IC);
        waveform.starts = startsBuffer(:, IC);
        waveform.stops = stopsBuffer(:, IC);
        waveform.spd = (cal.computed.pr650M * waveform.primaries + repmat(cal.computed.pr650MeanDark, 1, size(waveform.primaries, 2)));
end
[waveform.background.starts, waveform.background.stops] = OLSettingsToStartsStops(cal, OLPrimaryToSettings(cal, backgroundPrimary));