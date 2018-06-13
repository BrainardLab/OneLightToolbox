function OLCalibrateOOC
% OLCalibrateOOC - Calibrates the OneLight device, while
% tracking its state (power fluctuations and spectral shifts)
%
% Syntax:
% OLCalibrateOOC
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
% 2/17/14  dhb  All measurements get their starts/stops using OLSettingsToStartsStops.
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
% 8/17/16  npc  Added 'warming-up' stimuli right before the calibration
%               to see if this eliminates the large initial drift correction
% 8/24/16  dhb, ms Fix bug that NPC identified in the specified background
%               code.
% 9/2/16   npc  Removed Take*Measurements() methods and assembled them in 
%               static class @OLCalibrator
% 9/29/16  npc  Optionally record temperature
% 8/7/17   npc  Get relevant cal.describe params from OLCalibrationParamsDictionary, indexed on the box name

spectroRadiometerOBJ = [];

try
    % Ask which type of calibration we're doing.
    selectedCalType = OLGetEnumeratedCalibrationType;
    
    % Which box are we using?
    if contains(selectedCalType, 'BoxA')
        whichBox = 'BoxA';
    elseif contains(selectedCalType, 'BoxB')
        whichBox = 'BoxB';
    elseif contains(selectedCalType, 'BoxC')
        whichBox = 'BoxC';
    elseif contains(selectedCalType, 'BoxD')
        whichBox = 'BoxD';
    end
    
    fprintf('Using %s configuration\n', whichBox);
    
    % Get calibration params from dictionary.
    d = OLCalibrationParamsDictionary;
    calibrationParams = d(whichBox);
    
    % Set all cal.describe.xx params to calibrationParams.xx
    paramNames = fieldnames(calibrationParams);
    
    % Remove params that are not part of cal.describe.params
    noCalDescribeParamNames = {'dictionaryType', 'type', 'boxName'};
    paramNames = setdiff(paramNames, noCalDescribeParamNames);
    
    for k = 1:numel(paramNames)
        cal.describe.(paramNames{k}) = calibrationParams.(paramNames{k});
    end
    
    % Omni stuff
    meterToggle = [1 cal.describe.useOmni];
    od = [];
    
    % Enter bulb number.  This is a number that we assign by convention.
    cal.describe.bulbNumber = GetWithDefault('Enter bulb number',5);
    
    % Query user whether to take temperature measurements
    takeTemperatureMeasurements = GetWithDefault('Take Temperature Measurements ?', false);
    if (takeTemperatureMeasurements ~= true) && (takeTemperatureMeasurements ~= 1)
        takeTemperatureMeasurements = false;
    else
        takeTemperatureMeasurements = true;
    end

    if (takeTemperatureMeasurements)
        % Gracefully attempt to open the LabJack
        [takeTemperatureMeasurements, quitNow, theLJdev] = OLCalibrator.OpenLabJackTemperatureProbe(takeTemperatureMeasurements);
        if (quitNow)
            return;
        end
    else
       theLJdev = []; 
    end
    
    % Ask user if we want to save a temporary file with progression of the cal
    saveCalProgression = GetWithDefault('Save cal progression in a temporary file? [y/n]:','n');
    if (strcmpi(saveCalProgression, 'y'))
        tmpCalFileName = sprintf('OL%s_TMP', selectedCalType);
        calProgressionTemporaryFileName = ...
            fullfile(getpref('OneLightToolbox', 'OneLightCalData'), tmpCalFileName);
        calProgression{1} = struct();
        save(calProgressionTemporaryFileName, 'calProgression');
    else
        calProgressionTemporaryFileName = '';
    end
    
    % Ask for email recipient
    emailRecipient = GetWithDefault('Send status email to','cottaris@psych.upenn.edu');
    
    % Ask which PR-6xx radiometer to use
    % Some parameters are radiometer dependent.
    cal.describe.meterType = GetWithDefault('Enter PR-6XX radiometer type','PR-670');
    
    switch (cal.describe.meterType)
        case 'PR-650'
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
            
        case 'PR-670'
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
            
        otherwise
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
    
    % Find and set the optimal integration time.  Subtract off a couple
    % thousand microseconds just to give it a conservative value.
    ol.setAll(true);
    
    % Initialize the stateTracking substruct of cal
    cal = OLCalibrator.InitStateTracking(cal);
    
    % Ask for a keypress to start the warming up phase.
    % We hope this will will decrease the large initial drift correction
    input(sprintf('<strong>Press return to enter the OneLight warmup loop</strong>\n'));
    % don't take any measurements [false false]
    % warmpUpMeterToggle = [false false];
    % take measurements
    warmpUpMeterToggle = [1 cal.describe.useOmni];
    OLWarmUpOOC(cal, ol, od, spectroRadiometerOBJ, warmpUpMeterToggle);
    
    % Ask for a keypress to continue.
    input(sprintf('<strong>Press return to pause 10s then continue with the calibration</strong>\n'));
    pause(10);
    tic;
    startCal = GetSecs;
    
    % Depending on cables and light levels, the args to od.findIntegrationTime may
    % need to be fussed with a little.
    ol.setAll(false);
    
    fprintf('\n<strong>Initial measurements of spectra of interest</strong>\n\n');
    
    fullMeasurementIndex = 1;
    cal = OLCalibrator.TakeFullOnMeasurement(fullMeasurementIndex, cal, ol, od, ...
        spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, ...
        'takeTemperatureMeasurements', takeTemperatureMeasurements, ...
        'calProgressionTemporaryFileName', calProgressionTemporaryFileName);
    
    % Take a half on measurement.
    halfOnMeasurementIndex = 1;
    cal = OLCalibrator.TakeHalfOnMeasurement(halfOnMeasurementIndex, cal, ol, od, ...
        spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, ...
        'takeTemperatureMeasurements', takeTemperatureMeasurements, ...
        'calProgressionTemporaryFileName', calProgressionTemporaryFileName);
    
    % Take a wiggly measurement
    wigglyMeasurementIndex = 1;
    cal = OLCalibrator.TakeWigglyMeasurement(wigglyMeasurementIndex, cal, ol, od, ...
        spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, ...
        'takeTemperatureMeasurements', takeTemperatureMeasurements, ...
        'calProgressionTemporaryFileName', calProgressionTemporaryFileName);
    
    % Take a dark measurement
    darkMeasurementIndex = 1;
    cal = OLCalibrator.TakeDarkMeasurement(darkMeasurementIndex, cal, ol, od, ...
        spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, ...
        'takeTemperatureMeasurements', takeTemperatureMeasurements, ...
        'calProgressionTemporaryFileName', calProgressionTemporaryFileName);
    
    % Take a specified background measurement, if desired
    if (cal.describe.specifiedBackground)
        specifiedBackgroundMeasurementIndex = 1;
        cal = OLCalibrator.TakeSpecifiedBackgroundMeasurement(specifiedBackgroundMeasurementIndex, cal, ol, od, ...
            spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, ...
            'takeTemperatureMeasurements', takeTemperatureMeasurements, ...
            'calProgressionTemporaryFileName', calProgressionTemporaryFileName);
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
            [cal, wavelengthBandMeasurements(primaryIndex)] = OLCalibrator.TakePrimaryMeasurement(cal, primaryIndex, ol, od, ...
                spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, ...
                'takeTemperatureMeasurements', takeTemperatureMeasurements, ...
                'calProgressionTemporaryFileName', calProgressionTemporaryFileName);
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
            cal = OLCalibrator.TakeGammaMeasurements(cal, gammaBandIndex, ol, od, ...
                spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, ...
                'takeTemperatureMeasurements', takeTemperatureMeasurements, ...
                'calProgressionTemporaryFileName', calProgressionTemporaryFileName);
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
        
        cal = OLCalibrator.TakeIndependenceMeasurements(cal, ol, od, ...
            spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, ...
            'takeTemperatureMeasurements', takeTemperatureMeasurements, ...
            'calProgressionTemporaryFileName', calProgressionTemporaryFileName);
    end
    
    % Take a specified background measurement at the end, if desired
    if (cal.describe.specifiedBackground)
        specifiedBackgroundMeasurementIndex = size(cal.raw.specifiedBackgroundMeas,2) + 1;
        cal = OLCalibrator.TakeSpecifiedBackgroundMeasurement(specifiedBackgroundMeasurementIndex, cal, ol, od, ...
            spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, ...
            'takeTemperatureMeasurements', takeTemperatureMeasurements, ...
            'calProgressionTemporaryFileName', calProgressionTemporaryFileName);
    end
    
    % Take another dark measurement
    darkMeasurementIndex = size(cal.raw.darkMeas,2)+1;
    cal = OLCalibrator.TakeDarkMeasurement(darkMeasurementIndex, cal, ol, od, ...
        spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, ...
        'takeTemperatureMeasurements', takeTemperatureMeasurements, ...
        'calProgressionTemporaryFileName', calProgressionTemporaryFileName);
    
    % Take another wiggly measurement.
    wigglyMeasurementIndex = size(cal.raw.wigglyMeas.measSpd,2)+1;
    cal = OLCalibrator.TakeWigglyMeasurement(wigglyMeasurementIndex, cal, ol, od, ...
        spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, ...
        'takeTemperatureMeasurements', takeTemperatureMeasurements, ...
        'calProgressionTemporaryFileName', calProgressionTemporaryFileName);
    
    % Take another half on measurement.
    halfOnMeasurementIndex = size(cal.raw.halfOnMeas,2)+1;
    cal = OLCalibrator.TakeHalfOnMeasurement(halfOnMeasurementIndex, cal, ol, od, ...
        spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, ...
        'takeTemperatureMeasurements', takeTemperatureMeasurements, ...
        'calProgressionTemporaryFileName', calProgressionTemporaryFileName);
    
    % Take another full on measurement.
    fullMeasurementIndex = size(cal.raw.fullOn,2)+1;
    cal = OLCalibrator.TakeFullOnMeasurement(fullMeasurementIndex, cal, ol, od, ...
        spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, ...
        'takeTemperatureMeasurements', takeTemperatureMeasurements, ...
        'calProgressionTemporaryFileName', calProgressionTemporaryFileName);
    
    % Take a final set of state measurements
    cal = OLCalibrator.TakeStateMeasurements(cal, ol, od, ...
        spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, ...
        'takeTemperatureMeasurements', takeTemperatureMeasurements, ...
        'calProgressionTemporaryFileName', calProgressionTemporaryFileName);
        
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
        SaveCalFile(cal, selectedCalType.CalFileName, getpref('OneLightToolbox', 'OneLightCalData'));
    end
    
    % Run the calibration file through the initialization process.  This
    % loads up the data with a bunch of computed information found in the
    % computed subfield of the structure.  Only do this if we did full
    % calibration, since otherwise OLInitCal will barf.
    if (all([cal.describe.doPrimaries cal.describe.doGamma cal.describe.doIndependence]))
        if (cal.describe.specifiedBackground)
            % Use OLInitCalBG if the background is specified
            cal = OLInitCalBG(cal);
        else
            cal = OLInitCal(cal);
        end
        
        % Save out the calibration
        SaveCalFile(cal, ['OL', selectedCalType], getpref('OneLightToolbox', 'OneLightCalData'));
    end
    
    % Notify user we are done
    fprintf('\n<strong>Calibration Complete</strong>\n\n');
    
    if (strcmpi(saveCalProgression, 'y'))
        % If we reached this point, we can delete the temporary calibration
        fprintf('\n<strong>Temporary calibration file located in %s</strong>\n\n', calProgressionTemporaryFileName);
        %delete(calProgressionTemporaryFileName);
    end
    
    % Shutdown the PR670/650
    spectroRadiometerOBJ.shutDown();
    
    % Send email that we are done
    SendEmail(emailRecipient, 'OneLight Calibration Complete', ...
        'Finished!');
    
    if (takeTemperatureMeasurements)
        % Close temperature probe
        theLJdev.close();
    end
    
catch e
    fprintf('Failed with message: ''%s''.\nPlease wait for the spectroradiometer to shut down .... \n', e.message);
    if (~isempty(spectroRadiometerOBJ))
        spectroRadiometerOBJ.shutDown();
    end
    if exist('emailRecipient','var')
        SendEmail(emailRecipient, 'OneLight Calibration Failed', ...
            ['Calibration failed with the following error' 10 e.message]);
    end
    keyboard;
    
    if (takeTemperatureMeasurements)
        % Close temperature probe
        theLJdev.close();
    end
    
    rethrow(e);
end
end


function theSettings = GetEffectiveBackgroundSettingsForPrimary(whichPrimary,specifiedBackgroundSettings)

% Two ways of doing this.  The NEIGHBORHOOD method just sets the two
% primaries immediately adjacent to the one of interest.  The regular
% method sets the whole specified background.
NEIGHBORMETHOD = false;
if (NEIGHBORMETHOD)
    nPrimaries = length(specifiedBackgroundSettings);
    theSettings = zeros(size(specifiedBackgroundSettings));
    if (whichPrimary > 1)
        theSettings(whichPrimary-1) = specifiedBackgroundSettings(whichPrimary-1);
    end
    if (whichPrimary < nPrimaries)
        theSettings(whichPrimary+1) = specifiedBackgroundSettigns(whichPrimary+1);
    end
else
    theSettings = specifiedBackgroundSettings;
    theSettings(whichPrimary) = 0;
end
end
