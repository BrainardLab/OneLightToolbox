% VisualizeStateProgression
%
% Method to visualize the OneLight state progression during a calibration.
%
% 9/2/16   npc     Wrote it

function VisualizeStateProgression
    cal = OLGetCalibrationStructure;
    
    % Recompute cal
    % cal = OLInitCal(cal);
       
    hFig = figure(1); clf;
    set(hFig, 'Color', [1 1 1]);
    subplotPosVectors2 = NicePlot.getSubPlotPosVectors(...
           'rowsNum', 3, ...
           'colsNum', 1, ...
           'heightMargin',   0.04, ...
           'widthMargin',    0.04, ...
           'leftMargin',     0.05, ...
           'rightMargin',    0.01, ...
           'bottomMargin',   0.04, ...
           'topMargin',      0.01);
       
    % Get the peaks of the comb spectrum
    combPeaks = cal.computed.spectralShiftCorrection.combPeaks;
    referenceSPDpeaks = cal.computed.spectralShiftCorrection.referenceSPDpeaks;
    combPeaks
    referenceSPDpeaks

    spectralShiftMeasurementTimes = (cal.computed.spectralShiftCorrection.times - cal.computed.spectralShiftCorrection.times(1))/60;
    powerFluctuationTimeSeries = ones(numel(spectralShiftMeasurementTimes),1);

    paramIndex = 3;  % spectral peak
    % median over four main peaks
    spectralShiftTimeSeries = squeeze(median(cal.computed.spectralShiftCorrection.fitParams(:,:,paramIndex),2));
    spectralShiftTimeSeries = spectralShiftTimeSeries - spectralShiftTimeSeries(1);

    for stateMeasIndex = 1:numel(spectralShiftMeasurementTimes)-1
        correctionFactor = cal.computed.returnScaleFactor(cal.raw.powerFluctuationMeas.t(:, stateMeasIndex));
        powerFluctuationTimeSeries(stateMeasIndex+1) = 1/correctionFactor;
    end

    subplot('Position', subplotPosVectors2(1,calRow+1).v);
    plot(1:numel(spectralShiftMeasurementTimes), powerFluctuationTimeSeries, 'ks-', 'MarkerFaceColor', [0 0 0]);
    ylabel('power fluctuation (ratio to first SPD)', 'FontWeight', 'bold');
    xlabel('measurement index', 'FontWeight', 'bold');
    set(gca, 'XLim', [1 numel(spectralShiftMeasurementTimes)]);
    set(gca, 'YLim', [0.985 1.01]);
    axis 'square'
    if (cal.describe.specifiedBackground)
        title(sprintf('%s \n non-zero background', cal.describe.date));
    else
        title(sprintf('%s \n zero background', cal.describe.date));
    end

    subplot('Position', subplotPosVectors2(2,calRow+1).v);
    plot(1:numel(spectralShiftMeasurementTimes), spectralShiftTimeSeries, 'ks-', 'MarkerFaceColor', [0 0 0]);
    set(gca, 'XLim', [1 numel(spectralShiftMeasurementTimes)]);
    set(gca, 'YLim', [-0.05 0.3]);
    ylabel('spectral shift from first SPD (nm)', 'FontWeight', 'bold');
    xlabel('measurement index', 'FontWeight', 'bold');
    axis 'square'

    subplot('Position', subplotPosVectors2(3,calRow+1).v);
    plot(powerFluctuationTimeSeries, spectralShiftTimeSeries, 'ks-', 'MarkerFaceColor', [0 0 0]);
    set(gca, 'XLim', [0.985 1.01]);
    set(gca, 'YLim', [-0.05 0.3]);
    xlabel('power fluctuation (ratio to first SPD)', 'FontWeight', 'bold');
    ylabel('spectral shift from first SPD (nm)', 'FontWeight', 'bold');
    axis 'square'
    drawnow
end

