function plotPredictions(obj, varargin)

    parser = inputParser;
    parser.addRequired('spdType', @ischar);
    parser.addRequired('spdName', @ischar);
    parser.addRequired('predictionSettings', @isnumeric);
    % Execute the parser
    parser.parse(varargin{:});
    % Create a standard Matlab structure from the parser results.
    p = parser.Results;
    
    % Get spd type and name
    spdType = p.spdType;
    spdName = p.spdName;
    predictionSettings = p.predictionSettings;
    
    % Validate spdType
    validatestring(spdType, {'raw'});
    
    if (~isfield(obj.cal.raw, spdName))
        error('\nDid not find field ''cal.raw.%s''. Nothing plotted for this query.\n', spdName);
    else
        % Extract the desired spd data
        measuredSPD = eval(sprintf('obj.cal.raw.%s', spdName));
        measuredSPDpreCalibration = measuredSPD(:, 1);
        measuredSPDpostCalibration = measuredSPD(:, 2);
        % Compute predicted SPD
        primaries = OLSettingsToPrimary(obj.cal, predictionSettings);
        predictedSPD = OLPrimaryToSpd(obj.cal, primaries);
        
    end
    
    hFig = figure; clf;
    figurePrefix = sprintf('%s_%s_Predictions', spdType, spdName);
    obj.figsList.(figurePrefix) = hFig;
    set(hFig, 'Name', figurePrefix, 'Color', [1 1 1], 'Position', [10 1000 1780 950]);
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', 1, ...
               'colsNum', 2, ...
               'heightMargin',   0.02, ...
               'widthMargin',    0.05, ...
               'leftMargin',     0.05, ...
               'rightMargin',    0.01, ...
               'bottomMargin',   0.1, ...
               'topMargin',      0.05);

    subplot('position', subplotPosVectors(1,1).v);
    
    hold on;
    plot(obj.waveAxis, measuredSPDpreCalibration, 'r-', 'LineWidth', 4.0, 'Color', [1.0 0.4 0.4 0.5], 'DisplayName', 'preCalibration');
    plot(obj.waveAxis, measuredSPDpostCalibration, 'b-', 'LineWidth', 4.0, 'Color', [0.4 0.4 1.0 0.5], 'DisplayName', 'postCalibration');
    plot(obj.waveAxis, predictedSPD, 'k-', 'LineWidth', 1.0, 'DisplayName', 'predicted');
    
    % Finish plot  
    hL = legend('Location', 'North', 'Orientation', 'horizontal');
    hL.FontSize = 16;
    hL.FontName = 'Menlo';  
                
    pbaspect([1 1 1]); 
    box off
    set(gca, 'FontSize', 16);
    xlabel('wavelength (nm)', 'FontSize', 20); 
    ylabel('power (W/sr/m2/nm)', 'FontSize', 20);
    
    subplot('position', subplotPosVectors(1,2).v);
    plot(obj.waveAxis, predictedSPD-measuredSPDpreCalibration, 'r-', 'LineWidth', 2.0, 'Color', [1.0 0.4 0.4 0.5], 'DisplayName', 'predicted-preCalibration');
    hold on;
    plot(obj.waveAxis, predictedSPD-measuredSPDpostCalibration, 'b-', 'LineWidth', 3.0, 'Color', [0.4 0.4 1.0 0.5], 'DisplayName', 'predicted-postCalibration');
    hold off;
    
     % Finish plot  
    hL = legend('Location', 'North', 'Orientation', 'horizontal');
    hL.FontSize = 16;
    hL.FontName = 'Menlo';  
    
    pbaspect([1 1 1]); 
    box off
    set(gca, 'FontSize', 16);
    xlabel('wavelength (nm)', 'FontSize', 20); 
    ylabel('diff power (W/sr/m2/nm)', 'FontSize', 20);
    drawnow;
    
end

