function OLCalibrateWithStateTrackingOOC
% OLCalibrateWithStateTrackingOOC - Calibrates the OneLight device, while
% tracking its state (power fluctuations and spectral shifts) 
%
% Syntax:
% OLCalibrateWithStateTrackingOOC
%
% Description:
% Calibrates a OneLight device using a PR-6xx radiometer aor the OneLight
% supplied spectrometer (OmniDriver) while tracking for changes in: 
%   (a) the total power emitted and the bulb, and
%   (b) spectral shifts of the bulb.
%
% 3/29/13  dhb  Added cautionary note about changing stepSize to not equal
%               bandWidth, and set it directly to be the same as bandWidth
%               to hammer home the point.
% 7/3/13   dhb  Save to OneLight subfolder.
%          dhb  Add describe.gammaNumberWlUseIndices field, specifies number of
%               wavelength bands around peak to use when computing gamma factors.
%               (Uses this many on either side of peak.)
% 1/19/14  dhb, ms  Cleaned up variable naming.
%          dhb, ms  Generalize gamma measurements so we can do arbitrary numbers of wavelength bands.
% 1/31/14  ms   Added saving out the time stamps.
% 2/16/14  dhb  Took stray variables that evenutally got assigned to cal.describe fields and consolidated
%               from the get go.
%          dhb  Got rid of independent step size variable for primary measurements.  This enforces that it is
%               always equal to the primary band width (number of columns per primary).
%          dhb  Started converting to use new OLSettingsToStartStops for all computation of starts/stops.
%               A side effect of this was to fix a bug where out of band mirrors were not all the way off
%               for some measurements.
% 2/17/14  dhb  All measurements get their starts/stops using
% OLSettingsToStartsStops.
%          dhb  Set calID to mglGetSecs. dhb  Put in save before init,
%                 temporarily, because the init is likely to crash until we fix it
%                 for new cal file.
% 7/20/14  ms   calID set with OLGetCalID. Save before init taken out.
% 4/9/16   dhb  Added in option to measure around a non-zero background.
%               Also did a little cleaning, which I hope doesn't break
%                 anything.
%               Remove blocks of commented out code. Uncomment debugging
%                 save before call to init, because there will probably be bugs.
% 4/15/16  npc  Adapted to use PR650dev/PR670dev objects
% 8/13/16  npc  Proceduralized all the measurement code
%               Added stimuli for tracking power fluctuations and spectral
%               shifts of the OneLight bulb

    spectroRadiometerOBJ = [];

    try
        % Ask which type of calibration we're doing.
        calTypes = enumeration('OLCalibrationTypes');
        while true
            fprintf('- Available calibration types:\n');

            for i = 1:length(calTypes)
                fprintf('%d: %s\n', i, calTypes(i).char);
            end

            x = GetInput('Selection', 'number', 1);
            if x >= 1 && x <= length(calTypes)
                break;
            end
        end
        selectedCalType = calTypes(x);
    
        if strfind(selectedCalType.char, 'BoxA')
            whichBox = 'BoxA';
        elseif strfind(selectedCalType.char, 'BoxB')
            whichBox = 'BoxB';
        elseif strfind(selectedCalType.char, 'BoxC')
            whichBox = 'BoxC';
        elseif strfind(selectedCalType.char, 'BoxD')
            whichBox = 'BoxD';
        end
    
        % Which box are we using?
        %
        % Some parameters need to be tuned for the box, particularly
        % those related to skipped bands and handling of gamma functions.
        % This is done with the box dependent switch here.
        fprintf('Using %s configuration\n', whichBox');
        switch (whichBox)
            case 'BoxA'
                cal.describe.gammaFitType = 'betacdfpiecelin';
                cal.describe.useAverageGamma = false;
                cal.describe.nShortPrimariesSkip = 7;
                cal.describe.nLongPrimariesSkip = 3;
                cal.describe.nGammaBands = 16;
            case 'BoxB'
                cal.describe.gammaFitType = 'betacdfpiecelin';
                cal.describe.useAverageGamma = false;
                cal.describe.nShortPrimariesSkip = 5;
                cal.describe.nLongPrimariesSkip = 3;
                cal.describe.nGammaBands = 16;
            case 'BoxC'
                cal.describe.gammaFitType = 'betacdfpiecelin';
                cal.describe.useAverageGamma = false;
                cal.describe.nShortPrimariesSkip = 8;
                cal.describe.nLongPrimariesSkip = 8;
                cal.describe.nGammaBands = 16;
            case 'BoxD'
                cal.describe.gammaFitType = 'betacdfpiecelin';
                cal.describe.useAverageGamma = true;
                cal.describe.nShortPrimariesSkip = 8;
                cal.describe.nLongPrimariesSkip = 2;
                cal.describe.nGammaBands = 16;
            otherwise
                error('Unknown OneLight box');
        end
        cal.describe.nGammaFitLevels = 1024;
    
        % Levels at which to measure the gamma function
        cal.describe.nGammaLevels = 4;
        
        % ------------------------------- TEMPORARY -----------------------
        %fprintf('During development we set gamma levels to 6 only so we can go faster.\n');
        %cal.describe.nGammaLevels = 6;
        % ------------------------------- TEMPORARY -----------------------
        
        
        % Randomize measurements. If this flag is set, the measurements
        % will be done in random order. We do this to counter systematic device
        % drift.
        cal.describe.randomizeGammaLevels = 1;
        cal.describe.randomizeGammaMeas = 1;
        cal.describe.randomizePrimaryMeas = 1;
    
        % Scaling factor correction. If this flag is set, we will scale every
        % measured spectrum according to the predicted decrease in power, given the
        % time of measurement.
        cal.describe.correctLinearDrift = 1;
    
        % Specify how often (every how many stimuli) to gauge the system state 
        % In other words when to insert the power fluctuation and the spectral
        % shift gauge stimuli
        cal.describe.stateTracking.calibrationStimInterval = 5;
        cal.describe.stateTracking.calibrationStimIndex = 0;
        cal.describe.stateTracking.stateMeasurementIndex = 0;
        
        % Non-zero background for gamma and related measurments
        cal.describe.specifiedBackground = 0;

        % Some code for debugging and quick checks.  These should generally all
        % be set to true.  If any are false, OLInitCal is not run.  You'll want
        % cal.describe.extraSave set to true when you have any of these set to
        % false.
        cal.describe.doPrimaries = true;
        cal.describe.doGamma = true;
        cal.describe.doIndependence = true;

        % Call save
        cal.describe.extraSave = false;
    
        % Don't use omni.
        % First entry is PR-6xx and is always true.
        % Second entry is omni is false.
        cal.describe.useOmni = false;
        meterToggle = [1 cal.describe.useOmni];
        od = [];
    
        % Enter bulb number.  This is a number that we assign by convention.
        cal.describe.bulbNumber = GetWithDefault('Enter bulb number',5);

        % Ask for email recipient
        emailRecipient = GetWithDefault('Send status email to','cottaris@psych.upenn.edu');
    
        % Ask which PR-6xx radiometer to use
        % Some parameters are radiometer dependent.
        cal.describe.meterType = GetWithDefault('Enter PR-6XX radiometer type','PR-670');
    
        switch (cal.describe.meterType)
            case 'PR-650',
                cal.describe.meterTypeNum = 1;
                cal.describe.S = [380 4 101];
                nAverage = 1;
                cal.describe.gammaNumberWlUseIndices = 3;

                % Instantiate a PR650 object
                spectroRadiometerOBJ  = PR650dev(...
                    'verbosity',        1, ...       % 1 -> minimum verbosity
                    'devicePortString', [] ...       % empty -> automatic port detection)
                    );
                spectroRadiometerOBJ.setOptions('syncMode', 'OFF');

            case 'PR-670',
                cal.describe.meterTypeNum = 5;
                cal.describe.S = [380 2 201];
                nAverage = 1;
                cal.describe.gammaNumberWlUseIndices = 5;

                % Instantiate a PR670 object
                spectroRadiometerOBJ  = PR670dev(...
                    'verbosity',        1, ...       % 1 -> minimum verbosity
                    'devicePortString', [] ...       % empty -> automatic port detection)
                    );

                % Set options Options available for PR670:
                spectroRadiometerOBJ.setOptions(...
                    'verbosity',        1, ...
                    'syncMode',         'OFF', ...      % choose from 'OFF', 'AUTO', [20 400];
                    'cyclesToAverage',  1, ...          % choose any integer in range [1 99]
                    'sensitivityMode',  'STANDARD', ... % choose between 'STANDARD' and 'EXTENDED'.  'STANDARD': (exposure range: 6 - 6,000 msec, 'EXTENDED': exposure range: 6 - 30,000 msec
                    'exposureTime',     'ADAPTIVE', ... % choose between 'ADAPTIVE' (for adaptive exposure), or a value in the range [6 6000] for 'STANDARD' sensitivity mode, or a value in the range [6 30000] for the 'EXTENDED' sensitivity mode
                    'apertureSize',     '1 DEG' ...   % choose between '1 DEG', '1/2 DEG', '1/4 DEG', '1/8 DEG'
                    );

            otherwise,
                error('Unknown meter type');
        end
    
        % Open the OneLight device.
        ol = OneLight;
    
        % Get the number of rows and columns
        cal.describe.numRowMirrors = ol.NumRows;
        cal.describe.numColMirrors = ol.NumCols;
    
        % Definition of effective primaries, in terms of chip columns.
        % We can skip a specified number of primaries at the beginning and end
        cal.describe.bandWidth = 16;
        if (rem(ol.NumCols,cal.describe.bandWidth) ~= 0)
            error('We want bandWidth to divide number of columns exactly');
        end
        if (rem(ol.NumRows,cal.describe.nGammaLevels) ~= 0)
            error('We want nGammaLevels to divide number of rows exactly');
        end
    
        % Calculate the start columns for each effective primary. These are
        % indexed MATLAB style, 1:numCols.
        cal.describe.primaryStartCols = 1 + (cal.describe.nShortPrimariesSkip*cal.describe.bandWidth:cal.describe.bandWidth:(ol.NumCols - (cal.describe.nLongPrimariesSkip+1)*cal.describe.bandWidth));
        cal.describe.primaryStopCols = cal.describe.primaryStartCols + cal.describe.bandWidth-1;
        cal.describe.numWavelengthBands = length(cal.describe.primaryStartCols);
        nPrimaries = cal.describe.numWavelengthBands;

        % Specify specified background, if desired.  This could be customized
        % for the box or experiment, if it seems promising to do so.
        %
        % At present, this uses a half on background in settings space.
        if (cal.describe.specifiedBackground)
            cal.describe.specifiedBackgroundSettings = 0.5*ones(nPrimaries,1);
        end
    
        % Define the state tracking stimulus settings
        cal.describe.stateTracking.stimSettings.powerFluctuationsStim = ones(nPrimaries,1);
        cal.describe.stateTracking.stimSettings.spectralShiftsStim = zeros(nPrimaries,1);
        cal.describe.stateTracking.stimSettings.spectralShiftsStim(2:10:end) = 1.0;
        

        % Find and set the optimal integration time.  Subtract off a couple
        % thousand microseconds just to give it a conservative value.
        ol.setAll(true);

        % Ask for a keypress to continue.
        input(sprintf('<strong>Press return to pause 10s then continue with the calibration</strong>\n'));
        pause(10);
        tic;
        startCal = GetSecs;

        % Depending on cables and light levels, the args to od.findIntegrationTime may
        % need to be fussed with a little.
        ol.setAll(false);
    
        fprintf('\n<strong>Initial measurements of spectra of interest</strong>\n\n');

        % Take a full on measurement.
        fullMeasurementIndex = 1;
        cal = TakeFullOnMeasurement(fullMeasurementIndex, cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
    
        % Take a half on measurement.
        halfOnMeasurementIndex = 1;
        cal = TakeHalfOnMeasurement(halfOnMeasurementIndex, cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
       
        % Take a wiggly measurement
        wigglyMeasurementIndex = 1;
        cal = TakeWigglyMeasurement(wigglyMeasurementIndex, cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
    
        % Take a dark measurement
        darkMeasurementIndex = 1;
        cal = TakeDarkMeasurement(darkMeasurementIndex, cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
        
    
        % Take a specified background measurement, if desired
        if (cal.describe.specifiedBackground)
            specifiedBackgroundMeasurementIndex = 1;
            cal = TakeSpecifiedBackgroundMeasurement(specifiedBackgroundMeasurementIndex, cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
        end
        
    
        % Primary measurements.
        %
        % it is not clear to me (DHB, 4/9/16) why these are first stored in a
        % structure indexed by primary and then popped into matrix form in the
        % calibration structure.  As far as I can tell, the structure is never
        % used except to put the data in to the matrix.  This may be a vestigal
        % feature, but I am not going to change it right now.
        if (cal.describe.doPrimaries)
            fprintf('\n<strong>Measure spectra of effective primaries</strong>\n\n');
        
            % If needed, shuffle the primary measurements.
            if cal.describe.randomizePrimaryMeas
                primaryMeasIter = Shuffle(1:length(cal.describe.primaryStartCols));
            else
                primaryMeasIter = 1:length(cal.describe.primaryStartCols);
            end
            
            for primaryIndex = primaryMeasIter
                [cal, wavelengthBandMeasurements(primaryIndex)] = TakePrimaryMeasurement(cal, primaryIndex, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
            end
        
            % Refactor the measurements into separate matrices for further calculations.
            if (cal.describe.numWavelengthBands ~= length(wavelengthBandMeasurements))
                error('We did not understand what we thought was an identity when we edited the code');
            end
            cal.raw.lightMeas = zeros(cal.describe.S(3), cal.describe.numWavelengthBands);
            cal.raw.cols = zeros(ol.NumCols, cal.describe.numWavelengthBands);
            for i = 1:cal.describe.numWavelengthBands
                if (cal.describe.specifiedBackground)
                    cal.raw.effectiveBgMeas(:,i) = wavelengthBandMeasurements(i).effectiveBackgroundSpectrum;
                    cal.raw.t.effectiveBgMeas(i) = wavelengthBandMeasurements(i).effectiveBackgroundTime;
                    if (meterToggle(2))
                        cal.raw.omniDriver.effectiveBgMeas(:,i) = wavelengthBandMeasurements(i).effectiveBackgroundSpectrumOD;
                    end
                end

                % Store the spectrum for this measurement.
                cal.raw.lightMeas(:,i) = wavelengthBandMeasurements(i).lightSpectrum;
                cal.raw.t.lightMeas(i) = wavelengthBandMeasurements(i).time;

                % Store which columns were on for this measurement.
                cal.raw.cols(:,i) = zeros(ol.NumCols, 1);
                e = wavelengthBandMeasurements(i).bandRange;
                cal.raw.cols(e(1):e(2),i) = 1;
                if (e(1) ~= cal.describe.primaryStartCols(i) || e(2) ~= cal.describe.primaryStopCols(i))
                    error('Inconsistency in various primary column descriptors');
                end
            end
        end  % if (cal.describe.doPrimaries)
    

        % Store some measurement parameters.
        cal.describe.durationMinutes = (GetSecs - startCal)/60;
        cal.describe.date = datestr(now);
    
        % Gamma measurements.
        %
        % We do this for cal.describe.nGammaBands of the bands, at
        % cal.describe.nGammaLevels for each band.
        if (cal.describe.doGamma)
            fprintf('\n<strong>Gamma measurements</strong>\n\n');
        
            cal.describe.gamma.gammaBands = round(linspace(1,cal.describe.numWavelengthBands,cal.describe.nGammaBands));
            cal.describe.gamma.gammaLevels = linspace(1/cal.describe.nGammaLevels,1,cal.describe.nGammaLevels);
        
            % Allocate some memory.
            cal.raw.gamma.cols = zeros(ol.NumCols, cal.describe.nGammaBands);
        
            % Make gamma measurements for each band
            if cal.describe.randomizeGammaMeas
                gammaMeasIter = Shuffle(1:cal.describe.nGammaBands);
            else
                gammaMeasIter = 1:cal.describe.nGammaBands;
            end
        
            for gammaBandIndex = gammaMeasIter
                cal = TakeGammaMeasurements(cal, gammaBandIndex, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
            end
        end  % if (cal.describe.doGamma)
    

        % Now we'll do an independence test on the same column sets from the
        % gamma measurements.  Even when we use an effective background for
        % calibration, we do this test around a dark background.  This could
        % be modified with a little thought.
        if (cal.describe.doIndependence)
            % Set some parameters which we don't have if we just do the independence measurements
            if ~(cal.describe.doGamma)
                cal.describe.gamma.gammaBands = round(linspace(1,cal.describe.numWavelengthBands,cal.describe.nGammaBands));
                cal.describe.gamma.gammaLevels = linspace(1/cal.describe.nGammaLevels,1,cal.describe.nGammaLevels);
            end
        
            if ~(cal.describe.doPrimaries)
                % If needed, shuffle the primary measurements.
                if cal.describe.randomizePrimaryMeas
                    primaryMeasIter = Shuffle(1:length(cal.describe.primaryStartCols));
                else
                    primaryMeasIter = 1:length(cal.describe.primaryStartCols);
                end
                for i = primaryMeasIter
                    % Record the band start and end.
                    wavelengthBandMeasurements(i).bandRange = [cal.describe.primaryStartCols(i), cal.describe.primaryStopCols(i)]; %#ok<*AGROW>
                end
                
                for i = 1:cal.describe.numWavelengthBands
                    % Store which columns were on for this measurement.
                    cal.raw.cols(:,i) = zeros(ol.NumCols, 1);
                    e = wavelengthBandMeasurements(i).bandRange;
                    cal.raw.cols(e(1):e(2),i) = 1;
                end
            end % if ~(cal.describe.doPrimaries)
        
            cal = TakeIndependenceMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
        end
    
        % Take a specified background measurement at the end, if desired
        if (cal.describe.specifiedBackground)
            specifiedBackgroundMeasurementIndex = size(cal.raw.specifiedBackgroundMeas,2) + 1;
            cal = TakeSpecifiedBackgroundMeasurement(specifiedBackgroundMeasurementIndex, cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
        end
    
        % Take another dark measurement
        darkMeasurementIndex = size(cal.raw.darkMeas,2)+1;
        cal = TakeDarkMeasurement(darkMeasurementIndex, cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
        
        % Take another wiggly measurement.
        wigglyMeasurementIndex = size(cal.raw.wigglyMeas.measSpd,2)+1;
        cal = TakeWigglyMeasurement(wigglyMeasurementIndex, cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
        
        % Take another half on measurement.
        halfOnMeasurementIndex = size(cal.raw.halfOnMeas,2)+1;
        cal = TakeHalfOnMeasurement(halfOnMeasurementIndex, cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
        
        % Take another full on measurement.
        fullMeasurementIndex = size(cal.raw.fullOn,2)+1;
        cal = TakeFullOnMeasurement(fullMeasurementIndex, cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
    
        % Take a final set of state measurements
        cal = TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
    
        
        % Store the type of calibration and unique calibration ID
        cal.describe.calType = selectedCalType;
        cal.describe.calID = OLGetCalID(cal);
    
        % Save the calibration file.
        %
        % We do this while we are developing new code, so that
        % if the subsquent OLInitAndSaveCal crashes we still have
        % the data.  But now that things are stable, we have
        % commented out this initial save so that we don't get the
        % annoying double saves in the calibration files.
        if (cal.describe.extraSave)
            oneLightCalSubdir = 'OneLight';
            SaveCalFile(cal, fullfile(oneLightCalSubdir,selectedCalType.CalFileName));
        end
    
        % Run the calibration file through the initialization process.  This
        % loads up the data with a bunch of computed information found in the
        % computed subfield of the structure.  Only do this if we did full
        % calibration, since otherwise OLInitCal will barf.
        if (all([cal.describe.doPrimaries cal.describe.doGamma cal.describe.doIndependence]))
            cal = OLInitCal(cal);

            % Save out the calibration
            oneLightCalSubdir = 'OneLight';
            SaveCalFile(cal, fullfile(oneLightCalSubdir,selectedCalType.CalFileName));
        end
    
        % Notify user we are done
        fprintf('\n<strong>Calibration Complete</strong>\n\n');

        % Shutdown the PR670/650
        spectroRadiometerOBJ.shutDown();
        
        % Send email that we are done
        SendEmail(emailRecipient, 'OneLight Calibration Complete', ...
            'Finished!');
    catch e
        fprintf('Failed with message: ''%s''.\nPlease wait for the spectroradiometer to shut down .... ', e.message);
        if (~isempty(spectroRadiometerOBJ))
            spectroRadiometerOBJ.shutDown();
        end
        SendEmail(emailRecipient, 'OneLight Calibration Failed', ...
            ['Calibration failed with the following error' 10 e.message]);
        keyboard;
        rethrow(e);
    end

end

function cal = TakeStateMeasurements(cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage)
    cal = cal0;
    cal.describe.stateTracking.stateMeasurementIndex = cal.describe.stateTracking.stateMeasurementIndex + 1;

    fprintf('-- Power fluctuation state measurement #%d ...', cal.describe.stateTracking.stateMeasurementIndex);
    theSettings = cal.describe.stateTracking.stimSettings.powerFluctuationsStim;
    [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
    measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
    cal.raw.powerFluctuationMeas.measSpd(:, cal.describe.stateTracking.stateMeasurementIndex) = measTemp.pr650.spectrum;
    cal.raw.powerFluctuationMeas.t(:, cal.describe.stateTracking.stateMeasurementIndex) = measTemp.pr650.time(1);
    fprintf('Done\n');

    fprintf('-- Spectral shift state measurement #%d    ...', cal.describe.stateTracking.stateMeasurementIndex);
    theSettings = cal.describe.stateTracking.stimSettings.spectralShiftsStim;
    [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
    measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
    cal.raw.spectralShiftsMeas.measSpd(:, cal.describe.stateTracking.stateMeasurementIndex) = measTemp.pr650.spectrum;
    cal.raw.spectralShiftsMeas.t(:, cal.describe.stateTracking.stateMeasurementIndex) = measTemp.pr650.time(1);
    fprintf('Done\n');
end

function cal = TakeIndependenceMeasurements(cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage)

    cal = cal0;
    nPrimaries = cal.describe.numWavelengthBands;
    
    fprintf('\n<strong>Independence Test</strong>\n\n');  
    % Store some measurement data regarding the independence test.
    cal.describe.independence.gammaBands = cal.describe.gamma.gammaBands;
    cal.describe.independence.nGammaBands = cal.describe.nGammaBands;
    cal.raw.independence.cols = zeros(ol.NumCols, cal.describe.nGammaBands);
    
    % Test column sets individually
    for i = 1:cal.describe.independence.nGammaBands
        
        % See if we need to take a new set of state measurements
        if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
            cal = TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
        end
        % Update calibration stim index
        cal.describe.stateTracking.calibrationStimIndex = cal.describe.stateTracking.calibrationStimIndex + 1;
        
        fprintf('- Measurement #%d: column set %d of %d ...', cal.describe.stateTracking.calibrationStimIndex, i, cal.describe.independence.nGammaBands);
  
        % Store column set used for this measurement.
        cal.raw.independence.cols(:,i) = cal.raw.cols(:,cal.describe.independence.gammaBands(i));

        % Take a measurement.
        if (cal.describe.specifiedBackground)
            theSettings = zeros(nPrimaries,1);
        else
            theSettings = zeros(nPrimaries,1);
        end
        theSettings(cal.describe.independence.gammaBands(i)) = 1;
        [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
        measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
        cal.raw.independence.meas(:,i) = measTemp.pr650.spectrum;
        cal.raw.t.independence.meas(i) = measTemp.pr650.time(1);
        if (meterToggle(2))
            cal.raw.independence.measOD(:,i) = measTemp.omni.spectrum;
        end
        fprintf('Done\n');
    end
        

    % See if we need to take a new set of state measurements
    if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
        cal = TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
    end
    % Update calibration stim index
    cal.describe.stateTracking.calibrationStimIndex = cal.describe.stateTracking.calibrationStimIndex + 1;
        
    % Now take a cumulative measurement.
    fprintf('- Measurement #%d: cumulative column sets ...', cal.describe.stateTracking.calibrationStimIndex);
  
    cal.raw.independence.colsAll = sum(cal.raw.independence.cols, 2);
    if (cal.describe.specifiedBackground)
        theSettings = zeros(nPrimaries,1);
    else
        theSettings = zeros(nPrimaries,1);
    end
    for i = 1:cal.describe.independence.nGammaBands
        theSettings(cal.describe.independence.gammaBands(i)) = 1;
    end
    [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
    measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
    cal.raw.independence.measAll = measTemp.pr650.spectrum;
    cal.raw.t.independence.measAll = measTemp.pr650.time(1);
    if (meterToggle(2))
        cal.raw.independence.measODAll = measTemp.omni.spectrum;
    end
    fprintf('Done\n');
        
end

function cal = TakeGammaMeasurements(cal0, gammaBandIndex, ol, od, spectroRadiometerOBJ, meterToggle, nAverage)

    cal = cal0;
    nPrimaries = cal.describe.numWavelengthBands;
    
    fprintf('\n<strong>Gamma measurements on gamma band set %d of %d</strong>\n\n', gammaBandIndex , cal.describe.nGammaBands);
    
    % Store the columns used for this set.
    cal.raw.gamma.cols(:,gammaBandIndex ) = cal.raw.cols(:,cal.describe.gamma.gammaBands(gammaBandIndex ));
    % Allocate memory for the recorded spectra.
    cal.raw.gamma.rad(gammaBandIndex ).meas = zeros(cal.describe.S(3), cal.describe.nGammaLevels);
            
    % Test each gamma level for this band. If the gamma randomization
    % flag is set, shuffle now. We are still storing the measurements
    % in the right order as expected.
    if cal.describe.randomizeGammaLevels
        gammaLevelsIter = Shuffle(1:cal.describe.nGammaLevels);
    else
        gammaLevelsIter = 1:cal.describe.nGammaLevels;
    end
            
    % If we're specifying the background, we need a measurement of that
    % background but with the settings for the specified gamma band set
    % to zero.  This is then used to subtract off the background from
    % the series of gamma measurements, rather than using the omnibus
    % dark level measurement.
    if (cal.describe.specifiedBackground)
        
        % See if we need to take a new set of state measurements
        if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
            cal = TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
        end
        % Update calibration stim index
        cal.describe.stateTracking.calibrationStimIndex = cal.describe.stateTracking.calibrationStimIndex + 1;
    

        fprintf('- Measurement #%d: effective background for gamma band: %d ...', cal.describe.stateTracking.calibrationStimIndex, gammaBandIndex);
  
        % Why are we not using theSettings, below? Maybe a bug?
        theSettings = GetEffectiveBackgroundSettingsForPrimary(cal.describe.gamma.gammaBands(gammaBandIndex),cal.describe.specifiedBackgroundSettings);
        [starts,stops] = OLSettingsToStartsStops(cal,cal.describe.specifiedBackgroundSettings);
        
        measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
        cal.raw.gamma.rad(gammaBandIndex).effectiveBgMeas = measTemp.pr650.spectrum;
        cal.raw.t.gamma.rad(gammaBandIndex).effectiveBgMeas(gammaBandIndex) = measTemp.pr650.time(1);
        if (meterToggle(2))
            cal.raw.gamma.omniDriver(gammaBandIndex).effectiveBgMeas = measTemp.omni.spectrum;
        end
        fprintf('Done\n');
    end
           
    for gammaLevelIndex = gammaLevelsIter
        
        % See if we need to take a new set of state measurements
        if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
            cal = TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
        end
        % Update calibration stim index
        cal.describe.stateTracking.calibrationStimIndex = cal.describe.stateTracking.calibrationStimIndex + 1;
    
        fprintf('- Measurement #%d: gamma level %d of %d for gamma band: %d ...', cal.describe.stateTracking.calibrationStimIndex, gammaLevelIndex, cal.describe.nGammaLevels,gammaBandIndex);
  
        % Set the starts/stops, measure, and store
        if (cal.describe.specifiedBackground)
            theSettings = GetEffectiveBackgroundSettingsForPrimary(cal.describe.gamma.gammaBands(gammaBandIndex),cal.describe.specifiedBackgroundSettings);
        else
            theSettings = zeros(nPrimaries,1);
        end
        theSettings(cal.describe.gamma.gammaBands(gammaBandIndex)) = cal.describe.gamma.gammaLevels(gammaLevelIndex);
        [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
        measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
        cal.raw.gamma.rad(gammaBandIndex).meas(:,gammaLevelIndex) = measTemp.pr650.spectrum;
        cal.raw.t.gamma.rad(gammaBandIndex).meas(gammaLevelIndex) = measTemp.pr650.time(1);
        if (meterToggle(2))
            cal.raw.gamma.omnidriver(gammaBandIndex).meas(:,gammaLevelIndex) = measTemp.omni.spectrum;
        end
        fprintf('Done\n');
    end
            
end
    
function [cal, primaryMeasurement] = TakePrimaryMeasurement(cal0, primaryIndex, ol, od, spectroRadiometerOBJ, meterToggle, nAverage)

    cal = cal0;
    nPrimaries = cal.describe.numWavelengthBands;
    
    % Record the band start and end.
    primaryMeasurement.bandRange = [cal.describe.primaryStartCols(primaryIndex), cal.describe.primaryStopCols(primaryIndex)];
    
    % If we are using a specified background, we need to measure for all
    % primaries except the one being characterized at the specified
    % level. (If not, we just use the dark measurement for this
    % purpose.  Which is used to produce the actual calibration data is
    % handled when we post-process the measurements.)
    if (cal.describe.specifiedBackground)
        
        % See if we need to take a new set of state measurements
        if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
            cal = TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
        end
        % Update calibration stim index
        cal.describe.stateTracking.calibrationStimIndex = cal.describe.stateTracking.calibrationStimIndex + 1;
    
        
        fprintf('- Measurement #%d: effective background for effective primary %d ...', cal.describe.stateTracking.calibrationStimIndex, primaryIndex);
  
        % Why are we not using theSettings, below? Maybe a bug?
        theSettings = GetEffectiveBackgroundSettingsForPrimary(primaryIndex,cal.describe.specifiedBackgroundSettings);
        [starts,stops] = OLSettingsToStartsStops(cal,cal.describe.specifiedBackgroundSettings);
        
        measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
        primaryMeasurement.effectiveBackgroundSpectrum = measTemp.pr650.spectrum;
        primaryMeasurement.effectiveBackgroundTime = measTemp.pr650.time(1);
        if (meterToggle(2))
            primaryMeasurement.effectiveBackgroundSpectrumOD = measTemp.omni.spectrum;
        end
        fprintf('Done\n');
    end
    
    % See if we need to take a new set of state measurements
    if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
        cal = TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
    end
    % Update calibration stim index
    cal.describe.stateTracking.calibrationStimIndex = cal.describe.stateTracking.calibrationStimIndex + 1;
    
    % Set the starts/stops for this effective primary, relative to the
    % measurement background, and take the measurement.
    fprintf('- Measurement #%d: effective primary %d of %d...', cal.describe.stateTracking.calibrationStimIndex, primaryIndex, length(cal.describe.primaryStartCols));
    if (cal.describe.specifiedBackground)
        theSettings = GetEffectiveBackgroundSettingsForPrimary(primaryIndex,cal.describe.specifiedBackgroundSettings);
    else
        theSettings = zeros(nPrimaries,1);
    end
    theSettings(primaryIndex) = 1;
    [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
    measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
    primaryMeasurement.lightSpectrum = measTemp.pr650.spectrum;
    primaryMeasurement.time = measTemp.pr650.time(1);
    if (meterToggle(2))
        primaryMeasurement.lightSpectrumOD = measTemp.omni.spectrum;
    end
    fprintf('Done\n');
          
end

function cal = TakeSpecifiedBackgroundMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage)
    % Take a spcecified background measurement
    cal = cal0;
    fprintf('- Measurement #%d: specified background ...', cal.describe.stateTracking.calibrationStimIndex);
  
    % See if we need to take a new set of state measurements
    if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
        cal = TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
    end
    % Update calibration stim index
    cal.describe.stateTracking.calibrationStimIndex = cal.describe.stateTracking.calibrationStimIndex + 1;
    
    theSettings = cal.describe.specifiedBackgroundSettings;
    [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
    measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
    cal.raw.specifiedBackgroundMeas(:,measurementIndex) = measTemp.pr650.spectrum;
    cal.raw.t.specifiedBackgroundMeas(:,measurementIndex) = measTemp.pr650.time(1);
    if (meterToggle(2))
        cal.raw.omniDriver.specifiedBackgroundMeas(:,measurementIndex) = measTemp.omni.spectrum;
    end
    fprintf('Done\n');
        
end


function cal = TakeDarkMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage)
    % Take a dark measurement at the end.  Use special case provided by OLSettingsToStartsStops that turns all mirrors off.
    cal = cal0;
    nPrimaries = cal.describe.numWavelengthBands;
    
    % See if we need to take a new set of state measurements
    if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
        cal = TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
    end
    % Update calibration stim index
    cal.describe.stateTracking.calibrationStimIndex = cal.describe.stateTracking.calibrationStimIndex + 1;
    
    fprintf('- Measurement #%d: Dark...', cal.describe.stateTracking.calibrationStimIndex);
    spectroRadiometerOBJ.setOptions('sensitivityMode', 'EXTENDED');
    theSettings = 0*ones(nPrimaries,1);
    [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
    measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
    cal.raw.darkMeas(:,measurementIndex) = measTemp.pr650.spectrum;
    cal.raw.t.darkMeas(:,measurementIndex) = measTemp.pr650.time(1);
    if (meterToggle(2))
        cal.raw.omniDriver.darkMeas(:,measurementIndex) = measTemp.omni.spectrum;
    end
    fprintf('Done\n');
    
    % See if we need to take a new set of state measurements
    if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
        cal = TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
    end
    % Update calibration stim index
    cal.describe.stateTracking.calibrationStimIndex = cal.describe.stateTracking.calibrationStimIndex + 1;
    
    % Take a check dark measurement.  Use setAll(false) instead of our starts/stops code.
    fprintf('- Measurement #%d: Dark (now using setAll(false) instead of starts/stops code) ...', cal.describe.stateTracking.calibrationStimIndex);
    ol.setAll(false);
    cal.raw.darkMeasCheck(:,measurementIndex) = spectroRadiometerOBJ.measure('userS', cal.describe.S);
    cal.raw.t.darkMeasCheck(:,measurementIndex) = mglGetSecs;
    fprintf('Done\n');
    
    spectroRadiometerOBJ.setOptions('sensitivityMode', 'STANDARD');
end
        
function cal = TakeWigglyMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage)

    cal = cal0;
    nPrimaries = cal.describe.numWavelengthBands;
    
    % See if we need to take a new set of state measurements
    if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
        cal = TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
    end
    % Update calibration stim index
    cal.describe.stateTracking.calibrationStimIndex = cal.describe.stateTracking.calibrationStimIndex + 1;
    
    fprintf('- Measurement #%d: Wiggly pattern ...', cal.describe.stateTracking.calibrationStimIndex);
    theSettings = 0.1*ones(nPrimaries,1);
    theSettings(2:8:end) = 0.8;
    [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
    
    measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
    cal.raw.wigglyMeas.settings(:,measurementIndex) = theSettings;
    cal.raw.wigglyMeas.measSpd(:,measurementIndex) = measTemp.pr650.spectrum;
    cal.raw.t.wigglyMeas.t(:,measurementIndex) = measTemp.pr650.time(1);
    if (meterToggle(2))
        cal.raw.omniDriver.wigglyMeas(:,measurementIndex) = measTemp.omni.spectrum;
    end
    fprintf('Done\n');
end

function cal = TakeHalfOnMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage)
    
    cal = cal0;
    nPrimaries = cal.describe.numWavelengthBands;
    
    % See if we need to take a new set of state measurements
    if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
        cal = TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
    end
    % Update calibration stim index
    cal.describe.stateTracking.calibrationStimIndex = cal.describe.stateTracking.calibrationStimIndex + 1;
    
    fprintf('- Measurement #%d: Half ON pattern ...', cal.describe.stateTracking.calibrationStimIndex);
    theSettings = 0.5*ones(nPrimaries,1);
    [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
    measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
    
    cal.raw.halfOnMeas(:,measurementIndex) = measTemp.pr650.spectrum;
    cal.raw.t.halfOnMeas(:,measurementIndex) = measTemp.pr650.time(1);
    if (meterToggle(2))
        cal.raw.omniDriver.halfOnMeas(:,measurementIndex) = measTemp.omni.spectrum;
    end
    fprintf('Done\n');
end
    
function cal = TakeFullOnMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage)
    
    cal = cal0;
    nPrimaries = cal.describe.numWavelengthBands;
    
    % See if we need to take a new set of state measurements
    if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
        cal = TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
    end
    % Update calibration stim index
    cal.describe.stateTracking.calibrationStimIndex = cal.describe.stateTracking.calibrationStimIndex + 1;
    
    fprintf('- Measurement #%d: Full ON pattern ...', cal.describe.stateTracking.calibrationStimIndex);
    theSettings = ones(nPrimaries,1);
    [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
    measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
    
    cal.raw.fullOn(:,measurementIndex) = measTemp.pr650.spectrum;
    cal.raw.t.fullOn(:,measurementIndex) = measTemp.pr650.time(1);
    if (meterToggle(2))
        cal.raw.omniDriver.fullOnMeas(:,measurementIndex) = measTemp.omni.spectrum;
    end
    fprintf('Done\n');
    
end


function theSettings = GetEffectiveBackgroundSettingsForPrimary(whichPrimary,specifiedBackgroundSettings)

    nPrimaries = length(specifiedBackgroundSettings);
    theSettings = zeros(size(specifiedBackgroundSettings));
    if (whichPrimary > 1)
        theSettings(whichPrimary-1) = specifiedBackgroundSettigns(whichPrimary-1);
    end
    if (whichPrimary < nPrimaries)
        theSettings(whichPrimary+1) = specifiedBackgroundSettigns(whichPrimary+1);
    end
end

%% Run primary gamma and additivity test
% THIS IS CODE WE MIGHT WANT TO INSERT, BUT IT IS NOT DONE YET.
%
% Before we save the calibration, we will run a standard primary gamma
% and additivity test. This test takes a middle primary and measures it
% in the presence or absence of flanking primaries on either side at
% 0.25, 0.5 and 1 of the max. We do this here because we need the gamma
% function to run this successfully.
%     whichPrimaryToTest = cal.describe.gamma.gammaBands(ceil(end/2));
%     cal.raw.diagnostics.additivity.midPrimary.flankersSep0Off = OLPrimaryGammaAndAdditivityTest(cal, whichPrimaryToTest, 1, {[0 0.25 0], [0 0.5 0], [0 1 0]});
%     cal.raw.diagnostics.additivity.midPrimary.flankersSep0On = OLPrimaryGammaAndAdditivityTest(cal, whichPrimaryToTest, 1, {[1 0.25 1], [1 0.5 1], [1 1 1]});
%     cal.raw.diagnostics.additivity.midPrimary.flankersSep3Off = OLPrimaryGammaAndAdditivityTest(cal, whichPrimaryToTest, 3, {[0 0.25 0], [0 0.5 0], [0 1 0]});
%     cal.raw.diagnostics.additivity.midPrimary.flankersSep3On = OLPrimaryGammaAndAdditivityTest(cal, whichPrimaryToTest, 3, {[1 0.25 1], [1 0.5 1], [1 1 1]});
%
%     whichPrimaryToTest = round((cal.describe.gamma.gammaBands(ceil(end/2)+1) + cal.describe.gamma.gammaBands(ceil(end/2)))/2);
%     cal.raw.diagnostics.additivity.offGammaPrimary.flankersSep0Off = OLPrimaryGammaAndAdditivityTest(cal, whichPrimaryToTest, 1, {[0 0.25 0], [0 0.5 0], [0 1 0]});
%     cal.raw.diagnostics.additivity.offGammaPrimary.flankersSep0On = OLPrimaryGammaAndAdditivityTest(cal, whichPrimaryToTest, 1, {[1 0.25 1], [1 0.5 1], [1 1 1]});
%     cal.raw.diagnostics.additivity.offGammaPrimary.flankersSep3Off = OLPrimaryGammaAndAdditivityTest(cal, whichPrimaryToTest, 3, {[0 0.25 0], [0 0.5 0], [0 1 0]});
%     cal.raw.diagnostics.additivity.offGammaPrimary.flankersSep3On = OLPrimaryGammaAndAdditivityTest(cal, whichPrimaryToTest, 3, {[1 0.25 1], [1 0.5 1], [1 1 1]});
%

