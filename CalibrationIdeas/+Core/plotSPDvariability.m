function plotSPDvariability(rootDir, allComboKeys, comboBandData, referenceBandData, interactingBandData, nPrimariesNum, wavelengthAxis)

        
    [comboActivation, comboSPDstdMean, comboSPDstdMax, residualsFromComboSPDmean, comboActivations] = computeSPDstdStats(comboBandData, allComboKeys);
    
    for keyIndex = 1:numel(allComboKeys)
        theComboBandData = comboBandData(allComboKeys{keyIndex});
        referenceKeysCorrespondingToSortedComboKeys{keyIndex} = theComboBandData.referenceBandKey;
        interactingKeysCorrespondingToSortedComboKeys{keyIndex} = theComboBandData.interactingBandKey;
    end

    [referenceActivation, referenceSPDstdMean, referenceSPDstdMax, residualsFromReferenceSPDmean, referenceActivations] = computeSPDstdStats(referenceBandData, referenceKeysCorrespondingToSortedComboKeys);
    [interactingActivation, interactingSPDstdMean, interactingSPDstdMax, residualsFromInteractingSPDmean, interactingActivations] = computeSPDstdStats(interactingBandData, interactingKeysCorrespondingToSortedComboKeys);
    
    nRepeats = size(residualsFromComboSPDmean,2);
    repeatColors = jet(nRepeats);
    
    for keyIndex = 1:size(residualsFromComboSPDmean,1)
        totalComboActivation(keyIndex) = sum(squeeze(comboActivations(keyIndex,:)));
        totalReferenceActivation(keyIndex) = sum(squeeze(referenceActivations(keyIndex,:)));
        totalInteractingActivation(keyIndex) = sum(squeeze(interactingActivations(keyIndex,:)));
        for repeatIndex = 1:nRepeats
            meanComboResidual(keyIndex, repeatIndex) = mean(abs(squeeze(residualsFromComboSPDmean(keyIndex,repeatIndex,:))));
            meanReferenceResidual(keyIndex, repeatIndex) = mean(abs(squeeze(residualsFromReferenceSPDmean(keyIndex,repeatIndex,:))));
            meanInteactingResidual(keyIndex, repeatIndex) = mean(abs(squeeze(residualsFromInteractingSPDmean(keyIndex,repeatIndex,:))));
            maxComboResidual(keyIndex, repeatIndex) = max(abs(squeeze(residualsFromComboSPDmean(keyIndex,repeatIndex,:))));
            maxReferenceResidual(keyIndex, repeatIndex) = max(abs(squeeze(residualsFromReferenceSPDmean(keyIndex,repeatIndex,:))));
            maxInteactingResidual(keyIndex, repeatIndex) = max(abs(squeeze(residualsFromInteractingSPDmean(keyIndex,repeatIndex,:))));
            
        end
    end
    
    
    hFig = figure(111);clf; set(hFig, 'Color', [1 1 1], 'Position', [1 1 1900 920]);
    subplot('Position', [0.05 0.05 0.45 0.94]);
    plot(totalComboActivation, meanComboResidual, 'ks', 'MarkerSize', 6, 'MarkerFaceColor', [0.7 0.7 0.7], 'MarkerEdgeColor', [0.1 0.1 0.1]);
    hold on
    plot(totalReferenceActivation, meanReferenceResidual, 'gs', 'MarkerSize', 4, 'MarkerFaceColor', [0.1 0.2 0.2]);
    plot(totalInteractingActivation, meanInteactingResidual, 'ms', 'MarkerSize', 6, 'MarkerFaceColor', [1.0 0.1 0.3], 'MarkerEdgeColor', [0.2 0.1 0.2]);
    hold off
    set(gca, 'XLim', [4 50]);
    
    set(gca, 'XLim', [4 50], 'FontSize', 14);
    xlabel('total activation (settings)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('mean diff power (mWatts)', 'FontSize', 16, 'FontWeight', 'bold');
    grid on; box on;

    subplot('Position', [0.54 0.05 0.45 0.94]);
    plot(totalComboActivation, maxComboResidual, 'ks', 'MarkerSize', 6, 'MarkerFaceColor', [0.7 0.7 0.7], 'MarkerEdgeColor', [0.1 0.1 0.1]);
    hold on
    plot(totalReferenceActivation, maxReferenceResidual, 'gs', 'MarkerSize', 4, 'MarkerFaceColor', [0.1 0.2 0.2]);
    plot(totalInteractingActivation, maxInteactingResidual, 'ms', 'MarkerSize', 6, 'MarkerFaceColor', [1.0 0.1 0.3], 'MarkerEdgeColor', [0.2 0.1 0.2]);
    hold off
    set(gca, 'XLim', [4 50]);
    
    set(gca, 'XLim', [4 50], 'FontSize', 14);
    xlabel('total activation (settings)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('max diff power (mWatts)', 'FontSize', 16, 'FontWeight', 'bold');
    grid on; box on;
    
    drawnow
    NicePlot.exportFigToPNG('ActivationVsResidual.png', hFig,300);
    pause
    
    
    
    hFig = figure(112); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [1 1 1900 920]);
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
                   'rowsNum', 2, ...
                   'colsNum', 3, ...
                   'heightMargin',   0.06, ...
                   'widthMargin',    0.04, ...
                   'leftMargin',     0.04, ...
                   'rightMargin',    0.001, ...
                   'bottomMargin',   0.04, ...
                   'topMargin',      0.00);
    
    generateVideo = true;
    if (generateVideo)
        % Open video stream
        videoFilename = sprintf('SPDsingleTrialVariationsFromMean.m4v');
        writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
        writerObj.FrameRate = 15; 
        writerObj.Quality = 100;
        writerObj.open();
    end
    
    for keyIndex = 1:size(residualsFromComboSPDmean,1)
               
        subplot('Position', subplotPosVectors(1,1).v);
        
        legends = {};
        for repeatIndex = 1:nRepeats
            plot(wavelengthAxis, squeeze(residualsFromComboSPDmean(keyIndex,repeatIndex,:)), 'k-', 'LineWidth', 2.0, 'Color', squeeze(repeatColors(repeatIndex,:)));
            if (repeatIndex == 1)
                hold on
            end
            legends{numel(legends)+1} = sprintf('trial #%d', repeatIndex);
        end
        hold off
        set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)], 'YLim', 0.5*[-1 1], 'FontSize', 14);
        xlabel('wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold');
        ylabel('diff power (mWatts)', 'FontSize', 16, 'FontWeight', 'bold');
        grid on; box on;
        hL = legend(legends, 'Location', 'NorthWest');
        set(hL, 'FontSize', 12, 'FontName', 'Menlo');

        subplot('Position', subplotPosVectors(2,1).v);
        bar(1:nPrimariesNum,squeeze(comboActivations(keyIndex,:)), 1, 'FaceColor', [0.7 0.7 0.7]);
        set(gca, 'XLim', [0 nPrimariesNum+1], 'YLim', [0 1], 'FontSize', 14);
        xlabel('band no', 'FontSize', 16, 'FontWeight', 'bold');
        ylabel('settings value', 'FontSize', 16, 'FontWeight', 'bold');

        subplot('Position', subplotPosVectors(1,2).v);
        legends = {};
        for repeatIndex = 1:nRepeats
            plot(wavelengthAxis, squeeze(residualsFromReferenceSPDmean(keyIndex,repeatIndex,:)), 'k-', 'LineWidth', 2.0, 'Color', squeeze(repeatColors(repeatIndex,:)));
            if (repeatIndex == 1)
                hold on
            end
            legends{numel(legends)+1} = sprintf('trial #%d', repeatIndex);
        end
        hold off
        set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)], 'YLim', 0.5*[-1 1], 'FontSize', 14);
        xlabel('wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold');
        ylabel('diff power (mWatts)', 'FontSize', 16, 'FontWeight', 'bold');
        grid on; box on;
        hL = legend(legends, 'Location', 'NorthWest');
        set(hL, 'FontSize', 12, 'FontName', 'Menlo');


        subplot('Position', subplotPosVectors(2,2).v);
        bar(1:nPrimariesNum,squeeze(referenceActivations(keyIndex,:)), 1, 'FaceColor', [0.7 0.7 0.7]);
        set(gca, 'XLim', [0 nPrimariesNum+1], 'YLim', [0 1], 'FontSize', 14);
        xlabel('band no', 'FontSize', 16, 'FontWeight', 'bold');
        ylabel('settings value', 'FontSize', 16, 'FontWeight', 'bold');


        subplot('Position', subplotPosVectors(1,3).v);
        legends = {};
        for repeatIndex = 1:nRepeats
            plot(wavelengthAxis, squeeze(residualsFromInteractingSPDmean(keyIndex,repeatIndex,:)), 'k-', 'LineWidth', 2.0, 'Color', squeeze(repeatColors(repeatIndex,:)));
            if (repeatIndex == 1)
                hold on
            end
            legends{numel(legends)+1} = sprintf('trial #%d', repeatIndex);
        end
        hold off
        set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)], 'YLim', 0.5*[-1 1], 'FontSize', 14);
        xlabel('wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold');
        ylabel('diff power (mWatts)', 'FontSize', 16, 'FontWeight', 'bold');
        grid on; box on;
        hL = legend(legends, 'Location', 'NorthWest');
        set(hL, 'FontSize', 12, 'FontName', 'Menlo');


        subplot('Position', subplotPosVectors(2,3).v);
        bar(1:nPrimariesNum,squeeze(interactingActivations(keyIndex,:)), 1, 'FaceColor', [0.7 0.7 0.7]);
        set(gca, 'XLim', [0 nPrimariesNum+1], 'YLim', [0 1], 'FontSize', 14);
        xlabel('band no', 'FontSize', 16, 'FontWeight', 'bold');
        ylabel('settings value', 'FontSize', 16, 'FontWeight', 'bold');
        
        drawnow;
        if (generateVideo)
            writerObj.writeVideo(getframe(hFig));
        end
            
    end
    
    if (generateVideo)
        % Close video stream
        writerObj.close();
    end
    
end


function [activation, SPDstdMean, SPDstdMax, residualSPDsFromMean, activations] = computeSPDstdStats(data, theKeys)
   
    dataStruct = data(theKeys{1});
    repeatsNum = size(dataStruct.allSPDresidualsFromMean,2);
    spdGain = 1000;
    for keyIndex = 1:numel(theKeys)
        key = theKeys{keyIndex};
        dataStruct = data(key);
        activation(keyIndex) = sum(dataStruct.activation);
        SPDstdMean(keyIndex) = spdGain * mean(dataStruct.stdSPD);
        SPDstdMax(keyIndex) = spdGain * max(dataStruct.stdSPD);
        activations(keyIndex,:) = dataStruct.activation;
        for repeatIndex = 1:repeatsNum
            residualSPDsFromMean(keyIndex, repeatIndex,:) = spdGain * ...
                reshape(squeeze(dataStruct.allSPDresidualsFromMean(:,repeatIndex)), [1 1 numel(dataStruct.meanSPD)]);
        end
    end
end

