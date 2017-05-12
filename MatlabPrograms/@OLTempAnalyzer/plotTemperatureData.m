% Method to plot the temperature data set
function plotTemperatureData(obj, dataSetName, entryIndex, plotAxes, dataSetNameEditBox)
    
    switch dataSetName
        case 'calibration'
            data = obj.calData;
        case 'test'
            data = obj.testData;
        otherwise
            error('plotTemperatureData(dataSetName): dataSetName must be either ''calibration'' or ''test''.');
    end
    
    if (isempty(data.stabilitySpectra{entryIndex}.combPeakTimeSeries))
        theSpectralShiftData = [];
    else
        theSpectralShiftData = squeeze(data.stabilitySpectra{entryIndex}.combPeakTimeSeries);
    end
    
    if (~isfield(data, 'allTemperatureData'))
        fprintf(2, 'No temperature data found!!\n');
        return;
    end
    if (isempty(data.allTemperatureData))
        fprintf(2, 'No temperature data found!!\n');
        return;
    end
    
    theTemperatureData = data.allTemperatureData(entryIndex,:,:,:);
    fullFileName = strrep(data.fullFileName, '_', '\_');
            
    % Compute temperature range
    tempRange = [floor(min(data.allTemperatureData(:)))-0.2 ceil(max(data.allTemperatureData(:)))+0.2];

    % Collect all temperature data in 1 time series
    theOneLightTemp = [];
    theAmbientTemp = [];
    for iter1 = 1:size(theTemperatureData,2)
        for iter2 = 1:size(theTemperatureData,3)
            theOneLightTemp(numel(theOneLightTemp)+1) = theTemperatureData(1, iter1, iter2,1);
            theAmbientTemp(numel(theAmbientTemp)+1) = theTemperatureData(1, iter1, iter2,2);
        end
    end

    % Temperature data
    nMeasurements = numel(theOneLightTemp);
    yyaxis(plotAxes, 'left');
    plot(plotAxes, 1:nMeasurements, theOneLightTemp(:), 'ko-', 'MarkerFaceColor', [0.5 0.5 0.5], 'LineWidth', 1.5, 'MarkerSize', 10);
    hold(plotAxes, 'on');
    plot(plotAxes, 1:nMeasurements, theAmbientTemp(:), 'ko-', 'LineWidth', 1.5, 'MarkerSize', 10, 'MarkerFaceColor', [0.9 0.9 0.9]);
    hold(plotAxes, 'off');
    
    % Finish plot
    box(plotAxes, 'on');
    grid(plotAxes, 'on');
    XLims = [0 nMeasurements+1];
    set(plotAxes, 'YColor', [0 0 0], 'XLim', XLims, 'YLim', tempRange, 'XTickLabel', {}, 'YTick', 0:1:100);
    set(plotAxes, 'FontSize', 14);
    xlabel(plotAxes,'measurement index', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel(plotAxes, 'temperature (deg Celcius)', 'FontSize', 14, 'FontWeight', 'bold');
    
    if (~isempty(theSpectralShiftData))
        % Spectral shift data
        yyaxis(plotAxes, 'right');
        plot(plotAxes, 1:size(theSpectralShiftData,2), theSpectralShiftData(1,:), 'ks-', 'LineWidth', 1.5, 'MarkerSize', 2, 'Color', squeeze(obj.combSPDPlotColors(1,:)), 'MarkerFaceColor', squeeze(obj.combSPDPlotColors(1,:)));
        hold(plotAxes, 'on');
        plot(plotAxes, 1:size(theSpectralShiftData,2), theSpectralShiftData(2,:), 'ks-', 'LineWidth', 1.5, 'MarkerSize', 2, 'Color', squeeze(obj.combSPDPlotColors(2,:)), 'MarkerFaceColor', squeeze(obj.combSPDPlotColors(2,:)));
        plot(plotAxes, 1:size(theSpectralShiftData,2), theSpectralShiftData(3,:), 'ks-', 'LineWidth', 1.5, 'MarkerSize', 2, 'Color', squeeze(obj.combSPDPlotColors(3,:)), 'MarkerFaceColor', squeeze(obj.combSPDPlotColors(3,:)));
        plot(plotAxes, 1:size(theSpectralShiftData,2), theSpectralShiftData(4,:), 'ks-', 'LineWidth', 1.5, 'MarkerSize', 2, 'Color', squeeze(obj.combSPDPlotColors(4,:)), 'MarkerFaceColor', squeeze(obj.combSPDPlotColors(4,:)));
        hold(plotAxes, 'off')
        set(plotAxes, 'YColor', [0 0 0], 'YLim', [min(theSpectralShiftData(:))-0.1 max(theSpectralShiftData(:))+0.1]);
        ylabel(plotAxes, 'spectral shift (nm)', 'FontWeight', 'bold');
    end
    
    idx = strfind(fullFileName, 'materials');
    reducedFileName = strrep(fullFileName(idx(end)+10:end), '\_', '_');
    set(dataSetNameEditBox, 'string', reducedFileName);
    referenceCombPeaks = obj.combSPDActualPeaks{entryIndex};
    hL = legend(plotAxes, ...
        {sprintf('onelight temp'), ...
         sprintf('ambient temp'), ...
         sprintf('shift (%2.1f)', referenceCombPeaks(1)), ...
         sprintf('shift (%2.1f)', referenceCombPeaks(2)), ...
         sprintf('shift (%2.1f)', referenceCombPeaks(3)), ...
         sprintf('shift (%2.1f)', referenceCombPeaks(4)), ...
         }, ...
         'Location', 'northoutside', 'Orientation', 'Horizontal');
    hL.FontSize = 12;
    hL.FontName = 'Menlo';  
    drawnow;
end

