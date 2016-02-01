function OLCalibrate
% OLCalibrate - Calibrates the OneLight device.
%
% Syntax:
% OLCalibrate
%
% Description:
% Calibrates a OneLight device using a PR-650 radiometer and the OneLight
% supplied spectrometer (OmniDriver).  The goal is to bypass the
% several pieces of hardware and mathematics used by the software supplied
% by the OneLight people.
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
%          dhb  Set calID to mglGetSecs.
%          dhb  Put in save before init, temporarily, because the init is likely to crash until we fix it for
%               new cal file.
% 7/20/14  ms   calID set with OLGetCalID. Save before init taken out.


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
            % We for BoxB, we set nGammaBands to be nPrimaries, see below.
            %cal.describe.nGammaBands = 20;
            cal.describe.nShortPrimariesSkip = 5;
            cal.describe.nLongPrimariesSkip = 3;
        case 'BoxB'
            cal.describe.gammaFitType = 'betacdfpiecelin';
            cal.describe.useAverageGamma = true;
            % We for BoxB, we set nGammaBands to be nPrimaries, see below.
            %cal.describe.nGammaBands = 20;
            cal.describe.nShortPrimariesSkip = 5;
            cal.describe.nLongPrimariesSkip = 3;
        case 'BoxC'
            cal.describe.gammaFitType = 'betacdfpiecelin';
            cal.describe.useAverageGamma = false;
            % We for BoxB, we set nGammaBands to be nPrimaries, see below.
            cal.describe.nGammaBands = 20;
            cal.describe.nShortPrimariesSkip = 8;
            cal.describe.nLongPrimariesSkip = 8;
        case 'BoxD'
            cal.describe.gammaFitType = 'betacdfpiecelin';
            cal.describe.useAverageGamma = false;
            % We for BoxB, we set nGammaBands to be nPrimaries, see below.
            %cal.describe.nGammaBands = 20;
            cal.describe.nShortPrimariesSkip = 8;
            cal.describe.nLongPrimariesSkip = 2;
        otherwise
            error('Unknown OneLight box');
    end
    cal.describe.nGammaFitLevels = 1024;
    
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
    
    % Use Omni?
    % First entry is PR-6xx and is always true.
    % Second entry is omni and can be on or off.
    cal.describe.useOmni = 0;
    meterToggle = [1 cal.describe.useOmni];
    
    % Enter bulb number.  This is a number that we assign by convention.
    cal.describe.bulbNumber = GetWithDefault('Enter bulb number',5);
    
    % Ask for email recipient
    emailRecipient = GetWithDefault('Send status email to','mspits@sas.upenn.edu');
    
    % Ask which PR-6xx radiometer to use
    % Some parameters are radiometer dependent.
    cal.describe.meterType = GetWithDefault('Enter PR-6XX radiometer type','PR-670');
    
    % init spectroRadiometerOBJ to empty
    spectroRadiometerOBJ = [];
    
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
        
            spectroRadiometerOBJ.setOptions('syncMode', 'OFF');
            
            % Options available for PR670:
%           spectroRadiometerOBJ.setOptions(...
%                 'verbosity',        1, ...
%                 'syncMode',         'OFF', ...      % choose from 'OFF', 'AUTO', [20 400];        
%                 'cyclesToAverage',  1, ...          % choose any integer in range [1 99]
%                 'sensitivityMode',  'STANDARD', ... % choose between 'STANDARD' and 'EXTENDED'.  'STANDARD': (exposure range: 6 - 6,000 msec, 'EXTENDED': exposure range: 6 - 30,000 msec
%                 'exposureTime',     'ADAPTIVE', ... % choose between 'ADAPTIVE' (for adaptive exposure), or a value in the range [6 6000] for 'STANDARD' sensitivity mode, or a value in the range [6 30000] for the 'EXTENDED' sensitivity mode
%                 'apertureSize',     '1/2 DEG' ...   % choose between '1 DEG', '1/2 DEG', '1/4 DEG', '1/8 DEG'
%             );
    
        otherwise,
            error('Unknown meter type');
    end
    
    
    % Connect to the OceanOptics spectrometer.
    if (cal.describe.useOmni)
        od = OmniDriver;
        od.Debug = true;
        % Turn on some averaging and smoothing for the spectrum acquisition.
        od.ScansToAverage = 10;
        od.BoxcarWidth = 2;
        
        % Make sure electrical dark correction is enabled.
        od.CorrectForElectricalDark = true;
    else
        od = [];
    end
    
    % Open the OneLight device.
    ol = OneLight;
    
    % Gamma measurement parameters.  The measurements
    % are spaced evenly across the effective primaries.
    cal.describe.nGammaLevels = 24;
    
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
    
    % Calculate the start columns for each effective primary.
    % These are indexed MATLAB style, 1:numCols.
    cal.describe.primaryStartCols = 1 + (cal.describe.nShortPrimariesSkip*cal.describe.bandWidth:cal.describe.bandWidth:(ol.NumCols - (cal.describe.nLongPrimariesSkip+1)*cal.describe.bandWidth));
    cal.describe.primaryStopCols = cal.describe.primaryStartCols + cal.describe.bandWidth-1;
    cal.describe.numWavelengthBands = length(cal.describe.primaryStartCols);
    nPrimaries = cal.describe.numWavelengthBands;
    
    % For BoxB, we want to measure the gamma function for each primary.
    switch (whichBox)
        case 'BoxA'
            %cal.describe.nGammaBands = nPrimaries;
            cal.describe.nGammaBands = 16;
        case 'BoxB'
            %cal.describe.nGammaBands = nPrimaries;
            cal.describe.nGammaBands = 16;
        case 'BoxC'
            %cal.describe.nGammaBands = nPrimaries;
            cal.describe.nGammaBands = 16;
        case 'BoxD'
            %cal.describe.nGammaBands = nPrimaries;
            cal.describe.nGammaBands = 16;
    end
    
    
    
    % Find and set the optimal integration time.  Subtract off a couple
    % thousand microseconds just to give it a conservative value.
    ol.setAll(true);
    
    % Ask for a keypress to continue.
    input('*** Press return to pause 10s then continue with the calibration***\n');
    pause(10);
    tic;
    startCal = GetSecs;
    
    % Depending on cables and light levels, the args to od.findIntegrationTime may
    % need to be fussed with a little.
    if (cal.describe.useOmni)
        od.IntegrationTime = od.findIntegrationTime(100, 2, 1000);
        od.IntegrationTime = round(0.95*od.IntegrationTime);
        fprintf('- Using integration time of %d microseconds.\n', od.IntegrationTime);
    end
    ol.setAll(false);
    
    fprintf('\n*** Wavelength Calibration ***\n\n');
    
    % Take a full on measurement.
    fprintf('- Taking full on measurement...');
    theSettings = ones(nPrimaries,1);
    [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
    measTemp = OLTakeMeasurement(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
    cal.raw.fullOn(:,1) = measTemp.pr650.spectrum;
    cal.raw.t.fullOn(:,1) = measTemp.pr650.time(1);
    if (meterToggle(2))
        cal.raw.omniDriver.fullOnMeas(:,1) = measTemp.omni.spectrum;
    end
    fprintf('Done\n');
    
    % Take a half on measurement.
    fprintf('- Taking half on measurement...');
    theSettings = 0.5*ones(nPrimaries,1);
    [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
    measTemp = OLTakeMeasurement(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
    cal.raw.halfOnMeas(:,1) = measTemp.pr650.spectrum;
    cal.raw.t.halfOnMeas(:,1) = measTemp.pr650.time(1);
    if (meterToggle(2))
        cal.raw.omniDriver.halfOnMeas(:,1) = measTemp.omni.spectrum;
    end
    fprintf('Done\n');
    
    % Take a wiggly measurement.
    fprintf('- Taking wiggly measurement...');
    theSettings = 0.1*ones(nPrimaries,1);
    theSettings(2:8:end) = 0.8;
    [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
    measTemp = OLTakeMeasurement(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
    cal.raw.wigglyMeas.settings(:,1) = theSettings;
    cal.raw.wigglyMeas.measSpd(:,1) = measTemp.pr650.spectrum;
    cal.raw.t.wigglyMeas.t(:,1) = measTemp.pr650.time(1);
    if (meterToggle(2))
        cal.raw.omniDriver.wigglyMeas(:,1) = measTemp.omni.spectrum;
    end
    fprintf('Done\n');
    
    % Take a dark measurement.
    fprintf('- Measuring background...');
    theSettings = 0*ones(nPrimaries,1);
    [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
    measTemp = OLTakeMeasurement(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
    cal.raw.darkMeas(:,1) = measTemp.pr650.spectrum;
    cal.raw.t.darkMeas(:,1) = measTemp.pr650.time(1);
    if (meterToggle(2))
        cal.raw.omniDriver.darkMeas(:,1) = measTemp.omni.spectrum;
    end
    fprintf('Done\n');
    
    % Take a check dark measurement.  Use setAll(false) instead of our
    % starts/stops code.
    fprintf('- Measuring background again ...');
    ol.setAll(false);
    cal.raw.darkMeasCheck(:,1) = spectroRadiometerOBJ.measure('userS', cal.describe.S); 
    cal.raw.t.darkMeasCheck(:,1) = mglGetSecs;
    fprintf('Done\n');
    
    % If needed, shuffle the primary measurements.
    if cal.describe.randomizePrimaryMeas
        primaryMeasIter = Shuffle(1:length(cal.describe.primaryStartCols));
    else
        primaryMeasIter = 1:length(cal.describe.primaryStartCols);
    end
    for i = primaryMeasIter
        fprintf('- Measurement %d of %d...', i, length(cal.describe.primaryStartCols));
        
        % Set the starts/stops
        theSettings = zeros(nPrimaries,1);
        theSettings(i) = 1;
        [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
        
        % Record the band start and end.
        wavelengthBandMeasurements(i).bandRange = [cal.describe.primaryStartCols(i), cal.describe.primaryStopCols(i)]; %#ok<*AGROW>
        
        % Take a measurement.
        measTemp = OLTakeMeasurement(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
        wavelengthBandMeasurements(i).lightSpectrum = measTemp.pr650.spectrum;
        wavelengthBandMeasurements(i).time = measTemp.pr650.time(1);
        if (meterToggle(2))
            wavelengthBandMeasurements(i).lightSpectrumOD = measTemp.omni.spectrum;
        end
        fprintf('Done\n');
        
    end
    
    % Refactor the measurements into separate matrices for further calculations.
    if (cal.describe.numWavelengthBands ~= length(wavelengthBandMeasurements))
        error('We did not understand what we thought was an identity when we edited the code');
    end
    cal.raw.lightMeas = zeros(cal.describe.S(3), cal.describe.numWavelengthBands);
    if (cal.describe.useOmni)
        cal.raw.omniDriver.lightMeas = zeros(od.NumPixels, cal.describe.numWavelengthBands);
    end
    cal.raw.cols = zeros(ol.NumCols, cal.describe.numWavelengthBands);
    for i = 1:cal.describe.numWavelengthBands
        % Store the spectrum for this measurement.
        cal.raw.lightMeas(:,i) = wavelengthBandMeasurements(i).lightSpectrum;
        cal.raw.t.lightMeas(:,i) = wavelengthBandMeasurements(i).time;
        if (cal.describe.useOmni)
            cal.raw.omniDriver.lightMeas(:,i) = wavelengthBandMeasurements(i).lightSpectrumOD;
        end
        
        % Store which columns were on for this measurement.
        cal.raw.cols(:,i) = zeros(ol.NumCols, 1);
        e = wavelengthBandMeasurements(i).bandRange;
        cal.raw.cols(e(1):e(2),i) = 1;
        if (e(1) ~= cal.describe.primaryStartCols(i) || e(2) ~= cal.describe.primaryStopCols(i))
            error('Inconsistency in various primary column descriptors');
        end
    end
    
    % Store some measurement parameters.
    cal.describe.durationMinutes = (GetSecs - startCal)/60;
    cal.describe.date = datestr(now);
    if (cal.describe.useOmni)
        cal.describe.omniDriver.wavelengths = od.Wavelengths;
        cal.describe.omniDriver.integrationTime = od.IntegrationTime;
    end
    
    % Gamma measurements.
    %
    % We do this for cal.describe.nGammaBands of the bands, at
    % cal.describe.nGammaLevels for each band.
    cal.describe.gamma.gammaBands = round(linspace(1,cal.describe.numWavelengthBands,cal.describe.nGammaBands));
    cal.describe.gamma.gammaLevels = linspace(1/cal.describe.nGammaLevels,1,cal.describe.nGammaLevels);
    
    % OLD STUFF
    % Compute gamma settings stepSize for updating stops as we chunk through gamma levels
    % gammaStepSize = ol.NumRows/cal.describe.nGammaLevels;
    %
    % The mirror stop rows for each gamma measurement level
    % cal.raw.gamma.stops = (gammaStepSize:gammaStepSize:ol.NumRows) - 1;
    %
    %
    % if (cal.describe.nGammaLevels ~= length(cal.raw.gamma.stops))
    %     error('Failed to compute number of gamma levels to the same value in two places');
    % end
    %
    % Store some measurement parameters.
    % cal.describe.gamma.numRowsPerTest = cal.describe.nGammaLevels;
    % cal.describe.gamma.rowStepSize = gammaStepSize;
    
    % Allocate some memory.
    cal.raw.gamma.cols = zeros(ol.NumCols, cal.describe.nGammaBands);
    
    % Make gamma measurements for each band
    if cal.describe.randomizeGammaMeas
        gammaMeasIter = Shuffle(1:cal.describe.nGammaBands);
    else
        gammaMeasIter = 1:cal.describe.nGammaBands;
    end
    for i = gammaMeasIter
        fprintf('\n*** Gamma measurements on gamma band set %d of %d ***\n\n', i, cal.describe.nGammaBands);
        
        %SendEmail(emailRecipient, ['OneLight Calibration: Gamma meas ' num2str(i)], ...
        %    'Starting...');
        
        % Store the columns used for this set.
        cal.raw.gamma.cols(:,i) = cal.raw.cols(:,cal.describe.gamma.gammaBands(i));
        
        % Allocate memory for the recorded spectra.
        cal.raw.gamma.rad(i).meas = zeros(cal.describe.S(3), cal.describe.nGammaLevels);
        if (cal.describe.useOmni)
            cal.raw.gamma.omnidriver(i).meas = zeros(od.NumPixels, cal.describe.nGammaLevels);
        else
            cal.raw.gamma.omnidriver(i).meas = zeros(1, cal.describe.nGammaLevels);
        end
        
        % Test each gamma level for this band. If the gamma randomization
        % flag is set, shuffle now. We are still storing the measurements
        % in the right order as expected.
        if cal.describe.randomizeGammaLevels
            gammaLevelsIter = Shuffle(1:cal.describe.nGammaLevels);
        else
            gammaLevelsIter = 1:cal.describe.nGammaLevels;
        end
        for rowTest = gammaLevelsIter;
            fprintf('- Taking measurement %d of %d...', rowTest, cal.describe.nGammaLevels);
            
            % OLD STUFF
            % Get the stop row we are interested in.
            % rowVal = cal.raw.gamma.stops(rowTest);
            % starts = zeros(1, ol.NumCols);
            % stops = cal.raw.gamma.cols(:,i)' * rowVal;
            
            % Set the starts/stops, measure, and store
            theSettings = zeros(nPrimaries,1);
            theSettings(cal.describe.gamma.gammaBands(i)) = cal.describe.gamma.gammaLevels(rowTest);
            [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
            measTemp = OLTakeMeasurement(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
            cal.raw.gamma.rad(i).meas(:,rowTest) = measTemp.pr650.spectrum;
            cal.raw.t.gamma.rad(i).meas(:,rowTest) = measTemp.pr650.time(1);
            if (meterToggle(2))
                cal.raw.gamma.omnidriver(i).meas(:,rowTest) = measTemp.omni.spectrum;
            end
            fprintf('Done\n');
        end
        
        %SendEmail(emailRecipient, ['OneLight Calibration: Gamma meas ' num2str(i)], ...
        %'Finished!');
    end
    
    
    
    % Now we'll do an independence test on the same column sets from the
    % gamma measurements.
    fprintf('\n*** Independence Test ***\n\n');
    
    % Store some measurement data regarding the independence test.
    cal.describe.independence.gammaBands = cal.describe.gamma.gammaBands;
    cal.describe.independence.nGammaBands = cal.describe.nGammaBands;
    cal.raw.independence.cols = zeros(ol.NumCols, cal.describe.nGammaBands);
    fprintf('- Testing column sets individually...');
    for i = 1:cal.describe.independence.nGammaBands
        % Store column set used for this measurement.
        cal.raw.independence.cols(:,i) = cal.raw.cols(:,cal.describe.independence.gammaBands(i));
        
        % Take a measurement.
        theSettings = zeros(nPrimaries,1);
        theSettings(cal.describe.independence.gammaBands(i)) = 1;
        [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
        measTemp = OLTakeMeasurement(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
        cal.raw.independence.meas(:,i) = measTemp.pr650.spectrum;
        cal.raw.t.independence.meas(:,i) = measTemp.pr650.time(1);
        if (meterToggle(2))
            cal.raw.independence.measOD(:,i) = measTemp.omni.spectrum;
        end
    end
    fprintf('Done\n');
    
    % Now take a cumulative measurement.
    fprintf('- Testing column sets cumulatively...');
    cal.raw.independence.colsAll = sum(cal.raw.independence.cols, 2);
    theSettings = zeros(nPrimaries,1);
    for i = 1:cal.describe.independence.nGammaBands
        theSettings(cal.describe.independence.gammaBands(i)) = 1;
    end
    [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
    measTemp = OLTakeMeasurement(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
    cal.raw.independence.measAll = measTemp.pr650.spectrum;
    cal.raw.t.independence.measAll = measTemp.pr650.time(1);
    if (meterToggle(2))
        cal.raw.independence.measODAll = measTemp.omni.spectrum;
    end
    fprintf('Done\n');
    
    % Take a dark measurement at the end.  Use special case of starts/stops
    % that turns all mirrors off.
    fprintf('- Measuring background...');
    theSettings = 0*ones(nPrimaries,1);
    [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
    measTemp = OLTakeMeasurement(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
    cal.raw.darkMeas(:,2) = measTemp.pr650.spectrum;
    cal.raw.t.darkMeas(:,2) = measTemp.pr650.time(1);
    if (meterToggle(2))
        cal.raw.omniDriver.darkMeas(:,1) = measTemp.omni.spectrum;
    end
    fprintf('Done\n');
        
    % Take a wiggly measurement.
    fprintf('- Taking wiggly measurement...');
    theSettings = 0.1*ones(nPrimaries,1);
    theSettings(2:8:end) = 0.8;
    [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
    measTemp = OLTakeMeasurement(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
    cal.raw.wigglyMeas.settings(:,2) = theSettings;
    cal.raw.wigglyMeas.measSpd(:,2) = measTemp.pr650.spectrum;
    cal.raw.t.wigglyMeas.t(:,2) = measTemp.pr650.time(1);
    if (meterToggle(2))
        cal.raw.omniDriver.wigglyMeas(:,2) = measTemp.omni.spectrum;
    end
    
    fprintf('Done\n');
    
    % Take a half on on measurement.
    fprintf('- Taking half on measurement...');
    theSettings = 0.5*ones(nPrimaries,1);
    [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
    measTemp = OLTakeMeasurement(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
    cal.raw.halfOnMeas(:,2) = measTemp.pr650.spectrum;
    cal.raw.t.halfOnMeas(:,2) = measTemp.pr650.time(1);
    if (meterToggle(2))
        cal.raw.omniDriver.halfOnMeas(:,1) = measTemp.omni.spectrum;
    end
    fprintf('Done\n');
    
    % Take a full on on measurement.
    fprintf('- Taking full on measurement...');
    theSettings = ones(nPrimaries,1);
    [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
    measTemp = OLTakeMeasurement(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
    cal.raw.fullOn(:,2) = measTemp.pr650.spectrum;
    cal.raw.t.fullOn(:,2) = measTemp.pr650.time(1);
    if (meterToggle(2))
        cal.raw.omniDriver.fullOnMeas(:,2) = measTemp.omni.spectrum;
    end
    fprintf('Done\n');
    
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
    % SaveCalFile(cal, selectedCalType.CalFileName);
    
    % Run the calibration file through the initialization process.  This
    % loads up the data with a bunch of computed information found in the
    % computed subfield of the structure.
    cal = OLInitCal(cal);
    
    %% Run primary gamma and additivity test
    % Before we save the calibration, we will run a standard primary gamma
    % and additivity test. This test takes a middle primary and measures it
    % in the presence or absence of flanking primaries on either side at
    % 0.25, 0.5 and 1 of the max. We do this here because we need the gamma
    % function to run this successfully.
    whichPrimaryToTest = cal.describe.gamma.gammaBands(ceil(end/2));
    cal.raw.diagnostics.additivity.midPrimary.flankersSep0Off = OLPrimaryGammaAndAdditivityTest(cal, whichPrimaryToTest, 1, {[0 0.25 0], [0 0.5 0], [0 1 0]});
    cal.raw.diagnostics.additivity.midPrimary.flankersSep0On = OLPrimaryGammaAndAdditivityTest(cal, whichPrimaryToTest, 1, {[1 0.25 1], [1 0.5 1], [1 1 1]});
    cal.raw.diagnostics.additivity.midPrimary.flankersSep3Off = OLPrimaryGammaAndAdditivityTest(cal, whichPrimaryToTest, 3, {[0 0.25 0], [0 0.5 0], [0 1 0]});
    cal.raw.diagnostics.additivity.midPrimary.flankersSep3On = OLPrimaryGammaAndAdditivityTest(cal, whichPrimaryToTest, 3, {[1 0.25 1], [1 0.5 1], [1 1 1]});
    
    whichPrimaryToTest = round((cal.describe.gamma.gammaBands(ceil(end/2)+1) + cal.describe.gamma.gammaBands(ceil(end/2)))/2);
    cal.raw.diagnostics.additivity.offGammaPrimary.flankersSep0Off = OLPrimaryGammaAndAdditivityTest(cal, whichPrimaryToTest, 1, {[0 0.25 0], [0 0.5 0], [0 1 0]});
    cal.raw.diagnostics.additivity.offGammaPrimary.flankersSep0On = OLPrimaryGammaAndAdditivityTest(cal, whichPrimaryToTest, 1, {[1 0.25 1], [1 0.5 1], [1 1 1]});
    cal.raw.diagnostics.additivity.offGammaPrimary.flankersSep3Off = OLPrimaryGammaAndAdditivityTest(cal, whichPrimaryToTest, 3, {[0 0.25 0], [0 0.5 0], [0 1 0]});
    cal.raw.diagnostics.additivity.offGammaPrimary.flankersSep3On = OLPrimaryGammaAndAdditivityTest(cal, whichPrimaryToTest, 3, {[1 0.25 1], [1 0.5 1], [1 1 1]});
    
    % Savout the calibration
    oneLightCalSubdir = 'OneLight';
    SaveCalFile(cal, fullfile(oneLightCalSubdir,selectedCalType.CalFileName));
    
    fprintf('\n*** Calibration Complete ***\n\n');
    
    %fprintf('\n*** Putting ol into shutdown mode ***\n\n');
    %ol.shutdown;
    
    SendEmail(emailRecipient, 'OneLight Calibration Complete', ...
        'Finished!');
catch e
    
    % cleanup related to the spectroRadiometerOBJ
    if (exist('spectroRadiometerOBJ', 'var'))
        if (isempty(spectroRadiometerOBJ))
            fprintf(2,'\nClosing all IO ports due to encountered error.\n');
            IOPort('closeall');
        else
            % Shutdown spectroRadiometerOBJ object and close the associated device
            fprintf(2,'\nShutting down spectroRadiometerOBJ due to encountered error. \n');
            spectroRadiometerOBJ.shutDown();
        end
    end
    
    SendEmail(emailRecipient, 'OneLight Calibration Failed', ...
        ['Calibration failed with the following error' 10 e.message]);
    
    rethrow(e);
    keyboard
end


