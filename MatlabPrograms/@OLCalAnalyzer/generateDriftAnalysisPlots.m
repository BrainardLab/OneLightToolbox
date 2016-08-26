function generateDriftAnalysisPlots(obj)
  
    if (isfield(obj.cal.raw, 'spectralShiftsMeas'))
        computeDriftCorrectedStateMeasurements(obj)
        generateDriftCorrectedStateMeasurementPlots(obj);
        generateSpectralShiftPlots(obj);
    end
end


function generateSpectralShiftPlots(obj)

    cal = obj.cal;
    fitParams = cal.computed.spectralShiftCorrection.fitParams;

    % Peaks of the comb function
    combPeaks = cal.computed.spectralShiftCorrection.combPeaks;
    referenceSPDpeaks = cal.computed.spectralShiftCorrection.referenceSPDpeaks;
    combPeaks
    referenceSPDpeaks
    
    paramNames = cal.computed.spectralShiftCorrection.paramNames;
    
    cmap = jet(numel(combPeaks));
    
    % Plot the time series of the gain and the peak
    subplotPosVectors2 = NicePlot.getSubPlotPosVectors(...
           'rowsNum', 2, ...
           'colsNum', 2, ...
           'heightMargin',   0.06, ...
           'widthMargin',    0.06, ...
           'leftMargin',     0.05, ...
           'rightMargin',    0.01, ...
           'bottomMargin',   0.06, ...
           'topMargin',      0.01);

    hFig6 = figure(6); clf;
    set(hFig6, 'Position', [10 10 1260 1100], 'Color', [1 1 1]);
    fig6Legends = {};
    
    % rawData
    % theSPDs = cal.raw.spectralShiftsMeas.measSpd;
        
    % drift corrected data
    %theSPDs = cal.driftCorrected.spectralShiftsMeas.measSpd;
    

    timeAxis = (cal.computed.spectralShiftCorrection.times - cal.computed.spectralShiftCorrection.times(1))/60;
    
    for peakIndex = 1:numel(combPeaks)
        peak = combPeaks(peakIndex);
        
        % Add legend
        fig6Legends{peakIndex} = sprintf('peak at %d nm', peak);
        
        % The gain time series
        for paramIndex = [2 3 4 6]
            paramTimeSeries = squeeze(fitParams(:,peakIndex,paramIndex));
            
            switch paramIndex
                case 2 
                    subplot('Position', subplotPosVectors2(1,1).v);
                case 3
                    subplot('Position', subplotPosVectors2(1,2).v);
                    paramTimeSeries = paramTimeSeries - paramTimeSeries(1);
                case 4
                    subplot('Position', subplotPosVectors2(2,1).v);
                case 6
                    subplot('Position', subplotPosVectors2(2,2).v);
            end
            
            hold on
            plot(timeAxis, paramTimeSeries, 'ko-', 'Color', 0.5*squeeze(cmap(peakIndex,:)), 'MarkerSize', 12, 'MarkerFaceColor', squeeze(cmap(peakIndex,:)), 'LineWidth', 1);
            set(gca, 'FontSize', 14);
            if (paramIndex == 3)
                spectralShiftDiffs = bsxfun(@minus, squeeze(fitParams(:,:,paramIndex)), squeeze(fitParams(1,:,paramIndex)));
                set(gca, 'YLim', mean(mean(spectralShiftDiffs)) + [-0.4 0.4])
            end
            
            ylabel(sprintf('%s', paramNames{paramIndex}), 'FontSize', 16, 'FontWeight', 'bold');
            xlabel('time (minutes)', 'FontSize', 16, 'FontWeight', 'bold');
            if (peakIndex == numel(combPeaks))
                hL = legend(fig6Legends);
                set(hL, 'FontSize', 14);
            end
    
        end % paramIndex
        drawnow;
       
    end % peakIndex
    
end




function computeDriftCorrectedStateMeasurements(obj)

    cal = obj.cal;
    
    for stateMeasIndex = 1:size(cal.raw.spectralShiftsMeas.measSpd,2)-1
        cal.driftCorrectedOLD.powerFluctuationMeas.measSpd(:, stateMeasIndex) = ...
            bsxfun(@times, cal.raw.powerFluctuationMeas.measSpd(:, stateMeasIndex), cal.computed.returnScaleFactorOLD(cal.raw.powerFluctuationMeas.t(:, stateMeasIndex)));
        cal.driftCorrectedOLD.spectralShiftsMeas.measSpd(:, stateMeasIndex) = ...
            bsxfun(@times, cal.raw.spectralShiftsMeas.measSpd(:, stateMeasIndex), cal.computed.returnScaleFactorOLD(cal.raw.spectralShiftsMeas.t(:, stateMeasIndex)));
        cal.driftCorrected.powerFluctuationMeas.measSpd(:, stateMeasIndex) = ...
            bsxfun(@times, cal.raw.powerFluctuationMeas.measSpd(:, stateMeasIndex), cal.computed.returnScaleFactor(cal.raw.powerFluctuationMeas.t(:, stateMeasIndex)));
        cal.driftCorrected.spectralShiftsMeas.measSpd(:, stateMeasIndex) = ...
            bsxfun(@times, cal.raw.spectralShiftsMeas.measSpd(:, stateMeasIndex), cal.computed.returnScaleFactor(cal.raw.spectralShiftsMeas.t(:, stateMeasIndex)));
    end
    
    % Update the object's copy
    obj.cal = cal;
end

function generateDriftCorrectedStateMeasurementPlots(obj)

    cal = obj.cal;
    spectralAxis = SToWls(cal.describe.S);
    cmap = 0.7*jet(size(cal.raw.spectralShiftsMeas.measSpd,2));
    
    spectralLims = [spectralAxis(1) spectralAxis(end)];
    spectralLims = [450 700];
    powerLims = max(cal.raw.powerFluctuationMeas.measSpd(:))*[0.5 1.02];

    hFig = figure(3); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [10 500 2000 570]);
    subplot('Position', [0.03 0.05 0.31 0.90]);
    hold on;
    legends = {};
    for stateMeasIndex = 1:size(cal.raw.powerFluctuationMeas.measSpd,2)-1
        plot(spectralAxis, cal.raw.powerFluctuationMeas.measSpd(:,stateMeasIndex), 'k.-', 'Color', cmap(stateMeasIndex,:), 'LineWidth', 1.5);
        legends{numel(legends)+1} = sprintf('t = %2.2f mins', (cal.raw.powerFluctuationMeas.t(stateMeasIndex) - cal.raw.powerFluctuationMeas.t(1))/60);
    end
    set(gca, 'XLim', spectralLims, 'YLim', powerLims);
    set(gca,  'FontSize', 16);
    hL = legend(legends);
    set(hL, 'Orientation', 'Vertical', 'Location', 'West', 'FontSize', 12);
    title('Uncorrected measurements');
    drawnow;

    subplot('Position', [0.03+0.32 0.05 0.31 0.90]);
    hold on
    for stateMeasIndex = 1:size(cal.raw.powerFluctuationMeas.measSpd,2)-1
        plot(spectralAxis, cal.driftCorrectedOLD.powerFluctuationMeas.measSpd(:,stateMeasIndex), 'k.-', 'Color', cmap(stateMeasIndex,:), 'LineWidth', 1.5);
        legends{numel(legends)+1} = sprintf('t = %2.2f mins', (cal.raw.powerFluctuationMeas.t(stateMeasIndex) - cal.raw.powerFluctuationMeas.t(1))/60);
    end
    set(gca, 'XLim', spectralLims, 'YLim', powerLims);
    set(gca, 'YTickLabel', [], 'FontSize', 16);
    title('Drift corrected measurements (linear - OLD)');

    subplot('Position', [0.03+0.32*2 0.05 0.31 0.90]);
    hold on
    for stateMeasIndex = 1:size(cal.raw.powerFluctuationMeas.measSpd,2)-1
        plot(spectralAxis, cal.driftCorrected.powerFluctuationMeas.measSpd(:,stateMeasIndex), 'k.-', 'Color', cmap(stateMeasIndex,:), 'LineWidth', 1.5);
        legends{numel(legends)+1} = sprintf('t = %2.2f mins', (cal.raw.powerFluctuationMeas.t(stateMeasIndex) - cal.raw.powerFluctuationMeas.t(1))/60);
    end
    set(gca, 'XLim', spectralLims, 'YLim', powerLims);
    set(gca, 'YTickLabel', [], 'FontSize', 16);
    title('Drift corrected measurements (piecewise linear)');
    drawnow;
    
    powerLims = max(cal.raw.spectralShiftsMeas.measSpd(:))*[0.5 1.02];
    hFig = figure(4); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [10 10 2000 570]);
    subplot('Position', [0.03 0.05 0.31 0.90]);
    hold on;
    legends = {};
    for stateMeasIndex = 1:size(cal.raw.spectralShiftsMeas.measSpd,2)-1
        plot(spectralAxis, cal.raw.spectralShiftsMeas.measSpd(:,stateMeasIndex), 'k.-', 'Color', cmap(stateMeasIndex,:), 'LineWidth', 1.5);
        legends{numel(legends)+1} = sprintf('t = %2.2f mins', (cal.raw.spectralShiftsMeas.t(stateMeasIndex) - cal.raw.powerFluctuationMeas.t(1))/60);
    end
    set(gca, 'XLim', spectralLims, 'YLim', powerLims);
    set(gca, 'FontSize', 16);
    hL = legend(legends);
    set(hL, 'Orientation', 'Vertical', 'Location', 'West', 'FontSize', 12);
    title('Uncorrected measurements');
    drawnow;

    subplot('Position', [0.03+0.32 0.05 0.31 0.90]);
    hold on
    for stateMeasIndex = 1:size(cal.raw.spectralShiftsMeas.measSpd,2)-1
        plot(spectralAxis, cal.driftCorrectedOLD.spectralShiftsMeas.measSpd(:,stateMeasIndex), 'k.-', 'Color', cmap(stateMeasIndex,:), 'LineWidth', 1.5);
        legends{numel(legends)+1} = sprintf('t = %2.2f mins', (cal.raw.spectralShiftsMeas.t(stateMeasIndex) - cal.raw.powerFluctuationMeas.t(1))/60);
    end
    set(gca, 'XLim', spectralLims, 'YLim', powerLims);
    set(gca, 'YTickLabel', [], 'FontSize', 16);
    title('Drift corrected measurements (linear - OLD)');

    subplot('Position', [0.03+0.32*2 0.05 0.31 0.90]);
    hold on
    for stateMeasIndex = 1:size(cal.raw.spectralShiftsMeas.measSpd,2)-1
        plot(spectralAxis, cal.driftCorrected.spectralShiftsMeas.measSpd(:,stateMeasIndex), 'k.-', 'Color', cmap(stateMeasIndex,:), 'LineWidth', 1.5);
        legends{numel(legends)+1} = sprintf('t = %2.2f mins', (cal.raw.spectralShiftsMeas.t(stateMeasIndex) - cal.raw.powerFluctuationMeas.t(1))/60);
    end
    set(gca, 'XLim', spectralLims, 'YLim', powerLims);
    set(gca, 'YTickLabel', [], 'FontSize', 16);
    title('Drift corrected measurements (piecewise linear)');
    drawnow;
                    
end
    