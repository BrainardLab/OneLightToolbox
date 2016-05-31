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
    plotData(figNo, timeAxisInMinutes, spectroTemporalResponse);

    % Resample raw data so that time samples are uniformly-spaced
    [timeAxisInMinutes, spectroTemporalResponse] = resampleUniformly(timeAxisInMinutes, spectroTemporalResponse);
    
    
    % Ask user to see if we want to exclude the initial part of the data
    [timeAxisInMinutes, spectroTemporalResponse] = queryUserWhetherToExcudeInitialPartOfResponseSequence(timeAxisInMinutes, spectroTemporalResponse);
    figNo = 2;
    plotData(figNo, timeAxisInMinutes, spectroTemporalResponse);
 
    
    % Do linear drift correction
    spectroTemporalResponseLinearDriftUncorrected = spectroTemporalResponse;
    
    responsesToAverage = 11; % Use 0 for no correction
    [timeAxisInMinutes, spectroTemporalResponse] = correctForLinearDrift(timeAxisInMinutes, spectroTemporalResponse, responsesToAverage, wavelengthAxis);
    figNo = 3;
    plotData(figNo, timeAxisInMinutes, spectroTemporalResponse);
    
    
    % Spectral analysis
    [spectra, spectraLinearDriftUncorrected, spectraNoise, sineFreqInHz, ...
        spectroTemporalNoiseZeroMean, spectroTemporalResponseZeroMean, spectroTemporalResponseLinearDriftUncorrectedZeroMean, spectralAmplitudeRange] = ...
        doSpectralAnalysis(timeAxisInMinutes, spectroTemporalResponse, spectroTemporalResponseLinearDriftUncorrected);
    
    % Compute ranges
    frequencyRange = [spectraLinearDriftUncorrected{1}.frequencyAxis(1) spectraLinearDriftUncorrected{1}.frequencyAxis(end)];
    spectroTemporalResponseRangeZeroMean = max([max(abs(spectroTemporalResponseZeroMean(:))) max(abs(spectroTemporalResponseLinearDriftUncorrectedZeroMean(:))) max(abs(spectroTemporalNoiseZeroMean(:)))]) * [-1 1];
    timeRange = [timeAxisInMinutes(1) timeAxisInMinutes(end)];
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
                   'rowsNum', 3, ...
                   'colsNum', 3, ...
                   'heightMargin',   0.05, ...
                   'widthMargin',    0.02, ...
                   'leftMargin',     0.05, ...
                   'rightMargin',    0.000, ...
                   'bottomMargin',   0.04, ...
                   'topMargin',      0.01);
   
    generateVideo = true;
    if (generateVideo)
        % Open video stream
        videoFilename = sprintf('TimeSeriesAnalysis.m4v');
        writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
        writerObj.FrameRate = 15; 
        writerObj.Quality = 100;
        writerObj.open();
    end
        
    hFig = figure(5); clf; 
    set(hFig, 'Position', [10 10 1700 1200]);  
    
    for bandIndex =  1 : size(spectroTemporalResponse,2)
        pos = subplotPosVectors(1,1).v;
        subplot('Position', [pos(1) pos(2) 2*pos(3) pos(4)]);
            plot(timeAxisInMinutes, squeeze(spectroTemporalResponseLinearDriftUncorrectedZeroMean(:,bandIndex)), 'k-');
            set(gca, 'YLim', spectroTemporalResponseRangeZeroMean, 'XLim', timeRange);
            ylabel('Energy - mean(mWatts)');
            hL = legend(sprintf('band no %d', bandIndex));
            set(hL, 'FontName', 'Menlo');
            set(gca, 'FontSize', 14);
            title('no linear drift correction');
            
        pos = subplotPosVectors(2,1).v;
        subplot('Position', [pos(1) pos(2) 2*pos(3) pos(4)]);
            plot(timeAxisInMinutes, squeeze(spectroTemporalResponseZeroMean(:,bandIndex)), 'k-');
            set(gca, 'YLim', spectroTemporalResponseRangeZeroMean, 'XLim', timeRange);
            ylabel('Energy - mean (mWatts)');
            hL = legend(sprintf('band no %d', bandIndex));
            set(hL, 'FontName', 'Menlo');
            set(gca, 'FontSize', 14);
            title('linear drift correction');
            
        pos = subplotPosVectors(3,1).v;
        subplot('Position', [pos(1) pos(2) 2*pos(3) pos(4)]);
            plot(timeAxisInMinutes, squeeze(spectroTemporalNoiseZeroMean(:,bandIndex)), 'k-');
            set(gca, 'YLim', spectroTemporalResponseRangeZeroMean, 'XLim', timeRange);
            xlabel('time (minutes)'); ylabel('Energy - mean(mWatts)');
            set(gca, 'FontSize', 14);
            title('random data');
            hL = legend(sprintf('band no %d', bandIndex));
            set(hL, 'FontName', 'Menlo');
            
        pos = subplotPosVectors(1,3).v;
        subplot('Position', pos);
            plot(spectraLinearDriftUncorrected{bandIndex}.frequencyAxis, spectraLinearDriftUncorrected{bandIndex}.amplitude, 'k-', 'LineWidth', 2.0); 
            hold on;
            plot(spectraLinearDriftUncorrected{bandIndex}.frequencyAxis, spectraLinearDriftUncorrected{bandIndex}.confidenceIntervals, 'r-'); 
            plot(sineFreqInHz*[1 1]*1000, spectralAmplitudeRange, 'b-');
            hold off
            set(gca, 'XLim', frequencyRange, 'XScale', 'log', 'YLim', spectralAmplitudeRange);
            set(gca, 'FontSize', 14);
            hL = legend({'mean amplitude', '95% conf interval', '5% conf interval', '1 cycle/total duration'});
            set(hL, 'FontName', 'Menlo');
            
         pos = subplotPosVectors(2,3).v;
         subplot('Position', pos);
            plot(spectra{bandIndex}.frequencyAxis, spectra{bandIndex}.amplitude, 'k-', 'LineWidth', 2.0); 
            hold on;
            plot(spectra{bandIndex}.frequencyAxis, spectra{bandIndex}.confidenceIntervals, 'r-'); 
            plot(sineFreqInHz*[1 1]*1000, spectralAmplitudeRange, 'b-');
            hold off
            set(gca, 'XLim', frequencyRange, 'XScale', 'log', 'YLim', spectralAmplitudeRange);
            set(gca, 'FontSize', 14);
            hL = legend({'mean amplitude', '95% conf interval', '5% conf interval', '1 cycle/total duration'});
            set(hL, 'FontName', 'Menlo');
            
         pos = subplotPosVectors(3,3).v;
         subplot('Position', pos);
            plot(spectraNoise{bandIndex}.frequencyAxis, spectraNoise{bandIndex}.amplitude, 'k-', 'LineWidth', 2.0); 
            hold on;
            plot(spectraNoise{bandIndex}.frequencyAxis, spectraNoise{bandIndex}.confidenceIntervals, 'r-'); 
            plot(sineFreqInHz*[1 1]*1000, spectralAmplitudeRange, 'b-');
            hold off
            xlabel('frequency (milli Hertz)');
            set(gca, 'XLim', frequencyRange, 'XScale', 'log', 'YLim', spectralAmplitudeRange);
            set(gca, 'FontSize', 14);
            hL = legend({'mean amplitude', '95% conf interval', '5% conf interval', '1 cycle/total duration'});
            set(hL, 'FontName', 'Menlo');
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
    spectroTemporalNoiseZeroMean, spectroTemporalResponseZeroMean, spectroTemporalResponseLinearDriftUncorrectedZeroMean, spectralAmplitudeRange] = ...
    doSpectralAnalysis(timeAxisInMinutes, spectroTemporalResponse, spectroTemporalResponseLinearDriftUncorrected)

    % Multi-tapers
    fftN = 8192*4; NW = 3.0;
    [E,V] = dpss(fftN, NW);
    
    samplesNum = size(spectroTemporalResponse,1);
    spectralBandsNum = size(spectroTemporalResponse,2);
    zeroPaddingOffset = round((fftN - samplesNum)/2);
    
    dtInSeconds = (timeAxisInMinutes(2)-timeAxisInMinutes(1))*60;
    maxFreq = 1.0/(2*dtInSeconds);
    
    sineFreqInHz = 1.0/(timeAxisInMinutes(end)*60);
    
    maxAmp = 0;
    
    for k = 1:3
    for bandIndex =  1:spectralBandsNum
        % get time-series for each band
        if (k == 1)
            timeSeries = squeeze(spectroTemporalResponse(:,bandIndex));
        elseif (k == 2)
            timeSeries = squeeze(spectroTemporalResponseLinearDriftUncorrected(:,bandIndex));
        else
            tmp = squeeze(spectroTemporalResponse(:,bandIndex));
            tmp2 = tmp - mean(tmp);
            timeSeries = max(tmp2)/3*randn(size(tmp2));
            spectroTemporalNoise(:,bandIndex) = timeSeries;
        end
        
        % subtract mean across time
        meanTimeSeries = mean(timeSeries);
        timeSeries = timeSeries - meanTimeSeries;
       
        if (k == 1)
            spectroTemporalResponseZeroMean(:,bandIndex) = timeSeries;
        elseif (k == 2)
            spectroTemporalResponseLinearDriftUncorrectedZeroMean(:,bandIndex) = timeSeries;
        else
            spectroTemporalNoiseZeroMean(:,bandIndex) = timeSeries;
        end
        
        % apply Hanning window
        timeSeries = timeSeries .* hann(numel(timeSeries));
        
        % zero pad placing the time series in the center
        zeroPaddedTimeSeries = zeros(1, fftN);
        zeroPaddedTimeSeries(zeroPaddingOffset + (1:samplesNum)) = timeSeries;
        
        % Do the spectral analysis
        [amp, freq, conf] = pmtm(zeroPaddedTimeSeries, E, V, fftN, 2*maxFreq, 'ConfidenceLevel', 0.95, 'Droplasttaper', false);
        
        if (max(abs(amp)) > maxAmp)
            maxAmp = max(abs(amp));
        end
        
        % Frequency axis in milliHertz
        freq = freq * 1000;
        
        if (k == 1)
            spectra{bandIndex}.amplitude = amp;
            spectra{bandIndex}.frequencyAxis = freq;
            spectra{bandIndex}.confidenceIntervals = conf; 
        elseif (k == 2)
            spectraLinearDriftUncorrected{bandIndex}.amplitude = amp;
            spectraLinearDriftUncorrected{bandIndex}.frequencyAxis = freq;
            spectraLinearDriftUncorrected{bandIndex}.confidenceIntervals = conf; 
        else
            spectraNoise{bandIndex}.amplitude = amp;
            spectraNoise{bandIndex}.frequencyAxis = freq;
            spectraNoise{bandIndex}.confidenceIntervals = conf; 
            spectroTemporalNoise(:,bandIndex)  = spectroTemporalNoise(:,bandIndex);
        end 
    end % bandIndex
    end % for k
    
    spectralAmplitudeRange = [0 maxAmp];
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

function plotData(figNo, timeAxisInMinutes, spectroTemporalResponse)
    hFig = figure(figNo); clf; set(hFig, 'Position', [1 1 934 1298]);
    timeRange = [timeAxisInMinutes(1) timeAxisInMinutes(end)];
    subplot('Position', [0.05 0.05 0.94 0.94]);
    plot(timeAxisInMinutes, spectroTemporalResponse, 'k-');
    set(gca, 'YLim', [min(spectroTemporalResponse(:)) max(spectroTemporalResponse(:))], 'XLim', timeRange);
    xlabel('time (minutes)');
    drawnow;
end


    