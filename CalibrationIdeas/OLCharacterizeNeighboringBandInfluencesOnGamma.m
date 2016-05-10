function OLCharacterizeNeighboringBandInfluencesOnGamma
% OLCharacterizeNeighboringBandInfluencesOnGamma - Characterize influences of neighboring bands on target band gamma function
% Syntax:
% OLCharacterizeNeighboringBandInfluencesOnGamma
%
% 5/10/16  npc  Wrote it.
%

    [rootDir,~] = fileparts(which(mfilename()));
    cd(rootDir);
    
    choice = input('Measure data(0), or analyze data(1) : ', 's');
    if (str2double(choice) == 0)
        radiometerType = GetWithDefault('Enter PR-6XX radiometer type','PR-670');
        switch (radiometerType)
            case 'PR-650'
                    Svector = [380 4 101];
            case 'PR-670'
                    Svector = [380 2 201];
            otherwise
                error('Unknown radiometer type: ''%s''.', radiometerType)
        end
        measureData(rootDir, Svector, radiometerType);
    else
        analyzeData(rootDir);
    end
end


function analyzeData(rootDir)

    [fileName, pathName] = uigetfile('*.mat', 'Select a file to analyze', rootDir);
    load(fileName, 'data', 'Svector', 'interactingBandSettingsLevels', 'referenceBandSettingsLevels', 'referenceBands', 'interactingBands', 'nRepeats', 'randomizedSpectraIndices', 'cal');
    
    for k = 1:numel(interactingBands)
        interactingBandsStrings{k} = sprintf('%d \n', interactingBands{k});
    end
    

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
    
    interactingBandData = containers.Map;
    referenceBandData = containers.Map;
    comboBandData = containers.Map;
    
    allComboKeys = {};
    allSingletonSPDiKeys = {};
    allSingletonSPDrKeys = {};
    
    for spectrumIndex = 1:nSpectraMeasured
        % average over all reps
        data{spectrumIndex}.meanSPD = mean(data{spectrumIndex}.measuredSPD, 2);

        % compute min over all reps
        data{spectrumIndex}.minSPD  = min(data{spectrumIndex}.measuredSPD, [], 2);
        
        % compute max over all reps
        data{spectrumIndex}.maxSPD  = max(data{spectrumIndex}.measuredSPD, [], 2);
        
        referenceBandSettingsIndex = data{spectrumIndex}.referenceBandSettingsIndex;
        interactingBandSettingsIndex = data{spectrumIndex}.interactingBandSettingsIndex;
        interactingBands = data{spectrumIndex}.interactingBands;
        
        referenceBand = data{spectrumIndex}.referenceBand;
        spdType = data{spectrumIndex}.spdType;
        
        if (strcmp(spdType, 'singletonSPDi'))
            interactingBands = referenceBand+interactingBands;
            interactingBandsString = sprintf('%d \n', interactingBands);
            key = sprintf('activationIndex: %d, bands: %s', interactingBandSettingsIndex, interactingBandsString);
            allSingletonSPDiKeys{numel(allSingletonSPDiKeys)+1} = key;
            interactingBandData(key) = struct(...
                'activation', data{spectrumIndex}.activation, ...
                'meanSPD', data{spectrumIndex}.meanSPD, ...
                'minSPD', data{spectrumIndex}.minSPD, ...
                'maxSPD', data{spectrumIndex}.maxSPD ...
            );
 
        elseif (strcmp(spdType, 'singletonSPDr'))
            referenceBandsString = sprintf('%d \n', referenceBand);
            key = sprintf('activationIndex: %d, bands: %s', referenceBandSettingsIndex, referenceBandsString);
            allSingletonSPDrKeys{numel(allSingletonSPDrKeys)+1} = key;
            referenceBandData(key) = struct(...
                'activation', data{spectrumIndex}.activation, ...
                'meanSPD', data{spectrumIndex}.meanSPD, ...
                'minSPD', data{spectrumIndex}.minSPD, ...
                'maxSPD', data{spectrumIndex}.maxSPD ...
            );
            
        elseif (strcmp(spdType, 'comboSPD'))
            
            interactingBands = referenceBand+interactingBands;
            interactingBandsString = sprintf('%d \n', interactingBands);
            referenceBandsString = sprintf('%d \n', referenceBand);
            key = sprintf('activationIndices: [Reference=%d, Interacting=%d], Reference bands:%s Interacting bands:%s', referenceBandSettingsIndex, interactingBandSettingsIndex, referenceBandsString, interactingBandsString);
            allComboKeys{numel(allComboKeys)+1} = key;
            
            comboBandData(key) = struct(...
                'activation', data{spectrumIndex}.activation, ...
                'meanSPD', data{spectrumIndex}.meanSPD, ...
                'minSPD', data{spectrumIndex}.minSPD, ...
                'maxSPD', data{spectrumIndex}.maxSPD, ...
                'referenceBandKey', sprintf('activationIndex: %d, bands: %s', referenceBandSettingsIndex, referenceBandsString), ...
                'interactingBandKey', sprintf('activationIndex: %d, bands: %s', interactingBandSettingsIndex, interactingBandsString), ...
                'predictionSPD', [] ...
            );
            
        elseif (strcmp(spdType, 'dark'))
            darkSPD = data{spectrumIndex}.meanSPD;
            darkSPDrange(1,:) = data{spectrumIndex}.minSPD;
            darkSPDrange(2,:) = data{spectrumIndex}.maxSPD;
        else
            error('How can spdType be ''%s'' ?', spdType)
        end 
    end
    
    % Substract darkSPD from singleton
    selectKeys = keys(interactingBandData);
    for keyIndex = 1:numel(selectKeys)
        key = selectKeys{keyIndex};
        s = interactingBandData(key);
        s.meanSPD = s.meanSPD - darkSPD;
        s.minSPD = s.minSPD - darkSPD;
        s.maxSPD = s.maxSPD - darkSPD;
        interactingBandData(key) = s;
    end
    
    selectKeys = keys(referenceBandData);
    for keyIndex = 1:numel(selectKeys)
        key = selectKeys{keyIndex};
        s = referenceBandData(key);
        s.meanSPD = s.meanSPD - darkSPD;
        s.minSPD = s.minSPD - darkSPD;
        s.maxSPD = s.maxSPD - darkSPD;
        referenceBandData(key) = s;
    end
    
    % Compute combo predictions
    selectKeys = keys(comboBandData);
    maxSPD = 0;
    for keyIndex = 1:numel(selectKeys)
        key = selectKeys{keyIndex};
        s = comboBandData(key);
        refS = referenceBandData(s.referenceBandKey);
        interactingS = interactingBandData(s.interactingBandKey);
        s.predictionSPD = darkSPD + refS.meanSPD + interactingS.meanSPD;
        thisMax = max([max(s.predictionSPD) max(s.meanSPD)]);
        if (thisMax > maxSPD)
            maxSPD = thisMax;
        end
        comboBandData(key) = s;
    end
    
    
    % Plotting
    % plot in milliWatts
    gain = 1000;
    maxSPD = maxSPD * gain;
    
    % Open video stream
    videoFilename = sprintf('%s.m4v', fileName);
    writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
    writerObj.FrameRate = 15; 
    writerObj.Quality = 100;
    writerObj.open();
    
    hFig = figure(11); clf; set(hFig, 'Position', [10 10 1750 1100], 'Color', [1 1 1]);
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', 2, ...
               'colsNum', 2, ...
               'heightMargin',   0.04, ...
               'widthMargin',    0.05, ...
               'leftMargin',     0.05, ...
               'rightMargin',    0.005, ...
               'bottomMargin',   0.04, ...
               'topMargin',      0.01);
           
 
    for keyIndex = 1:numel(allComboKeys) 
        key          = allComboKeys{keyIndex};
        s            = comboBandData(key);
        refS         = referenceBandData(s.referenceBandKey);
        interactingS = interactingBandData(s.interactingBandKey);
        refActivation         = refS.activation;
        interactingActivation = interactingS.activation;
        refSPD              = gain * refS.meanSPD;
        interactingSPD      = gain * interactingS.meanSPD;
        predictedComboSPD   = gain * s.predictionSPD;
        measuredComboSPD    = gain * s.meanSPD;
        
        plotFrame(refActivation, interactingActivation, wavelengthAxis, refSPD, interactingSPD, measuredComboSPD, predictedComboSPD, maxSPD, subplotPosVectors);
        writerObj.writeVideo(getframe(hFig));
    end
   
    % Close video stream
    writerObj.close();
    
end

function plotFrame(refActivation, interactingActivation, wavelengthAxis, refSPD, interactingSPD, measuredComboSPD, predictedComboSPD, maxSPD, subplotPosVectors)
    clf;
    % The activation pattern on top-left
    subplot('Position', subplotPosVectors(1,1).v);
    bar(1:numel(refActivation), refActivation, 1.0, 'FaceColor', [1.0 0.75 0.75], 'EdgeColor', [1 0 0]);
    hold on
    bar(1:numel(interactingActivation), interactingActivation, 1.0, 'FaceColor', [0.75 0.75 1.0], 'EdgeColor', [0 0 1]);
    hold off;
    set(gca, 'YLim', [0 1.1], 'XLim', [0 numel(refActivation)+1]);
    hL = legend({'reference band', 'interacting band'});
    set(hL, 'FontSize', 12);
    set(gca, 'FontSize', 12);
    xlabel('band no', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('settings value', 'FontSize', 14, 'FontWeight', 'bold');

    % The reference and interacting SPDs pattern on top-right
    subplot('Position', subplotPosVectors(1,2).v);
    x = [wavelengthAxis(1) wavelengthAxis' wavelengthAxis(end)];
    baseline = min([0 min(refSPD)]);
    y = [baseline refSPD' baseline]; 
    patch(x,y, 'green', 'FaceColor', [1.0 0.8 0.8], 'EdgeColor', [1.0 0. 0.], 'EdgeAlpha', 0.5, 'LineWidth', 2.0);
    hold on
    baseline = min([0 min(interactingSPD)]);
    y = [baseline interactingSPD' baseline]; 
    patch(x,y, 'green', 'FaceColor', [0.8 0.8 1.0], 'EdgeColor', [0.0 0. 1], 'EdgeAlpha', 0.5, 'FaceAlpha', 0.5, 'LineWidth', 2.0);
    hold off;
    hL = legend('reference band SPD', 'interacting band SPD');
    set(hL, 'FontSize', 12);
    set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [0 maxSPD], 'XTick', [300:25:800]);
    set(gca, 'FontSize', 12);
    xlabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('power (mW)', 'FontSize', 14, 'FontWeight', 'bold');
    grid on
    box on

    % The measured and predicted combo SPDs on bottom-left
    subplot('Position', subplotPosVectors(2,1).v);
    baseline = min([0 min(predictedComboSPD)]);
    y = [baseline predictedComboSPD' baseline]; 
    patch(x,y, 'green', 'FaceColor', [1.0 0.1 0.9], 'EdgeColor', [1.0 0.1 0.9], 'EdgeAlpha', 1.0,  'LineWidth', 2.0);
    hold on
    baseline = min([0 min(measuredComboSPD)]);
    y = [baseline measuredComboSPD' baseline]; 
    patch(x,y, 'green', 'FaceColor', [1.0 0.8 0.2], 'EdgeColor', [1.0 0.8 0.2], 'EdgeAlpha', 0.5, 'FaceAlpha', 0.4, 'LineWidth', 2.0);
    hold off;
    hL = legend('predicted combo SPD', 'measured combo SPD');
    set(hL, 'FontSize', 12);
    set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [0 maxSPD], 'XTick', [300:25:800]);
    set(gca, 'FontSize', 12);
    xlabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('power (mW)', 'FontSize', 14, 'FontWeight', 'bold');
    grid on
    box on

    % The residual (measured - predicted combo SPDs) on bottom-right
    subplot('Position', subplotPosVectors(2,2).v);
    y = [0 (measuredComboSPD-predictedComboSPD)' 0];
    patch(x,y, 'green', 'FaceColor', [0.3 0.8 0.9], 'EdgeColor', [0.2 0.2 0.2], 'EdgeAlpha', 0.7, 'LineWidth', 2.0);
    hL = legend('measured combo SPD - predicted combo SPD');
    set(hL, 'FontSize', 12);
    set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [-5 5], 'XTick', [300:25:800]);
    set(gca, 'FontSize', 12);
    xlabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('power (mW)', 'FontSize', 14, 'FontWeight', 'bold');
    grid on
    box on
    
    drawnow;
end


function measureData(rootDir, Svector, radiometerType)

    % check that hardware is responding
    %checkHardware();
    
    % Ask for email recipient
    emailRecipient = GetWithDefault('Send status email to','cottaris@psych.upenn.edu');
    
    % Import a calibration 
    cal = OLGetCalibrationStructure;
    
    nPrimariesNum = cal.describe.numWavelengthBands;
    
    fullSet = false;
    
    if (fullSet)
        % Measure at these levels
        interactingBandSettingsLevels = [0.33 0.66 1.0];
        nGammaLevels = 24;
        referenceBandSettingsLevels = linspace(1.0/nGammaLevels, 1.0, nGammaLevels);
    
        % Measure interactions at these bands around the reference band
        pattern0 = [3 4];
        pattern1 = [1 2];
        pattern2 = [-2 -1];
        pattern3 = [-4 -3];
        
        interactingBands = { ...
            [                                       pattern0(:) ]; ...
            [                           pattern1(:)             ]; ...
            [                           pattern1(:) pattern0(:) ]; ...
            [               pattern2(:)                         ]; ...
            [               pattern2(:) pattern1(:)             ]; ...
            [               pattern2(:)             pattern0(:) ]; ...
            [               pattern2(:) pattern1(:) pattern0(:) ]; ...
            [                                       pattern0(:) ]; ...
            [pattern3(:)               pattern1(:)              ]; ...
            [pattern3(:)               pattern1(:) pattern0(:)  ]; ...
            [pattern3(:)   pattern2(:)                          ]; ...
            [pattern3(:)   pattern2(:) pattern1(:)              ]; ...
            [pattern3(:)   pattern2(:)             pattern0(:)  ]; ...
            [pattern3(:)   pattern2(:) pattern1(:) pattern0(:)  ]; ...
            };
 
            % Repeat 3 times
            nRepeats = 1;
    
    else
        % Measure at these levels
        interactingBandSettingsLevels = [0.4 0.8];
        nGammaLevels = 6;
        referenceBandSettingsLevels = linspace(1.0/nGammaLevels, 1.0, nGammaLevels);
    
        % Measure interactions at these bands around the reference band
        pattern0 = [1 2 3 4];
        pattern1 = [-4 -3 -2 -1];
        interactingBands = { ...
            [            pattern0(:)]; ...
            [pattern1(:)            ]; ...
            [pattern1(:) pattern0(:)]; ...
            };
        
        % Repeat 3 times
        nRepeats = 3;
    end
    
    
    % Reference band: One, at the center of the band range
    referenceBands = round(nPrimariesNum/2);
    
    
    stimPattern = 0;
    
    % add dark SPD
    spdType =  'dark';
    stimPattern = stimPattern + 1;
    activation = zeros(nPrimariesNum,1);
    data{stimPattern} = struct(...
        'spdType', spdType, ...
        'activation', activation, ...
        'referenceBandIndex', [], ...
        'interactingBandsIndex', [], ...
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
                        'referenceBandIndex', referenceBandIndex, ...
                        'interactingBandsIndex', interactingBandIndex, ...
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
                            'referenceBandIndex', referenceBandIndex, ...
                            'interactingBandsIndex', interactingBandIndex, ...
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
                        'referenceBandIndex', referenceBandIndex, ...
                        'interactingBandsIndex', [], ...
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
                
                subplot('Position', [0.5 0.04 0.45 0.47]);
                bar(settingsValues, 1);
                set(gca, 'YLim', [0 1], 'XLim', [0 nPrimariesNum+1]);
                subplot('Position', [0.5 0.52 0.45 0.47]);
                plot(SToWls(Svector), measurement.pr650.spectrum, 'k-');
                drawnow;
            end  % spectrumIter
        end % repeatIndex
        
        % Save data
        filename = fullfile(rootDir,sprintf('NeighboringBandInfluencesOnReferenceGamma_%s_%s.mat', cal.describe.calType, datestr(now, 'dd-mmm-yyyy_HH_MM_SS')));
        save(filename, 'data', 'Svector', 'interactingBandSettingsLevels', 'referenceBandSettingsLevels', 'referenceBands', 'interactingBands', 'nRepeats', 'randomizedSpectraIndices', 'cal', '-v7.3');
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
    
