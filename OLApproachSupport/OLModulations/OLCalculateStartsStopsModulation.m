function waveform = OLCalculateStartsStopsModulation(waveform, cal, backgroundPrimary, diffPrimaryPos, diffPrimaryNeg)
% OLCalculateStartsStopsModulation  Calculate various modulations given background and pos/neg primary differences.
%
% Usage:
%     waveform = OLCalculateStartsStopsModulation(waveform, cal, backgroundPrimary, diffPrimaryPos, diffPrimaryNeg)
%
% Description:
%     DHB NOTE: DESPARATELY SEEKING HEADER COMMENTS.
%
%     This is called by OLReceptorIsolateMakeModulationStartsStops to make the starts/stops
%     that implement a particular waveform, for a specific choice of waveform parameters.
%
%     It looks like if diffPrimayNeg is empty, only the positive arm is used (i.e. to make a pulse).
%
% Input:
%
% Output:
%
% Optional key/value pairs.
%    None.
%
% See also: OLMakeModulationsStartsStops, OLReceptorIsolateMakeModulationStartsStops, OLModulationParamsDictionary.

% 7/21/17  dhb  Tried to improve comments.

% Figure out the power levels.  The power levels (essentially a synonym for the
% contrast re max modulation given in the direction file) vary over time according
% to the desired waveform.  This routine first calculates the desired power level
% at each time point.
switch waveform.type
    case {'pulse'}
        % Set up power levels, first as a step pulse that goes to the desired
        % contrast.
        powerLevels = waveform.theContrastRelMax*ones(size(waveform.t));
        
        % Then window if specified
        if (waveform.window.cosineWindowIn | waveform.window.cosineWindowOut);
            cosineWindow = ((cos(pi + linspace(0, 1, waveform.window.nWindowed)*pi)+1)/2);
            cosineWindowReverse = cosineWindow(end:-1:1);
        end  
        if (waveform.window.cosineWindowIn)
            powerLevels(1:waveform.window.nWindowed) = waveform.theContrastRelMax*cosineWindow;
        end
        if (waveform.window.cosineWindowOut)
        	powerLevels(end-waveform.window.nWindowed+1:end) = waveform.theContrastRelMax*cosineWindowReverse; 
        end
        
    case 'AM'
        error('Still need to update AM for modern code');
        % Probably, when this was called in the old days, the modulationWaveform field was set to 'sin', although we didn't go check it explicitly.
        % Hunt around in the modulation config files in the old OLFlickerSensitivity respository if you need to know.
        waveModulation = 0.5+0.5*sin(2*pi*waveform.theEnvelopeFrequencyHz*waveform.t - waveform.thePhaseRad);
        eval(['waveCarrier = waveform.theContrastRelMax*' waveform.modulationWaveform '(2*pi*waveform.theFrequencyHz*waveform.t);']);
        powerLevels = waveModulation .* waveCarrier;
        
    case 'sinusoid'
        error('Still need to update sinusoid for for modern code');
        % When this was called in the old code, the modulationWaveform field was 'sin', so that the eval below produced a sinusoidal modulation.
        eval(['powerLevels = waveform.theContrastRelMax*' waveform.modulationWaveform '(2*pi*waveform.theFrequencyHz*waveform.t - waveform.thePhaseRad);']);
        
    case 'asym_duty'
        error('asym_duty type is not implemented and may never be again');
        eval(['powerLevels = waveform.theContrastRelMax*' waveform.modulationWaveform '(2*pi*waveform.theFrequencyHz*waveform.t - waveform.thePhaseRad);']);
        powerLevels = powerLevels.*rectify(square(2*pi*waveform.theEnvelopeFrequencyHz*waveform.t, 2/3*100), 'half');
        
    otherwise
        error('Unknown waveform type specified');
end


%% Once the temporal waveform is computed above, most types can follow with a common set of code
%
% So this switch has fewer types than the one above.
switch waveform.type
    case {'pulse'}
        % Handle case of a pulse
        
        % Grab number of settings and the power levels over time.
        %
        % Note that nSettings is the same thing as the number of time
        % points.
        nSettings = length(waveform.t);
        waveform.powerLevels = powerLevels;
        
        % Allocate memory
        waveform.starts = zeros(nSettings, cal.describe.numColMirrors);
        waveform.stops = zeros(nSettings, cal.describe.numColMirrors);
        waveform.settings = zeros(nSettings, length(backgroundPrimary));
        waveform.primaries = zeros(nSettings, length(backgroundPrimary));
        
        % Figure out the weight of the background and modulation primary
        % Use a little matrix algebra to add the weighted difference primary
        % to the background at each time point.
        %
        % This matrix w has the amount of the background and the amount of the
        % difference primary we want at each time.  Each column is for one time,
        % with 2 entries per column.  The number of columns is the number of time
        % points.
        w = [ones(1, nSettings) ; powerLevels];
        
        % The matrix [backgroundPrimary diffPrimaryPos] has the primary values
        % for the background in its first column and those for the difference at 
        % full power in the second.  
        %
        % Thus the matrix multiply expressed here creates a matrix with one column
        % for each time point, with the entries of the column giving the desired
        % primaries for that time point.
        waveform.primaries = [backgroundPrimary diffPrimaryPos]*w;
        
        % This next bit of code is designed to save us a little time.  For a pulse,
        % there are many time points where the primaries are the same, and it is 
        % a little slow to compute settings and starts/stops.  So, we find the
        % the unique primaries values and only do the conversion to settings and
        % starts/stops we got back into all the places the go in the returned
        % matrices.  This might be too clever for words, but we think it is robuse.

        % Find the unique primary settings.  Note the two transposes because
        % unique operates along the rows. Note also (see the help text for unique)
        % that with this calling form waveform.primaries' = uniqPrimariesBuffer(IC,:);
        [uniqPrimariesBuffer, ~, IC] = unique(waveform.primaries', 'rows');
        uniqPrimariesBuffer = uniqPrimariesBuffer';
        
        % Convert the unique primaries to starts and stops.  Primaries and settings are column
        % vectors (or in the columns of their matrices), while starts and stops live in the rows
        % The switch is handled inside of OLSettingsToStartsStops.  If you're curious, the logic
        % here is that primaries and settings are abstract quanties and by convention for DHB
        % this type of quantity always lives as a column.  But, starts and stops are OneLight
        % hardware dependent things and get passed as rows into the low-level OneLight routine.
        settingsBuffer = OLPrimaryToSettings(cal, uniqPrimariesBuffer);
        for si = 1:size(settingsBuffer, 2)
            [startsBuffer(si,:), stopsBuffer(si,:)] = OLSettingsToStartsStops(cal, settingsBuffer(:, si));
        end
        
        % Use IC to fill out the full return matrices, taking care with the various row/col conventions.
        waveform.settings = settingsBuffer(:, IC);
        waveform.starts = startsBuffer(IC,:);
        waveform.stops = stopsBuffer(IC,:);
        for ww = 1:size(waveform.primaries,2)
            waveform.spd(:,ww) = OLPrimaryToSpd(cal,waveform.primaries(:,ww));
        end
        
    case {'AM', 'sinusoid', 'asym_duty'}
        error('None of these cases are yet implemented');
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
            [startsBuffer(si,:), stopsBuffer(si,:)] = OLSettingsToStartsStops(cal, settingsBuffer(:, si));
        end
        waveform.settings = settingsBuffer(:, IC);
        waveform.starts = startsBuffer(IC,:);
        waveform.stops = stopsBuffer(IC,:);
        waveform.spd = (cal.computed.pr650M * waveform.primaries + repmat(cal.computed.pr650MeanDark, 1, size(waveform.primaries, 2)));
        
    otherwise
        error('Unknown modulation type specified');
end

%% Make the starts/stops for the background
[waveform.background.starts, waveform.background.stops] = OLSettingsToStartsStops(cal, OLPrimaryToSettings(cal, backgroundPrimary));