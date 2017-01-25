% Method to plot the collected (if any) temperature measurements
function plotTemperatureMeasurements(obj, varargin)

    parser = inputParser;
    % Execute the parser
    parser.parse(varargin{:});
    % Create a standard Matlab structure from the parser results.
    p = parser.Results;

    hFig = figure();
    set(hFig, 'Name', 'Temperatures', 'Color', [1 1 1], 'Position', [10 1000 850 800]);
    
    % Start tAxis at 0
    tAxis = (obj.cal.raw.temperature.t - min(obj.cal.raw.temperature.t))/60;
    tempRange = [floor(min(obj.cal.raw.temperature.value(:)))-1 ceil(max(obj.cal.raw.temperature.value(:)))+1];
    
    subplot('Position', [0.05 0.05 0.94 0.91]);
    plot(tAxis, obj.cal.raw.temperature.value(:,1), 'ro-', 'LineWidth', 1.5, 'MarkerSize', 10, 'MarkerFaceColor', [1 0.7 0.7]);
    hold on;
    plot(tAxis, obj.cal.raw.temperature.value(:,2), 'bo-', 'LineWidth', 1.5, 'MarkerSize', 10, 'MarkerFaceColor', [0.7 0.7 1.0]);
    hL = legend({'OneLight', 'Ambient'}, 'Location', 'SouthEast');
    title(sprintf('%s', strrep(obj.cal.describe.calID, '_', '')), 'FontSize', 14, 'FontWeight', 'bold');
    
    % Finish plot
    box off
    grid on
    pbaspect([1 1 1])
    hL.FontSize = 12;
    hL.FontName = 'Menlo';       
    set(gca, 'XLim', [tAxis(1) tAxis(end)], 'YLim', tempRange, 'XTick', 0:20:tAxis(end), 'YTick', 0:1:100);
    set(gca, 'FontSize', 12);
    xlabel('time (minutes)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('temperature (deg Celcius)', 'FontSize', 14, 'FontWeight', 'bold');
    drawnow;
end

