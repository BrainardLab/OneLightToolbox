function OLCharacterizeNeighboringBandInfluencesOnGamma
% OLCharacterizeNeighboringBandInfluencesOnGamma - Characterize influences of neighboring bands on target band gamma function
% Syntax:
% OLCharacterizeNeighboringBandInfluencesOnGamma
%
% 5/10/16  npc  Wrote it.
%

    [rootDir,~] = fileparts(which(mfilename()));
    cd(rootDir);
    
    radiometerType = GetWithDefault('Enter PR-6XX radiometer type','PR-670');
    switch (radiometerType)
        case 'PR-650'
                Svector = [380 4 101];
        case 'PR-670'
                Svector = [380 2 201];
        otherwise
            error('Unknown radiometer type: ''%s''.', radiometerType)
    end
    
    choice = input('Measure data(0), or analyze data(1) : ', 's');
    if (str2double(choice) == 0)
        measureData(rootDir, Svector, radiometerType);
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
        data{spectrumIndex}.meanSPD = mean(data{spectrumIndex}.measuredSPD, 2);

        % compute min over all reps
        data{spectrumIndex}.minSPD  = min(data{spectrumIndex}.measuredSPD, [], 2);
        
        % compute max over all reps
        data{spectrumIndex}.maxSPD  = max(data{spectrumIndex}.measuredSPD, [], 2);
        
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
    singletonSPDrange = bsxfun(@minus, singletonSPDrange, reshape(darkSPD, [1 1 1 nSpectralSamples]));
    
    % Compute predictions for comboSPDs
    for activationLevelIndex = 1:size(comboSPD,1)
        for referenceBand = 1:size(comboSPD,2)
            for interactingBand = 1:size(comboSPD,3)
                comboSPDprediction(activationLevelIndex, referenceBand, interactingBand,:) = ...
                    darkSPD + ...
                    squeeze(singletonSPD(activationLevelIndex, referenceBand,:)) + ...
                    squeeze(singletonSPD(activationLevelIndex, interactingBand,:));
                
                comboSPDpredictionRange(activationLevelIndex, referenceBand, interactingBand,1,:) = ...
                    darkSPD + ...
                    squeeze(singletonSPDrange(activationLevelIndex, referenceBand,1,:)) + ...
                    squeeze(singletonSPDrange(activationLevelIndex, interactingBand,1,:));
                
                comboSPDpredictionRange(activationLevelIndex, referenceBand, interactingBand,2,:) = ...
                    darkSPD + ...
                    squeeze(singletonSPDrange(activationLevelIndex, referenceBand,2,:)) + ...
                    squeeze(singletonSPDrange(activationLevelIndex, interactingBand,2,:));
                
            end % interactingBandIndex
        end % referenceBandIndex
    end %  activationLevelIndex
    
    
    % Compute max SPD
    maxSPD = max([max(comboSPD(:)) max(comboSPDprediction(:))]);
    
    % Residuals
    comboSPDresiduals  = comboSPD - comboSPDprediction;
    comboSPDpredictionMinError = comboSPDprediction - squeeze(comboSPDpredictionRange(:,:,:,1,:));
    comboSPDpredictionMaxError = comboSPDprediction - squeeze(comboSPDpredictionRange(:,:,:,2,:));
    
    
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
                plot(wavelengthAxis, gain*minSpd, 'r--', 'Color', [0.0 0.4 0.4]);
                plot(wavelengthAxis, gain*maxSpd, 'r--', 'Color', [0.0 0.7 0.7]);
                set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [0 maxSPD*gain]);
                hold off;
                title(sprintf('SPD(band no %d) - darkSPD', bandNo));
            end
        end % bandNo
    end
    
    
    fprintf('\nInteraction data are available for the following reference bands:');
    for k = 1:numel(referenceBands)
        fprintf('%d ', referenceBands(k));
    end
    
    selectedReferenceBand = input(sprintf('\nEnter reference band for visualization : [%d, or ''ALL'' for all] ', referenceBands(1)), 's');
    if (strcmp(selectedReferenceBand, 'ALL'))
        selectedReferenceBand = referenceBands;
    elseif (isempty(selectedReferenceBand))
        selectedReferenceBand = referenceBands(1);
    else
        selectedReferenceBand = str2double(selectedReferenceBand);
        if (isempty(selectedReferenceBand)) || (selectedReferenceBand<1) || (selectedReferenceBand>numel(referenceBands))
            selectedReferenceBand = referenceBands(1);
        else
            selectedReferenceBand = referenceBands(selectedReferenceBand);
        end
    end
    
    theSelectedReferenceBand = selectedReferenceBand;
    
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
    for selectedReferenceBand = theSelectedReferenceBand
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
            residualSPDInMilliWatts  = gain*squeeze(comboSPDresiduals(activationLevelIndex, referenceBand, interactingBand,:));
            comboSPDpredictionMinErrorInMilliWatts = gain*squeeze(comboSPDpredictionMinError(activationLevelIndex, referenceBand, interactingBand,:));
            comboSPDpredictionMaxErrorInMilliWatts = gain*squeeze(comboSPDpredictionMaxError(activationLevelIndex, referenceBand, interactingBand,:));
            plot(wavelengthAxis, residualSPDInMilliWatts, 'r-', 'LineWidth', 2.0);
            hold on
            plot(wavelengthAxis, comboSPDpredictionMinErrorInMilliWatts, 'r--', 'Color', [0.3 0.3 0.3], 'LineWidth', 2.0);
            plot(wavelengthAxis, comboSPDpredictionMaxErrorInMilliWatts, 'r--', 'Color', [0.7 0.7 0.7], 'LineWidth', 2.0);
            hold off
            hL = legend({'measured - prediction', 'prediction error across trials (min)', 'prediction error across trials (max)'});
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
    end
    
    % Close video stream
    writerObj.close();
    
end


function measureData(rootDir, Svector, radiometerType)

    % check that hardware is responding
    %checkHardware();
    
    % Ask for email recipient
    emailRecipient = GetWithDefault('Send status email to','cottaris@psych.upenn.edu');
    
    % Import a calibration 
    cal = OLGetCalibrationStructure;
    
    nPrimariesNum = cal.describe.numWavelengthBands;
    
    fullSet = true;
    
    if (fullSet)
        % Measure at these levels
        interactingBandSettingsLevels = [0.33 0.66 1.0];
        nGammaLevels = 16;
        referenceBandSettingsLevels = linspace(1.0/nGammaLevels, 1.0, nGammaLevels);
    
        % Measure interactions at these bands around the reference band
        interactingBands = { ...
            [        2]; ...
            [      1  ]; ...
            [      1 2]; ...
            [   -1    ]; ...
            [   -1 1  ]; ...
            [   -1   2]; ...
            [   -1 1 2]; ...
            [-2       ];
            [-2      2]; ...
            [-2    1  ]; ...
            [-2    1 2]; ...
            [-2 -1    ]; ...
            [-2 -1 1  ]; ...
            [-2 -1   2]; ...
            [-2 -1 1 2]; ...
            };
 
    else
        % Measure at these levels
        interactingBandSettingsLevels = [0.4 0.8];
        nGammaLevels = 6;
        referenceBandSettingsLevels = linspace(1.0/nGammaLevels, 1.0, nGammaLevels);
    
        % Measure interactions at these bands around the reference band
        interactingBands = { ...
            [   1 ]; ...
            [-1   ]; ...
            [-1 1 ]; ...
            };
        
    end
    
    
    % Reference band: One, at the center of the band range
    referenceBands = round(nPrimariesNum/2);
    
    % Repeat 3 times
    nRepeats = 1;
    
    stimPattern = 0;
    
    % add dark SPD
    spdType =  'dark';
    stimPattern = stimPattern + 1;
    activation = zeros(nPrimariesNum,1);
    data{stimPattern} = struct(...
        'spdType', spdType, ...
        'activation', activation, ...
        'referenceBand', [], ...
        'interactingBands', [], ...
        'referenceBandSettingsIndex', 0, ...
        'interactingBandSettingsIndex', 0, ...
        'measurementTime', [], ...
        'measuredSPD', [] ....
    ); 

    for referenceBandIndex = 1:numel(referenceBands)
        referenceBand = referenceBands(referenceBandIndex);
        for referenceBandSettingsIndex = 1:numel(referenceBandSettingsLevels)
            referenceBandSettings = referenceBandSettingsLevels(referenceBandSettingsIndex);
            
            for interactingBandIndex = 1:numel(interactingBands)
                interactingBand = referenceBand + interactingBands{interactingBandIndex};
                for interactingBandSettingsIndex = 1:numel(interactingBandSettingsLevels)
                    interactingBandSettings = interactingBandSettingsLevels(interactingBandSettingsIndex);
                    
                    spdType = 'comboSPD';
                    stimPattern = stimPattern + 1;
                    activation = zeros(nPrimariesNum,1);
                    activation(interactingBand) = interactingBandSettings;
                    activation(referenceBand) = referenceBandSettings;
                    data{stimPattern} = struct(...
                        'spdType', spdType, ...
                        'activation', activation, ...
                        'referenceBand', referenceBand, ...
                        'interactingBands', interactingBand, ...
                        'referenceBandSettingsIndex', referenceBandSettingsIndex, ...
                        'interactingBandSettingsIndex', interactingBandSettingsIndex, ...
                        'measurementTime', [], ...
                        'measuredSPD', [] ....
                    );
                
                    if (referenceBandSettingsIndex == 1)
                        spdType = 'singletonSPDi';
                        stimPattern = stimPattern + 1;
                        activation = zeros(nPrimariesNum,1);
                        activation(interactingBand) = interactingBandSettings;
                        data{stimPattern} = struct(...
                            'spdType', spdType, ...
                            'activation', activation, ...
                            'referenceBand', referenceBand, ...
                            'interactingBands', interactingBand, ...
                            'referenceBandSettingsIndex', 0, ...
                            'interactingBandSettingsIndex', interactingBandSettingsIndex, ...
                            'measurementTime', [], ...
                            'measuredSPD', [] ....
                        );
                    end
                    
                end % for interactingBandSettingsIndex 
            end % interactingBandIndex
            
            spdType = 'singletonSPDr';
            stimPattern = stimPattern + 1;
            activation = zeros(nPrimariesNum,1);
            activation(referenceBand) = referenceBandSettings;
            data{stimPattern} = struct(...
                        'spdType', spdType, ...
                        'activation', activation, ...
                        'referenceBand', referenceBand, ...
                        'interactingBands', [], ...
                        'referenceBandSettingsIndex', referenceBandSettingsIndex, ...
                        'interactingBandSettingsIndex', 0, ...
                        'measurementTime', [], ...
                        'measuredSPD', [] ....
                    );
                
        end % referenceBandSettingsIndex
    end % referenceBandIndex
    

    nSpectraMeasured = numel(data);
    fprintf('There will be %d distinct spectra measured (%d reps). \n', nSpectraMeasured, nRepeats);
    
    % Plot the activations (before randomization)
    figure(1);
    clf;
    subplot('Position', [0.04 0.04 0.95 0.95]);
    pcolor(1:nPrimariesNum, 1:nSpectraMeasured, retrieveActivationSequence(data, 1:nSpectraMeasured));
    xlabel('primary no');
    ylabel('spectrum no');
    set(gca, 'CLim', [0 1], 'YLim', [0 nSpectraMeasured+1]);
    title('primary values');
    colormap(gray);
    
    pause
    
    spectroRadiometerOBJ = [];
    ol = [];
    
    try
        meterToggle = [1 0];
        od = [];
        nAverage = 1;
        
        spectroRadiometerOBJ = initRadiometerObject(radiometerType);
        
        % Get handle to OneLight
        ol = OneLight;

        % Do all the measurements
        for repeatIndex = 1:nRepeats
         
            % Randomize presentation sequence
            randomizedSpectraIndices(repeatIndex,:) = randperm(nSpectraMeasured); 
            
            % Show randomized stimulation sequence
            hFig = figure(2); set(hFig, 'Position', [10 10 1500 970]);
            clf;
            subplot('Position', [0.04 0.04 0.45 0.95]);
            pcolor(1:nPrimariesNum, 1:nSpectraMeasured, retrieveActivationSequence(data, squeeze(randomizedSpectraIndices(repeatIndex,:))));
            hold on
            xlabel('primary no');
            ylabel('spectrum no');
            set(gca, 'CLim', [0 1], 'XLim', [1 nPrimariesNum], 'YLim', [0 nSpectraMeasured+1]);
            colormap(gray);
    
            for spectrumIter = 1:nSpectraMeasured
                
                % Show where in the stimulation sequence we are right now.
                subplot('Position', [0.04 0.04 0.45 0.95]);
                plot([1 nPrimariesNum], (spectrumIter+0.5)*[1 1], 'g-');
                drawnow;
                
                fprintf('Measuring spectrum %d of %d (repeat: %d/%d)\n', spectrumIter, nSpectraMeasured, repeatIndex, nRepeats);
                
                % Get randomized index
                spectrumIndex = randomizedSpectraIndices(repeatIndex,spectrumIter);
                
                settingsValues  = data{spectrumIndex}.activation;
                [starts,stops] = OLSettingsToStartsStops(cal,settingsValues);
                measurement = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, Svector, meterToggle, nAverage);
                data{spectrumIndex}.measuredSPD(:, repeatIndex)     = measurement.pr650.spectrum;
                data{spectrumIndex}.measurementTime(:, repeatIndex) = measurement.pr650.time(1);
                data{spectrumIndex}.repeatIndex = repeatIndex;
                
                subplot('Position', [0.5 0.04 0.45 0.5]);
                bar(settingsValues, 1);
                set(gca, 'YLim', [0 1], 'XLim', [0 nPrimariesNum+1]);
                subplot('Position', [0.5 0.5 0.45 0.5]);
                plot(SToWls(Svector), measurement.pr650.spectrum, 'k-');
                drawnow;
            end  % spectrumIter
        end % repeatIndex
        
        % Save data
        filename = fullfile(rootDir,sprintf('NeighboringBandInfluencesOnReferenceGamma_%s_%s.mat', cal.describe.calType, datestr(now, 'dd-mmm-yyyy_HH_MM_SS')));
        save(filename, 'data', 'interactingBandSettingsLevels', 'referenceBandSettingsLevels', 'referenceBands', 'interactingBands', 'nRepeats', 'randomizedSpectraIndices', 'cal', '-v7.3');
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


function spectroRadiometerOBJ = initRadiometerObject(radiometerType)

    spectroRadiometerOBJ = [];
    
    switch (radiometerType)
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
    
