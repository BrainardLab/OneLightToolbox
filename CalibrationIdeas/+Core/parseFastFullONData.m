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
    figNo = 1;
    %plotData(figNo, timeAxisInMinutes, spectroTemporalResponse, 'SPD amplitude (mWatts)', 'Raw Measurement');

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
    fftN = 8192*4;
    NW = 6;
    windowData = false;
    [spectraLinearDriftCorrected, spectraLinearDriftUncorrected, spectraNoise, sineFreqInHz, ...
        spectroTemporalNoiseZeroMean, spectroTemporalResponseZeroMean, spectroTemporalResponseLinearDriftUncorrectedZeroMean, spectroTemporalResponseZeroMeanTimeAxis, SlepianTapers, rawResponseRange, spectralAmplitudeRange, spectralAmplitudeRange2] = ...
        doSpectralAnalysis(timeAxisInMinutes, spectroTemporalResponse, spectroTemporalResponseLinearDriftUncorrected, fftN, NW, windowData);
    
    % Compute ranges
    frequencyRange = [spectraLinearDriftUncorrected{1}.frequencyAxis(1) spectraLinearDriftUncorrected{1}.frequencyAxis(end)];
    timeRange = [timeAxisInMinutes(1)-40 timeAxisInMinutes(end)+40];
   % timeRange = [spectroTemporalResponseZeroMeanTimeAxis(1) spectroTemporalResponseZeroMeanTimeAxis(end)];
    
   
   
    % Plot frequency analysis for all bands
    for bandIndex =  1 : size(spectroTemporalResponse,2)
        spectralEnergy(bandIndex,:) = spectraLinearDriftCorrected{bandIndex}.amplitude;
        spectralEnergyNoise(bandIndex,:) = spectraNoise{bandIndex}.confidenceIntervals(:,2);
    end
    

    hFig = figure(10);clf;
    set(hFig, 'Color', [1 1 1], 'Position', [1 1 1900 1300]);
    subplot('Position', [0.03 0.53 0.96 0.45]);
    pcolor(spectraLinearDriftCorrected{1}.frequencyAxis, 1:size(spectroTemporalResponse,2), spectralEnergy);
    hold on;
    plot(0.5*sineFreqInHz*[1 1]*1000, [1 size(spectroTemporalResponse,2)], 'b-', 'LineWidth', 1.5);
    plot(1.0*sineFreqInHz*[1 1]*1000, [1 size(spectroTemporalResponse,2)], 'm-', 'LineWidth', 1.5);
    plot(2.0*sineFreqInHz*[1 1]*1000, [1 size(spectroTemporalResponse,2)], 'r-', 'LineWidth', 1.5);
    ylabel('band no', 'FontSize', 16, 'FontWeight', 'bold');
    shading 'flat'
    set(gca, 'XLim', frequencyRange, 'XScale', 'log', 'CLim', spectralAmplitudeRange2);
    set(gca, 'FontSize', 14);       
    box on; colorbar
    title('drift corrected');
    
    subplot('Position', [0.03 0.04 0.96 0.45]);
    pcolor(spectraLinearDriftCorrected{1}.frequencyAxis, 1:size(spectroTemporalResponse,2), spectralEnergyNoise);
    hold on;
    plot(0.5*sineFreqInHz*[1 1]*1000, [1 size(spectroTemporalResponse,2)], 'b-', 'LineWidth', 1.5);
    plot(1.0*sineFreqInHz*[1 1]*1000, [1 size(spectroTemporalResponse,2)], 'm-', 'LineWidth', 1.5);
    plot(2.0*sineFreqInHz*[1 1]*1000, [1 size(spectroTemporalResponse,2)], 'r-', 'LineWidth', 1.5);
    xlabel('frequency (milliHertz)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('band no', 'FontSize', 16, 'FontWeight', 'bold');
    shading 'flat'
    set(gca, 'XLim', frequencyRange, 'XScale', 'log', 'CLim', spectralAmplitudeRange2);
    set(gca, 'FontSize', 14);       
    box on; colorbar
    title('noise - upper 99% confidence interval');

    
    colormap(gray(1024));
    
    
    if (windowData)
        NicePlot.exportFigToPNG(sprintf('TimeSeriesAnalysisWindowed.png'), hFig, 300);
    else
        NicePlot.exportFigToPNG(sprintf('TimeSeriesAnalysisNonWindowed.png'), hFig, 300);
    end
        
    pause
    
    
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
                   'rowsNum', 3, ...
                   'colsNum', 3, ...
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
        subplot('Position', [pos(1) pos(2) 2*pos(3) pos(4)]);
            plot(spectroTemporalResponseZeroMeanTimeAxis, squeeze(spectroTemporalResponseLinearDriftUncorrectedZeroMean(:,bandIndex)), 'k-', 'LineWidth', 1.5);
            hold on;
            plot(spectroTemporalResponseZeroMeanTimeAxis, SlepianTapers, 'LineWidth', 1.0);
            hold off;
            set(gca, 'YLim', rawResponseRange, 'XLim', timeRange, 'XTickLabel', {}, 'YColor', 'none', 'XColor', 'none');
            ylabel('Energy - mean(mWatts)', 'FontSize', 14, 'FontWeight', 'bold');
            hL = legend(sprintf('band no %d (linear drift - uncorrected)', bandIndex));
            set(hL, 'FontName', 'Menlo');
            set(gca, 'FontSize', 14);
            box off;
            
        pos = subplotPosVectors(2,1).v;
        subplot('Position', [pos(1) pos(2) 2*pos(3) pos(4)]);
            plot(spectroTemporalResponseZeroMeanTimeAxis, squeeze(spectroTemporalResponseZeroMean(:,bandIndex)), 'k-', 'LineWidth', 1.5);
            hold on;
            plot(spectroTemporalResponseZeroMeanTimeAxis, SlepianTapers, 'LineWidth', 1.0);
            hold off;
            set(gca, 'YLim', rawResponseRange, 'XLim', timeRange, 'XTickLabel', {}, 'YColor', 'none', 'XColor', 'none');
            ylabel('Energy - mean (mWatts)', 'FontSize', 14, 'FontWeight', 'bold');
            hL = legend(sprintf('band no %d (linear drift - corrected)', bandIndex));
            set(hL, 'FontName', 'Menlo');
            set(gca, 'FontSize', 14);
            box off;
            
             
        pos = subplotPosVectors(3,1).v;
        subplot('Position', [pos(1) pos(2) 2*pos(3) pos(4)]);
        size(spectroTemporalNoiseZeroMean)
        size(spectroTemporalResponseZeroMeanTimeAxis)
            plot(spectroTemporalResponseZeroMeanTimeAxis, squeeze(spectroTemporalNoiseZeroMean(:,bandIndex)), 'k-', 'LineWidth', 1.5);
            hold on;
            plot(spectroTemporalResponseZeroMeanTimeAxis, SlepianTapers, 'LineWidth', 1.0);
            hold off;
            set(gca, 'YLim', rawResponseRange, 'XLim', timeRange, 'YColor', 'none');
            xlabel('time (minutes)', 'FontSize', 14, 'FontWeight', 'bold'); 
            ylabel('Energy - mean(mWatts)', 'FontSize', 14, 'FontWeight', 'bold');
            set(gca, 'FontSize', 14);
            hL = legend(sprintf('band no %d (random data)', bandIndex));
            box off;
            set(hL, 'FontName', 'Menlo');
            
             
          
        pos = subplotPosVectors(1,3).v;
        subplot('Position', pos);
            plot(spectraLinearDriftUncorrected{bandIndex}.frequencyAxis, spectraLinearDriftUncorrected{bandIndex}.amplitude, 'k-', 'LineWidth', 2.0); 
            hold on;
            plot(spectraLinearDriftUncorrected{bandIndex}.frequencyAxis, spectraLinearDriftUncorrected{bandIndex}.confidenceIntervals, 'k--'); 
            plot(0.5*sineFreqInHz*[1 1]*1000, spectralAmplitudeRange, 'b-', 'LineWidth', 1.5);
            plot(1.0*sineFreqInHz*[1 1]*1000, spectralAmplitudeRange, 'm-', 'LineWidth', 1.5);
            plot(2.0*sineFreqInHz*[1 1]*1000, spectralAmplitudeRange, 'r-', 'LineWidth', 1.5);
            plot(spectraNoise{bandIndex}.frequencyAxis, spectraNoise{bandIndex}.confidenceIntervals(:,2), 'g-', 'LineWidth', 2.0, 'Color', [0 0.7 0.0]); 
            hold off
            set(gca, 'XLim', frequencyRange, 'XScale', 'log',  'YLim', spectralAmplitudeRange, 'XTickLabel', {} );
            %set(gca, 'YScale', 'log');
            set(gca, 'FontSize', 14);
            hL = legend({'energy', '99% conf interval', '1% conf interval', '0.5 cycles/total duration', '1.0 cycles/total duration', '2.0 cycles/total duration', 'noise ceiling'});
            set(hL, 'FontName', 'Menlo');
            box off;
            grid on
            
         pos = subplotPosVectors(2,3).v;
         subplot('Position', pos);
            plot(spectraLinearDriftCorrected{bandIndex}.frequencyAxis, spectraLinearDriftCorrected{bandIndex}.amplitude, 'k-', 'LineWidth', 2.0); 
            hold on;
            plot(spectraLinearDriftCorrected{bandIndex}.frequencyAxis, spectraLinearDriftCorrected{bandIndex}.confidenceIntervals, 'k--'); 
            plot(0.5*sineFreqInHz*[1 1]*1000, spectralAmplitudeRange, 'b-', 'LineWidth', 1.5);
            plot(1.0*sineFreqInHz*[1 1]*1000, spectralAmplitudeRange, 'm-', 'LineWidth', 1.5);
            plot(2.0*sineFreqInHz*[1 1]*1000, spectralAmplitudeRange, 'r-', 'LineWidth', 1.5);
            plot(spectraNoise{bandIndex}.frequencyAxis, spectraNoise{bandIndex}.confidenceIntervals(:,2), 'g-', 'LineWidth', 2.0, 'Color', [0 0.7 0.0]); 
            hold off
            set(gca, 'XLim', frequencyRange, 'XScale', 'log', 'YLim', spectralAmplitudeRange2, 'XTickLabel', {});
            %set(gca, 'YScale', 'log');
            set(gca, 'FontSize', 14);
            hL = legend({'energy', '99% conf interval', '1% conf interval', '0.5 cycles/total duration', '1.0 cycles/total duration', '2.0 cycles/total duration', 'noise ceiling'});
            set(hL, 'FontName', 'Menlo');
            box off;
            grid on
            
         pos = subplotPosVectors(3,3).v;
         subplot('Position', pos);
            plot(spectraNoise{bandIndex}.frequencyAxis, spectraNoise{bandIndex}.amplitude, 'k-', 'LineWidth', 2.0); 
            hold on;
            plot(spectraNoise{bandIndex}.frequencyAxis, spectraNoise{bandIndex}.confidenceIntervals, 'k--'); 
            plot(0.5*sineFreqInHz*[1 1]*1000, spectralAmplitudeRange, 'b-', 'LineWidth', 1.5);
            plot(1.0*sineFreqInHz*[1 1]*1000, spectralAmplitudeRange, 'm-', 'LineWidth', 1.5);
            plot(2.0*sineFreqInHz*[1 1]*1000, spectralAmplitudeRange, 'r-', 'LineWidth', 1.5);
            plot(spectraNoise{bandIndex}.frequencyAxis, spectraNoise{bandIndex}.confidenceIntervals(:,2), 'g-', 'LineWidth', 2.0, 'Color', [0 0.7 0.0]); 
            hold off
            xlabel('frequency (milli Hertz)', 'FontSize', 14, 'FontWeight', 'bold');
            set(gca, 'XLim', frequencyRange, 'XScale', 'log', 'YLim', spectralAmplitudeRange2);
            %set(gca, 'YScale', 'log');
            set(gca, 'FontSize', 14);
            hL = legend({'energy', '99% conf interval', '1% conf interval', '0.5 cycles/total duration', '1.0 cycles/total duration', '2.0 cycles/total duration', 'noise ceiling'});
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


function [spectra, spectraLinearDriftUncorrected, spectraNoise, sineFreqInHz, ...
    spectroTemporalNoiseZeroMean, spectroTemporalResponseZeroMean, spectroTemporalResponseLinearDriftUncorrectedZeroMean, spectroTemporalResponseZeroMeanTimeAxis, SlepianTapers, rawResponseRange, spectralAmplitudeRange, spectralAmplitudeRange2] = ...
    doSpectralAnalysis(timeAxisInMinutes, spectroTemporalResponse, spectroTemporalResponseLinearDriftUncorrected, fftN, NW, windowData)

    % Obtain slepian sequences
    [E,V] = dpss(fftN, NW);
    
    samplesNum = size(spectroTemporalResponse,1);
    spectralBandsNum = size(spectroTemporalResponse,2);
    zeroPaddingOffset = round((fftN - samplesNum)/2);
    
    dtInSeconds = (timeAxisInMinutes(2)-timeAxisInMinutes(1))*60;
    maxFreq = 1.0/(2*dtInSeconds);
    
    sineFreqInHz = 1.0/(timeAxisInMinutes(end)*60);
    
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
        
        % Frequency axis in milliHertz
        freq = freq * 1000;
        
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


    