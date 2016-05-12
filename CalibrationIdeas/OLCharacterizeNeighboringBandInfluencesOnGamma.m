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


function data = doLinearDriftCorrection(uncorrectedData, nRepeats)
    data = uncorrectedData;
    nSpectraMeasured = numel(data);
    allTimes = zeros(nRepeats*nSpectraMeasured,1);
   
    % Find the spectumIndex with the max activation
    maxActivation = 0;
    k = 0;
    for repeatIndex = 1:nRepeats
        for spectrumIndex = 1:nSpectraMeasured
            k = k + 1;
            totalActivation = sum(data{spectrumIndex}.activation);
            if (totalActivation > maxActivation)
                maxActivation = totalActivation;
                maxActivationSpectrumIndex = spectrumIndex;
            end
            allTimes(k) = data{spectrumIndex}.measurementTime(1, repeatIndex);
        end
    end
    
    t0 = squeeze(data{maxActivationSpectrumIndex}.measurementTime(1, 1));
    t1 = squeeze(data{maxActivationSpectrumIndex}.measurementTime(1, nRepeats));
    s0 = squeeze(data{maxActivationSpectrumIndex}.measuredSPD(:, 1));
    s1 = squeeze(data{maxActivationSpectrumIndex}.measuredSPD(:, nRepeats));
    % find the scaling factor based on points that are > 5% of the peak SPD
    indices = find(s1 > max(s1)*0.05);
    s = s0(indices) \ s1(indices);
    scalingFactor = @(t) 1./((1-(1-s)*((t-t0)./(t1-t0))));
    
    % Do the spectrum scaling correction
    for repeatIndex = 1:nRepeats
        for spectrumIndex = 1:nSpectraMeasured
            timeOfMeasurement = squeeze(data{spectrumIndex}.measurementTime(1, repeatIndex));
            data{spectrumIndex}.measuredSPD(:, repeatIndex) = data{spectrumIndex}.measuredSPD(:, repeatIndex) * scalingFactor(timeOfMeasurement);
            fprintf('Scaling spectrum %d (repat: %d) by %2.4f\n', spectrumIndex, repeatIndex, scalingFactor(timeOfMeasurement));
        end
    end
    
    plotScalingExample = false;
    if (plotScalingExample)
        t = sort(allTimes);
        correction = returnScaleFactor(t);
        figure(1);
        plot(t, correction, 'k-', 'LineWidth', 4.0);
        hold on;
        tt = t((t>=t0) & (t <=t1));
        plot(tt, returnScaleFactor(tt), 'rs');
        drawnow;


        figure(2); clf
        subplot(1,2,1);
        plot(1:numel(s0), s0, 'r-');
        hold on;
        plot(1:numel(s0), s1, 'b-');

        subplot(1,2,2);
        plot(1:numel(s0), s0*scalingFactor(t0), 'r-', 'LineWidth', 2.0);
        hold on;
        plot(1:numel(s0), s1*scalingFactor(t1), 'b:', 'LineWidth', 2.0);
        drawnow;
    end
    
end

function analyzeData(rootDir)

    [fileName, pathName] = uigetfile('*.mat', 'Select a file to analyze', rootDir);
    load(fileName, 'data', 'Svector', 'interactingBandSettingsLevels', 'referenceBandSettingsLevels', 'referenceBands', 'interactingBands', 'nRepeats', 'randomizedSpectraIndices', 'cal');
    
    data = doLinearDriftCorrection(data, nRepeats);
    
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
        
        referenceBandIndex = data{spectrumIndex}.referenceBandIndex;
        interactingBandsIndex = data{spectrumIndex}.interactingBandsIndex;
        referenceBandSettingsIndex = data{spectrumIndex}.referenceBandSettingsIndex;
        interactingBandSettingsIndex = data{spectrumIndex}.interactingBandSettingsIndex;
        if (isempty(interactingBandsIndex))
            theInteractingBands = [];
        else
            theInteractingBands = interactingBands{interactingBandsIndex}; 
        end
        theReferenceBand = referenceBands(data{spectrumIndex}.referenceBandIndex);
        
        spdType = data{spectrumIndex}.spdType;
        
        if (strcmp(spdType, 'singletonSPDi'))
            interactingBandsForThisCondition = theReferenceBand+theInteractingBands;
            interactingBandsString = sprintf('%d \n', interactingBandsForThisCondition);
            key = sprintf('activationIndex: %d, bands: %s', interactingBandSettingsIndex, interactingBandsString);
            allSingletonSPDiKeys{numel(allSingletonSPDiKeys)+1} = key;
            interactingBandData(key) = struct(...
                'activation', data{spectrumIndex}.activation, ...
                'settingsValue', interactingBandSettingsLevels(data{spectrumIndex}.interactingBandSettingsIndex), ...
                'allSPDs', data{spectrumIndex}.measuredSPD, ...
                'meanSPD', data{spectrumIndex}.meanSPD, ...
                'minSPD', data{spectrumIndex}.minSPD, ...
                'maxSPD', data{spectrumIndex}.maxSPD ...
            );
 
        elseif (strcmp(spdType, 'singletonSPDr'))
            referenceBandsString = sprintf('%d \n', theReferenceBand);
            key = sprintf('activationIndex: %d, bands: %s', referenceBandSettingsIndex, referenceBandsString);
            allSingletonSPDrKeys{numel(allSingletonSPDrKeys)+1} = key;
            referenceBandData(key) = struct(...
                'activation', data{spectrumIndex}.activation, ...
                'settingsValue', referenceBandSettingsLevels(data{spectrumIndex}.referenceBandSettingsIndex), ...
                'allSPDs', data{spectrumIndex}.measuredSPD, ...
                'meanSPD', data{spectrumIndex}.meanSPD, ...
                'minSPD', data{spectrumIndex}.minSPD, ...
                'maxSPD', data{spectrumIndex}.maxSPD ...
            );
            
        elseif (strcmp(spdType, 'comboSPD'))
            interactingBandsForThisCondition = theReferenceBand+theInteractingBands;
            interactingBandsString = sprintf('%d \n', interactingBandsForThisCondition);
            referenceBandsString = sprintf('%d \n', theReferenceBand);
            key = sprintf('activationIndices: [Reference=%d, Interacting=%d], Reference bands:%s Interacting bands:%s', referenceBandSettingsIndex, interactingBandSettingsIndex, referenceBandsString, interactingBandsString);
            
            % arrange according to interactingBandsIndex
            comboKeyIndex =  (referenceBandIndex-1) * numel(referenceBandSettingsLevels)*(numel(interactingBands))*numel(interactingBandSettingsLevels) + ...
                             (referenceBandSettingsIndex-1) * (numel(interactingBands))*numel(interactingBandSettingsLevels) + ...
                             (interactingBandSettingsIndex-1)*(numel(interactingBands)) + interactingBandsIndex;
            
            % arrange according to interactingBandSettingsIndex
            comboKeyIndex =  (referenceBandIndex-1) * numel(referenceBandSettingsLevels)*(numel(interactingBands))*numel(interactingBandSettingsLevels) + ...
                             (referenceBandSettingsIndex-1) * (numel(interactingBands))*numel(interactingBandSettingsLevels) + ...
                             (interactingBandsIndex-1)* numel(interactingBandSettingsLevels) + interactingBandSettingsIndex;
                         
            % arrange so we get gamma data for each condition
            comboKeyIndex = (referenceBandIndex-1) * (numel(interactingBands)) * (numel(interactingBandSettingsLevels)) * (numel(referenceBandSettingsLevels)) + ...
                            (interactingBandsIndex-1) * (numel(interactingBandSettingsLevels)) * (numel(referenceBandSettingsLevels)) + ...
                            (interactingBandSettingsIndex-1) * numel(referenceBandSettingsLevels) + referenceBandSettingsIndex;
            
            [comboKeyIndex referenceBandIndex referenceBandSettingsIndex interactingBandsIndex interactingBandSettingsIndex]
            %comboKeyIndex = numel(allComboKeys)+1;
            
            allComboKeys{comboKeyIndex} = key;
            q(comboKeyIndex,:) = [referenceBandIndex referenceBandSettingsIndex interactingBandsIndex interactingBandSettingsIndex];
            comboBandData(key) = struct(...
                'activation', data{spectrumIndex}.activation, ...
                'allSPDs', data{spectrumIndex}.measuredSPD, ...
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
    maxSPD = round((maxSPD+4)/10)*10;
    
    generateVideo = true;
    
    if (generateVideo)
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
                   'heightMargin',   0.05, ...
                   'widthMargin',    0.05, ...
                   'leftMargin',     0.04, ...
                   'rightMargin',    0.005, ...
                   'bottomMargin',   0.04, ...
                   'topMargin',      0.005);
    end
    
 
    maxResidualSPD = zeros(1,numel(allComboKeys));
    for keyIndex = 1:numel(allComboKeys) 
        key          = allComboKeys{keyIndex};
        s            = comboBandData(key);
        refS         = referenceBandData(s.referenceBandKey);
        interactingS = interactingBandData(s.interactingBandKey);
        refSettingsValue     = refS.settingsValue;
        refActivation         = refS.activation;
        interactingActivation = interactingS.activation;
        interactingSettingsValue = interactingS.settingsValue;
        refSPD              = gain * refS.meanSPD;
        refSPDmin           = gain * refS.minSPD;
        refSPDmax           = gain * refS.maxSPD;
        interactingSPD      = gain * interactingS.meanSPD;
        interactingSPDmin   = gain * interactingS.minSPD;
        interactingSPDmax   = gain * interactingS.maxSPD;
        predictedComboSPD   = gain * s.predictionSPD;
        measuredComboAllSPDs= gain * s.allSPDs;
        measuredComboSPD    = gain * s.meanSPD;
        measuredComboSPDmin = gain * s.minSPD;
        measuredComboSPDmax = gain * s.maxSPD;
        maxResidualSPD(keyIndex)  = max(abs(measuredComboSPD - predictedComboSPD));
        if (generateVideo)
            plotFrame(refActivation, interactingActivation, wavelengthAxis, refSettingsValue, interactingSettingsValue, refSPD, refSPDmin, refSPDmax, interactingSPD, interactingSPDmin, interactingSPDmax, measuredComboAllSPDs, measuredComboSPD, predictedComboSPD, measuredComboSPDmin, measuredComboSPDmax, maxSPD, subplotPosVectors);
            writerObj.writeVideo(getframe(hFig));
        end
    end
   
    if (generateVideo)
        % Close video stream
        writerObj.close();
    end
    
    % Now show SPDs in decreasing residual error
    [~, indices] = sort(maxResidualSPD, 'descend');
    
    
    % Open video stream
    videoFilename = sprintf('%s_ranked.m4v', fileName);
    writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
    writerObj.FrameRate = 15; 
    writerObj.Quality = 100;
    writerObj.open();
        
    measurementsPerFigure = 4;
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
                   'rowsNum', 4, ...
                   'colsNum', measurementsPerFigure, ...
                   'heightMargin',   0.05, ...
                   'widthMargin',    0.02, ...
                   'leftMargin',     0.02, ...
                   'rightMargin',    0.005, ...
                   'bottomMargin',   0.04, ...
                   'topMargin',      0.005);
               
    hFig = figure(100); set(hFig, 'Position', [1 1 2000 1150], 'Color', [1 1 1]);
    
    for groupNo = 1:floor(numel(allComboKeys)/measurementsPerFigure)
        clf;
  
        for k = 1:measurementsPerFigure
            key     = allComboKeys{indices((groupNo-1)*measurementsPerFigure+k)};
            s            = comboBandData(key);
            refS         = referenceBandData(s.referenceBandKey);
            interactingS = interactingBandData(s.interactingBandKey);
            refSettingsValue     = refS.settingsValue;
            refActivation         = refS.activation;
            interactingActivation = interactingS.activation;
            interactingSettingsValue = interactingS.settingsValue;
            refSPD              = gain * refS.meanSPD;
            refSPDmin           = gain * refS.minSPD;
            refSPDmax           = gain * refS.maxSPD;
            interactingSPD      = gain * interactingS.meanSPD;
            interactingSPDmin   = gain * interactingS.minSPD;
            interactingSPDmax   = gain * interactingS.maxSPD;
            predictedComboSPD   = gain * s.predictionSPD;
            measuredComboSPD    = gain * s.meanSPD;
            measuredComboSPDmin = gain * s.minSPD;
            measuredComboSPDmax = gain * s.maxSPD;
            maxResidualSPD  = max(abs(measuredComboSPD - predictedComboSPD)); 
            meanResidualSPD = mean(abs(measuredComboSPD - predictedComboSPD));
            plotSummarySubFrame(refActivation, interactingActivation, wavelengthAxis, refSettingsValue, interactingSettingsValue, refSPD, refSPDmin, refSPDmax, interactingSPD, interactingSPDmin, interactingSPDmax, measuredComboSPD, predictedComboSPD, measuredComboSPDmin, measuredComboSPDmax, maxSPD, maxResidualSPD, meanResidualSPD ,squeeze(subplotPosVectors(:,k)));
        end
        
        writerObj.writeVideo(getframe(hFig));
        pause(0.5);
    end % groupNo
    
    writerObj.close();
    
end

function plotSummarySubFrame(refActivation, interactingActivation, wavelengthAxis, referenceSettingsValue, interactingSettingsValue, refSPD, refSPDmin, refSPDmax, interactingSPD, interactingSPDmin, interactingSPDmax, measuredComboSPD, predictedComboSPD, measuredComboSPDmin, measuredComboSPDmax, maxSPD, maxResidualSPD, meanResidualSPD ,subplotPosVectors)
% The activation pattern on top-left
    subplot('Position', subplotPosVectors(1,1).v);
    bar(1:numel(refActivation), refActivation, 1.0, 'FaceColor', [1.0 0.75 0.75], 'EdgeColor', [1 0 0], 'EdgeAlpha', 0.5, 'LineWidth', 1.5);
    hold on
    bar(1:numel(interactingActivation), interactingActivation, 1.0, 'FaceColor', [0.75 0.75 1.0], 'EdgeColor', [0 0 1], 'EdgeAlpha', 0.7, 'LineWidth', 1.5);
    hold off;
    set(gca, 'YLim', [0 1.0], 'XLim', [0 numel(refActivation)+1]);
    %hL = legend({'reference band', 'interacting band(s)'}, 'Location', 'SouthWest');
    %legend boxoff;
    %set(hL, 'FontSize', 12, 'FontName', 'Menlo');
    %set(gca, 'FontSize', 12);
    xlabel('band no', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('settings value', 'FontSize', 14, 'FontWeight', 'bold');
    box off;
    
    % The reference and interacting SPDs pattern on top-right
    subplot('Position', subplotPosVectors(2,1).v);
    x = [wavelengthAxis(1) wavelengthAxis' wavelengthAxis(end)];
    baseline = min([0 min(refSPD)]);
    y = [baseline refSPD' baseline]; 
    patch(x,y, 'green', 'FaceColor', [1.0 0.8 0.8], 'EdgeColor', [1.0 0. 0.], 'EdgeAlpha', 0.5, 'LineWidth', 2.0);
    hold on
    plot(wavelengthAxis, refSPDmin, '-', 'Color', [0 0 0]);
    plot(wavelengthAxis, refSPDmax, '-', 'Color', [0 0 0]);
    baseline = min([0 min(interactingSPD)]);
    y = [baseline interactingSPD' baseline]; 
    patch(x,y, 'green', 'FaceColor', [0.8 0.8 1.0], 'EdgeColor', [0.0 0. 1], 'EdgeAlpha', 0.5, 'FaceAlpha', 0.5, 'LineWidth', 2.0);
    plot(wavelengthAxis, interactingSPDmin, '-', 'Color', [0 0 0]);
    plot(wavelengthAxis, interactingSPDmax, '-', 'Color', [0 0 0]);
    hold off;
    %hL = legend('reference band SPD', 'reference band SPD(min)', 'reference band SPD(max)', 'interacting band(s) SPD', 'interacting band(s) SPD (min)', 'interacting band(s) SPD (max)', 'Location', 'SouthWest');
    %set(hL, 'FontSize', 12, 'FontName', 'Menlo');
    %legend boxoff;
    set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [0 maxSPD], 'XTick', [300:25:800]);
    set(gca, 'FontSize', 12);
    xlabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('power (mW)', 'FontSize', 14, 'FontWeight', 'bold');
    grid on
    box off

    % The measured and predicted combo SPDs on bottom-left
    subplot('Position', subplotPosVectors(3,1).v);
    plot(wavelengthAxis,predictedComboSPD, '-', 'Color', [1.0 0.1 0.9], 'LineWidth', 2.0);
    hold on;
    plot(wavelengthAxis,measuredComboSPD, '-', 'Color', [0.1 0.8 0.5],  'LineWidth', 2.0);
    
    %baseline = min([0 min(predictedComboSPD)]);
    %y = [baseline predictedComboSPD' baseline]; 
    %patch(x,y, 'green', 'FaceColor', [1.0 0.1 0.9], 'EdgeColor', [1.0 0.1 0.9], 'EdgeAlpha', 1.0,  'LineWidth', 2.0);
    %hold on
    %baseline = min([0 min(measuredComboSPD)]);
    %y = [baseline measuredComboSPD' baseline]; 
    %patch(x,y, 'green', 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', [0.7 0.7 0.7], 'EdgeAlpha', 0.5, 'FaceAlpha', 0.4, 'LineWidth', 2.0);
    plot(wavelengthAxis, measuredComboSPDmin, '-', 'Color', [0 0 0]);
    plot(wavelengthAxis, measuredComboSPDmax, '-', 'Color', [0 0 0]);
    hold off;
    hL = legend('predicted SPD', 'measured SPD', 'measured SPD (min)', 'measured SPD (max)', 'Location', 'SouthWest');
    set(hL, 'FontSize', 12, 'FontName', 'Menlo');
    legend boxoff;
    set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [0 maxSPD], 'XTick', [300:25:800]);
    set(gca, 'FontSize', 12, 'FontName', 'Menlo');
    xlabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('power (mW)', 'FontSize', 14, 'FontWeight', 'bold');
    grid on
    box off

    % The residual (measured - predicted combo SPDs) on bottom-right
    subplot('Position', subplotPosVectors(4,1).v);
    y = [0 (measuredComboSPD-predictedComboSPD)' 0];
    patch(x,y, 'green', 'FaceColor', [0.3 0.8 1.0], 'EdgeColor', [0.2 0.6 0.6], 'FaceAlpha', 0.7, 'EdgeAlpha', 0.9, 'LineWidth', 2.0);
    hold on;
    plot(wavelengthAxis, measuredComboSPD-measuredComboSPDmin, 'k--', 'LineWidth', 2.0);
    plot(wavelengthAxis, measuredComboSPD-measuredComboSPDmax, 'k:',  'LineWidth', 2.0);
    
    %hL = legend('measured SPD - predicted SPD', 'measured SPD - measured SPDmin', 'measured SPD - measured SPDmax', 'Location', 'SouthWest');
    %set(hL, 'FontSize', 12, 'FontName', 'Menlo');
    %legend boxoff;
    set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [-5 5], 'XTick', [300:25:800]);
    set(gca, 'FontSize', 12);
    xlabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('residual power (mW)', 'FontSize', 14, 'FontWeight', 'bold');
    grid on
    box off
    
    text(385, 4.7, sprintf('reference   band  settings: %2.2f', referenceSettingsValue), 'Color', [1.0 0.3 0.3], 'FontName', 'Menlo', 'FontSize', 12);
    text(385, 4.2, sprintf('interacting band(s) settings: %2.2f', interactingSettingsValue), 'Color', [0.3 0.3 1.0],'FontName', 'Menlo', 'FontSize', 12);
    %text(385, 3.7, sprintf('residualSPD: max = %2.2f mW, mean = %2.2f mW', maxResidualSPD, meanResidualSPD), 'Color', [0.3 0.3 0.3],'FontName', 'Menlo', 'FontSize', 14);
    drawnow;
    
end

function plotFrame(refActivation, interactingActivation, wavelengthAxis, referenceSettingsValue, interactingSettingsValue, refSPD, refSPDmin, refSPDmax, interactingSPD, interactingSPDmin, interactingSPDmax, measuredComboAllSPDs, measuredComboSPD, predictedComboSPD, measuredComboSPDmin, measuredComboSPDmax, maxSPD, subplotPosVectors)
    clf;
    % The activation pattern on top-left
    subplot('Position', subplotPosVectors(1,1).v);
    bar(1:numel(refActivation), refActivation, 1.0, 'FaceColor', [1.0 0.75 0.75], 'EdgeColor', [1 0 0], 'EdgeAlpha', 0.5, 'LineWidth', 1.5);
    hold on
    bar(1:numel(interactingActivation), interactingActivation, 1.0, 'FaceColor', [0.75 0.75 1.0], 'EdgeColor', [0 0 1], 'EdgeAlpha', 0.7, 'LineWidth', 1.5);
    hold off;
    set(gca, 'YLim', [0 1.0], 'XLim', [0 numel(refActivation)+1]);
    hL = legend({'reference band', 'interacting band(s)'}, 'Location', 'SouthWest');
    legend boxoff;
    set(hL, 'FontSize', 14, 'FontName', 'Menlo');
    set(gca, 'FontSize', 14);
    xlabel('band no', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('settings value', 'FontSize', 16, 'FontWeight', 'bold');
    box off;
    
    % The reference and interacting SPDs pattern on top-right
    subplot('Position', subplotPosVectors(1,2).v);
    x = [wavelengthAxis(1) wavelengthAxis' wavelengthAxis(end)];
    baseline = min([0 min(refSPD)]);
    y = [baseline refSPD' baseline]; 
    patch(x,y, 'green', 'FaceColor', [1.0 0.8 0.8], 'EdgeColor', [1.0 0. 0.], 'EdgeAlpha', 0.5, 'LineWidth', 2.0);
    hold on
    plot(wavelengthAxis, refSPDmin, '-', 'Color', [0 0 0]);
    plot(wavelengthAxis, refSPDmax, '-', 'Color', [0 0 0]);
    baseline = min([0 min(interactingSPD)]);
    y = [baseline interactingSPD' baseline]; 
    patch(x,y, 'green', 'FaceColor', [0.8 0.8 1.0], 'EdgeColor', [0.0 0. 1], 'EdgeAlpha', 0.5, 'FaceAlpha', 0.5, 'LineWidth', 2.0);
    plot(wavelengthAxis, interactingSPDmin, '-', 'Color', [0 0 0]);
    plot(wavelengthAxis, interactingSPDmax, '-', 'Color', [0 0 0]);
    hold off;
    hL = legend('reference band SPD', 'reference band SPD(min)', 'reference band SPD(max)', 'interacting band(s) SPD', 'interacting band(s) SPD (min)', 'interacting band(s) SPD (max)', 'Location', 'SouthWest');
    set(hL, 'FontSize', 14, 'FontName', 'Menlo');
    legend boxoff;
    set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [0 maxSPD], 'XTick', [300:25:800]);
    set(gca, 'FontSize', 14);
    xlabel('wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('power (mW)', 'FontSize', 16, 'FontWeight', 'bold');
    grid on
    box off

    % The measured and predicted combo SPDs on bottom-left
    repeatsColors = colormap(jet(2+size(measuredComboAllSPDs,2)));
    subplot('Position', subplotPosVectors(2,1).v);
    allLegends = {};
    for k = 1:size(measuredComboAllSPDs,2)
        allLegends{k} = sprintf('measured SPD (#%d)\n', k);
        plot(wavelengthAxis,squeeze(measuredComboAllSPDs(:,k)), '-', 'Color', squeeze(repeatsColors(k+1,:)), 'LineWidth', 1.5);
        if (k == 1)
            hold on;
        end
    end
    plot(wavelengthAxis,measuredComboSPD, '-', 'Color', [0.1 0.1 0.1],  'LineWidth', 3.0);
    plot(wavelengthAxis,predictedComboSPD, '-', 'Color', [1.0 0.1 0.9], 'LineWidth', 3.0);
    hold off;
    
    allLegends{numel(allLegends)+1} = 'measured SPD (mean)';
    allLegends{numel(allLegends)+1} = 'predicted SPD (mean)';
     
    hL = legend(allLegends);
    set(hL, 'FontSize', 14, 'FontName', 'Menlo');
    legend boxoff;
    set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [0 maxSPD], 'XTick', [300:25:800]);
    set(gca, 'FontSize', 14, 'FontName', 'Menlo');
    xlabel('wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('power (mW)', 'FontSize', 16, 'FontWeight', 'bold');
    grid on
    box off

    % The residual (measured - predicted combo SPDs) on bottom-right
    subplot('Position', subplotPosVectors(2,2).v);
    
    
    allLegends = {};
    for k = 1:size(measuredComboAllSPDs,2)
        allLegends{k} = sprintf('measured SPDmean - measuredSPD(#%d)\n', k);
        plot(wavelengthAxis, measuredComboSPD-squeeze(measuredComboAllSPDs(:,k)), '-', 'Color', squeeze(repeatsColors(k+1,:)), 'LineWidth', 2.0);
        if (k == 1)
            hold on;
        end
    end
    y = [0 (measuredComboSPD-predictedComboSPD)' 0];
    patch(x,y, 'green', 'FaceColor', [0.6 0.6 0.6], 'EdgeColor', [0.3 0.3 0.3], 'FaceAlpha', 0.7, 'EdgeAlpha', 0.9, 'LineWidth', 2.0);
    hold off;
    allLegends{numel(allLegends)+1} = 'measured SPDmean - predicted SPD';
    
    hL = legend(allLegends, 'Location', 'SouthWest');
    set(hL, 'FontSize', 14, 'FontName', 'Menlo');
    legend boxoff;
    set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [-3 3], 'XTick', [300:25:800]);
    set(gca, 'FontSize', 14);
    xlabel('wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('residual power (mW)', 'FontSize', 16, 'FontWeight', 'bold');
    grid on
    box off
    
    text(385, 2.7, sprintf('reference   band  settings: %2.2f', referenceSettingsValue), 'Color', [1.0 0.3 0.3], 'FontName', 'Menlo', 'FontSize', 14);
    text(385, 2.2, sprintf('interacting band(s) settings: %2.2f', interactingSettingsValue), 'Color', [0.3 0.3 1.0],'FontName', 'Menlo', 'FontSize', 14);
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
    
    % Reference band: One, at the center of the band range
    referenceBands = round(nPrimariesNum/2);
    
    setType = 'combinatorialFull';
    %setType = 'combinatorialSmall';
    %setType = 'slidingInteraction';
    
    % How many times to repeat each measurement
    nRepeats = 6;
            
    if (strcmp(setType, 'slidingInteraction'))
        % Measure at these levels
        interactingBandSettingsLevels = [0.25 0.50 0.75 1.0];
        nGammaLevels = 16;
        referenceBandSettingsLevels = linspace(1.0/nGammaLevels, 1.0, nGammaLevels);
        
       % pattern = [1 2 3 4];
        pattern = [1 2 3];
       % pattern = [1 2];
        interactingBands = {};
        
        k = 0;
        while (max(referenceBands) + max(pattern) < 56)
            k = k + 1;
            interactingBands{k} = pattern;
            pattern = pattern + numel(pattern);
        end
        max(max(referenceBands) + max(pattern))
        if (max(max(referenceBands) + max(pattern)) > 56)
            interactingBands = interactingBands(1:(numel(interactingBands)-1));
        end
        
    elseif (strcmp(setType, 'combinatorialFull'))
        % Measure at these levels
        interactingBandSettingsLevels = [0.33 0.66 1.0];
        nGammaLevels = 20;
        referenceBandSettingsLevels = linspace(1.0/nGammaLevels, 1.0, nGammaLevels);
    
        interactingBandLocation = 'BilateralToReferenceBand';
        %interactingBandLocation = 'UnilateralToReferenceBand';
        
        if (strcmp(interactingBandLocation, 'BilateralToReferenceBand'))
            % Measure interactions with bands around the reference band
            % 2 band patterns
            pattern0 = [ 3  4];
            pattern1 = [ 1  2];
            pattern2 = [-2 -1];
            pattern3 = [-4 -3];
            
            % 3 band patterns
            pattern0 = [ 4  5  6];
            pattern1 = [ 1  2  3];
            pattern2 = [-3 -2 -1];
            pattern3 = [-6 -5 -4];
            
        elseif (strcmp(interactingBandLocation, 'UnilateralToReferenceBand'))
            % OR Measure interactions with bands to the right of the reference band
            % 2 band patterns
            pattern0 = [7 8];
            pattern1 = [5 6];  
            pattern2 = [3 4];
            pattern3 = [1 2];
            
            % 3 band patterns
            pattern0 = [10 11 12];
            pattern1 = [7 8 9];  
            pattern2 = [4 5 6];
            pattern3 = [1 2 3];
            
        end
        
        interactingBands = { ...
             [                                       pattern0(:) ]; ...
             [pattern3(:)                                        ]; ...
             [                           pattern1(:)             ]; ...
             [              pattern2(:)                          ]; ...
             [pattern3(:)                            pattern0(:) ]; ...
             [pattern3(:)   pattern2(:)                          ]; ...
             [                           pattern1(:) pattern0(:) ]; ...
             [              pattern2(:)  pattern1(:)             ]; ...
             [              pattern2(:)  pattern1(:) pattern0(:) ]; ...
             [pattern3(:)   pattern2(:)  pattern1(:)             ]; ...
             [pattern3(:)   pattern2(:)  pattern1(:) pattern0(:) ]; ...
             [              pattern2(:)              pattern0(:) ]; ...
             [pattern3(:)                pattern1(:)             ]; ...
             [pattern3(:)                pattern1(:) pattern0(:) ]; ...
             [pattern3(:)   pattern2(:)              pattern0(:) ]; ...
            };
 
    elseif (strcmp(setType, 'combinatorialSmall'));
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
    end
    
    
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
            subplot('Position', [0.03 0.04 0.45 0.95]);
            pcolor(1:nPrimariesNum, 1:nSpectraMeasured, retrieveActivationSequence(data, squeeze(randomizedSpectraIndices(repeatIndex,:))));
            hold on
            xlabel('primary no');
            ylabel('spectrum no');
            set(gca, 'CLim', [0 1], 'XLim', [1 nPrimariesNum], 'YLim', [0 nSpectraMeasured+1]);
            colormap(gray);
    
            for spectrumIter = 1:nSpectraMeasured
                
                % Show where in the stimulation sequence we are right now.
                subplot('Position', [0.03 0.04 0.45 0.95]);
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
                
                subplot('Position', [0.51 0.04 0.45 0.47]);
                bar(settingsValues, 1, 'FaceColor', [0.9 0.8 0.3]);
                set(gca, 'YLim', [0 1.05], 'XLim', [0 nPrimariesNum+1], 'XTick', [], 'YTick', []);
                subplot('Position', [0.51 0.52 0.45 0.47]);
                plot(SToWls(Svector), measurement.pr650.spectrum, 'r-', 'LineWidth', 2.0);
                set(gca, 'XTick', [], 'YTick', []);
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