function parseCombFunctionData(warmUpData, wavelengthAxis)
 
    [warmUpDataCorrected, ~] = correctForLinearDrift(warmUpData, wavelengthAxis);
    darkSPD = mean(warmUpDataCorrected{1}.measuredSPD,2);
    
    %fitData(warmUpDataCorrected, wavelengthAxis, darkSPD );
    %return;
    
%     load T_cones_ss2;
%     load 'T_melanopsin'
%     T_cones      = SplineCmf(S_cones_ss2,  T_cones_ss2,  WlsToS(wavelengthAxis));
%     T_melanopsin = SplineCmf(S_melanopsin, T_melanopsin, WlsToS(wavelengthAxis));
    
    [warmUpData, warmUpDataUncorrected] = correctForLinearDrift(warmUpData, wavelengthAxis);
    warmUpData = subtractDarkSPD(warmUpData);
    
    plotTimeCourseOfAllWavelengths(wavelengthAxis, warmUpData);
    
    meanFullOnSPD = mean(warmUpData{2}.measuredSPD,2);
    fullOnResiduals = bsxfun(@minus, warmUpData{2}.measuredSPD, meanFullOnSPD);
    
    for stimIndex = 3:numel(warmUpData)
        testSPD = mean(warmUpData{stimIndex}.measuredSPD,2);
        testFilter = testSPD ./ meanFullOnSPD;
        measuredResiduals(stimIndex-2,:,:) = bsxfun(@minus, warmUpData{stimIndex}.measuredSPD, testSPD);
        predictedResiduals(stimIndex-2,:,:) = bsxfun(@times, fullOnResiduals, testFilter);
        measuredResidualsTimes(stimIndex-2,:) = warmUpData{stimIndex}.measurementTime;
    end
    
    
    videoFilename = 'all.m4v';
    writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
    writerObj.FrameRate = 15; 
    writerObj.Quality = 100;
    writerObj.open();
    
    hFig = figure(1); clf;
    wavelengthRange = [400 720];
    set(hFig, 'Color', [1 1 1], 'Position', [1 1 1024 768]);
    makeVideo(wavelengthAxis, wavelengthRange, predictedResiduals, measuredResiduals, measuredResidualsTimes, hFig, writerObj);
    writerObj.close();
end

function fitData(warmUpData, wavelengthAxis, darkSPD)
    stimPattern = 7;
    % subtract darkSPD
    darkSubtractedSPD = bsxfun(@minus, warmUpData{stimPattern}.measuredSPD, darkSPD);
    measuredSPDmWatts = 1000*darkSubtractedSPD;
    measuredSPDmWatts = measuredSPDmWatts / max(measuredSPDmWatts(:));
    
    measurementTimeMinutes = warmUpData{stimPattern}.measurementTime;
    measurementTimeMinutes = measurementTimeMinutes-measurementTimeMinutes(1);
    primarySPD = squeeze(mean(measuredSPDmWatts,2));
    firstMeasurementSPD = squeeze(measuredSPDmWatts(:,1));
    [maxPrimary,peakWavelengthIndex] = max(primarySPD);
    [~,leftSideWavelengthIndex] = min(abs(primarySPD(1:peakWavelengthIndex)-maxPrimary/2));
    [~,rightSideWavelengthIndex] = min(abs(primarySPD(peakWavelengthIndex:end)-maxPrimary/2));
    rightSideWavelengthIndex = rightSideWavelengthIndex + (peakWavelengthIndex-1);
    peakTrace = measuredSPDmWatts(peakWavelengthIndex,:);
    leftSideTrace = measuredSPDmWatts(leftSideWavelengthIndex,:);
    rightSideTrace = measuredSPDmWatts(rightSideWavelengthIndex,:);
    
    extraPoints = 6;
    dataIndicesToFit = leftSideWavelengthIndex-extraPoints  : rightSideWavelengthIndex+extraPoints
    
    
    visualizedWavelengthRange = [540 590]; % wavelengthAxis(peakWavelengthIndex) + [-25 25];
    measurementTimeRange = [0 max(measurementTimeMinutes)];
    
    if (1==2)
    hFig = figure(3); 
    set(hFig, 'Color', [1 1 1], 'Position', [1 1 1024 768], 'MenuBar', 'none');
    
    writerObj = VideoWriter('TimeSeriesAnimation.m4v', 'MPEG-4'); % H264 format
    writerObj.FrameRate = 15; 
    writerObj.Quality = 100;
    writerObj.open();
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
           'rowsNum', 2, ...
           'colsNum', 2, ...
           'heightMargin',   0.05, ...
           'widthMargin',    0.06, ...
           'leftMargin',     0.05, ...
           'rightMargin',    0.000, ...
           'bottomMargin',   0.06, ...
           'topMargin',      0.01);
       
    
    
    for tBin = 1:numel(measurementTimeMinutes)
        clf;
        
        pos = subplotPosVectors(2,1).v;
        subplot('Position', [pos(1) pos(2) pos(3) pos(4)*2.1]);
        hold on
        plot(wavelengthAxis, measuredSPDmWatts(:,tBin), 'k-', 'Color', [0.0 0.0 0], 'LineWidth', 3.0);
        plot(wavelengthAxis(dataIndicesToFit), measuredSPDmWatts(dataIndicesToFit,tBin), 'ko', 'MarkerSize', 16, 'MarkerFaceColor', [0.6 0.6 0.6]);
        plot(wavelengthAxis(leftSideWavelengthIndex), measuredSPDmWatts(leftSideWavelengthIndex,tBin), 'ro', 'MarkerSize', 16, 'MarkerFaceColor', [1.0 0.6 0.6]);
        plot(wavelengthAxis(rightSideWavelengthIndex), measuredSPDmWatts(rightSideWavelengthIndex,tBin), 'bo', 'MarkerSize', 16, 'MarkerFaceColor', [0.6 0.6 1.0]);
        plot(wavelengthAxis(peakWavelengthIndex)*[1 1], [0 maxPrimary*1.1], 'k--', 'LineWidth', 2.0);
        plot(wavelengthAxis(leftSideWavelengthIndex)*[1 1], [0 maxPrimary*1.1], 'r--', 'LineWidth', 2.0);
        plot(wavelengthAxis(rightSideWavelengthIndex)*[1 1], [0 maxPrimary*1.1], 'b--', 'LineWidth', 2.0);
        set(gca, 'XLim', visualizedWavelengthRange, 'YLim', [0 1], 'FontSize', 16);
        text(542, 0.95, sprintf('t: %2.1fmin', measurementTimeMinutes(tBin)), 'FontSize', 16, 'FontName', 'Menlo');
        box off; grid on;
        xlabel('wavelength (nm)', 'FontSize', 18, 'FontWeight', 'bold');
        ylabel('power', 'FontSize', 18, 'FontWeight', 'bold');
        
        
        subplot('Position', subplotPosVectors(1,2).v);
        plot(measurementTimeMinutes(1:tBin), peakTrace(1:tBin), 'k-', 'LineWidth', 3.0); hold on;
        plot(measurementTimeMinutes(1:tBin), leftSideTrace(1:tBin), 'r-', 'LineWidth', 3.0); hold on;
        plot(measurementTimeMinutes(1:tBin), rightSideTrace(1:tBin), 'b-', 'LineWidth', 3.0); hold on;
        set(gca, 'XLim', measurementTimeRange, 'YLim', [0 1], 'FontSize', 16);
        box off; grid on;
        %xlabel('time (mins)', 'FontSize', 18, 'FontWeight', 'bold');
        ylabel('power', 'FontSize', 18, 'FontWeight', 'bold');
        
        subplot('Position', subplotPosVectors(2,2).v);
        plot(measurementTimeMinutes(1:tBin), peakTrace(1:tBin)-mean(peakTrace), 'k-', 'LineWidth', 3.0); hold on;
        plot(measurementTimeMinutes(1:tBin), leftSideTrace(1:tBin)-mean(leftSideTrace), 'r-', 'LineWidth', 3.0); hold on;
        plot(measurementTimeMinutes(1:tBin), rightSideTrace(1:tBin)-mean(rightSideTrace), 'b-', 'LineWidth', 3.0); hold on;
        yTicks = -0.05:0.01:0.05;
        set(gca, 'XLim', measurementTimeRange, 'YLim', 0.021*[-1 1], 'FontSize', 16, 'YTick', yTicks, 'YTickLabel', sprintf('%0.2f\n', yTicks));
        box off; grid on;
        xlabel('time (mins)', 'FontSize', 18, 'FontWeight', 'bold');
        ylabel('diff power', 'FontSize', 18, 'FontWeight', 'bold');
        
        
        drawnow;
        writerObj.writeVideo(getframe(hFig));
    end
    writerObj.close();
    
    NicePlot.exportFigToPDF('Fitting.pdf', hFig,300); 
     
end


    hFig = figure(10); clf; 
    set(hFig, 'Color', [1 1 1], 'Position', [1 100 860 950]);
    subplot('position', [0.06 0.06 0.920 0.925]);
    %plot(wavelengthAxis, primarySPD, 'k-', 'LineWidth', 2.0); hold on;
    %plot(wavelengthAxis, firstMeasurementSPD, 'r-', 'LineWidth', 4.0); hold on;
    wavelengthAxis(dataIndicesToFit)
    firstMeasurementSPD(dataIndicesToFit)
    size(wavelengthAxis(dataIndicesToFit))
    size(firstMeasurementSPD(dataIndicesToFit))
    plot(wavelengthAxis(dataIndicesToFit), firstMeasurementSPD(dataIndicesToFit), 'ko', 'MarkerSize', 20, 'MarkerFaceColor', [0.8 0.8 0.8]);
    hold on
    visualizedWavelengthRange
    set(gca, 'XLim', visualizedWavelengthRange, 'FontSize', 18);
    xlabel('wavelength (nm)', 'FontSize', 20, 'FontWeight', 'bold');
    ylabel('power', 'FontSize', 20, 'FontWeight', 'bold');
    
    xData = wavelengthAxis(dataIndicesToFit);
    
    % Fit the first measurement
    paramNames       = {'offset (mWatts)', 'gain (mWatts)', 'peak (nm)', 'left side sigma (nm)', 'right side sigma (nm)', 'exponent'};
    initialParams    = [0   5  565  6.28   6.28   2];
    paramLowerBounds =   [0   0  500  1   1 1.5];  % [0   0  500  6.28   6.28   2];
    paramUpperBounds = [0  10  600  10  10 4]; % [0  10  600  6.28  6.28  2]; % 
    firstMeasurementParams = fitGaussianToData(xData, firstMeasurementSPD(dataIndicesToFit), initialParams, paramLowerBounds, paramUpperBounds)
    hiresWavelengthAxis = wavelengthAxis(1):0.05:wavelengthAxis(end);
    plot(hiresWavelengthAxis, gaussianFilter(hiresWavelengthAxis', firstMeasurementParams), 'r-', 'LineWidth', 3.0);
    set(gca, 'XLim', visualizedWavelengthRange, 'YLim', [0 1.05]);
    box off;
    grid on
    NicePlot.exportFigToPDF('Fitting.pdf', hFig,300);
    pause;
    
    
    % Choose fixed params
    paramTestLowerBounds = paramLowerBounds;
    paramTestUpperBounds = paramUpperBounds;
    fixedParamIndices = [1  3 4 5 6];  % Gain-only 
    %fixedParamIndices = [1     4 5 6];  % Gain + peak only 
    %fixedParamIndices = [1     3 4 5];  % Gain + exponent vary
    %fixedParamIndices = [1];  % All vary (expect for offset)
    for paramIndex = fixedParamIndices
        paramTestLowerBounds(paramIndex) = firstMeasurementParams(paramIndex)-eps;
        paramTestUpperBounds(paramIndex) = firstMeasurementParams(paramIndex)+eps;
    end
    
    meanFilterParams = fitGaussianToData(xData, primarySPD(dataIndicesToFit), firstMeasurementParams, paramTestLowerBounds, paramTestUpperBounds);
    for measurementIndex = 1:numel(measurementTimeMinutes)
        yData = squeeze(measuredSPDmWatts(dataIndicesToFit, measurementIndex));
        fittedParams(measurementIndex,:) = fitGaussianToData(xData, yData, firstMeasurementParams, paramTestLowerBounds, paramTestUpperBounds);
        yDataPrediction = gaussianFilter(xData, squeeze(fittedParams(measurementIndex,:)));
        residuals(measurementIndex,:) = yData-yDataPrediction;
        errorSequence(measurementIndex) = sqrt(mean((squeeze(residuals(measurementIndex,:))).^2));
    end
    
    hFig = figure(3); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [1 1 1024 768]);
    subplot('Position', [0.05 0.05 0.94 0.94]);
    plot(wavelengthAxis(dataIndicesToFit), 100*std(residuals, 0, 1), 'ro-', 'LineWidth', 2.0, 'MarkerSize', 14, 'MarkerFaceColor', [1.0 0.5 0.5]);
    hold on
    plot(wavelengthAxis(dataIndicesToFit), squeeze(measuredSPDmWatts(dataIndicesToFit, :)), 'k-', 'LineWidth', 2.0);
    hL = legend({'100*std', 'measurements'});
    set(hL, 'FontSize', 14, 'FontName', 'Menlo');
    box off; grid on
    set(gca, 'XLim', [wavelengthAxis(dataIndicesToFit(1)) wavelengthAxis(dataIndicesToFit(end))], 'FontSize', 14);
    xlabel('wavelength (nm)', 'FontSize', 16,  'FontWeight', 'bold'); 
    ylabel('power (mWatts)','FontSize', 16, 'FontWeight', 'bold');
     NicePlot.exportFigToPDF('TimeSeriesParamResiduals.pdf', hFig,300);    

    
    hFig = figure(2);
    set(hFig, 'Color', [1 1 1], 'Position', [1 1 1600 900]);
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
           'rowsNum', 2, ...
           'colsNum', 3, ...
           'heightMargin',   0.05, ...
           'widthMargin',    0.05, ...
           'leftMargin',     0.05, ...
           'rightMargin',    0.000, ...
           'bottomMargin',   0.05, ...
           'topMargin',      0.01);
       
    for paramIndex = 1:6
        row = floor((paramIndex-1)/3)+1;
        col = mod(paramIndex-1,3) + 1;
        subplot('Position', subplotPosVectors(row,col).v);
        
        if (paramIndex == 1)
            plot(measurementTimeMinutes, errorSequence, 'bo-', 'MarkerSize', 8, 'MarkerFaceColor', [0.6 0.6 1.0]);
            yLabelTitle = 'rms error (mWatts)';
            YLims = [0.02 0.045]; YTicks = [0.02 :0.005 : 0.045];
        else
            paramTimeVariation = squeeze(fittedParams(:,paramIndex));
            if (paramIndex == 3)
                plot(measurementTimeMinutes, paramTimeVariation-meanFilterParams(3), 'bo-', 'MarkerSize', 8, 'MarkerFaceColor', [0.6 0.6 1.0]); hold on;
                plot([measurementTimeMinutes(1) measurementTimeMinutes(end)], meanFilterParams(3)*[0 0], 'r--', 'LineWidth', 2.0);
            else
                plot(measurementTimeMinutes, paramTimeVariation, 'bo-', 'MarkerSize', 8, 'MarkerFaceColor', [0.6 0.6 1.0]); hold on;
                plot([measurementTimeMinutes(1) measurementTimeMinutes(end)], meanFilterParams(paramIndex)*[1 1], 'r--', 'LineWidth', 2.0);
            end
            plot([measurementTimeMinutes(1) measurementTimeMinutes(end)], paramLowerBounds(paramIndex)*[1 1], 'c--', 'LineWidth', 2.0);
            plot([measurementTimeMinutes(1) measurementTimeMinutes(end)], paramUpperBounds(paramIndex)*[1 1], 'b--', 'LineWidth', 2.0);
            hold off
            hL = legend({'time varying value', 'mean filter value'}, 'Location', 'NorthWest');
            set(hL, 'FontName', 'Menlo', 'FontSize', 14);
            yLabelTitle = paramNames{paramIndex};
            YLims = [min(paramTimeVariation)-0.0001 max(paramTimeVariation)+0.0001];
            switch paramNames{paramIndex}
                case 'left side sigma (nm)'
                    YLims = [6.9 7.0]; YTicks = [6.9:0.02:7.0];
                case 'right side sigma (nm)'
                    YLims = [6.9 7.0];  YTicks = [6.9:0.02:7.0];
                case 'gain (mWatts)'
                    YLims = [4.3 4.6]; YTicks = [4.3 : 0.05: 4.6];
                case 'peak (nm)'
                    YLims = [-0.15 0.15]; YTicks = [-0.15 : 0.05 : 0.15];
                case 'exponent'
                    YLims = [2.51 2.55]; YTicks = [2.51 : 0.01 : 2.55];
            end
        end
        
        measurementTimeMinutes
        set(gca, 'XTick', (0:60:1000), 'XLim', [measurementTimeMinutes(1) measurementTimeMinutes(end)]);
        set(gca, 'YLim', YLims, 'YTick', YTicks, 'YTickLabel', sprintf('%2.3f\n', YTicks), 'FontSize', 14);
        if (row == 2)
            xlabel('time (min)', 'FontSize', 16,  'FontWeight', 'bold'); 
        end
        ylabel(yLabelTitle,'FontSize', 16, 'FontWeight', 'bold');
        
        box off; grid on
    end
    
    NicePlot.exportFigToPDF('TimeSeriesParamFits.pdf', hFig,300);
    
end

function solution = fitGaussianToData(xData, yData, initialParams, paramLowerBounds, paramUpperBounds)
    
    Aeq = [];
    beq = [];
    A = [];
    b = [];
    solution = fmincon(@functionToMinimize, initialParams,A, b,Aeq,beq, paramLowerBounds, paramUpperBounds);
    
    function rmsResidual = functionToMinimize(params)
        yfit = gaussianFilter(xData, params);
        rmsResidual  = sum((yfit - yData) .^2);
    end
end

function g = gaussianFilter(wavelength, params)
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
    


function plotTimeCourseOfAllWavelengths(wavelengthAxis, warmUpData)
    
    stimPattern = 1;
    [wavesNum, repeatsNum] = size(warmUpData{stimPattern}.measuredSPD);
    
    totalTimeBins = (numel(warmUpData)-1)*repeatsNum;
    times = zeros(1, totalTimeBins);
    amplitudes = zeros(wavesNum, totalTimeBins);
    
   
    spectralPeaks = [422 468 516 564 608 654 700 746];
    stimPatternOrder = 1:numel(warmUpData)-1;
    stimPatternOrder = [1 2 2+5 2+3 2+6 2+4 2+2 2+7 2+1];
    stimPatternOrder = [1 2  2+3 2+6 2+4 2+2 2+7 ];
    
    warmUpDataTmp = warmUpData;
    warmUpData = {};
    warmUpData{1} = warmUpDataTmp{1+1};
    warmUpData{2} = warmUpDataTmp{2+1};
    warmUpData{3} = warmUpDataTmp{7+1};
    warmUpData{4} = warmUpDataTmp{4+1};
    warmUpData{5} = warmUpDataTmp{6+1};
    warmUpData{6} = warmUpDataTmp{3+1};
    warmUpData{7} = warmUpDataTmp{5+1};
      
    spdGain = 1000;
    for stimPattern = 1:numel(warmUpData)
        warmUpData{stimPattern}.measuredSPD = warmUpData{stimPattern}.measuredSPD * spdGain;
    end
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
           'rowsNum', numel(warmUpData), ...
           'colsNum', 5, ...
           'heightMargin',   0.005, ...
           'widthMargin',    0.03, ...
           'leftMargin',     0.002, ...
           'rightMargin',    0.000, ...
           'bottomMargin',   0.05, ...
           'topMargin',      0.00);
       
    videoFilename = 'all2.m4v';
    writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
    writerObj.FrameRate = 15; 
    writerObj.Quality = 100;
    writerObj.open();
    
    hFig = figure(100); clf; 
    set(hFig, 'Position', [1 100 1200 950], 'Color', [1 1 1], 'MenuBar', 'none');
    
    
    wavelengthAxisRange = [440 680];
    indices = find(wavelengthAxis>wavelengthAxisRange(1) & wavelengthAxis<wavelengthAxisRange(2));
    wavelengthAxis = wavelengthAxis(indices);

    
    for stimPattern = 1:numel(warmUpData)
        warmUpData{stimPattern}.measuredSPD = warmUpData{stimPattern}.measuredSPD(indices,:);
    end
    
    for bandIndex = 1:numel(wavelengthAxis)
        
        for stimPattern = 1:numel(stimPatternOrder)
            
            pos = subplotPosVectors(stimPattern,1).v;
            subplot('Position', [pos(1) pos(2) pos(3)*0.91 pos(4)]);
            bar(1:numel(warmUpData{stimPattern}.activation), warmUpData{stimPattern}.activation, 1, 'FaceColor', [0.2 0.2 0.2], 'EdgeColor', 'none');
            set(gca, 'XColor', [1 1 1], 'YColor', [1 1 1]);
            
            pos = subplotPosVectors(stimPattern,2).v;
            subplot('Position', [pos(1)-0.015 pos(2) 3.3*pos(3) pos(4)]);
            meanSPD = squeeze(mean(warmUpData{stimPattern}.measuredSPD,2));
            stdSPD = squeeze(std(warmUpData{stimPattern}.measuredSPD,0,2));
            
            maxMeanSPD = max(meanSPD);
            if (stimPattern < 3)
                maxMeanSPD = max(meanSPD);
             else
                 maxMeanSPD = 4.5;
             end
          
            
            
            plot(wavelengthAxis, meanSPD, 'b-', 'LineWidth', 2.0);
            hold on
            plot(wavelengthAxis, 100*stdSPD, 'r-', 'LineWidth', 2.0);
            plot(wavelengthAxis, 10*bsxfun(@minus, warmUpData{stimPattern}.measuredSPD, meanSPD), 'k-', 'Color', [0.6 0.6 0.6], 'LineWidth', 1.0);
%             plot(wavelengthAxis, T_melanopsin/max(T_melanopsin)*maxMeanSPD, 'b-', 'LineWidth', 2.0);
%             plot(wavelengthAxis, T_cones(1,:)/max(T_cones(1,:))*maxMeanSPD, 'r-', 'Color', [1.0, 0.4 0.6], 'LineWidth', 2.0);
%             plot(wavelengthAxis, T_cones(2,:)/max(T_cones(2,:))*maxMeanSPD, 'r-', 'Color', [0.4, 1.0 0.6], 'LineWidth', 2.0);
%             plot(wavelengthAxis, T_cones(3,:)/max(T_cones(3,:))*maxMeanSPD, 'r-', 'Color', [0.4, 0.3 1.0], 'LineWidth', 2.0);
            
            plot(wavelengthAxis(bandIndex)*[1 1], [0 maxMeanSPD*0.85], 'k-', 'LineWidth', 1.5);
            plot(wavelengthAxis(bandIndex), meanSPD(bandIndex), 'ko', 'MarkerSize', 12, 'MarkerFaceColor', [0.8 0.8 1.0]);
            text(wavelengthAxis(bandIndex)-5, maxMeanSPD*0.95, sprintf('%dnm', wavelengthAxis(bandIndex)), 'FontSize', 16, 'Color', [0.2 0.2 0.2]);
            
            hL = legend({'mean', '100*std'});
            set(hL, 'FontSize', 16, 'FontName', 'Menlo', 'EdgeColor', 'none', 'Color', 'none');
            

            hold off;
            set(gca, 'LineWidth', 2.0, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)], 'YLim', maxMeanSPD*[-0.1 1], 'XTick', (300:50:900), 'XTick', spectralPeaks, 'FontSize', 16);
            if (stimPattern == 4)
                ylabel('power (mWatts)', 'FontSize', 20, 'FontWeight', 'bold');
            end
            if (stimPattern == numel(warmUpData))
                xlabel('wavelength (nm)', 'FontSize', 20, 'FontWeight', 'bold'); 
            else
                set(gca, 'XTickLabel', {});
                if (stimPattern ~= 1)
                    set(gca, 'YTickLabel', {});
                end
            end
            box off; grid off;
            
            subplot('Position', subplotPosVectors(stimPattern,5).v);
            bandTraceAcrossTime = squeeze(warmUpData{stimPattern}.measuredSPD(bandIndex,:));
            plot(warmUpData{stimPattern}.measurementTime, (bandTraceAcrossTime-mean(bandTraceAcrossTime)), 'b-', 'LineWidth', 2.0);
            hold on
            plot(warmUpData{stimPattern}.measurementTime, 0*(bandTraceAcrossTime-mean(bandTraceAcrossTime)), 'k-', 'LineWidth', 1.0);
            hold off;
            yTicks = [-0.1 :0.05: 0.1];
            set(gca, 'LineWidth', 2.0, 'YLim', 0.11*[-1 1], 'XLim', [0 max(warmUpData{1}.measurementTime)], 'XTick', (0:120:1000), 'YTick', yTicks, 'YTickLabel', sprintf('%0.2f\n', yTicks), 'FontSize', 16);
            
            if (stimPattern == 4)
                ylabel('diff power (mWatts)', 'FontSize', 20, 'FontWeight', 'bold');
            end
            if (stimPattern == numel(warmUpData))
                xlabel('time (minutes)', 'FontSize', 20, 'FontWeight', 'bold'); 
            else
                set(gca, 'XTickLabel', {});
                set(gca, 'YTickLabel', {});
            end
            box off; grid off;
            
        end
        
        drawnow;
        writerObj.writeVideo(getframe(hFig)); 
    end

    writerObj.close();
    
end


function makeVideo(wavelengthAxis, wavelengthRange, predictedResiduals, measuredResiduals, measuredResidualsTimes,  hFig, writerObj)

    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
           'rowsNum', 1, ...
           'colsNum', 1, ...
           'heightMargin',   0.00, ...
           'widthMargin',    0.04, ...
           'leftMargin',     0.05, ...
           'rightMargin',    0.000, ...
           'bottomMargin',   0.05, ...
           'topMargin',      0.01);
       
    colors = jet(9);
    spdGain = 1000;
    for repeatIndex = 1:size(measuredResiduals,3)
        for stimPattern = 1:8
            row = 1;
            subplot('Position', subplotPosVectors(1,1).v);
            
            if (stimPattern == 1)
                theColor = [1.0 0.2 0.2 1.0];
                plot(wavelengthAxis, spdGain*squeeze(predictedResiduals(stimPattern,:,:)), 'k-',  'Color', [0.6 0.6 0.6], 'LineWidth', 1.0); hold on;
            else
                theColor = squeeze(colors(stimPattern,:));
            end
            plot(wavelengthAxis, spdGain*squeeze(measuredResiduals(stimPattern,:,repeatIndex)), 'k-', 'LineWidth', 5);
            plot(wavelengthAxis, spdGain*squeeze(measuredResiduals(stimPattern,:,repeatIndex)), '-', 'LineWidth', 3, 'Color', theColor);
            if (stimPattern == 8)
                hold off;
            end
            
            set(gca, 'YLim', 0.1*[-1 1], 'XLim', wavelengthRange, 'FontSize', 14, 'XTick', [300:50:1000], 'FontSize', 14);
            ylabel('power (mWatts)', 'FontSize', 16, 'FontWeight', 'bold');
            xlabel('wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold'); 
            
            box off; grid on
            text(400, 0.099,  sprintf('predicted'), 'Color', [0.7 0.7 0.7], 'FontName', 'Menlo', 'FontSize', 16, 'BackgroundColor', [0.25 0.25 0.25]);
            ycoord = 0.099 - (stimPattern)*0.006;
            text(400, ycoord, sprintf('measured (trial %d, t: %02.2f min)', repeatIndex, measuredResidualsTimes(stimPattern,repeatIndex)), 'Color', theColor.^0.5, 'FontName', 'Menlo', 'FontSize', 16, 'BackgroundColor', [0.25 0.25 0.25]);
            
        end
        drawnow;
        writerObj.writeVideo(getframe(hFig)); 
    end
    
end



function parseCombFunctionDataOLD(warmUpData, wavelengthAxis)
   
    [warmUpData, warmUpDataUncorrected] = correctForLinearDrift(warmUpData, wavelengthAxis);
    [warmUpData, warmUpDataUncorrected] = subtractDarkSPD(warmUpData, warmUpDataUncorrected);
    
    meanFullOn = mean(warmUpData{2}.measuredSPD,2);
    meanComb   = mean(warmUpData{3}.measuredSPD,2);
    combFilter = meanComb ./ meanFullOn;
    
    fullOnResiduals = bsxfun(@minus, warmUpData{2}.measuredSPD, meanFullOn);
    combResiduals   = bsxfun(@minus, warmUpData{3}.measuredSPD, meanComb);
    predictedCombResiduals = bsxfun(@times, fullOnResiduals, combFilter);
    
    videoFilename = 'all.m4v';
    writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
    writerObj.FrameRate = 15; 
    writerObj.Quality = 100;
    writerObj.open();
    makeVideo(wavelengthAxis, meanFullOn, meanComb, combFilter, fullOnResiduals, combResiduals, predictedCombResiduals, writerObj);
    
    for bandIndex = 1:7
        bandMeanSPD = mean(warmUpData{3+bandIndex}.measuredSPD,2);
        bandFilter = bandMeanSPD./ meanFullOn;
        bandResiduals  = bsxfun(@minus, warmUpData{3+bandIndex}.measuredSPD, bandMeanSPD);
        predictedBandResiduals = bsxfun(@times, fullOnResiduals, bandFilter);
        makeVideo(wavelengthAxis, meanFullOn, bandMeanSPD, bandFilter, fullOnResiduals, bandResiduals, predictedBandResiduals, writerObj);
    end
    
    writerObj.close();
end


function makeVideoOLD(wavelengthAxis, meanFullOn, meanTestSPD, testFilter, fullOnResiduals, spdResiduals, predictedSpdResiduals, writerObj)
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
                   'rowsNum', 2, ...
                   'colsNum', 2, ...
                   'heightMargin',   0.05, ...
                   'widthMargin',    0.05, ...
                   'leftMargin',     0.03, ...
                   'rightMargin',    0.000, ...
                   'bottomMargin',   0.04, ...
                   'topMargin',      0.01);
               
    close all;
    hFig = figure(1); clf;
    wavelengthRange = [400 750];
    set(hFig, 'Color', [1 1 1], 'Position', [1 1 1819 1288]);
    
    subplot('Position', subplotPosVectors(1,1).v);
    plot(wavelengthAxis, 1000*meanFullOn, 'r-', 'LineWidth', 2.0);
    hold on;
    plot(wavelengthAxis, 1000*meanTestSPD, 'b-', 'LineWidth', 2.0);
    set(gca, 'XLim', wavelengthRange, 'FontSize', 12);
    box off; grid on
    title('fullON SPD, test SPD','FontSize', 16);
    
    subplot('Position', subplotPosVectors(1,2).v);
    plot(wavelengthAxis, 1000*fullOnResiduals, 'k-', 'LineWidth', 1.0, 'Color', [0.5 0.5 0.5]);
    set(gca, 'YLim', 0.3*[-1 1], 'XLim', wavelengthRange, 'FontSize', 12);
    box off; grid on
    title('full ON residuals', 'FontSize', 16);
    
    subplot('Position', subplotPosVectors(2,1).v);
    plot(wavelengthAxis, testFilter, 'k-', 'LineWidth', 2.0);
    set(gca, 'XLim', wavelengthRange, 'FontSize', 12);
    box off; grid on
    title('test filter', 'FontSize', 16);
    

        
    subplot('Position', subplotPosVectors(2,2).v);
    for repeatIndex = 1:size(spdResiduals,2)
        plot(wavelengthAxis, 1000*predictedSpdResiduals , 'k-',  'Color', [0.5 0.5 0.5], 'LineWidth', 1.0); hold on;
        plot(wavelengthAxis, 1000*spdResiduals(:,repeatIndex), 'r-', 'LineWidth', 3, 'Color', [1.0 0.0 0.0 0.9]);
        set(gca, 'YLim', 0.3*[-1 1], 'XLim', wavelengthRange, 'FontSize', 12);
        hold off
        box off; grid on
        title('test residuals', 'FontSize', 16);
        text(410, 0.25, sprintf('measured (trial %d)', repeatIndex), 'Color', [1 0 0], 'FontName', 'Menlo', 'FontSize', 16);
        text(410, 0.22, sprintf('predicted'), 'Color', [0.5 0.5 0.5], 'FontName', 'Menlo', 'FontSize', 16);
        drawnow;
        writerObj.writeVideo(getframe(hFig));
    end



end


%     
%     pause
%     
%     stimPattern = 1;
%     darkSPD = mean(warmUpData{stimPattern}.measuredSPD,2);
%     
%     for stimPattern = 2:numel(warmUpData)
%         figure(stimPattern); clf;
%         
%         subplot(1,3,1);
%         bar(warmUpData{stimPattern}.activation);
%         
%         % Subtract darkSPD
%         warmUpData{stimPattern}.measuredSPD = bsxfun(@minus, warmUpData{stimPattern}.measuredSPD, darkSPD);
%         
%         % Compute meanSPD
%         meanSPD = mean(warmUpData{stimPattern}.measuredSPD,2);
%         
%         % Compute residualSPD
%         residualSPD = bsxfun(@minus, warmUpData{stimPattern}.measuredSPD, meanSPD);
%         
%         if (stimPattern == 2)
%             fullOnData = spdGain * residualSPD;
%         elseif (stimPattern == 3)
%             combData = spdGain * residualSPD;
%         else
%             combComponentData(stimPattern-3,:,:) = spdGain * residualSPD;
%         end
%         
%         subplot(1,3,2);
%         plot(wavelengthAxis, spdGain * residualSPD, 'k-');
%         
%         subplot(1,3,3);
%         plot(wavelengthAxis, spdGain * residualSPD, 'k-');
%     end
%     
% end



function [warmUpData, warmUpDataUncorrected] = correctForLinearDrift(warmUpDataUncorrected, wavelengthAxis)

    warmUpData = warmUpDataUncorrected;
    % Let's correct based on the FullON patterns
    
    stimPattern = 2;
    size(warmUpData{stimPattern}.measuredSPD)
    size(warmUpData{stimPattern}.measurementTime)
    
    s0 = warmUpData{stimPattern}.measuredSPD(:,1);
    t0 = warmUpData{stimPattern}.measurementTime(1);
    
    s1 = warmUpData{stimPattern}.measuredSPD(:,end);
    t1 = warmUpData{stimPattern}.measurementTime(end);
    
    indices = find( ...
            (s1 > max(s1)*0.2) & ...
            ((wavelengthAxis >= 420) & (wavelengthAxis <= 700)) ...
        );
    s0 = s0(indices);
    s1 = s1(indices);
    dt1 = t1-t0;
    s = s0 \ s1;
    scalingFactor = @(t) 1./((1-(1-s)*((t-t0)./dt1)));
    
    for stimPattern = 1:numel(warmUpData)
        warmUpDataUncorrected{stimPattern}.measuredSPD = warmUpDataUncorrected{stimPattern}.measuredSPD;
        for repeatIndex = 1:size(warmUpData{stimPattern}.measuredSPD,2)
            t = warmUpDataUncorrected{stimPattern}.measurementTime(repeatIndex);
            warmUpData{stimPattern}.measuredSPD(:, repeatIndex) = squeeze(warmUpDataUncorrected{stimPattern}.measuredSPD(:, repeatIndex)) * scalingFactor(t);
        end
        warmUpData{stimPattern}.measurementTime = (warmUpDataUncorrected{stimPattern}.measurementTime - warmUpDataUncorrected{stimPattern}.measurementTime(1))/60;
        warmUpDataUncorrected{stimPattern}.measurementTime = warmUpData{stimPattern}.measurementTime;
    end
end


function warmUpData = subtractDarkSPD(warmUpData)
    % Compute dark SPD
    darkSPD = mean(warmUpData{1}.measuredSPD,2);
    
    % subtract dark SPD
    for stimPattern = 2: numel(warmUpData)
        warmUpData{stimPattern}.measuredSPD = bsxfun(@minus, warmUpData{stimPattern}.measuredSPD, darkSPD);
    end
end


function warmUpData = correctForLinearDriftOLD(warmUpDataUncorrected, wavelengthAxis)

    warmUpData = warmUpDataUncorrected;
    % Let's correct based on the FullON patterns
    
    stimPattern = 2;
    size(warmUpData{stimPattern}.measuredSPD)
    size(warmUpData{stimPattern}.measurementTime)
    
    s0 = warmUpData{stimPattern}.measuredSPD(:,1);
    t0 = warmUpData{stimPattern}.measurementTime(1);
    
    s1 = warmUpData{stimPattern}.measuredSPD(:,end);
    t1 = warmUpData{stimPattern}.measurementTime(end);
    
    indices = find( ...
            (s1 > max(s1)*0.2) & ...
            ((wavelengthAxis >= 420) & (wavelengthAxis <= 700)) ...
        );
    
    s0 = s0(indices);
    s1 = s1(indices);
    dt1 = t1-t0;
    s = s0 \ s1;
    scalingFactor = @(t) 1./((1-(1-s)*((t-t0)./dt1)));
    
    spdGain = 1000;
    for stimPattern = 1:numel(warmUpData)
        warmUpDataUncorrected{stimPattern}.measuredSPD = spdGain * warmUpDataUncorrected{stimPattern}.measuredSPD;
        for repeatIndex = 1:size(warmUpData{stimPattern}.measuredSPD,2)
            t = warmUpDataUncorrected{stimPattern}.measurementTime(repeatIndex);
            warmUpData{stimPattern}.measuredSPD(:, repeatIndex) = squeeze(warmUpDataUncorrected{stimPattern}.measuredSPD(:, repeatIndex)) * scalingFactor(t);
        end
        warmUpData{stimPattern}.measurementTime = (warmUpDataUncorrected{stimPattern}.measurementTime - warmUpDataUncorrected{stimPattern}.measurementTime(1))/60;
        warmUpDataUncorrected{stimPattern}.measurementTime = warmUpData{stimPattern}.measurementTime;
    end
    
    % Compute dark SPD
    darkSPD = mean(warmUpData{1}.measuredSPD,2);
    
    % subtract dark SPD
    for stimPattern = 2: numel(warmUpDataUncorrected)
        warmUpData{stimPattern}.measuredSPD = bsxfun(@minus, warmUpData{stimPattern}.measuredSPD, darkSPD);
        warmUpDataUncorrected{stimPattern}.measuredSPD = bsxfun(@minus, warmUpDataUncorrected{stimPattern}.measuredSPD, darkSPD);
    end
    
    referenceFullOn = mean(warmUpData{2}.measuredSPD,2);
    %referenceFullOn = squeeze(warmUpData{2}.measuredSPD(:,1));
    spectroTemporalResponseFullOnDiff = bsxfun(@minus, warmUpData{2}.measuredSPD, referenceFullOn);
    for stimPattern = 6:6 % 2: numel(warmUpDataUncorrected)
        figNo = 1000+stimPattern;
        plotData(figNo, warmUpDataUncorrected{stimPattern}.activation, warmUpDataUncorrected{stimPattern}.measurementTime, wavelengthAxis, warmUpDataUncorrected{stimPattern}.measuredSPD, warmUpData{stimPattern}.measuredSPD, spectroTemporalResponseFullOnDiff, 'power (mWatts)', sprintf('CombFunctionAnalysis_Stim%d', stimPattern));
    end

end


function plotData(figNo, activation, timeAxisInMinutes, wavelengthAxis, spectroTemporalResponseUncorrected, spectroTemporalResponse, spectroTemporalResponseFullOnDiff, yLabelString, titleString)
    
    colors = jet(size(spectroTemporalResponse,1)).^0.6;
    wavelengthRange = [450 720];
    
    hFig = figure(figNo); clf; set(hFig, 'Position', [1 1 1960 1180], 'Color', [1 1 1]);
    set(hFig, 'MenuBar', 'none');
    timeRange = [timeAxisInMinutes(1) timeAxisInMinutes(end)];

    subplot('Position', [0.025 0.89 0.31 0.10]);
    bar(1:numel(activation), activation, 1, 'FaceColor', [0.6 0.6 0.6], 'LineWidth', 1.5);
    set(gca, 'XTick', [], 'YTick', [], 'XColor', [1 1 1], 'YColor', [1 1 1]);
    box off;
    

    
    subplot('Position', [0.025 0.03 0.30 0.45]);
    hold on;
    for kBand = 1:size(spectroTemporalResponse,1)
        bar(wavelengthAxis(kBand), mean(squeeze(spectroTemporalResponse(kBand,:))), 2, 'FaceColor', squeeze(colors(kBand,:)), 'EdgeColor', 'none', 'LineWidth', 1.0);
    end
    plot(wavelengthAxis, spectroTemporalResponse, 'k-');
    [~,idx] = max(mean(spectroTemporalResponse,2));
    wavelengthOfMaxResponse = wavelengthAxis(idx);
    plot(wavelengthOfMaxResponse*[1 1], [0 max(spectroTemporalResponse(:))], 'k--', 'LineWidth', 1.5);
    set(gca, 'XColor', [1 1 1], 'XLim', wavelengthRange, 'YLim', [0 max(spectroTemporalResponse(:))], 'FontSize', 14);
    ylabel(yLabelString, 'FontSize', 16, 'FontWeight', 'bold');
    box off;
    
    
    % Open video stream

        videoFilename = sprintf('%s.m4v', titleString);
        writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
        writerObj.FrameRate = 15; 
        writerObj.Quality = 100;
        writerObj.open();
        
    for repeatIndex = 1:size(spectroTemporalResponse,2)
        
        subplot('Position', [0.35 0.53 0.645 0.445]);
        for kBand = 1:size(spectroTemporalResponse,1)
            plot(timeAxisInMinutes(1:repeatIndex), squeeze(spectroTemporalResponseUncorrected(kBand,1:repeatIndex)), 'ko-', 'MarkerSize', 8, 'MarkerFaceColor', squeeze(colors(kBand,:)), 'LineWidth', 1.0);
            if (kBand == 1)
                hold on;
            end
        end
        hold off;
        set(gca, 'YLim', [0 max(spectroTemporalResponse(:))], 'XLim', timeRange, 'XTickLabel', {});
        set(gca, 'FontSize', 14);
        ylabel(yLabelString, 'FontSize', 16, 'FontWeight', 'bold');
        title('linear-drift uncorrected', 'FontSize', 16);
        box on;
        grid on

        subplot('Position', [0.35 0.03 0.645 0.445]);
        for kBand = 1:size(spectroTemporalResponse,1)
            plot(timeAxisInMinutes(1:repeatIndex), squeeze(spectroTemporalResponse(kBand,1:repeatIndex)), 'ko-', 'MarkerSize', 8, 'MarkerFaceColor', squeeze(colors(kBand,:)), 'LineWidth', 1.0);
            if (kBand == 1)
                hold on;
            end
        end
        hold off;
        set(gca, 'YLim', [0 max(spectroTemporalResponse(:))], 'XLim', timeRange);
        set(gca, 'FontSize', 14);
        xlabel('time (minutes)', 'FontSize', 16, 'FontWeight', 'bold');
        ylabel(yLabelString, 'FontSize', 16, 'FontWeight', 'bold');
        title('linear drift corrected', 'FontSize', 16);
        box on;
        grid on
    
    
        
        subplot('Position', [0.025 0.50 0.30 0.38]);
        %filter = squeeze(spectroTemporalResponse(:,repeatIndex));
        filter = mean(spectroTemporalResponse,2);
        filter = filter/max(filter);
        prediction = bsxfun(@times, spectroTemporalResponseFullOnDiff, filter);
        plot(wavelengthAxis, prediction, 'k-', 'Color', [0.4 0.4 0.4]);
        hold on
        plot(wavelengthAxis, filter*0.2, 'k-', 'Color', [0 0 0], 'LineWidth', 2.0);
        
        trial1Color = [0 0.7 1];
        trialNColor = [0.3 1.0 0.2];
        meanTrialColor = [01.0 0.3 0.5];
        diffSPD = bsxfun(@minus, spectroTemporalResponse(:,repeatIndex), squeeze(spectroTemporalResponse(:, 1)));
        plot(wavelengthAxis, bsxfun(@times, diffSPD, filter), 'k-',  'LineWidth', 5.0);
        plot(wavelengthAxis, bsxfun(@times, diffSPD, filter), '-', 'Color',trial1Color,  'LineWidth', 3.0);
        
        otherTrialNo = round(size(spectroTemporalResponse,2)/2);
        diffSPD = bsxfun(@minus, spectroTemporalResponse(:,repeatIndex), squeeze(spectroTemporalResponse(:, otherTrialNo)));
        plot(wavelengthAxis, bsxfun(@times, diffSPD, filter), 'k-',  'LineWidth', 5.0);
        plot(wavelengthAxis, bsxfun(@times, diffSPD, filter), '-', 'Color', trialNColor, 'LineWidth', 3.0);
        
        diffSPD = bsxfun(@minus, spectroTemporalResponse(:,repeatIndex), mean(spectroTemporalResponse,2));
        plot(wavelengthAxis,  bsxfun(@times, diffSPD, filter), 'k-',  'LineWidth', 5.0);
        plot(wavelengthAxis,  bsxfun(@times, diffSPD, filter), '-', 'Color', meanTrialColor, 'LineWidth', 3.0);
        
        plot(wavelengthOfMaxResponse*[1 1], 0.25*[-1 1], 'k--', 'LineWidth', 1.5);
        hold off
        set(gca, 'YLim', 0.25*[-1 1], 'XLim', wavelengthRange, 'XColor', [1 1 1], 'FontSize', 14);
        ylabel(yLabelString, 'FontSize', 16, 'FontWeight', 'bold');
        text(wavelengthRange(1)+25, -0.286, 'filter', 'Color', [0 0 0], 'FontName', 'Menlo', 'FontSize', 12);
        text(wavelengthRange(1)+25, -0.264, 'predicted residuals (filter x fullONresiduals)', 'Color', [0.6 0.6 0.6], 'FontName', 'Menlo', 'FontSize', 12, 'BackgroundColor', [1 1 1]);
        text(wavelengthRange(1)+25, -0.242, 'measured residual (current trial - trial #1)', 'Color', trial1Color , 'FontName', 'Menlo', 'FontSize', 12, 'BackgroundColor', [1 1 1]);
        text(wavelengthRange(1)+25, -0.22, sprintf('measured residual (current trial - trial #%d)', otherTrialNo), 'Color', trialNColor, 'FontName', 'Menlo', 'FontSize', 12, 'BackgroundColor', [1 1 1]);
        text(wavelengthRange(1)+25, -0.198,  'measured residual (current trial - mean trial)', 'Color', meanTrialColor , 'FontName', 'Menlo', 'FontSize', 12, 'BackgroundColor', [1 1 1]);
        box off;
        
        drawnow;
        writerObj.writeVideo(getframe(hFig));
    end
    writerObj.close();
    
    NicePlot.exportFigToPNG(sprintf('%s.png', titleString), hFig, 300);
end
