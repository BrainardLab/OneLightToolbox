% Method to plot a temperature data set
function plotTemperatureData(obj, dataSetName)
    
    switch dataSetName
        case 'calibration'
            data = obj.calData;
        case 'test'
            data = obj.testData;
        otherwise
            error('plotTemperatureData(dataSetName): dataSetName must be either ''calibration'' or ''test''.');
    end
    
    allTemperatureData = data.allTemperatureData;
    dateStrings = data.DateStrings;
    fullFileName = strrep(data.fullFileName, '_', '\_');
            
    % Compute temperature range
    tempRange = [floor(min(allTemperatureData(:)))-1 ceil(max(allTemperatureData(:)))+1];

    % Plot data
    hFig = figure(); clf;
    set(hFig, 'Position', [10 10 1000 1000]);

    for calibrationIndex = 1:size(allTemperatureData,1)
        theTemperatureData = allTemperatureData(calibrationIndex,:,:,:);
        theOneLightTemp = [];
        theAmbientTemp = [];
        for iter1 = 1:size(theTemperatureData,2)
            for iter2 = 1:size(theTemperatureData,3)
                theOneLightTemp(numel(theOneLightTemp)+1) = theTemperatureData(1,iter1, iter2,1);
                theAmbientTemp(numel(theAmbientTemp)+1) = theTemperatureData(1,iter1, iter2,2);
            end
        end

        subplot(size(allTemperatureData,1), 1, calibrationIndex)
        plot(1:numel(theOneLightTemp), theOneLightTemp(:), 'ro-', 'LineWidth', 1.5, 'MarkerSize', 10, 'MarkerFaceColor', [1 0.7 0.7]);
        hold on
        plot(1:numel(theOneLightTemp), theAmbientTemp(:), 'bo-', 'LineWidth', 1.5, 'MarkerSize', 10, 'MarkerFaceColor', [0.7 0.7 1.0]);

        hL = legend({'OneLight', 'Ambient'}, 'Location', 'SouthEast');
        % Finish plot
        box off
        grid on
        hL.FontSize = 12;
        hL.FontName = 'Menlo';       
        XLims = [0 numel(theOneLightTemp)+1];
        set(gca, 'XLim', XLims, 'YLim', tempRange, 'XTick', [1:2:numel(theOneLightTemp)], 'YTick', 0:1:100);
        set(gca, 'FontSize', 12);
        xlabel('measurement index', 'FontSize', 14, 'FontWeight', 'bold');
        ylabel('temperature (deg Celcius)', 'FontSize', 14, 'FontWeight', 'bold');
        drawnow;
        title(sprintf('%s\n%s', fullFileName, dateStrings{calibrationIndex}));
    end
end

