function generateDriftAnalysisPlots(obj)
  
    cal = obj.cal;
    if (isfield(cal.computed, 'returnScaleFactor'))
        generateScalingFactorPlots(obj);
        generateDriftCorrectedStateMeasurementPlots(obj);
        generateSpectralShiftPlots(obj);
    end
    
end


function generateSpectralShiftPlots(obj)

    cal = obj.cal;
    spectralAxis = SToWls(cal.describe.S);
    
    % Peaks of the comb function
    combPeaks = [480 540 596 652]; 
         
    paramNames = {...
        'offset (mWatts)', ...
        'gain (mWatts)', ...
        'peak (nm)', ...
        'left side sigma (nm)', ...
        'right side sigma (nm)', ...
        'exponent'};
    
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
    theSPDs = cal.driftCorrected.spectralShiftsMeas.measSpd;
        
    % Fit each of the combPeaks separately
    for peakIndex = 1:numel(combPeaks)
        peak = combPeaks(peakIndex);
        
        % Adjust the peak if needed
        stateMeasIndex = 1;
        dataIndicesToFit = sort(find(abs(spectralAxis - peak) <= 15));
        [maxComb,idx] = max(theSPDs(dataIndicesToFit, stateMeasIndex));
        peak = spectralAxis(dataIndicesToFit(idx));
        % Add legend
        fig6Legends{peakIndex} = sprintf('peak at %d nm', peak);

    
        dataIndicesToFit2 = find(theSPDs(dataIndicesToFit, stateMeasIndex) > 0.1*maxComb);
        dataIndicesToFit = dataIndicesToFit(dataIndicesToFit2);
    
        xData = spectralAxis(dataIndicesToFit);
        xDataHiRes = (xData(1):0.2:xData(end))';
    
        for stateMeasIndex = 1:size(theSPDs,2)
            initialParams    = [0   5  peak     6.28   6.28  2.0];
            paramLowerBounds = [0   0  peak-20  1.00   1.00  1.5]; 
            paramUpperBounds = [0  10  peak+20 10.00  10.00  4.0];
            d(peakIndex, stateMeasIndex).yData = 1000*theSPDs(dataIndicesToFit, stateMeasIndex);  % in milliWatts
            d(peakIndex, stateMeasIndex).fitParams = fitGaussianToData(xData, d(peakIndex, stateMeasIndex).yData, initialParams, paramLowerBounds, paramUpperBounds);
            d(peakIndex, stateMeasIndex).yDataHiRes = twoSidedExponential(xDataHiRes, d(peakIndex, stateMeasIndex).fitParams);
        end
    
        hFig = figure(5 + 100*(peakIndex-1)); clf;
        set(hFig, 'Position', [10 10 1400 1000], 'Color', [1 1 1]);
        rowsNum = round(sqrt(size(theSPDs,2))*0.7);
        colsNum = ceil(size(theSPDs,2) / rowsNum);
        subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', rowsNum, ...
               'colsNum', colsNum, ...
               'heightMargin',   0.03, ...
               'widthMargin',    0.02, ...
               'leftMargin',     0.01, ...
               'rightMargin',    0.01, ...
               'bottomMargin',   0.03, ...
               'topMargin',      0.01);

        YLims = [min(d(peakIndex, stateMeasIndex).yData(:)) 1.05*max(d(peakIndex, stateMeasIndex).yData(:))];
    
        for stateMeasIndex = 1:size(theSPDs,2)
            rowIndex = floor((stateMeasIndex-1)/colsNum)+1;
            colIndex = mod(stateMeasIndex-1, colsNum) + 1;
            subplot('Position', subplotPosVectors(rowIndex, colIndex).v);
            hold on;
            plot(xData, d(peakIndex, stateMeasIndex).yData, 'ks', 'MarkerFaceColor', [0.5 0.5 0.5]);
            plot(xDataHiRes, d(peakIndex, stateMeasIndex).yDataHiRes, 'r-', 'LineWidth', 1.5);
            set(gca, 'XLim', [xData(1) xData(end)], 'YLim', YLims, 'XTick', (0:5:1000), 'YTickLabel', {});
            if (rowIndex < rowsNum)
                set(gca, 'XTickLabel', {});
            end
            title(sprintf('measurement %d', stateMeasIndex));
        end
        drawnow;
    
    
        
        % Update figure 6
        figure(hFig6);
        % The gain time series
        paramIndex = 2;
        for stateMeasIndex = 1:size(theSPDs,2)
            paramTimeSeries(stateMeasIndex) = d(peakIndex, stateMeasIndex).fitParams(paramIndex) / d(peakIndex, 1).fitParams(paramIndex);
        end
        subplot('Position', subplotPosVectors2(1,1).v);
        hold on
        plot(1:size(theSPDs,2), paramTimeSeries, 'ko-', 'Color', 0.5*squeeze(cmap(peakIndex,:)), 'MarkerSize', 12, 'MarkerFaceColor', squeeze(cmap(peakIndex,:)), 'LineWidth', 1);
        set(gca, 'FontSize', 14);
        ylabel(sprintf('%s (ratio)', paramNames{paramIndex}), 'FontSize', 16, 'FontWeight', 'bold');
        xlabel('measurement index', 'FontSize', 16, 'FontWeight', 'bold');
        if (peakIndex == numel(combPeaks))
            hL = legend(fig6Legends);
            set(hL, 'FontSize', 14);
        end
    
        % The peak time series
        paramIndex = 3;
        for stateMeasIndex = 1:size(theSPDs,2)
            paramTimeSeries(stateMeasIndex) = d(peakIndex, stateMeasIndex).fitParams(paramIndex) - d(peakIndex, 1).fitParams(paramIndex);
        end
        subplot('Position', subplotPosVectors2(1,2).v);
        hold on
        plot(1:size(theSPDs,2), paramTimeSeries, 'ko-', 'MarkerSize', 12, 'Color', 0.5*squeeze(cmap(peakIndex,:)), 'MarkerFaceColor', squeeze(cmap(peakIndex,:)), 'LineWidth', 1);
        set(gca, 'FontSize', 14);
        ylabel(sprintf('%s (differential)', paramNames{paramIndex}), 'FontSize', 16, 'FontWeight', 'bold');
        xlabel('measurement index', 'FontSize', 16, 'FontWeight', 'bold');
        
    
        % The left/right sigmas series
        paramIndex = 4;
        for stateMeasIndex = 1:size(theSPDs,2)
            paramTimeSeries1(stateMeasIndex) = d(peakIndex, stateMeasIndex).fitParams(paramIndex);
            paramTimeSeries2(stateMeasIndex) = d(peakIndex, stateMeasIndex).fitParams(paramIndex+1);
        end
        subplot('Position', subplotPosVectors2(2,1).v);
        hold on
        plot(1:size(theSPDs,2), paramTimeSeries1, 'ko-', 'MarkerSize', 12, 'Color', 0.5*squeeze(cmap(peakIndex,:)), 'MarkerFaceColor', squeeze(cmap(peakIndex,:)), 'LineWidth', 1);
        plot(1:size(theSPDs,2), paramTimeSeries2, 'ks-', 'MarkerSize', 12, 'Color', 0.5*squeeze(cmap(peakIndex,:)), 'MarkerFaceColor', squeeze(cmap(peakIndex,:)), 'LineWidth', 1);
        set(gca, 'FontSize', 14);
        ylabel(sprintf('%s/%s', paramNames{4}, paramNames{5}), 'FontSize', 16, 'FontWeight', 'bold');
        xlabel('measurement index', 'FontSize', 16, 'FontWeight', 'bold');
        
    
        % The exponent time series
        paramIndex = 6;
        for stateMeasIndex = 1:size(theSPDs,2)
            paramTimeSeries(stateMeasIndex) = d(peakIndex, stateMeasIndex).fitParams(paramIndex);
        end
        subplot('Position', subplotPosVectors2(2,2).v);
        hold on
        plot(1:size(theSPDs,2), paramTimeSeries, 'ko-', 'MarkerSize', 12, 'Color', 0.5*squeeze(cmap(peakIndex,:)), 'MarkerFaceColor', squeeze(cmap(peakIndex,:)), 'LineWidth', 1);
        set(gca, 'FontSize', 14);
        ylabel(paramNames{paramIndex}, 'FontSize', 16, 'FontWeight', 'bold');
        xlabel('measurement index', 'FontSize', 16, 'FontWeight', 'bold');
        
        drawnow;
    end % peakIndex
    
end

function solution = fitGaussianToData(xData, yData, initialParams, paramLowerBounds, paramUpperBounds)
    
    Aeq = [];
    beq = [];
    A = [];
    b = [];
    solution = fmincon(@functionToMinimize, initialParams,A, b,Aeq,beq, paramLowerBounds, paramUpperBounds);
    
    function rmsResidual = functionToMinimize(params)
        yfit = twoSidedExponential(xData, params);
        rmsResidual  = sum((yfit - yData) .^2);
    end
end

function g = twoSidedExponential(wavelength, params)
    offset = params(1);
    gain = params(2);
    peakWavelength = params(3);
    leftSigmaWavelength = params(4);
    rightSigmaWavelength = params(5);
    exponent = params(6);
    leftIndices = find(wavelength < peakWavelength);
    rightIndices = find(wavelength >= peakWavelength);
    g1 = offset + gain*exp(-0.5*(abs((wavelength(leftIndices)-peakWavelength)/leftSigmaWavelength)).^exponent);    
    g2 = offset + gain*exp(-0.5*(abs((wavelength(rightIndices)-peakWavelength)/rightSigmaWavelength)).^exponent);
    g = cat(1, g1, g2);
end

function generateDriftCorrectedStateMeasurementPlots(obj)

    cal = obj.cal;
    spectralAxis = SToWls(cal.describe.S);
    cmap = 0.7*jet(size(cal.raw.spectralShiftsMeas.measSpd,2));
    
    % Compute drift corrected state measurements
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

function generateScalingFactorPlots(obj)

    cal = obj.cal;
    spectralAxis = SToWls(cal.describe.S);
    cmap = 0.7*jet(size(cal.raw.spectralShiftsMeas.measSpd,2));
    
    % test at a fine time axis, every dt seconds
    dt = 5.0;
    tInterp = cal.raw.powerFluctuationMeas.t(1):dt:cal.raw.powerFluctuationMeas.t(end);

    hFig = figure(1);  clf;
    set(hFig, 'Position', [10 10 1200 600]);
    subplot('Position', [0.07 0.08 0.92 0.91]);
    timeAxis = (tInterp - tInterp(1))/60;
    plot(timeAxis, cal.computed.returnScaleFactorOLD(tInterp), 'ko-', 'LineWidth', 1.5, 'MarkerSize', 8, 'MarkerFaceColor', [0.5 0.5 0.5]);

    hold on;
    plot(timeAxis, cal.computed.returnScaleFactor(tInterp), 'ro-', 'LineWidth', 1.5, 'MarkerSize', 8, 'MarkerFaceColor', [1.0 0.8 0.8]);
    hL = legend('original correction (2 points)', 'correction by tracking state over time');
    set(hL, 'Orientation', 'Horizontal', 'Location', 'NorthOutside', 'FontSize', 16);
    set(gca, 'FontSize', 14);
    xlabel('Time (minutes)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('Drift correction', 'FontSize', 16, 'FontWeight', 'bold');

    % Also generate a figure showing the power and spectral stability over time
    figure(2); clf; hold on;
    diffSpectraInMilliWatts = 1000*bsxfun(@minus, cal.raw.spectralShiftsMeas.measSpd, cal.raw.spectralShiftsMeas.measSpd(:,1));
    legends = {};
    for stateMeasIndex = 1:size(cal.raw.spectralShiftsMeas.measSpd,2)
        plot(spectralAxis, diffSpectraInMilliWatts (:,stateMeasIndex), 'k-', 'Color', cmap(stateMeasIndex,:), 'LineWidth', 1.5);
        legends{numel(legends)+1} = sprintf('t = %2.2f mins', (cal.raw.spectralShiftsMeas.t(stateMeasIndex) - cal.raw.spectralShiftsMeas.t(1))/60);
    end
    hL = legend(legends);
    set(hL, 'Orientation', 'Vertical', 'Location', 'WestOutside', 'FontSize', 12)
    drawnow;
end