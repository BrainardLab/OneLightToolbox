function parseWiggly2Data(data, nRepeats, wavelengthAxis)
    
    nSpectraMeasured = numel(data);
    repeatColors = jet(nRepeats);
    
    for spectrumIndex = 1:nSpectraMeasured
        if (strcmp(data{spectrumIndex}.spdType, 'dark'))
            darkSPD = mean(data{spectrumIndex}.measuredSPD, 2);
        end
    end
    
    % subtract darkSPD from all SPDs
    for spectrumIndex = 1:nSpectraMeasured
        
        if (~strcmp(data{spectrumIndex}.spdType, 'dark'))
            % subtract darkSPD from all SPDs
            data{spectrumIndex}.measuredSPD = bsxfun(@minus, data{spectrumIndex}.measuredSPD, darkSPD);
        end
        
        % average over all reps
        data{spectrumIndex}.meanSPD = mean(data{spectrumIndex}.measuredSPD, 2);

        % stderrors over all reps
        data{spectrumIndex}.stdSPD = std(data{spectrumIndex}.measuredSPD, 0, 2);
        
        % compute min over all reps
        data{spectrumIndex}.minSPD  = min(data{spectrumIndex}.measuredSPD, [], 2);
        
        % compute max over all reps
        data{spectrumIndex}.maxSPD  = max(data{spectrumIndex}.measuredSPD, [], 2); 
    end
    
    
    % Compute predictions
    figure(1); clf
    for spectrumIndex = 1:nSpectraMeasured
        % average over all reps
        subplot(6,4, spectrumIndex);
        bar(1:56, data{spectrumIndex}.activation);
        set(gca, 'XLim', [0 57], 'YLim', [0 1]);
        title(sprintf('%d\n', spectrumIndex));
        drawnow;
    end
    
   steadyBandsSpectrumIndex = 4;
   steadyBandsSpectrum = data{steadyBandsSpectrumIndex}.meanSPD;
   combo1SpectrumIndex = 16;
   combo1Component1SpectrumIndex = 6;
   combo1Component2SpectrumIndex = 12;
   combo{1}.SpectrumPrediction = data{combo1Component1SpectrumIndex}.meanSPD + data{combo1Component2SpectrumIndex}.meanSPD - data{steadyBandsSpectrumIndex}.meanSPD;
   combo{1}.SpectrumPredictionStDev = max([data{combo1Component1SpectrumIndex}.stdSPD'; data{combo1Component2SpectrumIndex}.stdSPD'; data{steadyBandsSpectrumIndex}.stdSPD'], [], 1);
   combo{1}.Spectrum = data{combo1SpectrumIndex}.meanSPD;
   combo{1}.SpectrumStDev = data{combo1SpectrumIndex}.stdSPD;
   combo{1}.Activation = data{combo1SpectrumIndex}.activation;
   
   combo2SpectrumIndex = 14;
   combo2Component1SpectrumIndex = 8;
   combo2Component2SpectrumIndex = 10;
   combo{2}.SpectrumPrediction = data{combo2Component1SpectrumIndex}.meanSPD + data{combo2Component2SpectrumIndex}.meanSPD - steadyBandsSpectrum;
   combo{2}.SpectrumPredictionStDev = max([data{combo2Component1SpectrumIndex}.stdSPD'; data{combo2Component2SpectrumIndex}.stdSPD'; data{steadyBandsSpectrumIndex}.stdSPD'], [], 1);
   combo{2}.Spectrum = data{combo2SpectrumIndex}.meanSPD;
   combo{2}.SpectrumStDev = data{combo2SpectrumIndex}.stdSPD;
   combo{2}.Activation = data{combo2SpectrumIndex}.activation;
   
   combo3SpectrumIndex = 15;
   combo3Component1SpectrumIndex = 5;
   combo3Component2SpectrumIndex = 11;
   combo{3}.SpectrumPrediction = data{combo3Component1SpectrumIndex}.meanSPD + data{combo3Component2SpectrumIndex}.meanSPD - steadyBandsSpectrum;
   combo{3}.SpectrumPredictionStDev = max([data{combo3Component1SpectrumIndex}.stdSPD'; data{combo3Component2SpectrumIndex}.stdSPD'; data{steadyBandsSpectrumIndex}.stdSPD'], [], 1);
   combo{3}.Spectrum = data{combo3SpectrumIndex}.meanSPD;
   combo{3}.SpectrumStDev = data{combo3SpectrumIndex}.stdSPD;
   combo{3}.Activation = data{combo3SpectrumIndex}.activation;
   
   combo4SpectrumIndex = 13;
   combo4Component1SpectrumIndex = 9;
   combo4Component2SpectrumIndex = 7;
   combo{4}.SpectrumPrediction = data{combo4Component1SpectrumIndex}.meanSPD + data{combo4Component2SpectrumIndex}.meanSPD - steadyBandsSpectrum;
   combo{4}.SpectrumPredictionStDev = max([data{combo4Component1SpectrumIndex}.stdSPD'; data{combo4Component2SpectrumIndex}.stdSPD'; data{steadyBandsSpectrumIndex}.stdSPD'], [], 1);
   combo{4}.Spectrum = data{combo4SpectrumIndex}.meanSPD;
   combo{4}.SpectrumStDev = data{combo4SpectrumIndex}.stdSPD;
   combo{4}.Activation = data{combo4SpectrumIndex}.activation;
   
  
   
   
   iter = 0;
   repeatsToUse = 10;
   for iter1 = 1:repeatsToUse
       iter1
   for iter2 = 1:repeatsToUse
   for iter3 = 1:repeatsToUse
   for iter4 = 1:repeatsToUse
            iter = iter + 1;
            combo{1}.SpectrumResiduals(:,iter) = data{combo1Component1SpectrumIndex}.measuredSPD(:, iter1) + data{combo1Component2SpectrumIndex}.measuredSPD(:, iter2) - data{steadyBandsSpectrumIndex}.measuredSPD(:, iter3) - data{combo1SpectrumIndex}.measuredSPD(:, iter4);
            combo{2}.SpectrumResiduals(:,iter) = data{combo2Component1SpectrumIndex}.measuredSPD(:, iter1) + data{combo2Component2SpectrumIndex}.measuredSPD(:, iter2) - data{steadyBandsSpectrumIndex}.measuredSPD(:, iter3) - data{combo2SpectrumIndex}.measuredSPD(:, iter4);
            combo{3}.SpectrumResiduals(:,iter) = data{combo3Component1SpectrumIndex}.measuredSPD(:, iter1) + data{combo3Component2SpectrumIndex}.measuredSPD(:, iter2) - data{steadyBandsSpectrumIndex}.measuredSPD(:, iter3) - data{combo3SpectrumIndex}.measuredSPD(:, iter4);
            combo{4}.SpectrumResiduals(:,iter) = data{combo4Component1SpectrumIndex}.measuredSPD(:, iter1) + data{combo4Component2SpectrumIndex}.measuredSPD(:, iter2) - data{steadyBandsSpectrumIndex}.measuredSPD(:, iter3) - data{combo4SpectrumIndex}.measuredSPD(:, iter4);
   end
   end
   end
   end
   
   
   spdGain = 1000;
   spectralPeaks = [422 468 516 564 608 654 700 746];
   
   rowsNum = 4;
   colsNum = 4;
   subplotPosVectors = NicePlot.getSubPlotPosVectors(...
                   'rowsNum', rowsNum, ...
                   'colsNum', colsNum, ...
                   'heightMargin',   0.05, ...
                   'widthMargin',    0.04, ...
                   'leftMargin',     0.01, ...
                   'rightMargin',    0.000, ...
                   'bottomMargin',   0.05, ...
                   'topMargin',      0.01);
               
   hFig = figure(2); clf; set(hFig, 'Position', [10 10 2210 1140], 'Color', [1 1 1]);
   for comboIndex = 1:numel(combo)
       
        subplot('Position', subplotPosVectors(comboIndex,1).v);
        bar(1:numel(combo{comboIndex}.Activation), combo{comboIndex}.Activation, 1, 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', [0 0 0], 'LineWidth', 2.0)
        set(gca, 'XLim', [0 numel(combo{comboIndex}.Activation)+1], 'YLim', [0 1.00], 'XTick', [], 'YTick', []);
        set(gca, 'FontSize', 14);
        box off;
        
        subplot('Position', subplotPosVectors(comboIndex,2).v);
        plot(wavelengthAxis, spdGain*combo{comboIndex}.Spectrum, 'r-', 'LineWidth', 2.0);
        hold on;
        plot(wavelengthAxis, spdGain*(100*combo{comboIndex}.SpectrumStDev), 'b-', 'LineWidth', 1.0);
        hL = legend({'mean', '100*st.dev.'}, 'Location', 'NorthEast');
        set(hL, 'FontSize', 14, 'FontName', 'Menlo');
        for k = 1:numel(spectralPeaks)
                plot(spectralPeaks(k)*[1 1], [-100 100], 'k-');
        end
        hold off
        set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)], 'YLim', [0 70], 'XTick', spectralPeaks);
        set(gca, 'FontSize', 14);
        title('measured SPD');
        
        subplot('Position', subplotPosVectors(comboIndex,3).v);
        plot(wavelengthAxis, spdGain*combo{comboIndex}.SpectrumPrediction, 'r-', 'LineWidth', 2.0);
        hold on;
        plot(wavelengthAxis, spdGain*(100*combo{comboIndex}.SpectrumPredictionStDev), 'b-', 'LineWidth', 1.0);
        hL = legend({'mean', '100*st.dev.'}, 'Location', 'NorthEast');
        set(hL, 'FontSize', 14, 'FontName', 'Menlo');
        for k = 1:numel(spectralPeaks)
                plot(spectralPeaks(k)*[1 1], [-100 100], 'k-');
        end
        hold off
        set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)], 'YLim', [0 70], 'XTick', spectralPeaks, 'YTickLabel', {});
        set(gca, 'FontSize', 14);
        title('predicted SPD');
        
        subplot('Position', subplotPosVectors(comboIndex,4).v);
        plot(wavelengthAxis, spdGain*combo{comboIndex}.SpectrumResiduals, 'k-', 'Color', [0.6 0.6 0.6]);
        hold on;
        plot(wavelengthAxis, spdGain*(combo{comboIndex}.SpectrumPrediction-combo{comboIndex}.Spectrum), 'r-', 'LineWidth', 2.0);
        
        for k = 1:numel(spectralPeaks)
                plot(spectralPeaks(k)*[1 1], [-100 100], 'k-');
        end
        hold off
        set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)], 'YLim', 0.5*[-1 1], 'YTick', (-0.5:0.1:0.5));
        set(gca, 'FontSize', 14);
        title('residual SPD', 'FontSize', 14);
        
        drawnow;
    end
    pause;
    
    
    

    rowsNum = 4;
    colsNum = 4;
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
                   'rowsNum', rowsNum, ...
                   'colsNum', colsNum, ...
                   'heightMargin',   0.05, ...
                   'widthMargin',    0.02, ...
                   'leftMargin',     0.04, ...
                   'rightMargin',    0.000, ...
                   'bottomMargin',   0.02, ...
                   'topMargin',      0.01);
               
    
          
    generateVideo = true;
        if (generateVideo)
            % Open video stream
            videoFilename = sprintf('VariabilityForAllSpectra.m4v');
            writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
            writerObj.FrameRate = 15; 
            writerObj.Quality = 100;
            writerObj.open();
        end
        
    hFig2 = figure(2001); clf; set(hFig2, 'Position', [1 1 768 600], 'Color', [1 1 1]);
    
    measurementTimes = [];
    allSPDratios = [];
        
    for spectrumIndex = 1:nSpectraMeasured
        
        hFig = figure(2000); clf; set(hFig, 'Position', [1 1 1900 1200], 'Color', [1 1 1], 'MenuBar', 'none', 'Toolbar', 'none');
        
        % average over all reps
        data{spectrumIndex}.meanSPD = mean(data{spectrumIndex}.measuredSPD, 2);

        % stderrors over all reps
        data{spectrumIndex}.stdSPD = std(data{spectrumIndex}.measuredSPD, 0, 2);
        
        % compute min over all reps
        data{spectrumIndex}.minSPD  = min(data{spectrumIndex}.measuredSPD, [], 2);
        
        % compute max over all reps
        data{spectrumIndex}.maxSPD  = max(data{spectrumIndex}.measuredSPD, [], 2);
        
        
        
        
        indices = find( ...
            data{spectrumIndex}.meanSPD > 0.10*max(data{spectrumIndex}.meanSPD) & ...
            ((wavelengthAxis >= 420) & (wavelengthAxis <= 700)) ...
        );
        
    
        figure(hFig);  
        
        referenceSPD = data{spectrumIndex}.meanSPD;
        referenceSPDtitle = 'SPD(ref) = mean over all iterations';
            
        %referenceSPD = squeeze(data{spectrumIndex}.measuredSPD(:,1));
        %referenceSPDtitle = 'SPD(ref) = first iteration';
            
        referenceSPD = squeeze(data{spectrumIndex}.measuredSPD(:,nRepeats));
        referenceSPDtitle = 'SPD(ref) = last iteration';
        
        maxSPDref = spdGain*(max(referenceSPD));
            
        for repeatIndex = 1:nRepeats
            
            theColor = [0 0 0];
            if  (~generateVideo)
               theColor = squeeze(repeatColors(repeatIndex,:)); 
            end
            
            SPDratios = data{spectrumIndex}.measuredSPD(indices,repeatIndex) ./ referenceSPD(indices);
            globalSPDratio(repeatIndex) = referenceSPD(indices) \ squeeze(data{spectrumIndex}.measuredSPD(indices,repeatIndex));
            globallyScaledTrialByTrialSPD(:,repeatIndex) = data{spectrumIndex}.measuredSPD(:,repeatIndex)/globalSPDratio(repeatIndex);
            globallyScaledTrialByTrialsSPDratios = globallyScaledTrialByTrialSPD(indices,repeatIndex) ./ referenceSPD(indices);
            
            maxSPDiter = max(squeeze(spdGain*(data{spectrumIndex}.measuredSPD(:,repeatIndex))));
            if (maxSPDiter < 1)
                maxSPDiter = 1;
            end
            ratioGain  = 1000.0 * maxSPDiter/50;
            
            subplot('Position', subplotPosVectors(1,1).v);
            incRatios = find(log(SPDratios) > 0);
            decRatios = find(log(SPDratios) <= 0);
            stem(spdGain * data{spectrumIndex}.meanSPD(indices(incRatios)), log(SPDratios(incRatios)), 'r.', 'MarkerFaceColor', [1.0 0.8 0.8], 'BaseValue', 0.0, 'LineWidth', 2.0);
            hold on
            stem(spdGain * data{spectrumIndex}.meanSPD(indices(decRatios)), log(SPDratios(decRatios)), 'b.', 'MarkerFaceColor', [0.8 0.8 1.0], 'BaseValue', 0.0, 'LineWidth', 2.0);
            plot(spdGain*[0 max(referenceSPD)], log(globalSPDratio(repeatIndex))*[1 1], 'k--', 'LineWidth', 2.0);
            hold off
            box off;
            logRatioIntervals = -0.03:0.01:0.03;
            hL = legend('ratios(lambda-by-lambda)', 'ratios(lambda-by-lambda)', 'full spectrum ratio');
            set(hL, 'FontName', 'Menlo');
            set(gca, 'XLim', [0 maxSPDiter], 'YLim', 0.03*[-1 1], 'YTick', logRatioIntervals, 'YTickLabel', sprintf('%2.3f\n', exp(logRatioIntervals)));
            set(gca, 'FontSize', 14);
            xlabel(' SPD amplitude (mWatts)', 'FontSize', 16, 'FontWeight', 'bold')
            ylabel('SPD(iter) / SPD(ref)', 'FontSize', 16, 'FontWeight', 'bold')

            
            subplot('Position', subplotPosVectors(1,2).v);
            plot([0 nRepeats+1], [0 0], 'k-');
            hold on;
            plot(1:repeatIndex, log(globalSPDratio(1:repeatIndex)), 'k-', 'Color', [0.4 0.4 0.4 0.4], 'LineWidth', 4.0);
            plot(1:repeatIndex, log(globalSPDratio(1:repeatIndex)), 'k--', 'LineWidth', 2.0);
            hold off;
            set(gca, 'YLim', 0.03*[-1 1], 'YTick', logRatioIntervals, 'YTickLabel', {});
            set(gca, 'XLim', [0 nRepeats+1], 'XTick', 0:10:100);
            set(gca, 'FontSize', 14);
            ylabel('full spectrum ratio', 'FontSize', 16, 'FontWeight', 'bold')
            xlabel('stimulus iteration', 'FontSize', 16, 'FontWeight', 'bold')
            box off
            
            pos = subplotPosVectors(2,1).v;
            subplot('Position', [pos(1) pos(2)-0.02 pos(3) pos(4)]);
            plot(wavelengthAxis, spdGain*(data{spectrumIndex}.measuredSPD(:,repeatIndex)), 'k-',  'LineWidth', 1.0);
            hold on;
            for dataPoint = 1:numel(indices)
                if (log(SPDratios(dataPoint)) > 0)
                    ratioColor = [1 0 0];
                else
                    ratioColor = [0 0 1];
                end
                plot(wavelengthAxis(indices(dataPoint))*[1 1], spdGain*(data{spectrumIndex}.measuredSPD(indices(dataPoint),repeatIndex)) + [0 ratioGain*log(SPDratios(dataPoint))], 'k-', 'Color', ratioColor, 'LineWidth', 2.0);
            end
            for k = 1:numel(spectralPeaks)
                plot(spectralPeaks(k)*[1 1], [-100 100], 'k-');
            end
            hold off
            set(gca, 'YLim', maxSPDiter*[0.0 1.1], 'XLim', [wavelengthAxis(1) wavelengthAxis(end)], 'XTick', [], 'XTickLabel', {});
            set(gca, 'FontSize', 14);
            ylabel('SPD amplitude (mWatts)', 'FontSize', 16, 'FontWeight', 'bold');
            grid off
            box off;

            
            
            
            pos = subplotPosVectors(2,2).v;
            subplot('Position', [pos(1) pos(2)-0.02 pos(3) pos(4)]);
            plot(wavelengthAxis, spdGain*squeeze(globallyScaledTrialByTrialSPD(:,repeatIndex)), 'k-', 'LineWidth', 1.0);
            hold on
            for dataPoint = 1:numel(indices)
                if (log(globallyScaledTrialByTrialsSPDratios(dataPoint)) > 0)
                    ratioColor = [1 0 0];
                else
                    ratioColor = [0 0 1];
                end
                plot(wavelengthAxis(indices(dataPoint))*[1 1], spdGain*(data{spectrumIndex}.measuredSPD(indices(dataPoint),repeatIndex)) + [0 ratioGain*log(globallyScaledTrialByTrialsSPDratios(dataPoint))], 'k-', 'Color', ratioColor, 'LineWidth', 2.0);
            end
            for k = 1:numel(spectralPeaks)
                plot(spectralPeaks(k)*[1 1], [-100 100], 'k-');
            end
            hold off
            set(gca, 'YLim', maxSPDiter*[0.0 1.1], 'XLim', [wavelengthAxis(1) wavelengthAxis(end)], 'XTick', [], 'XTickLabel', {}, 'YTickLabel', {});
            set(gca, 'FontSize', 14);
            grid off
            box off;
            
            
            
            
            % 
            pos = subplotPosVectors(3,1).v;
            subplot('Position', [pos(1) pos(2)+0.01 pos(3) pos(4)]);
            plot([wavelengthAxis(1) wavelengthAxis(end)], [0 0], 'k-');
            hold on;
            % plot previous reps in gray
            for iter = 1:repeatIndex-1
                plot(wavelengthAxis, spdGain*(squeeze(data{spectrumIndex}.measuredSPD(:,iter))-referenceSPD), 'k-', 'Color', [0.65 0.65 0.65], 'LineWidth', 1.0);
            end
            % plot current rep
            plot(wavelengthAxis, spdGain*(squeeze(data{spectrumIndex}.measuredSPD(:,repeatIndex))-referenceSPD), 'r-', 'Color', theColor, 'LineWidth', 2.0);
            % plot current mean rep
            plot(wavelengthAxis, spdGain*(mean(squeeze(data{spectrumIndex}.measuredSPD(:,1:repeatIndex)),2)-referenceSPD), 'g-', 'Color', [0 0.8 0.0], 'LineWidth', 3.0);
            
            for k = 1:numel(spectralPeaks)
                plot(spectralPeaks(k)*[1 1], [-100 100], 'k-');
            end
            hold off
            ylabel('SPD(iterm) - SPD(ref) (mWatts)', 'FontSize', 16, 'FontWeight', 'bold');
            xlabel('wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold');
            set(gca, 'YLim', 0.5*[-1 1], 'YTick', (-1:0.1:1.0), 'XLim', [wavelengthAxis(1) wavelengthAxis(end)], 'XTick', spectralPeaks);
            set(gca, 'FontSize', 14);
            grid off
            box off;
            
            
            % 
            pos = subplotPosVectors(3,2).v;
            subplot('Position', [pos(1) pos(2)+0.01 pos(3) pos(4)]);
            plot([wavelengthAxis(1) wavelengthAxis(end)], [0 0], 'k-');
            hold on;
            % plot previous reps in gray
            for iter = 1:repeatIndex-1
                plot(wavelengthAxis, spdGain*(squeeze(globallyScaledTrialByTrialSPD(:,iter))-referenceSPD), 'k-', 'Color', [0.65 0.65 0.65], 'LineWidth', 1.0);
            end
            % plot current rep
            plot(wavelengthAxis, spdGain*(squeeze(globallyScaledTrialByTrialSPD(:,repeatIndex))-referenceSPD), 'r-', 'Color', theColor, 'LineWidth', 2.0);
            for k = 1:numel(spectralPeaks)
                plot(spectralPeaks(k)*[1 1], [-100 100], 'k-');
            end
            hold off
            xlabel('wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold');
            set(gca, 'YLim', 0.5*[-1 1], 'YTick', (-1:0.1:1.0), 'XLim', [wavelengthAxis(1) wavelengthAxis(end)], 'XTick', spectralPeaks);
            set(gca, 'FontSize', 14);
            grid off
            box off;
            
            
            
            
            pos = subplotPosVectors(4,1).v;
            subplot('Position', [pos(1)+0.12 pos(2) pos(3) pos(4)]);
            bar(1:numel(data{spectrumIndex}.activation), data{spectrumIndex}.activation, 1, 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', [0 0 0], 'LineWidth', 2.0)
            set(gca, 'XLim', [0 numel(data{spectrumIndex}.activation)+1], 'YLim', [0 1.05]);
            set(gca, 'FontSize', 14);
            box off;
            
            
            pos = subplotPosVectors(4,3).v;
            subplot('Position', [pos(1) pos(2) pos(3)*2.2 0.98]);
            plot(wavelengthAxis, spdGain*(referenceSPD), 'o-', 'MarkerSize', 4, 'Color', [0.0 0.0 0.8], 'MarkerFaceColor', [0.8 0.8 1.0], 'LineWidth', 1.0);
            hold on
            plot(wavelengthAxis, spdGain*(data{spectrumIndex}.measuredSPD(:,repeatIndex)), 'o-', 'MarkerSize', 4, 'MarkerFaceColor', [1.0 0.8 0.8], 'Color', [1.0 0.0 0.0], 'LineWidth', 1.0);
            for k = 1:numel(spectralPeaks)
                plot(spectralPeaks(k)*[1 1], [-100 100], 'k-');
            end
            hL = legend({referenceSPDtitle, sprintf('SPD(iteration %d)', repeatIndex)}, 'Location', 'NorthOutside', 'Orientation', 'Horizontal');
            set(hL, 'FontName', 'Menlo');
            hold off
            set(gca, 'YLim', maxSPDref*[0.0 1.01], 'XLim', [wavelengthAxis(1) wavelengthAxis(end)], 'XTick', [], 'XTickLabel', {}, 'YTickLabel', {});
            set(gca, 'FontSize', 14);
            xlabel('wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold');
            grid off
            box off;
            
            
            drawnow
            if (generateVideo)
                writerObj.writeVideo(getframe(hFig));
            end
        end
        

        
        measurementTimes = cat(2, measurementTimes, squeeze(data{spectrumIndex}.measurementTime));
        allSPDratios = cat(2,allSPDratios, globalSPDratio);
        
        [measurementTimes, idx] = sort(measurementTimes);
        allSPDratios = allSPDratios(idx);
        
        figure(hFig2);
        subplot('Position', [0.07 0.04 0.93 0.95]);
        plot((measurementTimes-measurementTimes(1))/(60), log(allSPDratios), 'ks-', 'MarkerFaceColor', [0.7 0.7 0.7], 'LineWidth', 2.0);
        logRatioIntervals = -0.03:0.01:0.03;
        set(gca, 'YLim', 0.03*[-1 1], 'YTick', logRatioIntervals, 'YTickLabel', sprintf('%2.3f\n', exp(logRatioIntervals)));
        set(gca, 'FontSize', 14);
        xlabel('time (minutes)', 'FontSize', 16, 'FontWeight', 'bold');
        ylabel('trial-by-trial SPD ratios', 'FontSize', 16, 'FontWeight', 'bold');
        drawnow
        pause(1.0);
        
        

        
        
        spdType = data{spectrumIndex}.spdType;
        switch (spdType)
            case 'steadyBandsOnly'
                steadyBandsOnlySPD = data{spectrumIndex}.meanSPD;
                steadyBandsOnlySPDrange(1,:) = data{spectrumIndex}.minSPD;
                steadyBandsOnlySPDrange(2,:) = data{spectrumIndex}.maxSPD;
                fprintf('Found Steady Bands Only SPD type\n');
                
            case 'dark'
                darkSPD = data{spectrumIndex}.meanSPD;
                darkSPDrange(1,:) = data{spectrumIndex}.minSPD;
                darkSPDrange(2,:) = data{spectrumIndex}.maxSPD;
                fprintf('Found Dark SPD type\n');
                
            case 'temporalStabilityGauge1SPD'
                ; % ignore
                
            case 'temporalStabilityGauge2SPD'
                ; % ignore
                
            case 'comboSPD'
                fprintf('Found combo SPD with interacting bands index: %d and settings index: %d\n', data{spectrumIndex}.interactingBandsIndex, data{spectrumIndex}.interactingBandSettingsIndex);
                
            case 'singletonSPDr'
                
                fprintf('Found SingletonR SPD type\n');
                
            otherwise
                fprintf(2, 'Found ''%s'' spd type\n', spdType);
                pause
        end % switch
    end % spectrumIndex
    
            if (generateVideo)
            % Close video stream
            writerObj.close();
            end
        
end

