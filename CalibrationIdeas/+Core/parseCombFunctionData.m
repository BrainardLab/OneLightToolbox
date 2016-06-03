function parseCombFunctionData(warmUpData, wavelengthAxis)
   
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
    wavelengthRange = [380 720];
    set(hFig, 'Color', [1 1 1], 'Position', [1 1 1760 1160]);
    makeVideo(wavelengthAxis, wavelengthRange, predictedResiduals, measuredResiduals, measuredResidualsTimes, hFig, writerObj);
    writerObj.close();
end


function plotTimeCourseOfAllWavelengths(wavelengthAxis, warmUpData)
    
    stimPattern = 1;
    [wavesNum, repeatsNum] = size(warmUpData{stimPattern}.measuredSPD);
    
    totalTimeBins = (numel(warmUpData)-1)*repeatsNum;
    times = zeros(1, totalTimeBins);
    amplitudes = zeros(wavesNum, totalTimeBins);
    
    
    indices = find((wavelengthAxis > 400) & (wavelengthAxis < 750));
    wavelengthAxis = wavelengthAxis(indices);
    
    stimPatternOrder = 1:numel(warmUpData)-1;
    stimPatternOrder = [1 2 2+5 2+3 2+6 2+4 2+2 2+7 2+1];
    
    spdGain = 1000;
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
           'rowsNum', numel(stimPatternOrder), ...
           'colsNum', 3, ...
           'heightMargin',   0.03, ...
           'widthMargin',    0.04, ...
           'leftMargin',     0.05, ...
           'rightMargin',    0.000, ...
           'bottomMargin',   0.03, ...
           'topMargin',      0.01);
       
    for bandIndex = 1:numel(wavelengthAxis)
        hFig = figure(100); clf; 
        set(hFig, 'Position', [1 1 1420 1290], 'Color', [1 1 1]);
        for stimPattern = 1:numel(warmUpData)-1
            
            subplot('Position', subplotPosVectors(stimPatternOrder(stimPattern),1).v);
            bar(1:numel(warmUpData{stimPattern+1}.activation), warmUpData{stimPattern+1}.activation, 1);
            set(gca, 'XColor', [1 1 1], 'YColor', [1 1 1]);
            
            subplot('Position', subplotPosVectors(stimPatternOrder(stimPattern),2).v);
            meanSPD = spdGain * squeeze(mean(warmUpData{stimPattern+1}.measuredSPD(indices,:),2));
            if (stimPattern < 3)
                maxMeanSPD = max(meanSPD);
            else
                maxMeanSPD = 4.5;
            end
          
            plot(wavelengthAxis, meanSPD, 'b-', 'LineWidth', 2.0);
            hold on;
            plot(wavelengthAxis(bandIndex)*[1 1], [0 maxMeanSPD], 'k-', 'LineWidth', 1.5);
            plot(wavelengthAxis(bandIndex), meanSPD(bandIndex), 'ro', 'MarkerSize', 12, 'MarkerFaceColor', [1.0 0.5 0.5]);
            hold off;
            set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)], 'YLim', [0 maxMeanSPD], 'XTick', (300:50:900));
            if (stimPattern == 4)
                ylabel('power (mWatts)');
            end
            if (stimPatternOrder(stimPattern) == numel(warmUpData)-1)
                xlabel('wavelength (nm)'); 
            else
                set(gca, 'XTickLabel', {});
            end
            box off; grid on;
            
            subplot('Position', subplotPosVectors(stimPatternOrder(stimPattern),3).v);
            bandTraceAcrossTime = squeeze(warmUpData{stimPattern+1}.measuredSPD(bandIndex,:));
            plot(warmUpData{stimPattern+1}.measurementTime, spdGain*(bandTraceAcrossTime-mean(bandTraceAcrossTime)), 'r-', 'LineWidth', 2.0);
            hold on
            plot(warmUpData{stimPattern+1}.measurementTime, 0*(bandTraceAcrossTime-mean(bandTraceAcrossTime)), 'k-', 'LineWidth', 1.0);
            hold off;
            
            set(gca, 'YLim', 0.1*[-1 1], 'XLim', [0 max(warmUpData{1}.measurementTime)], 'YTick', [-0.1 0 0.1]);
            
            if (stimPattern == 1)
                title(sprintf('%d nm', wavelengthAxis(bandIndex)));
            end
            if (stimPattern == 4)
                ylabel('amplitude - meanAcrossTime(amplitude)');
            end
            if (stimPatternOrder(stimPattern) == numel(warmUpData)-1)
                xlabel('time (minutes)'); 
            end
            box off; grid on;
            
        end
        
        drawnow;
    end

    
    
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
    for repeatIndex = 1:size(measuredResiduals,3)
        for stimPattern = 1:8
            row = 1;
            if (stimPattern == 1)
                col = 1;
                theColor = [1.0 0.2 0.2 1.0];
            else
                theColor = squeeze(colors(stimPattern,:));
                col = 1;
            end
            subplot('Position', subplotPosVectors(row,col).v);
            
            plot(wavelengthAxis, 1000*squeeze(predictedResiduals(stimPattern,:,:)), 'k-',  'Color', [0.6 0.6 0.6], 'LineWidth', 1.0); hold on;
            plot(wavelengthAxis, 1000*squeeze(measuredResiduals(stimPattern,:,repeatIndex)), 'k-', 'LineWidth', 5);
            plot(wavelengthAxis, 1000*squeeze(measuredResiduals(stimPattern,:,repeatIndex)), '-', 'LineWidth', 3, 'Color', theColor);
            
            if (stimPattern == 8)
                hold off;
            end
            
            set(gca, 'YLim', 0.1*[-1 1], 'XLim', wavelengthRange, 'FontSize', 14, 'XTick', [300:50:1000], 'FontSize', 14);
            ylabel('power (mWatts)', 'FontSize', 16, 'FontWeight', 'bold');
            xlabel('wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold'); 
            
            box off; grid on
            text(385, 0.096,  sprintf('predicted'), 'Color', [0.7 0.7 0.7], 'FontName', 'Menlo', 'FontSize', 16, 'BackgroundColor', [0.25 0.25 0.25]);
            ycoord = 0.096 - (stimPattern)*0.004;
            text(385, ycoord, sprintf('measured (trial %d, time: %02.2f minutes)', repeatIndex, measuredResidualsTimes(stimPattern,repeatIndex)), 'Color', theColor.^0.5, 'FontName', 'Menlo', 'FontSize', 16, 'BackgroundColor', [0.25 0.25 0.25]);
            
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
