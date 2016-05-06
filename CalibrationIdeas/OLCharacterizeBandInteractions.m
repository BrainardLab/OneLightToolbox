function OLCharacterizeBandInteractions
% OLCharacterizeBandInteractions - Characterize interactions between bands of the OneLight device.
%
% Syntax:
% OLCharacterizeBandInteractions
%
% 5/2/16  npc  Wrote it.
%

    [rootDir,~] = fileparts(which(mfilename()));
    cd(rootDir);
    
    Svector = [380 2 201];
    
    choice = input('Measure data(0), or analyze data(1) : ', 's');
    if (str2double(choice) == 0)
        measureData(rootDir, Svector);
    else
        analyzeData(rootDir, Svector);
    end
end


function analyzeData(rootDir, Svector)
    [fileName, pathName] = uigetfile('*.mat', 'Select a file to analyze', rootDir);
    load(fileName, 'data', 'primaryLevels', 'referenceBands', 'interactingBands', 'nRepeats', 'randomizedSpectraIndices', 'cal');
    
    nSpectraMeasured = numel(data);
    fprintf('There are %d distinct spectra measured (each measured %d times). \n', nSpectraMeasured, nRepeats);
    
    nPrimariesNum = numel(data{1}.activation);
    wavelengthAxis = SToWls(Svector);
    nSpectralSamples = numel(wavelengthAxis);
    
    % Compute average and range of measured spectra
    for repeatIndex = 1:nRepeats
        stimulationSequence = squeeze(randomizedSpectraIndices(repeatIndex,:)); 
            
        % Show stimulation sequence for this repeat
        figure(1);
        clf;
        subplot('Position', [0.04 0.04 0.95 0.95]);
        pcolor(1:nPrimariesNum, 1:nSpectraMeasured, retrieveActivationSequence(data, stimulationSequence));
        xlabel('primary no');
        ylabel('spectrum no');
        set(gca, 'CLim', [0 1], 'XLim', [1 nPrimariesNum], 'YLim', [0 nSpectraMeasured+1]);
        colormap(gray);
        title(sprintf('Repeat %d\n', repeatIndex));
    end
    
    
    for spectrumIndex = 1:nSpectraMeasured
        % average over all reps
        data{spectrumIndex}.meanSPD = mean(data{spectrumIndex}.measuredSPD(:, 1:nRepeats), 2);

        % compute min over all reps
        data{spectrumIndex}.minSPD  = min(data{spectrumIndex}.measuredSPD(:, 1:nRepeats), [], 2);
        
        % compute max over all reps
        data{spectrumIndex}.maxSPD  = max(data{spectrumIndex}.measuredSPD(:, 1:nRepeats), [], 2);
        
        activationLevelIndex = data{spectrumIndex}.activationLevelIndex;
        spdType = data{spectrumIndex}.spdType;
        
        if (strcmp(spdType, 'singetonSPDi'))
            interactingBand = data{spectrumIndex}.interactingBand;
            singletonSPDactivation(activationLevelIndex, interactingBand,:) = data{spectrumIndex}.activation;
            singletonSPD(activationLevelIndex, interactingBand,:) = data{spectrumIndex}.meanSPD;
            singletonSPDrange(activationLevelIndex, interactingBand,1,:) = data{spectrumIndex}.minSPD;
            singletonSPDrange(activationLevelIndex, interactingBand,2,:) = data{spectrumIndex}.maxSPD;
            
        elseif (strcmp(spdType, 'singetonSPDb'))
            referenceBand = data{spectrumIndex}.referenceBand;
            singletonSPDactivation(activationLevelIndex, referenceBand,:) = data{spectrumIndex}.activation;
            singletonSPD(activationLevelIndex, referenceBand,:) = data{spectrumIndex}.meanSPD;
            singletonSPDrange(activationLevelIndex, referenceBand,1,:) = data{spectrumIndex}.minSPD;
            singletonSPDrange(activationLevelIndex, referenceBand,2,:) = data{spectrumIndex}.maxSPD;
            
        elseif (strcmp(spdType, 'comboSPD'))
            interactingBand = data{spectrumIndex}.interactingBand;
            referenceBand = data{spectrumIndex}.referenceBand;
            comboSPDactivation(activationLevelIndex, referenceBand, interactingBand,:) = data{spectrumIndex}.activation;
            comboSPD(activationLevelIndex, referenceBand, interactingBand,:) = data{spectrumIndex}.meanSPD;
            comboSPDrange(activationLevelIndex, referenceBand, interactingBand, 1, :) = data{spectrumIndex}.minSPD;
            comboSPDrange(activationLevelIndex, referenceBand, interactingBand, 2, :) = data{spectrumIndex}.maxSPD;
            
        elseif (strcmp(spdType, 'dark'))
            darkSPD = data{spectrumIndex}.meanSPD;
            darkSPDrange(1,:) = data{spectrumIndex}.minSPD;
            darkSPDrange(2,:) = data{spectrumIndex}.maxSPD;
        else
            error('How can spdType be ''%s'' ?', spdType)
        end 
    end
    
    % Substract darkSPD from singleton
    singletonSPD = bsxfun(@minus, singletonSPD, reshape(darkSPD, [1 1 nSpectralSamples]));
    
    % Compute predictions for comboSPDs
    for activationLevelIndex = 1:size(comboSPD,1)
        for referenceBand = 1:size(comboSPD,2)
            for interactingBand = 1:size(comboSPD,3)
                comboSPDprediction(activationLevelIndex, referenceBand, interactingBand,:) = ...
                    darkSPD + ...
                    squeeze(singletonSPD(activationLevelIndex, referenceBand,:)) + ...
                    squeeze(singletonSPD(activationLevelIndex, interactingBand,:));
            end % interactingBandIndex
        end % referenceBandIndex
    end %  activationLevelIndex
    
    
    % Compute max SPD
    maxSPD = max([max(comboSPD(:)) max(comboSPDprediction(:))]);
    
    % Residuals
    comboSPDresiduals = comboSPD - comboSPDprediction;
    
    
    % Plotting
     gain = 1000;
     
     
    % Plot the singleton SPDs together with their min/maxs
    measuredBandsNum = 0;
    for bandNo = 1:size(singletonSPD,2)
       spd = squeeze(singletonSPD(1, bandNo,:));
       if (any(spd>0))
           measuredBandsNum = measuredBandsNum + 1;
       end
    end
    
    plotCols = 6;
    plotRows = ceil(measuredBandsNum/plotCols);
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', plotRows, ...
               'colsNum', plotCols, ...
               'heightMargin',   0.03, ...
               'widthMargin',    0.01, ...
               'leftMargin',     0.01, ...
               'rightMargin',    0.005, ...
               'bottomMargin',   0.03, ...
               'topMargin',      0.01);
           
    for activationLevelIndex = 1:size(comboSPD,1)
        figure(100+activationLevelIndex);
        bandIter = 0;
        for bandNo = 1:size(singletonSPD,2)
            spd = squeeze(singletonSPD(activationLevelIndex, bandNo,:));
            minSpd = squeeze(singletonSPDrange(activationLevelIndex, bandNo,1,:));
            maxSpd = squeeze(singletonSPDrange(activationLevelIndex, bandNo,2,:));
            if (any(spd>0))
                bandIter = bandIter + 1;
                col = mod(bandIter-1,plotCols) + 1;
                row = floor((bandIter-1)/plotCols) + 1;
                subplot('Position', subplotPosVectors(row,col).v);
                plot(wavelengthAxis, gain*darkSPD, 'k-');
                hold on;
                plot(wavelengthAxis, gain*squeeze(darkSPDrange(1,:)), 'k--');
                plot(wavelengthAxis, gain*squeeze(darkSPDrange(2,:)), 'k--');
                plot(wavelengthAxis, gain*spd, 'r-', 'Color', [1.0 0.3 0.3 0.5], 'LineWidth', 4.0);
                plot(wavelengthAxis, gain*minSpd, 'r--');
                plot(wavelengthAxis, gain*maxSpd, 'r--');
                set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [0 maxSPD*gain]);
                hold off;
                title(sprintf('activated band: %d', bandNo));
            end
        end % bandNo
    end
    
    
    fprintf('\nInteraction data are available for the following reference bands:');
    for k = 1:numel(referenceBands)
        fprintf('%d ', referenceBands(k));
    end
    
    selectedReferenceBand = input(sprintf('\nEnter reference band for visualization : [%d] ', referenceBands(1)), 's');
    if (isempty(selectedReferenceBand))
        selectedReferenceBand = referenceBands(1);
    else
        selectedReferenceBand = str2double(selectedReferenceBand);
        if (isempty(selectedReferenceBand)) || (selectedReferenceBand<1) || (selectedReferenceBand>numel(referenceBands))
            selectedReferenceBand = referenceBands(1);
        else
            selectedReferenceBand = referenceBands(selectedReferenceBand);
        end
    end
    
    % Plot the interactions
    hFig = figure(1000);
    clf;
    set(hFig, 'Position', [10 10 1150 1350], 'Color', [1 1 1], 'MenuBar', 'none');
    
    % Open video stream
    videoFilename = sprintf('%s_ReferenceBar_%d.m4v', fileName, selectedReferenceBand);
    writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
    writerObj.FrameRate = 15; 
    writerObj.Quality = 100;
    writerObj.open();
    
    % Do the plotting
    yTickLevels = [-100:0.5:100];
    for spectrumIndex = 1:nSpectraMeasured
        % get activation params for this spectum index
        spdType = data{spectrumIndex}.spdType;
        if (strcmp(spdType, 'comboSPD'))
            
            referenceBand = data{spectrumIndex}.referenceBand;
            if (referenceBand ~= selectedReferenceBand)
                continue;
            end
            activationLevelIndex  = data{spectrumIndex}.activationLevelIndex;
            interactingBand       = data{spectrumIndex}.interactingBand;
            
            % The raw combo measurement (top left)
            subplot('Position', [0.05 0.29 0.44 0.70]);
            
            meanSPDInMilliWatts = gain*squeeze(comboSPD(activationLevelIndex, referenceBand, interactingBand,:));
            minSPDInMilliWatts  = gain*squeeze(comboSPDrange(activationLevelIndex, referenceBand, interactingBand, 1, :));
            maxSPDInMilliWatts  = gain*squeeze(comboSPDrange(activationLevelIndex, referenceBand, interactingBand, 2, :));
            
            plot(wavelengthAxis, meanSPDInMilliWatts, 'r-', 'LineWidth', 2.0);
            hold on;
            plot(wavelengthAxis, minSPDInMilliWatts, 'k--', 'LineWidth', 1.0);
            plot(wavelengthAxis, maxSPDInMilliWatts, 'k--', 'LineWidth', 1.0);
            hold off;
            hL = legend('measurement', 'min', 'max');
            set(hL, 'FontSize', 12);
            set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [0 maxSPD*gain]);
            set(gca, 'FontSize', 12);
            xlabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
            ylabel('power (mW)', 'FontSize', 14, 'FontWeight', 'bold');
            grid on
            box on
            
            % The combo measurement and its prediction (top right)
            subplot('Position', [0.55 0.29 0.44 0.70]);
            predictionSPDInMilliWatts = gain*squeeze(comboSPDprediction(activationLevelIndex, referenceBand, interactingBand,:));
            plot(wavelengthAxis, meanSPDInMilliWatts, 'r-', 'LineWidth', 2.0);
            hold on;
            plot(wavelengthAxis, predictionSPDInMilliWatts, 'b-', 'Color', [0 0.4 1 0.5], 'LineWidth', 2.0);
            hold off;
            hL = legend('measurement', 'prediction');
            set(hL, 'FontSize', 12);
            set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [0 maxSPD*gain]);
            set(gca, 'FontSize', 12);
            xlabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
            ylabel('power (mW)', 'FontSize', 14, 'FontWeight', 'bold');
            grid on
            box on
        
            % The band activation pattern (bottom left)
            subplot('Position', [0.05 0.05 0.44 0.20]);
            activationPattern = squeeze(comboSPDactivation(activationLevelIndex, referenceBand, interactingBand,:));
            bar(1:numel(activationPattern), activationPattern, 1.0, 'FaceColor', [1.0 0.6 0.6], 'EdgeColor', [0 0 0]);
            hold on;
            activationPattern(interactingBand) = 0;
            bar(1:numel(activationPattern), activationPattern, 1.0, 'FaceColor', [0.6 0.6 1.0], 'EdgeColor', [0 0 0]);
            hold off;
            set(gca, 'YLim', [0 1.1], 'XLim', [0 nPrimariesNum+1]);
            hL = legend({'interacting band', 'reference band'});
            set(hL, 'FontSize', 12);
            set(gca, 'FontSize', 12);
            xlabel('primary index', 'FontSize', 14, 'FontWeight', 'bold');
            ylabel('primary activation', 'FontSize', 14, 'FontWeight', 'bold');
        
            % The residual SPD (bottom right)
            subplot('Position', [0.55 0.05 0.44 0.20]);
            residualSPDInMilliWatts = gain*squeeze(comboSPDresiduals(activationLevelIndex, referenceBand, interactingBand,:));
            plot(wavelengthAxis, residualSPDInMilliWatts, 'r-', 'LineWidth', 2.0);
            hL = legend('measured - prediction');
            set(hL, 'FontSize', 12);
            set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)], 'YLim', [-1 1], 'YTick', yTickLevels, 'YTickLabel', sprintf('%2.1f\n', yTickLevels));
            set(gca, 'FontSize', 12);
            xlabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
            ylabel('residual power (mW)', 'FontSize', 14, 'FontWeight', 'bold');
            grid on
            box on
            
            % Write video frame
            drawnow;
            writerObj.writeVideo(getframe(hFig));
        end  % plot comboSPDs 
    end  % spectrumIndex
    
    % Close video stream
    writerObj.close();
    
end


function measureData(rootDir, Svector)

    % check that hardware is responding
    checkHardware();
    
    % Ask for email recipient
    emailRecipient = GetWithDefault('Send status email to','cottaris@psych.upenn.edu');
    
    % Import a calibration 
    cal = OLGetCalibrationStructure;
    
    nPrimariesNum = cal.describe.numWavelengthBands;
    
    % Measure at these levels
    primaryLevels = [0.33 0.66 1.0];
    
    % Measure interactions at +/- these many bands from the reference band
    interactionRange = 10;
    interactingBands = [(-interactionRange:-1) (1:interactionRange)];
 
    % Reference band: One, at the center of the band range
    % referenceBands = round(nPrimariesNum/2);
    
    % Reference bands: Span the range of bands
    referenceBands = interactionRange+1 : interactionRange : nPrimariesNum-(interactionRange+1);
    
    % Repeat 3 times
    nRepeats = 3;
    
    stimPattern = 0;
    for activationLevelIndex = 1:numel(primaryLevels)
        for referenceBandIndex = 1:numel(referenceBands)    
            
            referenceBand = referenceBands(referenceBandIndex);
            for interactingBandIndex = 1:numel(interactingBands)
                
                interactingBand = referenceBand + interactingBands(interactingBandIndex);                
                for spdType = {'singetonSPDi', 'comboSPD'}
                    stimPattern = stimPattern + 1;
                    activation = zeros(nPrimariesNum,1);
                
                    if strcmp(spdType, 'comboSPD')
                        % combo SPD
                        activation(interactingBand) = primaryLevels(activationLevelIndex);
                        activation(referenceBand)   = primaryLevels(activationLevelIndex);
                    elseif strcmp(spdType, 'singetonSPDi')
                        % singleton SPD for the interacting band
                        activation(interactingBand) = primaryLevels(activationLevelIndex);
                        activation(referenceBand)   = 0;
                    else
                        error('What the ?')
                    end
                    
                    data{stimPattern} = struct(...
                        'spdType', spdType, ...
                        'activation', activation, ...
                        'referenceBand', referenceBand, ...
                        'interactingBand', interactingBand, ...
                        'activationLevelIndex', activationLevelIndex, ...
                        'measurementTime', [], ...
                        'measuredSPD', [] ....
                    );
            
                end % for spdType
            end % interactingBandIndex
            
            % singleton for the reference band
            spdType = 'singetonSPDb';
            stimPattern = stimPattern + 1;
            activation = zeros(nPrimariesNum,1);  
            activation(referenceBand)   = primaryLevels(activationLevelIndex);
            data{stimPattern} = struct(...
                        'spdType', spdType, ...
                        'activation', activation, ...
                        'referenceBand', referenceBand, ...
                        'interactingBand', 0, ...
                        'activationLevelIndex', activationLevelIndex, ...
                        'measurementTime', [], ...
                        'measuredSPD', [] ....
                    );
                
        end % for refBandIndex
    end  % for activationLevelIndex
    
    % add dark SPD
    stimPattern = stimPattern + 1;
    activation = zeros(nPrimariesNum,1);
    data{stimPattern} = struct(...
        'spdType', 'dark', ...
        'activation', activation, ...
        'referenceBand', 0, ...
        'interactingBand', 0, ...
        'activationLevelIndex', 0, ...
        'measurementTime', [], ...
        'measuredSPD', [] ....
    );       
                 
    nSpectraMeasured = numel(data);
    fprintf('There will be %d distinct spectra measured (%d reps). \n', nSpectraMeasured, nRepeats);
    
    % Plot the activations (before randomization)
    figure(1);
    clf;
    subplot('Position', [0.04 0.04 0.95 0.95]);
    pcolor(1:nPrimariesNum, 1:nSpectraMeasured, retrieveActivationSequence(data, 1:nSpectraMeasured));
    xlabel('primary no');
    ylabel('spectrum no');
    set(gca, 'CLim', [0 1]);
    title('primary values');
    colormap(gray);
    
    
    spectroRadiometerOBJ = [];
    ol = [];
    
    try
        meterToggle = [1 0];
        od = [];
        nAverage = 1;
        
        spectroRadiometerOBJ = initRadiometerObject();
        
        % Get handle to OneLight
        ol = OneLight;

        % Do all the measurements
        for repeatIndex = 1:nRepeats
         
            % Randomize presentation sequence
            randomizedSpectraIndices(repeatIndex,:) = randperm(nSpectraMeasured); 
            
            % Show randomized stimulation sequence
            figure(2);
            clf;
            subplot('Position', [0.04 0.04 0.95 0.95]);
            pcolor(1:nPrimariesNum, 1:nSpectraMeasured, retrieveActivationSequence(data, squeeze(randomizedSpectraIndices(repeatIndex,:))));
            hold on
            xlabel('primary no');
            ylabel('spectrum no');
            set(gca, 'CLim', [0 1], 'XLim', [1 nPrimariesNum], 'YLim', [0 nSpectraMeasured+1]);
            colormap(gray);
    
            for spectrumIter = 1:nSpectraMeasured
                
                % Show where in the stimulation sequence we are right now.
                figure(2);
                plot([1 nPrimariesNum], (spectrumIter+0.5)*[1 1], 'g-');
                drawnow;
                
                fprintf('Measuring spectrum %d of %d (repeat: %d/%d)\n', spectrumIter, nSpectraMeasured, repeatIndex, nRepeats);
                
                % Get randomized index
                spectrumIndex = randomizedSpectraIndices(repeatIndex,spectrumIter);
                
                primaryValues  = data{spectrumIndex}.activation;
                settingsValues = OLPrimaryToSettings(cal, primaryValues);
                [starts,stops] = OLSettingsToStartsStops(cal,settingsValues);
                measurement = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, Svector, meterToggle, nAverage);
                data{spectrumIndex}.measuredSPD(:, repeatIndex)     = measurement.pr650.spectrum;
                data{spectrumIndex}.measurementTime(:, repeatIndex) = measurement.pr650.time(1);
                data{spectrumIndex}.repeatIndex = repeatIndex;
                
                figure(3);
                clf;
                subplot(2,1,1);
                bar(primaryValues, 1);
                set(gca, 'YLim', [0 1], 'XLim', [0 nPrimariesNum+1]);
                subplot(2,1,2);
                plot(SToWls(Svector), measurement.pr650.spectrum, 'k-');
                drawnow;
            end  % spectrumIter
        end % repeatIndex
        
        % Save data
        filename = fullfile(rootDir,sprintf('BandInteractions_%s_%s.mat', cal.describe.calType, datestr(now, 'dd-mmm-yyyy_HH_MM_SS')));
        save(filename, 'data', 'primaryLevels', 'referenceBands', 'interactingBands', 'nRepeats', 'randomizedSpectraIndices', 'cal', '-v7.3');
        fprintf('Data saved in ''%s''. \n', filename); 
        SendEmail(emailRecipient, 'OneLight Calibration Complete', 'Finished!');
        
        % Shutdown spectroradiometer
        spectroRadiometerOBJ.shutDown();
        
        % Shutdown OneLight
        ol.shutdown();
        
    catch err
        fprintf('Failed with message: ''%s''... ', err.message);
        if (~isempty(spectroRadiometerOBJ))
            % Shutdown spectroradiometer
            spectroRadiometerOBJ.shutDown();
        end
        
        SendEmail(emailRecipient, 'OneLight Calibration Failed', ...
            ['Calibration failed with the following error' err.message]);
        
        if (~isempty(ol))
            % Shutdown OneLight
            ol.shutdown();
        end
        
        keyboard;
        rethrow(e);
    end
end

function activationSequence = retrieveActivationSequence(data, presentationIndices)
    for spectrumIter = 1:numel(presentationIndices)
        % Get presentation index
        spectrumIndex = presentationIndices(spectrumIter);
        activationSequence(spectrumIter,:)  = data{spectrumIndex}.activation;
    end
end

function checkHardware()

    spectroRadiometerOBJ = [];
    ol = [];
    
    try
        spectroRadiometerOBJ = initRadiometerObject();

        spectroRadiometerOBJ.shutDown();
        fprintf('PR670 is good!\n');
        pause(0.5);
        
        ol = OneLight;
        fprintf('One Light is good!\n');
        fprintf('Hit enter to continue  ');
        pause
        
    catch err
        
        if (~isempty(spectroRadiometerOBJ))
            % Shutdown spectroradiometer
            spectroRadiometerOBJ.shutDown();
        end
        
        rethrow(err);
        
    end
    
end


function spectroRadiometerOBJ = initRadiometerObject()

 	radiometerType = GetWithDefault('Enter PR-6XX radiometer type','PR-670');
    spectroRadiometerOBJ = [];
    
    switch (radiometerType)
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
                'sensitivityMode',  'EXTENDED', ... % choose between 'STANDARD' and 'EXTENDED'.  'STANDARD': (exposure range: 6 - 6,000 msec, 'EXTENDED': exposure range: 6 - 30,000 msec
                'exposureTime',     'ADAPTIVE', ... % choose between 'ADAPTIVE' (for adaptive exposure), or a value in the range [6 6000] for 'STANDARD' sensitivity mode, or a value in the range [6 30000] for the 'EXTENDED' sensitivity mode
                'apertureSize',     '1 DEG' ...   % choose between '1 DEG', '1/2 DEG', '1/4 DEG', '1/8 DEG'
            );

        otherwise,
            error('Unknown meter type');
    end
    
end
    
