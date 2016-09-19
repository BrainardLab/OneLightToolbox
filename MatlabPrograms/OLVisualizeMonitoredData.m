% OLVisualizeMonitoredData - Visualizes data returned by OLMonitorStateWindow.
%
% Syntax:
% OLVisualizeMonitoredData(monitoredData);
%
% See testOLMonitorStateWindow for usage of this function.
%
% 9/12/16   npc     Wrote it.
%

function OLVisualizeMonitoredData(varargin)
    
    monitoredData = varargin{1};
    if (nargin == 2)
        cal = varargin{2};
    else
        cal = [];
    end
    
    cal.describe
    measurementsNum = numel(monitoredData.measurements);
    if (isfield(monitoredData, 'fitParamsTimeSeries'))
        for k = 1:measurementsNum
            combSPDMeasTimes(k) = monitoredData.measurements{k}.powerSPDt;
        end
        combSPDMeasTimes = (combSPDMeasTimes - combSPDMeasTimes(1))/60;
    end

    for k = 1:measurementsNum
        if (k == 1)
            powerSPDs = zeros(measurementsNum, numel(monitoredData.measurements{1}.powerSPD));
            combSPDs = powerSPDs;
        end
        powerSPDs(k,:) = monitoredData.measurements{k}.powerSPD;
        combSPDs(k,:) = monitoredData.measurements{k}.shiftSPD;
    end
        
    if (isempty(cal))
        fitParamsTimeSeries = monitoredData.fitParamsTimeSeries;
        powerRatioSeries = monitoredData.powerRatioSeries;
        spectralShiftSeries = monitoredData.spectralShiftSeries;
        timeSeries = monitoredData.timeSeries;
        referenceDate = '';
        monitedDataDate = '';
    else
        timeBegin = cal.raw.spectralShiftsMeas.t(1);
        timeEnd = cal.raw.spectralShiftsMeas.t(end);
        referenceCombSPDTime = (timeEnd-timeBegin)/60;
        referenceCombSPD  = cal.raw.spectralShiftsMeas.measSpd(:, end);
        referencePowerSPD = cal.raw.powerFluctuationMeas.measSpd(:, end);
        referenceDate = cal.describe.date;
        fprintf('Reference combSPD was collected %2.1f minutes into the calibration run\n', referenceCombSPDTime);
    
        [timeSeries, fitParamsTimeSeries, powerRatioSeries, spectralShiftSeries, monitedDataDate] = ...
            reAnalyzeDataBasedOnReferenceSPDs(monitoredData,referenceCombSPD, referencePowerSPD);
    end
    
    
    subplotPosVectors2 = NicePlot.getSubPlotPosVectors(...
           'rowsNum', 2, ...
           'colsNum', 3, ...
           'heightMargin',   0.08, ...
           'widthMargin',    0.06, ...
           'leftMargin',     0.07, ...
           'rightMargin',    0.01, ...
           'bottomMargin',   0.06, ...
           'topMargin',      0.05);
       
    hFig = figure(1);
    clf;
    set(hFig, 'Position', [30 30 2000 900], 'Color', [1 1 1]);
    
    cmap = jet(measurementsNum);
    
    subplot('Position', subplotPosVectors2(1,1).v);
    hold on
    for k = 1:measurementsNum
        plot(monitoredData.spectralAxis, powerSPDs(k,:), '-', 'Color', cmap(k,:), 'LineWidth', 2);
    end
    for k = 1:measurementsNum
        plot(monitoredData.spectralAxis, combSPDs(k,:), '-', 'Color', cmap(k,:), 'LineWidth', 2);
    end
    set(gca, 'XLim', [monitoredData.spectralAxis(1) monitoredData.spectralAxis(end)]);
    set(gca, 'FontSize', 14);
    xlabel('wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold');
    title(sprintf('reference cal:%s\nmonitored data date: %s', cal.describe.calID, monitedDataDate), 'interpreter','none');
    box 'on';
    
    
    subplot('Position', subplotPosVectors2(1,2).v);
    stairs(timeSeries, powerRatioSeries, 'ks-', 'LineWidth', 2.0, 'MarkerSize', 10, 'MarkerFaceColor', [1.0 0.7 0.7]);
    set(gca, 'FontSize', 14, 'XLim', [timeSeries(1)-5 timeSeries(end)+5]);
    set(gca, 'YTick', powerRatioSeries(1)+ 0.01*(-100:1:100));
    xlabel('Time elapsed (minutes)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('power ratio (current:REFcal)',  'FontSize', 16, 'FontWeight', 'bold');
    if (~isempty(referenceDate))
        hold on;
        stairs(timeSeries(1), powerRatioSeries(1), 'ks-', 'LineWidth', 2.0, 'MarkerSize', 18, 'MarkerFaceColor', [1.0 0.7 0.7]);
        hold off
    end
    box 'on'; grid 'on';
    
    
    subplot('Position', subplotPosVectors2(1,3).v);
    stairs(timeSeries, spectralShiftSeries, 'ks-', 'LineWidth', 2.0, 'MarkerSize', 10, 'MarkerFaceColor', [0.7 0.7 1.0]);
    set(gca, 'FontSize', 14, 'XLim', [timeSeries(1)-5 timeSeries(end)+5]);
    set(gca, 'YTick', spectralShiftSeries(1) + 0.2*(-100:1:100));
    xlabel('Time elapsed (minutes)',  'FontSize', 16, 'FontWeight', 'bold');
    ylabel('spectral shift (mean of 4 peaks), nm (current-REFcal)',  'FontSize', 16, 'FontWeight', 'bold');
    box 'on'; grid on
    if (~isempty(referenceDate))
        hold on;
        stairs(timeSeries(1), spectralShiftSeries(1), 'ks-', 'LineWidth', 2.0, 'MarkerSize', 18, 'MarkerFaceColor', [0.7 0.7 1.0]);
        hold off
    end
    
    
    maxPeakShifts = max(max(abs(squeeze(bsxfun(@minus, fitParamsTimeSeries(:, 3, :), fitParamsTimeSeries(:, 3, 1))))))
    subplot('Position', subplotPosVectors2(2,1).v);
    peakNo = 1;
    stairs(timeSeries, squeeze(fitParamsTimeSeries(peakNo, 3, 1:numel(timeSeries))), 'ks-', 'LineWidth', 2.0, 'MarkerSize', 10, 'MarkerFaceColor', [0.6 1.0 0.7]);
    set(gca, 'FontSize', 14, 'XLim', [timeSeries(1)-5 timeSeries(end)+5]);
    set(gca, 'YTick', fitParamsTimeSeries(peakNo, 3, 1)+ 0.2*(-100:1:100), 'YLim', fitParamsTimeSeries(peakNo, 3, 1) + maxPeakShifts * [-1 1]);
    xlabel('Time elapsed (minutes)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('spectral shift, peak #1 (nm)', 'FontSize', 16, 'FontWeight', 'bold');
    if (~isempty(referenceDate));
        hold on;
        stairs(timeSeries(1), fitParamsTimeSeries(peakNo, 3, 1), 'ks-', 'LineWidth', 2.0, 'MarkerSize', 18, 'MarkerFaceColor', [1.0 0.7 0.7]);
        hold off
    end
    box 'on'; grid on
    
    subplot('Position', subplotPosVectors2(2,2).v);
    peakNo = 2;
    stairs(timeSeries, squeeze(fitParamsTimeSeries(peakNo, 3, 1:numel(timeSeries))), 'ks-', 'LineWidth', 2.0, 'MarkerSize', 10, 'MarkerFaceColor', [0.6 1.0 0.7]);
    set(gca, 'FontSize', 14, 'XLim', [timeSeries(1)-5 timeSeries(end)+5]);
    set(gca, 'YTick', fitParamsTimeSeries(peakNo, 3, 1) + 0.2*(-100:1:100), 'YLim', fitParamsTimeSeries(peakNo, 3, 1) + maxPeakShifts* [-1 1]);
    xlabel('Time elapsed (minutes)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('spectral shift, peak #2 (nm)', 'FontSize', 16, 'FontWeight', 'bold');
    if (~isempty(referenceDate));
        hold on;
        stairs(timeSeries(1), fitParamsTimeSeries(peakNo, 3, 1), 'ks-', 'LineWidth', 2.0, 'MarkerSize', 18, 'MarkerFaceColor', [1.0 0.7 0.7]);
        hold off
    end
    box 'on'; grid on;
    
    subplot('Position', subplotPosVectors2(2,3).v);
    peakNo = 3;
    stairs(timeSeries, squeeze(fitParamsTimeSeries(peakNo, 3, 1:numel(timeSeries))), 'ks-', 'LineWidth', 2.0, 'MarkerSize', 10, 'MarkerFaceColor', [0.6 1.0 0.7]);
    set(gca, 'FontSize', 14, 'XLim', [timeSeries(1)-5 timeSeries(end)+5]);
    set(gca, 'YTick', fitParamsTimeSeries(peakNo, 3, 1) + 0.2*(-100:1:100), 'YLim', fitParamsTimeSeries(peakNo, 3, 1) + maxPeakShifts * [-1 1]);
    xlabel('Time elapsed (minutes)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('spectral shift, peak #3 (nm)', 'FontSize', 16, 'FontWeight', 'bold');
    if (~isempty(referenceDate))
        hold on;
        stairs(timeSeries(1), fitParamsTimeSeries(peakNo, 3, 1), 'ks-', 'LineWidth', 2.0, 'MarkerSize', 18, 'MarkerFaceColor', [0.6 1.0 0.7]);
        hold off
    end
    box 'on'; grid on;
    
    
    
    
    
    drawnow
    
end

function [timeSeries, fitParamsTimeSeries, powerRatioSeries, spectralShiftSeries, monitedDataDate] = ...
            reAnalyzeDataBasedOnReferenceSPDs(monitoredStateData, referenceCombSPD, referencePowerSPD)
        
    measurementsNum = numel(monitoredStateData.measurements);
    spectralAxis =  monitoredStateData.spectralAxis;
    referenceTime = monitoredStateData.measurements{1}.shiftSPDt;
    monitedDataDate = monitoredStateData.measurements{1}.datestr;
    wavelengthIndices = find(referencePowerSPD(:) > 0.2*max(referencePowerSPD(:)));
    referencePowerSPD = referencePowerSPD(wavelengthIndices);
    
    combPeaks = [480 540 596 652]+10;
    
    timeSeries(1) = -20;
    powerRatioSeries(1) = 1.0;
    spectralShiftSeries(1) = 0.0;
    [~, ~, fitParams] = OLComputeSpectralShiftBetweenCombSPDs(referenceCombSPD, referenceCombSPD, combPeaks, spectralAxis);
    fitParamsTimeSeries(:,:,1) = fitParams;
    
    progressHandle = generateProgressBar('Re-analyzing state measurements ...');
    for k = 1:measurementsNum
        waitbar(k/measurementsNum, progressHandle, sprintf('Re-analyzing state measurement %d /%d\n', k, measurementsNum));
        
        data = monitoredStateData.measurements{k};
        %data.shiftSPD 
        %data.shiftSPDt 
        %data.powerSPD 
        %data.powerSPDt 
        %data.datestr
        newSPDRatio = 1.0 / (data.powerSPD(wavelengthIndices) \ referencePowerSPD);
        [spectralShifts, refPeaks, fitParams] = OLComputeSpectralShiftBetweenCombSPDs(data.shiftSPD, referenceCombSPD, combPeaks, spectralAxis);
        
        timeSeries = cat(2, timeSeries, (data.shiftSPDt-referenceTime)/60);
        powerRatioSeries = cat(2, powerRatioSeries, newSPDRatio);
        spectralShiftSeries = cat(2, spectralShiftSeries, median(spectralShifts));   
        fitParamsTimeSeries(:,:,k+1) = fitParams; 
    end
    close(progressHandle);
    
end

function progressHandle = generateProgressBar(initialMessage)
    progressHandle = waitbar(0, '');
    titleHandle = get(findobj(progressHandle,'Type','axes'),'Title');
    set(titleHandle,'FontSize',12, 'FontName', 'Menlo');
    waitbar(0, progressHandle, initialMessage);
    pause(0.2);
end

