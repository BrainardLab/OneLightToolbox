% OLVisualizeMonitoredData - Visualizes data returned by OLMonitorStateWindow.
%
% Syntax:
% OLVisualizeMonitoredData(monitoredData);
%
% See testOLMonitorStateWindow for usage of this function.
%
% 9/12/16   npc     Wrote it.
%

function OLVisualizeMonitoredData(monitoredData)
    
    measurementsNum = numel(monitoredData.measurements);
    
    for k = 1:measurementsNum
        if (k == 1)
            powerSPDs = zeros(measurementsNum, numel(monitoredData.measurements{1}.powerSPD));
            combSPDs = powerSPDs;
        end
        powerSPDs(k,:) = monitoredData.measurements{k}.powerSPD;
        combSPDs(k,:) = monitoredData.measurements{k}.shiftSPD;
    end
    
    subplotPosVectors2 = NicePlot.getSubPlotPosVectors(...
           'rowsNum', 2, ...
           'colsNum', 2, ...
           'heightMargin',   0.08, ...
           'widthMargin',    0.06, ...
           'leftMargin',     0.07, ...
           'rightMargin',    0.01, ...
           'bottomMargin',   0.06, ...
           'topMargin',      0.05);
       
    hFig = figure(1);
    clf;
    set(hFig, 'Position', [30 30 1600 900]);
    
    subplot('Position', subplotPosVectors2(1,1).v);
    plot(monitoredData.spectralAxis, powerSPDs, '-');
    set(gca, 'XLim', [monitoredData.spectralAxis(1) monitoredData.spectralAxis(end)]);
    set(gca, 'FontSize', 14);
    xlabel('wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold');
    
    subplot('Position', subplotPosVectors2(1,2).v);
    plot(monitoredData.spectralAxis, combSPDs, '-');
    set(gca, 'XLim', [monitoredData.spectralAxis(1) monitoredData.spectralAxis(end)]);
    set(gca, 'FontSize', 14);
    xlabel('wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold');
    
    subplot('Position', subplotPosVectors2(2,1).v);
    plot(monitoredData.timeSeries, monitoredData.powerRatioSeries, 'ks-', 'LineWidth', 1.5, 'MarkerSize', 8, 'MarkerFaceColor', [1.0 0.7 0.7]);
    set(gca, 'FontSize', 14);
    xlabel('Time elapsed (minutes)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('power ratio (current:first)',  'FontSize', 16, 'FontWeight', 'bold');
    
    subplot('Position', subplotPosVectors2(2,2).v);
    plot(monitoredData.timeSeries, monitoredData.spectralShiftSeries, 'ks-', 'LineWidth', 1.5, 'MarkerSize', 8, 'MarkerFaceColor', [0.7 0.7 1.0]);
    set(gca, 'FontSize', 14);
    xlabel('Time elapsed (minutes)',  'FontSize', 16, 'FontWeight', 'bold');
    ylabel('spectral shift, nm (current-first)',  'FontSize', 16, 'FontWeight', 'bold');

    colormap(lines);
    drawnow
    NicePlot.exportFigToPNG('MonitoredData.png', hFig, 300);
end