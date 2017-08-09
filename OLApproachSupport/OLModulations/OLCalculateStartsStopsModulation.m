function modulation = OLCalculateStartsStopsModulation(waveformParams, cal, backgroundPrimary, diffPrimaryPos, diffPrimaryNeg)
%%OLCalculateStartsStopsModulation  Calculate various modulations given background and pos/neg primary differences.
%
% Usage:
%     modulation = OLCalculateStartsStopsModulation(waveformParams, cal, backgroundPrimary, diffPrimaryPos, diffPrimaryNeg)
%
% Description:
%     This programes takes the waveform parameters and turns them into
%     modulations.
%
%     This is called by OLReceptorIsolateMakeModulationStartsStops to make the starts/stops
%     that implement a particular modulation, for a specific choice of waveform parameters.
%
%     It looks like if diffPrimayNeg is empty, only the positive arm is used (i.e. to make a pulse).
%
% Input:
%
% Output:
%    modulation             Structure containing (among other things) the starts/stops matrices that produce the modulation.
%
% Optional key/value pairs.
%    None.
%
% See also: OLMakeModulationsStartsStops, OLReceptorIsolateMakeModulationStartsStops, OLModulationParamsDictionary.

% 7/21/17  dhb        Tried to improve comments.
% 8/09/17  dhb, mab   Compute pos/neg diff more flexibly. 

% Figure out the power levels.  The power levels (essentially a synonym for the
% contrast re max modulation given in the direction file) vary over time according
% to the desired waveform.  This routine first calculates the desired power level
% at each time point.
switch waveformParams.type
    case {'pulse'}
        % Set up power levels, first as a step pulse that goes to the desired
        % contrast.
        powerLevels = waveformParams.contrast*ones(size(waveformParams.t));
        
        % Then the half-cosine window if specified
        if (waveformParams.window.cosineWindowIn | waveformParams.window.cosineWindowOut);
            cosineWindow = ((cos(pi + linspace(0, 1, waveformParams.window.nWindowed)*pi)+1)/2);
            cosineWindowReverse = cosineWindow(end:-1:1);
        end
        if (waveformParams.window.cosineWindowIn)
            powerLevels(1:waveformParams.window.nWindowed) = waveformParams.contrast*cosineWindow;
        end
        if (waveformParams.window.cosineWindowOut)
            powerLevels(end-waveformParams.window.nWindowed+1:end) = waveformParams.contrast*cosineWindowReverse;
        end
        
    case 'sinusoid'
        powerLevels = waveformParams.contrast*sin(2*pi*waveformParams.frequency*waveformParams.t + (pi/180)*waveformParams.phaseDeg);
        
        % Then half-cosine window if specified
        if (waveformParams.window.cosineWindowIn | waveformParams.window.cosineWindowOut);
            cosineWindow = ((cos(pi + linspace(0, 1, waveformParams.window.nWindowed)*pi)+1)/2);
            cosineWindowReverse = cosineWindow(end:-1:1);
        end
        if (waveformParams.window.cosineWindowIn)
            powerLevels(1:waveformParams.window.nWindowed) = powerLevels*cosineWindow;
        end
        if (waveformParams.window.cosineWindowOut)
            powerLevels(end-waveformParams.window.nWindowed+1:end) = powerLevels*cosineWindowReverse;
        end
        
    case 'AM'
        error('Still need to update AM for modern code');
        % Probably, when this was called in the old days, the modulationWaveform field was set to 'sin', although we didn't go check it explicitly.
        % Hunt around in the modulation config files in the old OLFlickerSensitivity respository if you need to know.
        waveModulation = 0.5+0.5*sin(2*pi*waveformParams.theEnvelopeFrequencyHz*waveformParams.t - waveformParams.thePhaseRad);
        eval(['waveCarrier = waveformParams.contrast*' waveformParams.modulationWaveform '(2*pi*waveformParams.theFrequencyHz*waveformParams.t);']);
        powerLevels = waveModulation .* waveCarrier;
        
    case 'asym_duty'
        error('asym_duty type is not implemented and may never be again');
        eval(['powerLevels = waveformParams.contrast*' waveformParams.modulationWaveform '(2*pi*waveformParams.theFrequencyHz*waveformParams.t - waveformParams.thePhaseRad);']);
        powerLevels = powerLevels.*rectify(square(2*pi*waveformParams.theEnvelopeFrequencyHz*waveformParams.t, 2/3*100), 'half');
        
    otherwise
        error('Unknown waveform type specified');
end

%% Once the temporal waveform is computed above, most types can follow with a common set of code
%
% So this switch has fewer types than the one above.
switch waveformParams.type
    case {'pulse', 'sinusoid'}
        % Handle case of a pulse
 
        % Store parameters for return
        modulation.waveformParams = waveformParams;
        
        % Grab number of settings and the power levels over time.
        %
        % Note that nSettings is the same thing as the number of time
        % points.
        nSettings = length(waveformParams.t);
        modulation.powerLevels = powerLevels;
        
        % Allocate memory
        modulation.starts = zeros(nSettings, cal.describe.numColMirrors);
        modulation.stops = zeros(nSettings, cal.describe.numColMirrors);
        modulation.settings = zeros(length(backgroundPrimary),nSettings);
        modulation.primaries = zeros(length(backgroundPrimary),nSettings);
        
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
        % full power in the second.  And similarly for diffPrimaryNeg.
        %
        % Thus the matrix multiply expressed here creates a matrix with one column
        % for each time point, with the entries of the column giving the desired
        % primaries for that time point.
        %
        % We allow for asymmetric positive and negative excursions.
        index = find(powerLevels >= 0);
        if (~isempty(index))
            modulation.primaries(:,index) = [backgroundPrimary diffPrimaryPos]*w(:,index);
        end
        index = find(powerLevels < 0);
        if (~isempty(index))
            assert(~isempty(diffPrimaryNeg),'diffPrimaryNeg cannot be empty if there are negative power values');
            modulation.primaries(index,:) = [backgroundPrimary diffPrimaryNeg]*w(index,:);
        end
        
        % Make sure primaries are all within gamut.  If not, something has gone wrong and the
        % user needs to think about and fix it.
        if (any(modulation.primaries(:) < 0) | any(modulation.primaries(:) > 1))
            error('Primary value out of gamut. You need to look into why and fix it.');
        end
        
        % This next bit of code is designed to save us a little time.  For a pulse,
        % there are many time points where the primaries are the same, and it is
        % a little slow to compute settings and starts/stops.  So, we find the
        % the unique primaries values and only do the conversion to settings and
        % starts/stops we got back into all the places the go in the returned
        % matrices.  This might be too clever for words, but we think it is robuse.
        
        % Find the unique primary settings.  Note the two transposes because
        % unique operates along the rows. Note also (see the help text for unique)
        % that with this calling form modulation.primaries' = uniqPrimariesBuffer(IC,:);
        [uniqPrimariesBuffer, ~, IC] = unique(modulation.primaries', 'rows');
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
        modulation.settings = settingsBuffer(:, IC);
        modulation.starts = startsBuffer(IC,:);
        modulation.stops = stopsBuffer(IC,:);
        for ww = 1:size(modulation.primaries,2)
            modulation.spd(:,ww) = OLPrimaryToSpd(cal,modulation.primaries(:,ww));
        end
        
    case {'AM', 'asym_duty'}
        error('These cases are yet implemented');
        % Need to update usage for waveformParams and modulation, instead of just waveform
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
[modulation.background.starts, modulation.background.stops] = OLSettingsToStartsStops(cal, OLPrimaryToSettings(cal, backgroundPrimary));