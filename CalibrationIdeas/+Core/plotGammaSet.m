function plotGammaSet(rootDir, gammaSet1, gammaSet2, wavelengthAxis)

    gammaSet = containers.Map();
    
    % Join 2 sets
    gammaKeys = keys(gammaSet1);
    for keyIndex = 1:numel(gammaKeys)
        key = gammaKeys{keyIndex};
        theGamma = gammaSet1(key);
        gammaSet(key) = theGamma;
    end
    
    gammaKeys = keys(gammaSet2);
    for keyIndex = 1:numel(gammaKeys)
        key = gammaKeys{keyIndex};
        theGamma = gammaSet2(key);
        gammaSet(key) = theGamma;
    end
    clear 'gammaSet1'
    clear 'gammaSet2'
    
    gammaKeys = keys(gammaSet);
    theGamma = gammaSet(gammaKeys{1});
    nRepeats = size(theGamma.primaryOutSingleTrials,1);
    repeatColors = jet(nRepeats);
    conditionColors = jet(numel(gammaKeys));
    settingsColors = jet(numel(theGamma.settingsValue));
    
    % sort keys according to total actual activation
    totalActivation = zeros(1, numel(gammaKeys));
    for keyIndex = 1:numel(gammaKeys)
        key = gammaKeys{keyIndex};
        theGamma = gammaSet(key);
        totalActivation(keyIndex) = sum(squeeze(theGamma.actualActivation(end,:)));
    end
    
    [~,idx] = sort(totalActivation);
    sortedGammaKeys = {gammaKeys{idx}};
    
    rowsNum = 7;
    colsNum = round(numel(gammaKeys)/rowsNum)+1;
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
                   'rowsNum', rowsNum, ...
                   'colsNum', colsNum, ...
                   'heightMargin',   0.01, ...
                   'widthMargin',    0.01, ...
                   'leftMargin',     0.005, ...
                   'rightMargin',    0.000, ...
                   'bottomMargin',   0.01, ...
                   'topMargin',      0.005);
               
    plotActivationsEnsembe = false;
    plotGammaFunctionsEnsemble = false;
    
    if (plotActivationsEnsembe)
        % The activations (effective in color)
        hFig = figure(990); clf;
        set(hFig, 'Color', [1 1 1], 'Position', [1 1 2560 1300]);

        for keyIndex = 1:numel(gammaKeys)
            key = sortedGammaKeys{keyIndex};
            theGamma = gammaSet(key);
            row = floor((keyIndex-1)/colsNum) + 1;
            col = mod(keyIndex-1, colsNum) + 1;
            subplot('Position', subplotPosVectors(row,col).v);
            hold on;
            for settingsIndex = size(theGamma.effectiveActivation,1):-1:1
                bar(1:size(theGamma.effectiveActivation,2), squeeze(theGamma.actualActivation(settingsIndex,:)), 1.0, 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none');
                bar(1:size(theGamma.effectiveActivation,2), squeeze(theGamma.effectiveActivation(settingsIndex,:)), 1.0, 'FaceColor', squeeze(settingsColors(settingsIndex,:)));
            end
            set(gca, 'XLim', [0 size(theGamma.effectiveActivation,2)+1], 'YLim', [0 1], 'YTick', [0:0.1:1.0], 'XTickLabel', {}, 'YTickLabel', {});
            grid off; box on;
            title(key);
            drawnow;
        end % keyIndex
        NicePlot.exportFigToPDF(fullfile(rootDir, 'exports', 'Activations.pdf'), hFig, 300);
    end
    
    if (plotGammaFunctionsEnsemble)
        % The gamma functions
        hFig = figure(991); clf;
        set(hFig, 'Color', [1 1 1], 'Position', [1 1 2560 1300]);

        for keyIndex = 1:numel(gammaKeys)
            key = sortedGammaKeys{keyIndex};
            theGamma = gammaSet(key);
            row = floor((keyIndex-1)/colsNum) + 1;
            col = mod(keyIndex-1, colsNum) + 1;
            subplot('Position', subplotPosVectors(row,col).v);
            hold on
            for repeatIndex = 1:nRepeats
                colorForThisRepeat = [0.1 0.1 0.1];
                plot(theGamma.settingsValue, squeeze(theGamma.primaryOutSingleTrials(repeatIndex,:)), 'k-', ...
                    'Color', colorForThisRepeat, 'LineWidth', 2.0, 'MarkerFaceColor', colorForThisRepeat.^0.7, 'MarkerEdgeColor', colorForThisRepeat);
            end
            plot(theGamma.settingsValue, theGamma.primaryOutMean, 'r-');
            plot([0 1], [1 1], 'k-');
            set(gca, 'YLim', [0 1.1], 'XLim', [0 1], 'XTick', 0:0.1:1.0, 'YTick', 0:0.1:1.0, 'XTickLabel', {}, 'YTickLabel', {});
            grid on; box off;
            text(0.05, 1.05, sprintf('condition no: %d', keyIndex), 'FontSize', 12, 'FontName', 'Menlo');
            drawnow;
        end % keyIndex
        NicePlot.exportFigToPDF(fullfile(rootDir, 'exports', 'GammaFunctions.pdf'), hFig, 300);
    end
    
    
    % Comparing standard gamma to all others
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
                   'rowsNum', 1, ...
                   'colsNum', 1, ...
                   'heightMargin',   0.01, ...
                   'widthMargin',    0.03, ...
                   'leftMargin',     0.03, ...
                   'rightMargin',    0.001, ...
                   'bottomMargin',   0.02, ...
                   'topMargin',      0.01);
               
   
    hFig = figure(993); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [1 1 1200 1200]);
    
    subplot('Position', subplotPosVectors(1,1).v);
    hold on
    for keyIndex = 1:numel(gammaKeys)
        colorForThisCondition = squeeze(conditionColors(keyIndex,:));
        key = sortedGammaKeys{keyIndex};
        theGamma = gammaSet(key);
        plot(theGamma.settingsValue, theGamma.primaryOutMean, 'ks-', 'Color', colorForThisCondition, 'LineWidth', 2.0, 'MarkerFaceColor', colorForThisCondition.^0.7, 'MarkerEdgeColor', colorForThisCondition);
        drawnow;
    end % keyIndex
    set(gca, 'YLim', [0 1.1], 'XLim', [0 1], 'XTick', 0:0.1:1.0, 'YTick', [0:0.1:1.0]);
    grid on; box off;
    
    
    generateVideo = true;
    if (generateVideo)
        % Open video stream
        videoFilename = sprintf('GammaSPDs.m4v');
        writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
        writerObj.FrameRate = 15; 
        writerObj.Quality = 100;
        writerObj.open();
    end
    
    hFig = figure(1000); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [1 1 1600 1300]);
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
                   'rowsNum', 2, ...
                   'colsNum', 2, ...
                   'heightMargin',   0.04, ...
                   'widthMargin',    0.04, ...
                   'leftMargin',     0.04, ...
                   'rightMargin',    0.001, ...
                   'bottomMargin',   0.04, ...
                   'topMargin',      0.00);
               
    referenceGamma = [];
    for keyIndex = 1:numel(gammaKeys)
        key = sortedGammaKeys{keyIndex};
        theGamma = gammaSet(key);
        
        
        spdGain = 1000.0;
        maxSPDForThisCondition = spdGain*max(theGamma.effectiveMeanSPD(:));
        
        for settingsIndex = 1:numel(theGamma.settingsValue)
            
            % The current gamma curve
            subplot('Position', subplotPosVectors(1,1).v);
            
            legends = {};
            if (~isempty(referenceGamma))
                legends{numel(legends)+1} = 'no interacting bands';
                plot(theGamma.settingsValue, referenceGamma, 'k-', 'LineWidth', 4.0, 'Color', [0.6 0.6 0.6]);
                hold on
            end
            
            % The mean gamma
            plot(theGamma.settingsValue(1:settingsIndex), theGamma.primaryOutMean(1:settingsIndex), 'k.-', 'LineWidth', 2.0, 'MarkerSize', 12, 'MarkerFaceColor', [0.7 0.7 0.7]);
            if (strcmp(theGamma.effectiveSPDcomputationMethod, 'Reference - Steady')) && (settingsIndex == numel(theGamma.settingsValue))
                referenceGamma = theGamma.primaryOutMean;
            end
            hold on;
            legends{numel(legends)+1} = 'mean';
            for repeatIndex = 1:nRepeats
                plot(theGamma.settingsValue(1:settingsIndex), squeeze(theGamma.primaryOutSingleTrials(repeatIndex,1:settingsIndex)), 'k-', 'LineWidth', 2.0, 'Color', cat(2, squeeze(repeatColors(repeatIndex,:)), 1.0));
                legends{numel(legends)+1} = sprintf('trial #%d', repeatIndex);
            end
            plot([0 1], [1 1], 'k--');
            hold off
            set(gca, 'XLim', [0 1], 'YLim', [0 1.05], 'XTick', 0:0.1:1.0, 'YTick', 0:0.1:1.0);
            set(gca, 'FontSize', 14);
            xlabel('settings value', 'FontSize', 16, 'FontWeight', 'bold');
            ylabel('spd scaling factor', 'FontSize', 16, 'FontWeight', 'bold');
            grid on; box off;
            hL = legend(legends, 'Location', 'NorthWest');
            set(hL, 'FontSize', 12, 'FontName', 'Menlo');
            
            
            % The activation
            subplot('Position', subplotPosVectors(1,2).v); 
            bar(1:size(theGamma.effectiveActivation,2), squeeze(theGamma.actualActivation(settingsIndex,:)), 1.0, 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', [0 0 0], 'LineWidth', 2.0);
            hold on;
            bar(1:size(theGamma.effectiveActivation,2), squeeze(theGamma.effectiveActivation(settingsIndex,:)), 1.0, 'FaceColor', [0 0 0], 'LineWidth', 2.0);
            hold off;
            set(gca, 'XLim', [0 size(theGamma.effectiveActivation,2)+1], 'YLim', [0 1.0]);
            box off;
            set(gca, 'FontSize', 14);
            xlabel('band no', 'FontSize', 16, 'FontWeight', 'bold');
            ylabel('settings value', 'FontSize', 16, 'FontWeight', 'bold');
            
            
            % The SPDs
            subplot('Position', subplotPosVectors(2,1).v); 
            spdScalar = theGamma.primaryOutMean(settingsIndex);
            
            plot(wavelengthAxis, spdGain*squeeze(theGamma.effectiveMeanSPDComboComponent(settingsIndex,:)), 'k-', 'Color', [0.1 0.1 0.1], 'LineWidth', 4.0);
            hold on;
            plot(wavelengthAxis, spdGain*squeeze(theGamma.effectiveMeanSPDInteractingComponent(settingsIndex,:)), 'k--', 'Color', [0.4 0.4 0.4], 'LineWidth', 4.0);
            plot(wavelengthAxis, spdGain*squeeze(theGamma.effectiveMeanSPD(settingsIndex,:)), 'k-', 'LineWidth', 2.0);
            legends = {'combo (mean)', 'interacting (mean)', 'effective (mean)'};
            
            for repeatIndex = 1:nRepeats
                spdScalar = theGamma.primaryOutSingleTrials(repeatIndex,settingsIndex);
                plot(wavelengthAxis, spdGain*squeeze(theGamma.effectiveAllSPDs(repeatIndex,settingsIndex,:)), 'k-', 'LineWidth', 2.0, 'Color', cat(2, squeeze(repeatColors(repeatIndex,:)), 1.0));
                legends{numel(legends)+1} = sprintf('effective (trial #%d)', repeatIndex);
            end
            hold off;
            hL = legend(legends, 'Location', 'NorthWest');
            set(hL, 'FontSize', 12, 'FontName', 'Menlo');
            set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)], 'YLim', maxSPDForThisCondition*([-0.05 1.05]));
            set(gca, 'FontSize', 14);
            xlabel('wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold');
            ylabel('energy (mWatts)', 'FontSize', 16, 'FontWeight', 'bold');
            
            
            % The SPD diffs
            subplot('Position', subplotPosVectors(2,2).v); 
            meanScaledSPD = spdGain*spdScalar*squeeze(theGamma.effectiveMeanSPD(settingsIndex,:));
            legends = {};
            for repeatIndex = 1:nRepeats
                spdScalar = theGamma.primaryOutSingleTrials(repeatIndex,settingsIndex);
                singleTrialScaledSPD = spdGain*spdScalar*squeeze(theGamma.effectiveAllSPDs(repeatIndex,settingsIndex,:));
                diffSPD = meanScaledSPD(:) - singleTrialScaledSPD(:);
                plot(wavelengthAxis, diffSPD, 'k-', 'LineWidth', 2.0, 'Color', cat(2, squeeze(repeatColors(repeatIndex,:)), 1.0));
                if (repeatIndex == 1)
                    hold on;
                end
                legends{numel(legends)+1} = sprintf('mean - trial #%d effective SPD', repeatIndex);
            end
            hold off;
            hL = legend(legends, 'Location', 'NorthWest');
            set(hL, 'FontSize', 12, 'FontName', 'Menlo');
            set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)], 'YLim', 5*[-1 1]);
            set(gca, 'FontSize', 14);
            xlabel('wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold');
            ylabel('differential energy (mWatts)', 'FontSize', 16, 'FontWeight', 'bold');
            
            drawnow
            if (generateVideo)
                writerObj.writeVideo(getframe(hFig));
            end
        end
    end
    
    if (generateVideo)
        % Close video stream
        writerObj.close();
    end
    
               
end

