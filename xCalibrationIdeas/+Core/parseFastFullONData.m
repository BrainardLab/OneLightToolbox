function parseFastFullONData(data, wavelengthAxis)

    stimPattern = 1;
    [passesNum, nAveragesPerPass, ~] = size(data{stimPattern}.measuredSPDallSpectraToBeAveraged);
    averageIter = 1:nAveragesPerPass;
    
    passIter = 1;
    
    % Time axis in minuts, spectral data in milliWatts
    timeAxisInMinutes = data{stimPattern}.measuredSPDallSpectraToBeAveragedTimes(passIter, averageIter) / 60;
    spdGain = 1000;
    spectroTemporalResponse = spdGain*squeeze(data{stimPattern}.measuredSPDallSpectraToBeAveraged(passIter, averageIter,:));
    
    % Plot raw data collecte
    %figNo = 1;
    %plotData(figNo, timeAxisInMinutes, spectroTemporalResponse, 'SPD amplitude (mWatts)', 'Raw Measurement');
    figNo = 2;
    animateDataTimeSeries(figNo, timeAxisInMinutes, spectroTemporalResponse, 'SPD amplitude (mWatts)', 'Raw Measurement');
    %pause;
    
    % Resample raw data so that time samples are uniformly-spaced
    [timeAxisInMinutes, spectroTemporalResponse] = resampleUniformly(timeAxisInMinutes, spectroTemporalResponse);
    
    
    % Ask user to see if we want to exclude the initial part of the data
    [timeAxisInMinutes, spectroTemporalResponse] = queryUserWhetherToExcudeInitialPartOfResponseSequence(timeAxisInMinutes, spectroTemporalResponse);
    figNo = 2;
    %plotData(figNo, timeAxisInMinutes, spectroTemporalResponse, 'SPD amplitude (mWatts)', 'Uniform time sampling, partial time series');
 
    
    % Do linear drift correction
    spectroTemporalResponseLinearDriftUncorrected = spectroTemporalResponse;
    
    responsesToAverage = 11; % Use 0 for no correction
    [timeAxisInMinutes, spectroTemporalResponse] = correctForLinearDrift(timeAxisInMinutes, spectroTemporalResponse, responsesToAverage, wavelengthAxis);
    figNo = 3;
    %plotData(figNo, timeAxisInMinutes, spectroTemporalResponse, 'SPD amplitude (mWatts)', sprintf('Linear drift corrected (end-point averages: %d)', responsesToAverage));
    
    
    % Spectral analysis
    fftN = 8192*8;
    NW = 3;
    windowData = false;
    [spectraLinearDriftCorrected, spectraLinearDriftUncorrected, spectraNoise,  ...
        spectroTemporalNoiseZeroMean, spectroTemporalResponseZeroMean, spectroTemporalResponseLinearDriftUncorrectedZeroMean, spectroTemporalResponseZeroMeanTimeAxis, SlepianTapers, rawResponseRange, spectralAmplitudeRange, spectralAmplitudeRange2] = ...
        doSpectralAnalysis(timeAxisInMinutes, spectroTemporalResponse, spectroTemporalResponseLinearDriftUncorrected, fftN, NW, windowData);
    
    % Compute ranges
    frequencyRange = [spectraLinearDriftUncorrected{1}.frequencyAxis(1) spectraLinearDriftUncorrected{1}.frequencyAxis(end)];
    timeRange = [timeAxisInMinutes(1)-10 timeAxisInMinutes(end)+10];
   % timeRange = [spectroTemporalResponseZeroMeanTimeAxis(1) spectroTemporalResponseZeroMeanTimeAxis(end)];
    
   
   
    % Plot frequency analysis for all bands
    for bandIndex =  1 : size(spectroTemporalResponse,2)
        spectralEnergy(bandIndex,:) = spectraLinearDriftCorrected{bandIndex}.amplitude;
        spectralEnergyNoise(bandIndex,:) = spectraNoise{bandIndex}.confidenceIntervals(:,2);
    end
    
    indices = find(wavelengthAxis>400 & wavelengthAxis < 730);
    wavelengthAxis = wavelengthAxis(indices);
    spectralEnergy = spectralEnergy(indices,:);
    spectralEnergy = spectralEnergy / max(spectralEnergy(:));
    [m,idx] = max(spectralEnergy(:));
    [peakWaveIndex, peakFreqIndex] = ind2sub(size(spectralEnergy), idx);
    
    hFig = figure(10);clf;
    set(hFig, 'Color', [1 1 1], 'Position', [1 1 1550 1100]);
    subplot('Position', [0.05 0.06 0.94 0.93]);
    contourf(spectraLinearDriftCorrected{1}.frequencyAxis, wavelengthAxis, spectralEnergy, [0.0:0.1:1.0]);
    hold on;
    plot(spectraLinearDriftCorrected{1}.frequencyAxis, wavelengthAxis(1) + (0.0 + 0.35*squeeze(spectralEnergy(peakWaveIndex,:)))*(wavelengthAxis(end)-wavelengthAxis(1)), 'b-', 'LineWidth', 3);
    %plot(spectraLinearDriftCorrected{1}.frequencyAxis(peakFreqIndex)*[1 1], [wavelengthAxis(1) wavelengthAxis(end)], 'b-', 'LineWidth', 2.0);
    %plot([spectraLinearDriftCorrected{1}.frequencyAxis(2) spectraLinearDriftCorrected{1}.frequencyAxis(end)], wavelengthAxis(peakWaveIndex)*[1 1], 'b-', 'LineWidth', 2.0);
    
    ylabel('wavelength (nm)', 'FontSize', 20, 'FontWeight', 'bold');
    xlabel('frequency (cycles/hour)', 'FontSize', 20, 'FontWeight', 'bold');
    shading 'flat'
    grid on
    set(gca, 'XLim', frequencyRange, 'XScale', 'log', 'XTick', [0.1 0.2 0.3 0.6 1 2 3 6 10 20 30 60 100 200], 'XLim', [0.1 100], 'CLim', [0 1]);
    set(gca, 'FontSize', 18); set(gca,'GridLineStyle','-')      
    box on; 
    colormap(1-gray(1024));
    
    
    if (windowData)
        NicePlot.exportFigToPNG(sprintf('TimeSeriesAnalysisWindowed.png'), hFig, 300);
    else
        NicePlot.exportFigToPNG(sprintf('TimeSeriesAnalysisNonWindowed.png'), hFig, 300);
    end
        
    pause
    
    
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
                   'rowsNum', 2, ...
                   'colsNum', 2, ...
                   'heightMargin',   0.03, ...
                   'widthMargin',    0.015, ...
                   'leftMargin',     0.01, ...
                   'rightMargin',    0.000, ...
                   'bottomMargin',   0.04, ...
                   'topMargin',      0.01);
   
    generateVideo = true;
    if (generateVideo)
        % Open video stream
        if (windowData)
            videoFilename = sprintf('TimeSeriesAnalysisWindowed.m4v');
        else
            videoFilename = sprintf('TimeSeriesAnalysisNonWindowed.m4v');
        end
        writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
        writerObj.FrameRate = 15; 
        writerObj.Quality = 100;
        writerObj.open();
    end
        
    hFig = figure(5); clf; 
    set(hFig, 'Position', [10 400 3760/2 2450/2], 'Color', [1 1 1], 'MenuBar', 'none');
    
    for bandIndex =  1 : size(spectroTemporalResponse,2)

        pos = subplotPosVectors(1,1).v;
        subplot('Position', pos);
            plot(spectroTemporalResponseZeroMeanTimeAxis, squeeze(spectroTemporalResponseZeroMean(:,bandIndex)), 'k-', 'LineWidth', 1.5);
            hold on;
            %plot(spectroTemporalResponseZeroMeanTimeAxis, SlepianTapers, 'LineWidth', 1.0);
            hold off;
            set(gca, 'YLim', rawResponseRange, 'XLim', timeRange, 'XTickLabel', {}, 'YColor', 'none', 'XColor', 'none');
            ylabel('Energy - mean (mWatts)', 'FontSize', 18, 'FontWeight', 'bold');
            hL = legend(sprintf('band no %d (linear drift - corrected)', bandIndex));
            set(hL, 'FontName', 'Menlo');
            set(gca, 'FontSize', 14);
            box off;
            
             
        pos = subplotPosVectors(2,1).v;
        subplot('Position', pos);
            plot(spectroTemporalResponseZeroMeanTimeAxis, squeeze(spectroTemporalNoiseZeroMean(:,bandIndex)), 'k-', 'LineWidth', 1.5);
            hold on;
            %plot(spectroTemporalResponseZeroMeanTimeAxis, SlepianTapers, 'LineWidth', 1.0);
            hold off;
            set(gca, 'YLim', rawResponseRange, 'XLim', timeRange, 'YColor', 'none');
            xlabel('time (minutes)', 'FontSize', 16, 'FontWeight', 'bold'); 
            ylabel('Energy - mean(mWatts)', 'FontSize', 18, 'FontWeight', 'bold');
            set(gca, 'FontSize', 14);
            hL = legend(sprintf('band no %d (random data)', bandIndex));
            box off;
            set(hL, 'FontName', 'Menlo');
            
             
          
            
         pos = subplotPosVectors(1,2).v;
         subplot('Position', pos);
            plot(spectraLinearDriftCorrected{bandIndex}.frequencyAxis, spectraLinearDriftCorrected{bandIndex}.amplitude, 'k-', 'LineWidth', 2.0); 
            hold on;
            plot(spectraLinearDriftCorrected{bandIndex}.frequencyAxis, spectraLinearDriftCorrected{bandIndex}.confidenceIntervals, 'k--'); 
            plot(spectraNoise{bandIndex}.frequencyAxis, spectraNoise{bandIndex}.confidenceIntervals(:,2), 'g-', 'LineWidth', 2.0, 'Color', [0 0.7 0.0]); 
            hold off
            set(gca, 'XLim', frequencyRange, 'XScale', 'log', 'YLim', spectralAmplitudeRange2, 'XTickLabel', {});
            %set(gca, 'YScale', 'log');
            set(gca, 'FontSize', 16);
            hL = legend({'energy', '99% conf interval', '1% conf interval',  'noise ceiling'});
            set(hL, 'FontName', 'Menlo');
            box off;
            grid on
            
         pos = subplotPosVectors(2,2).v;
         subplot('Position', pos);
            plot(spectraNoise{bandIndex}.frequencyAxis, spectraNoise{bandIndex}.amplitude, 'k-', 'LineWidth', 2.0); 
            hold on;
            plot(spectraNoise{bandIndex}.frequencyAxis, spectraNoise{bandIndex}.confidenceIntervals, 'k--'); 
            plot(spectraNoise{bandIndex}.frequencyAxis, spectraNoise{bandIndex}.confidenceIntervals(:,2), 'g-', 'LineWidth', 2.0, 'Color', [0 0.7 0.0]); 
            hold off
            xlabel('frequency (cycles/hour)', 'FontSize', 18, 'FontWeight', 'bold');
            set(gca, 'XLim', frequencyRange, 'XScale', 'log', 'YLim', spectralAmplitudeRange2);
            %set(gca, 'YScale', 'log');
            set(gca, 'FontSize', 16);
            hL = legend({'energy', '99% conf interval', '1% conf interval',  'noise ceiling'});
            set(hL, 'FontName', 'Menlo');
            box off;
            grid on
            
            drawnow; 
            if (generateVideo)
                writerObj.writeVideo(getframe(hFig));
            end
    end
    
    if (generateVideo)
        % Close video stream
        writerObj.close();
    end       
   
end



function [spectra, spectraLinearDriftUncorrected, spectraNoise, ...
    spectroTemporalNoiseZeroMean, spectroTemporalResponseZeroMean, spectroTemporalResponseLinearDriftUncorrectedZeroMean, spectroTemporalResponseZeroMeanTimeAxis, SlepianTapers, rawResponseRange, spectralAmplitudeRange, spectralAmplitudeRange2] = ...
    doSpectralAnalysis(timeAxisInMinutes, spectroTemporalResponse, spectroTemporalResponseLinearDriftUncorrected, fftN, NW, windowData)

    % Obtain slepian sequences
    [E,V] = dpss(fftN, NW);
    
    samplesNum = size(spectroTemporalResponse,1);
    spectralBandsNum = size(spectroTemporalResponse,2);
    zeroPaddingOffset = round((fftN - samplesNum)/2);
    
    dtInSeconds = (timeAxisInMinutes(2)-timeAxisInMinutes(1))*60;
    maxFreq = 1.0/(2*dtInSeconds);
    
    maxAmp = 0;
    maxAmp2 = 0;
    
    maxRawResponse = 0;
    noiseDraws = 10;
    
    for k = 1:2+noiseDraws
    for bandIndex =  1:spectralBandsNum
        % get time-series for each band
        if (k == 1)
            timeSeries = squeeze(spectroTemporalResponseLinearDriftUncorrected(:,bandIndex));
        elseif (k == 2)
            timeSeries = squeeze(spectroTemporalResponse(:,bandIndex));
        else
            timeSeries = randn(size(spectroTemporalResponse,1),1)*std(squeeze(spectroTemporalResponse(:,bandIndex)));
            spectroTemporalNoise(k-2,:,bandIndex) = timeSeries;
        end
        
        % subtract mean across time
        meanTimeSeries = mean(timeSeries);
        timeSeries = timeSeries - meanTimeSeries;
       
        % apply Hanning window
        if (windowData)
            timeSeries = timeSeries .* hann(numel(timeSeries));
        end
        
        % zero pad placing the time series in the center
        zeroPaddedTimeSeries = zeros(1, fftN);
        zeroPaddedTimeSeries(zeroPaddingOffset + (1:samplesNum)) = timeSeries;
        spectroTemporalResponseZeroMeanTimeAxis = timeAxisInMinutes(1) + (timeAxisInMinutes(2)-timeAxisInMinutes(1)) * ((1:fftN)-zeroPaddingOffset);
        
        if (k == 1)
            spectroTemporalResponseLinearDriftUncorrectedZeroMean(:,bandIndex) = zeroPaddedTimeSeries;
        elseif (k == 2)
            spectroTemporalResponseZeroMean(:,bandIndex) = zeroPaddedTimeSeries;
            if (max(abs(zeroPaddedTimeSeries)) > maxRawResponse)
                maxRawResponse = max(abs(zeroPaddedTimeSeries));
            end
        else
            % displaying the last noise draqw one only
            spectroTemporalNoiseZeroMean(:,bandIndex) = zeroPaddedTimeSeries;
        end

            
        % Do the spectral analysis
        [amp, freq, conf] = pmtm(zeroPaddedTimeSeries, E, V, fftN, 2*maxFreq, 'ConfidenceLevel', 0.99); % , 'Droplasttaper', false);
        
        if (max(abs(amp)) > maxAmp)
            maxAmp = max(abs(amp));
        end
        
        if (k > 1)
            if (max(abs(amp)) > maxAmp2)
                maxAmp2 = max(abs(amp));
            end
        end
        
        % Frequency axis in cycles/hour
        freq = freq * 60*60;
        
        if (k == 1)
            spectraLinearDriftUncorrected{bandIndex}.amplitude = amp;
            spectraLinearDriftUncorrected{bandIndex}.frequencyAxis = freq;
            spectraLinearDriftUncorrected{bandIndex}.confidenceIntervals = conf;  
        elseif (k == 2)
            spectra{bandIndex}.amplitude = amp;
            spectra{bandIndex}.frequencyAxis = freq;
            spectra{bandIndex}.confidenceIntervals = conf; 
        else
            spectraNoiseTmp{k-2,bandIndex}.amplitude = amp;
            spectraNoise{bandIndex}.frequencyAxis = freq;
            spectraNoiseTmp{k-2,bandIndex}.confidenceIntervals = conf; 
        end 
    end % bandIndex
    end % for k
    
    % average noise draws
    for bandIndex =  1:spectralBandsNum
        for k = 1:size(spectraNoiseTmp,1)
           tmpAmp(k,:) = spectraNoiseTmp{k,bandIndex}.amplitude;
           tmpConf(k,:,:) = spectraNoiseTmp{k,bandIndex}.confidenceIntervals;
        end
        spectraNoise{bandIndex}.amplitude = (squeeze(mean(tmpAmp,1)));
        spectraNoise{bandIndex}.confidenceIntervals = squeeze(mean(tmpConf,1));
    end
    
    spectralAmplitudeRange  = [0.0001 maxAmp];
    spectralAmplitudeRange2 = [0.0001 maxAmp2];
    
    rawResponseRange = maxRawResponse*[-1 1];
    SlepianTapers = E/max(E(:)) * maxRawResponse;
end


function [timeAxisInMinutes, spectroTemporalResponse] = correctForLinearDrift(timeAxisInMinutes, spectroTemporalResponse, responsesToAverage, wavelengthAxis)
    
    if (responsesToAverage == 0)
        return;
    end
    
    if (mod(responsesToAverage,2) == 0)
        responsesToAverage = responsesToAverage + 1;
    end
    
    n = (responsesToAverage-1)/2;
    nn = -n:n;
    s0 = (mean(squeeze(spectroTemporalResponse(n+1+nn,:)), 1))';
    s1 = (mean(squeeze(spectroTemporalResponse(end-n+nn,:)), 1))';
    t0 = timeAxisInMinutes(1+n);
    t1 = timeAxisInMinutes(end-n);
    indices = find( ...
            (s1 > max(s1)*0.2) & ...
            ((wavelengthAxis >= 420) & (wavelengthAxis <= 700)) ...
        );
    s0 = s0(indices);
    s1 = s1(indices);
    dt1 = t1-t0;
    s = s0 \ s1;
    scalingFactor = @(t) 1./((1-(1-s)*((t-t0)./dt1)));
    for tBin = 1:numel(timeAxisInMinutes)
        spectroTemporalResponse(tBin,:) = spectroTemporalResponse(tBin,:) * scalingFactor(timeAxisInMinutes(tBin));
    end
    
    timeAxisInMinutes = timeAxisInMinutes - timeAxisInMinutes(1);
end
    
    
function  [timeAxis, spectroTemporalResponse] = resampleUniformly(timeAxis, spectroTemporalResponse)
    % Uniform time sampling
    diffTimeAxis = diff(timeAxis);
    samplingInterval = min(diffTimeAxis);
    uniformTimeAxis = timeAxis(1):samplingInterval:timeAxis(end);
    uniformTimeAxisSpectroTemporalResponse = zeros(numel(uniformTimeAxis), size(spectroTemporalResponse,2));
    for bandNo = 1:size(spectroTemporalResponse,2)
        uniformTimeAxisSpectroTemporalResponse(:,bandNo) = interp1(timeAxis, squeeze(spectroTemporalResponse(:,bandNo)), uniformTimeAxis, 'linear');
    end
    
    timeAxis = uniformTimeAxis';
    spectroTemporalResponse = uniformTimeAxisSpectroTemporalResponse;
end


function [timeAxisInMinutes, spectroTemporalResponse] = queryUserWhetherToExcudeInitialPartOfResponseSequence(timeAxisInMinutes, spectroTemporalResponse)
    minTimeForInclusion = input('Enter min lateny for inclusion in FFT analysis : ');
    t = find(timeAxisInMinutes > minTimeForInclusion);
    timeAxisInMinutes = timeAxisInMinutes(t);
    spectroTemporalResponse = spectroTemporalResponse(t,:);
end

function animateDataTimeSeries(figNo, timeAxisInMinutes, spectroTemporalResponse, yLabelString, titleString)
    hFig = figure(figNo); clf; set(hFig, 'Position', [1 1 1450 1200], 'Color', [1 1 1]);
    set(hFig, 'MenuBar', 'none');
    timeAxisInMinutes = timeAxisInMinutes - timeAxisInMinutes(1);
    
    % Open video stream

    writerObj = VideoWriter('TimeSeriesAnimation.m4v', 'MPEG-4'); % H264 format
    writerObj.FrameRate = 15; 
    writerObj.Quality = 100;
    writerObj.open();
    
    stepSize = 0.01;
    tEnd = 3;
    while tEnd < timeAxisInMinutes(end)
    	tEnd = tEnd + stepSize;
        if (stepSize < 0.02)
            stepSize = stepSize*1.005;
        elseif (stepSize < 0.03)
            stepSize = stepSize*1.003;
        else
            stepSize = stepSize*1.0015;
        end
        

        clf;
        subplot('Position', [0.044 0.044 0.95 0.945]);
        timeRange = [max([-timeAxisInMinutes(1)-0.1 tEnd-timeAxisInMinutes(end)]) tEnd+0.1];
        lw = 8 - tEnd/timeAxisInMinutes(end)*4;
        plot(timeAxisInMinutes, spectroTemporalResponse, '-', 'Color', [0.4 0.6 0.9 0.5], 'LineWidth', lw);
        hold on
        plot(timeAxisInMinutes, spectroTemporalResponse, 'k-', 'LineWidth', max([1 lw/3]));
        hold off
        amplitudeRange = [max([0 58-tEnd*0.4]) max(spectroTemporalResponse(:))];
        YTicks = linspace(amplitudeRange(1), amplitudeRange(end), 10);
        set(gca, 'LineWidth', 2.0, 'YLim', amplitudeRange, 'XLim', timeRange, 'FontSize', 18, 'YTick', YTicks, 'YTickLabel', sprintf('%2.1f\n', YTicks));
        xlabel('time (min)', 'FontSize', 20, 'FontWeight', 'bold');
        ylabel('power (mWatts)', 'FontSize', 20, 'FontWeight', 'bold');
        drawnow;
        writerObj.writeVideo(getframe(hFig));
        
    end
    
    writerObj.close();
    
end


function plotData(figNo, timeAxisInMinutes, spectroTemporalResponse, yLabelString, titleString)
    hFig = figure(figNo); clf; set(hFig, 'Position', [1 1 2250 1300], 'Color', [1 1 1]);
    set(hFig, 'MenuBar', 'none');
    timeRange = [timeAxisInMinutes(1) timeAxisInMinutes(end)];
    subplot('Position', [0.02 0.03 0.975 0.95]);
    plot(timeAxisInMinutes, spectroTemporalResponse, 'b-', 'Color', [0.2 0.1 0.2]);
    set(gca, 'YLim', [min(spectroTemporalResponse(:)) max(spectroTemporalResponse(:))], 'XLim', timeRange);
    set(gca, 'FontSize', 14);
    xlabel('time (minutes)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel(yLabelString, 'FontSize', 16, 'FontWeight', 'bold');
    title(titleString, 'FontSize', 16);
    box off;
    grid on
    drawnow;
    NicePlot.exportFigToPDF(sprintf('%s.pdf', titleString), hFig, 300);
end


    