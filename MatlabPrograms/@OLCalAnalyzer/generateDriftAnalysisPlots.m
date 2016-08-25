function generateDriftAnalysisPlots(obj)
  
    cal = obj.cal;
    if (isfield(cal.raw, 'spectralShiftsMeas'))
        computeDriftCorrectedStateMeasurements(obj)
        spectralShiftCorrection = computeSpectralShiftCorrectedStateMeasurements(obj);
  
        generateScalingFactorPlots(obj, spectralShiftCorrection);
  
        generateDriftCorrectedStateMeasurementPlots(obj);
       
        generateSpectralShiftPlots(obj);
        
    end
    
end


function generateSpectralShiftPlots(obj)

    cal = obj.cal;
    spectralAxis = SToWls(cal.describe.S);
    
    % Peaks of the comb function
    combPeaks = [480 540 596 652]+10; 
         
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
            drawnow;
        end
            
    
        
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
    nonlcon = [];
    options = optimoptions('fmincon');
    options = optimset('Display', 'off');
    solution = fmincon(@functionToMinimize, initialParams,A, b,Aeq,beq, paramLowerBounds, paramUpperBounds, nonlcon, options);
    
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


function spectralShiftCorrection = computeSpectralShiftCorrectedStateMeasurements(obj)
    cal = obj.cal;
    spectralAxis = SToWls(cal.describe.S);
    
    for stateMeasIndex = 1:size(cal.raw.spectralShiftsMeas.measSpd,2)-1
        
        [spectralShifts(:, stateMeasIndex), refPeaks] = computeSpectralShifts(cal.driftCorrected.spectralShiftsMeas.measSpd(:, stateMeasIndex), ...
            cal.driftCorrected.spectralShiftsMeas.measSpd(:, 1), spectralAxis);
        
        % Apply spectral shift correction
        spectralShiftCorrection.amplitudes(stateMeasIndex) = -median(squeeze(spectralShifts(:, stateMeasIndex)));
        spectralShiftCorrection.times(stateMeasIndex) = cal.raw.spectralShiftsMeas.t(:, stateMeasIndex);
    end
    
    figure(1122); clf; legends = {}; cmap = colormap(lines(size(spectralShifts,1)));
    for k = 1:size(spectralShifts,1)
        plot(spectralShifts(k,:), 'k-', 'LineWidth', 1.5, 'Color', squeeze(cmap(k,:))); hold on;
        legends{numel(legends)+1} = sprintf('%2.1fnm shift',refPeaks(k));
    end
    plot(spectralShiftCorrection.amplitudes, 'k--', 'LineWidth', 1.5);
    plot(spectralShiftCorrection.amplitudes, 'k-', 'LineWidth', 1.5);
    legends{numel(legends)+1} = 'median shift';
    legends{numel(legends)+1} = 'correction applied';
    legend(legends);
    % Update the object's copy
    obj.cal = cal;
end

function shiftedSpd = applySpectalShiftCorrection(theSpd, spectralShiftCorrection, spectralAxis)
    xData = spectralAxis;
    
    % Upsample
    dX = 0.01;
    xDataHiRes = (xData(1):dX:xData(end));
    
    % Interpolate
    theHiResSpd = interp1(xData, squeeze(theSpd), xDataHiRes, 'spline');
    
    % Shift
    shiftBinsNum = sign(spectralShiftCorrection) * round(abs(spectralShiftCorrection)/dX);
    shiftedSpd = circshift(theHiResSpd, shiftBinsNum, 2);
    if (shiftBinsNum>=0)
        shiftedSpd(1:shiftBinsNum) = 0;
    else
        shiftedSpd(end:end+shiftBinsNum+1) = 0;
    end
    
    % back to original sampling
    shiftedSpd = interp1(xDataHiRes, shiftedSpd, xData);
end

function [spectralShifts, refPeaks] = computeSpectralShifts(theSPD, theReferenceSPD, spectralAxis)
    % Peaks of the comb function
    combPeaks = [480 540 596 652]+10; 
    
    paramNames = {...
        'offset (mWatts)', ...
        'gain (mWatts)', ...
        'peak (nm)', ...
        'left side sigma (nm)', ...
        'right side sigma (nm)', ...
        'exponent'};
    
    % Fit each of the combPeaks separately
    for peakIndex = 1:numel(combPeaks)
        
        % nominal peak
        peak = combPeaks(peakIndex);
        
        % Find exact peak
        dataIndicesToFit = sort(find(abs(spectralAxis - peak) <= 15));
        [maxComb,idx] = max(theReferenceSPD(dataIndicesToFit));
        peak = spectralAxis(dataIndicesToFit(idx));
        refPeaks(peakIndex) = peak;
        
        % Select spectral region to fit
        dataIndicesToFit = sort(find(abs(spectralAxis - peak) <= 15));
        dataIndicesToFit = dataIndicesToFit(find(theReferenceSPD(dataIndicesToFit) > 0.1*maxComb));
        
        xData = spectralAxis(dataIndicesToFit);
        xDataHiRes = (xData(1):0.1:xData(end))';
        
        initialParams    = [0   5  peak     6.28   6.28  2.0];
        paramLowerBounds = [0   0  peak-20  1.00   1.00  1.5]; 
        paramUpperBounds = [0  10  peak+20 10.00  10.00  4.0];
        
        % Fit the reference SPD peak
        spdData = 1000*theReferenceSPD(dataIndicesToFit);  % in milliWatts
        fitParams = fitGaussianToData(xData, spdData, initialParams, paramLowerBounds, paramUpperBounds);
        refPeak(peakIndex) = fitParams(3);
        
        % Fit the current SPD peak
        spdData = 1000*theSPD(dataIndicesToFit);  % in milliWatts
        fitParams = fitGaussianToData(xData, spdData, initialParams, paramLowerBounds, paramUpperBounds);
        currentPeak(peakIndex) = fitParams(3);
        
        spectralShifts(peakIndex) = currentPeak(peakIndex) - refPeak(peakIndex);
    end % peakIndex

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

function generateScalingFactorPlots(obj, spectralShiftCorrection)

    cal = obj.cal;
    spectralAxis = SToWls(cal.describe.S);
    cmap = 0.7*jet(size(cal.raw.spectralShiftsMeas.measSpd,2));
    rawData = rawScaleFactorsFromStateTrackingData(cal);
    
    % test at a fine time axis, every dt seconds
    dt = 5.0;
    tInterp = cal.raw.powerFluctuationMeas.t(1):dt:cal.raw.powerFluctuationMeas.t(end);

    hFig = figure(1);  clf;
    set(hFig, 'Position', [10 10 1200 600]);
    subplot('Position', [0.07 0.08 0.92 0.91]);
    timeAxis = (tInterp - tInterp(1))/60;
    plot(timeAxis, cal.computed.returnScaleFactorOLD(tInterp), 'k-', 'LineWidth', 1.5, 'MarkerSize', 8, 'MarkerFaceColor', [0.5 0.5 0.5]);

    hold on;
    plot(timeAxis, cal.computed.returnScaleFactor(tInterp), 'r-', 'LineWidth', 1.5, 'MarkerSize', 8, 'MarkerFaceColor', [1.0 0.8 0.8]);
    plot((rawData.x - tInterp(1))/60, rawData.y, 'rs');
    hL = legend('original correction (2 points)', 'correction by tracking state over time');
    set(hL, 'Orientation', 'Horizontal', 'Location', 'NorthOutside', 'FontSize', 16);
    set(gca, 'FontSize', 14);
    xlabel('Time (minutes)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('Drift correction', 'FontSize', 16, 'FontWeight', 'bold');

    % Also generate a figure showing the power and spectral stability over time
    figure(2); clf; 
    subplot(1,2,1);
    hold on;
    legends = {};
    referenceSpd = cal.raw.spectralShiftsMeas.measSpd(:,1);
    diffSpectraInMilliWatts = 1000*bsxfun(@minus, cal.raw.spectralShiftsMeas.measSpd, referenceSpd);
    Ylim = max(abs(diffSpectraInMilliWatts(:)))*[-1 1];
    for stateMeasIndex = 1:size(cal.raw.spectralShiftsMeas.measSpd,2)
        plot(spectralAxis, diffSpectraInMilliWatts (:,stateMeasIndex), 'k-', 'Color', cmap(stateMeasIndex,:), 'LineWidth', 1.5);
        legends{numel(legends)+1} = sprintf('t = %2.2f mins', (cal.raw.spectralShiftsMeas.t(stateMeasIndex) - cal.raw.spectralShiftsMeas.t(1))/60);
    end
    set(gca, 'YLim', Ylim);
    ylabel('raw spd - reference spd');
    title('raw data');
    hL = legend(legends);
    set(hL, 'Orientation', 'Vertical', 'Location', 'WestOutside', 'FontSize', 12)
    
    subplot(1,2,2);
    hold on;
    for stateMeasIndex = 1:size(cal.raw.spectralShiftsMeas.measSpd,2)-1
        
        % Find closest state measurement index
        theMeasurementTime = cal.raw.spectralShiftsMeas.t(:, stateMeasIndex);
        [~,closestStateMeasIndex] = min(abs(spectralShiftCorrection.times - theMeasurementTime));
        [closestStateMeasIndex stateMeasIndex spectralShiftCorrection.amplitudes(closestStateMeasIndex)]
        % Shift according to that index
 
        spectralShiftCorrectedSpd = applySpectalShiftCorrection(cal.driftCorrected.spectralShiftsMeas.measSpd(:, stateMeasIndex), ...
            spectralShiftCorrection.amplitudes(closestStateMeasIndex), spectralAxis);
        
        diffSpectraInMilliWatts = 1000*(spectralShiftCorrectedSpd - referenceSpd);
        plot(spectralAxis, diffSpectraInMilliWatts, 'k-', 'Color', cmap(stateMeasIndex,:), 'LineWidth', 1.5);
        legends{numel(legends)+1} = sprintf('t = %2.2f mins', (cal.raw.spectralShiftsMeas.t(stateMeasIndex) - cal.raw.spectralShiftsMeas.t(1))/60);
    end
    ylabel('spectral shift corrected spd - reference spd');
    title('spectral shift corrected data');
    set(gca, 'YLim', Ylim);
    hL = legend(legends);
    set(hL, 'Orientation', 'Vertical', 'Location', 'WestOutside', 'FontSize', 12)
    
    drawnow;
end

% Nested function computing scale factor based on state tracking measurements
function rawData = rawScaleFactorsFromStateTrackingData(cal)
    wavelengthIndices = find(cal.raw.fullOn(:,end) > 0.2*max(cal.raw.fullOn(:)));
    stateMeasurementsNum = size(cal.raw.powerFluctuationMeas.measSpd,2);
    meas0 = cal.raw.powerFluctuationMeas.measSpd(wavelengthIndices,1);
    figure(222);
    clf;
    for k = 1:3
        subplot(1,3,k);
        plot(1:numel(wavelengthIndices), meas0, 'k-');
        hold on;
        meas1 = cal.raw.powerFluctuationMeas.measSpd(wavelengthIndices,1+k);
        plot(1:numel(wavelengthIndices), meas1, 'r-');
        legend({'1', sprintf('%d', 1+k)});
    end
    drawnow;
    
    figure(223);
    clf;
    meas0 = cal.raw.spectralShiftsMeas.measSpd(wavelengthIndices,1);
    for k = 1:3
        subplot(1,3,k);
        plot(1:numel(wavelengthIndices), meas0, 'k-');
        hold on;
        meas1 = cal.raw.spectralShiftsMeas.measSpd(wavelengthIndices,1+k);
        plot(1:numel(wavelengthIndices), meas1, 'r-');
        legend({'1', sprintf('%d', 1+k)});
    end
    drawnow;
 
    meas0 = cal.raw.powerFluctuationMeas.measSpd(wavelengthIndices,1);
    for stateMeasurementIndex = 1:stateMeasurementsNum
        y(stateMeasurementIndex) = 1.0 ./ (meas0 \ cal.raw.powerFluctuationMeas.measSpd(wavelengthIndices,stateMeasurementIndex));
    end
    x = cal.raw.powerFluctuationMeas.t;
    rawData.x = x;
    rawData.y = y;
end
    