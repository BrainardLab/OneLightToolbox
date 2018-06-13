function OLAnalyzeTempCalFile

    rootDir = '/Volumes/DropBoxDisk/Dropbox/Dropbox (Aguirre-Brainard Lab)';
    approach = 'MELA_materials/Experiments/OLApproach_Psychophysics';
    temCalFile = 'OLBoxARandomizedLongCableAEyePiece3ND00_TMP.mat';
    
    load(fullfile(rootDir, approach, 'OneLightCalData', temCalFile), 'calProgression');
    
    entriesNum = numel(calProgression);
    powerFluctuationSPDs = [];
    spectralShiftSPDs = [];
    primarySPDs = [];
    gammaSPDs = [];
    darkSPDs = [];
    temperature.time = [];
    temperature.values = [];
    
    for entryIndex = 1:entriesNum 
        d = calProgression{entryIndex};
        if (isempty(fieldnames(d)))
            fprintf('Event %d has an empty data struct\n', entryIndex);
        else
            fprintf('%d: %s\n', entryIndex-1, d.methodName);
            if (contains(d.methodName, 'TakeStateMeasurements - PowerFluctuation measurement'))
                if (isempty(powerFluctuationSPDs))
                    powerFluctuationSPDs = d.spdData.spectrum';
                else
                    powerFluctuationSPDs = cat(1,powerFluctuationSPDs, d.spdData.spectrum');
                end
            elseif (contains(d.methodName, 'TakeStateMeasurements - SpectralShift measurement'))
                if (isempty(spectralShiftSPDs ))
                    spectralShiftSPDs  = d.spdData.spectrum';
                else
                    spectralShiftSPDs  = cat(1,spectralShiftSPDs, d.spdData.spectrum');
                end
            elseif (contains(d.methodName,  'TakePrimaryMeasurement - Primary'))
                if (isempty(primarySPDs))
                    primarySPDs  = d.spdData.spectrum';
                else
                    primarySPDs  = cat(1,primarySPDs, d.spdData.spectrum');
                end
            elseif (contains(d.methodName, 'TakeDarkMeasurement'))
                if (isempty(darkSPDs))
                    darkSPDs  = d.spdData.spectrum';
                else
                    darkSPDs  = cat(1,darkSPDs, d.spdData.spectrum');
                end
            elseif (contains(d.methodName, 'TakeGammaMeasurements'))
                if (isempty(gammaSPDs))
                    gammaSPDs  = d.spdData.spectrum';
                else
                    gammaSPDs = cat(1,gammaSPDs, d.spdData.spectrum');
                end
            end
            
            allSPDs(entryIndex,:) = d.spdData.spectrum;
            if (isfield(d, 'temperatureData'))
                tempData = d.temperatureData;
                if (~isempty(fieldnames(tempData)))
                    if (isempty(temperature.time))
                        temperature.time = tempData.time;
                        temperature.values = tempData.value;
                    else
                        temperature.time = cat(1, temperature.time, tempData.time);
                        temperature.values = cat(1, temperature.values, tempData.value);
                    end
                end
            end
        end
    end
    
    hFig = figure(1);
    set(hFig, 'Color', [1 1 1]);
    clf;
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'rowsNum', 2, ...
       'colsNum', 3, ...
       'heightMargin',  0.07, ...
       'widthMargin',    0.05, ...
       'leftMargin',     0.05, ...
       'rightMargin',    0.01, ...
       'bottomMargin',   0.05, ...
       'topMargin',      0.05);
    
    if (~isempty(powerFluctuationSPDs))
        subplot('Position', subplotPosVectors(1,1).v);
        plot(1:size(allSPDs,2), powerFluctuationSPDs , 'r-', 'LineWidth', 1.5);
        set(gca, 'XLim', [1 size(allSPDs,2)], 'XTick', [], 'YLim', [-0.01 0.15]);
        title(sprintf('Power Fluctuation SPDs\n(%d measurements)', size(powerFluctuationSPDs,1)));
        set(gca, 'FontSize', 12);
    end
    
    if (~isempty(spectralShiftSPDs))
        subplot('Position', subplotPosVectors(1,2).v);
        plot(1:size(allSPDs,2), spectralShiftSPDs , 'r-', 'LineWidth', 1.5);
        set(gca, 'XLim', [1 size(allSPDs,2)], 'XTick', [], 'YLim', [-0.01 0.15]);
        title(sprintf('Spectral Shift SPDs\n(%d measurements)', size(spectralShiftSPDs,1)));
        set(gca, 'FontSize', 12);
    end
    
    if (~isempty(primarySPDs))
       subplot('Position', subplotPosVectors(1,3).v);
        plot(1:size(allSPDs,2), primarySPDs , 'r-', 'LineWidth', 1.5);
        set(gca, 'XLim', [1 size(allSPDs,2)], 'XTick', [], 'YLim', [-0.01 0.15]);
        title(sprintf('Primary SPDs\n(%d measurements)', size(primarySPDs,1)));
        set(gca, 'FontSize', 12);
    end
    
    if (~isempty(darkSPDs))
        subplot('Position', subplotPosVectors(2,1).v);
        plot(1:size(allSPDs,2), darkSPDs , 'r-', 'LineWidth', 1.5);
        set(gca, 'XLim', [1 size(allSPDs,2)], 'XTick', [], 'YLim', [-0.01 0.15]);
        title(sprintf('Dark SPDs\n(%d measurements)', size(darkSPDs,1)));
        set(gca, 'FontSize', 12);
    end
    
    if (~isempty(gammaSPDs))
        subplot('Position', subplotPosVectors(2,2).v);
        plot(1:size(allSPDs,2), gammaSPDs , 'r-', 'LineWidth', 1.5);
        set(gca, 'XLim', [1 size(allSPDs,2)], 'XTick', [], 'YLim', [-0.01 0.15]);
        title(sprintf('Gamma SPDs\n(%d measurements)', size(gammaSPDs,1)));
        set(gca, 'FontSize', 12);
    end
    
    if (~isempty(temperature.time))
        subplot('Position', subplotPosVectors(2,3).v);
        temperature.time = (temperature.time - temperature.time(1))/60;
        plot(temperature.time, temperature.values(:,1), 'r-', 'LineWidth', 1.5);
        hold on;
        plot(temperature.time, temperature.values(:,2), 'b-', 'LineWidth', 1.5);
        set(gca, 'YLim', [28 35])
        xlabel('time (minutes)');
        ylabel('temperature');
        legend({'OL', 'ambient'}, 'Location', 'SouthWest', 'Orientation', 'Horizontal');
        set(gca, 'FontSize', 12);
    end
    
    NicePlot.exportFigToPNG('CalProgression.png', hFig, 300);
end

