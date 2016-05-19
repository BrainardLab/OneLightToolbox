function plotSPDvariability(rootDir, comboBandData, referenceBandData, interactingBandData, nPrimariesNum, wavelengthAxis)

        
    [comboActivation, comboSPDstdMean, comboSPDstdMax, residualsFromComboSPDmean, comboActivations, sortedKeys] = computeSPDstdStats(comboBandData, []);
    
    for keyIndex = 1:numel(sortedKeys)
        theComboBandData = comboBandData(sortedKeys{keyIndex});
        referenceKeysCorrespondingToSortedComboKeys{keyIndex} = theComboBandData.referenceBandKey;
        interactingKeysCorrespondingToSortedComboKeys{keyIndex} = theComboBandData.interactingBandKey;
    end

    [referenceActivation, referenceSPDstdMean, referenceSPDstdMax, residualsFromReferenceSPDmean, referenceActivations, ~] = computeSPDstdStats(referenceBandData, referenceKeysCorrespondingToSortedComboKeys);
    [interactingActivation, interactingSPDstdMean, interactingSPDstdMax, residualsFromInteractingSPDmean, interactingActivations, ~] = computeSPDstdStats(interactingBandData, interactingKeysCorrespondingToSortedComboKeys);
    
    nRepeats = size(residualsFromComboSPDmean,2);
    repeatColors = jet(nRepeats);
    
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
    
    pause
    
    figure(111); clf;
    
    for k = 1:2
        subplot(2,1,k);
        if (k == 1)
            comboSPDdata = comboSPDstdMean;
            interactingSPDdata = interactingSPDstdMean;
            referenceSPDdata = referenceSPDstdMean;
        else
            comboSPDdata = comboSPDstdMax;
            interactingSPDdata = interactingSPDstdMax;
            referenceSPDdata = referenceSPDstdMax;
        end
        
        plot(comboActivation, comboSPDdata, 'cs', 'MarkerSize', 4, 'MarkerFaceColor', [0.7 0.7 0.7]);
        hold on;
        plot(interactingActivation, interactingSPDdata, 'ks', 'MarkerSize', 4, 'MarkerFaceColor', [0 0 0]);
        plot(referenceActivation, referenceSPDdata, 'rs', 'MarkerSize', 4, 'MarkerFaceColor', [1.0 0.0 0.0]);
        hL = legend({'combo SPD', 'interacting bands SPD', 'reference band SPD'});
        set(hL, 'FontSize', 14, 'FontName', 'Menlo')
        set(gca, 'XLim', [0 nPrimariesNum], 'FontSize', 14)
        xlabel('total settings activation', 'FontSize', 16, 'FontWeight', 'bold');
        if (k == 1)
            ylabel('mean of SPD std (mWatts)', 'FontSize', 16, 'FontWeight', 'bold');
        else
            ylabel('max of SPD std (mWatts)', 'FontSize', 16, 'FontWeight', 'bold');
        end
    end
    
    pause
            
end


function [activation, SPDstdMean, SPDstdMax, residualSPDsFromMean, activations, sortedKeys] = computeSPDstdStats(data, sortedKeys)
    
    if (isempty(sortedKeys))
        theKeys = keys(data);
        for keyIndex = 1:numel(theKeys)
            key = theKeys{keyIndex};
            dataStruct = data(key);
            totalActivation(keyIndex) = sum(dataStruct.activation);
        end
        [~,idx] = sort(totalActivation);
        sortedKeys = {theKeys{idx}};
    end

    theKeys = keys(data);
    dataStruct = data(theKeys{1});
    repeatsNum = size(dataStruct.allSPDresidualsFromMean,2);
    spdGain = 1000;
    for keyIndex = 1:numel(sortedKeys)
        key = sortedKeys{keyIndex};
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

