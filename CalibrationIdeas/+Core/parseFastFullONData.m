function parseFastFullONData(data, wavelengthAxis)

    stimPattern = 1;
    [passesNum, nAveragesPerPass, ~] = size(data{stimPattern}.measuredSPDallSpectraToBeAveraged);
    averageIter = 1:nAveragesPerPass;
    
    passIter = 1;
    % Resample so we are on a time axis with constant sampling
    timeAxis = data{stimPattern}.measuredSPDallSpectraToBeAveragedTimes(passIter, averageIter);
    spectroTemporalResponse = squeeze(data{stimPattern}.measuredSPDallSpectraToBeAveraged(passIter, averageIter,:));
    
    
    t = find(timeAxis > 254.2);
    t = t(1);
    s0 = (squeeze(spectroTemporalResponse(t(1),:)))';
    s1 = (squeeze(spectroTemporalResponse(end,:)))';
    t0 = timeAxis(t(1))
    t1 = timeAxis(end)
    indices = find( ...
            (s1 > max(s1)*0.1) & ...
            ((wavelengthAxis >= 420) & (wavelengthAxis <= 700)) ...
        );
    s0 = s0(indices);
    s1 = s1(indices);
    
    repeatIndex = 1;
    dt1 = t1-t0;
    s = s0 \ s1;
    scalingFactor = @(t) 1./((1-(1-s)*((t-t0)./dt1)));
   
    size(spectroTemporalResponse)
    for k = 1:size(spectroTemporalResponse,1)
        spectroTemporalResponseScaled(k,:) = spectroTemporalResponse(k,:) / scalingFactor(timeAxis(k));
    end
    size(spectroTemporalResponseScaled)
    pause
    
    diffTimeAxis = diff(timeAxis);
    samplingInterval = min(diffTimeAxis);
    uniformTimeAxis = timeAxis(1):samplingInterval:timeAxis(end);
    uniformTimeAxisSpectroTemporalResponse = zeros(numel(uniformTimeAxis), size(spectroTemporalResponse,2));
    for bandNo = 1:size(spectroTemporalResponse,2)
        uniformTimeAxisSpectroTemporalResponse(:,bandNo) = interp1(timeAxis, squeeze(spectroTemporalResponse(:,bandNo)), uniformTimeAxis, 'linear');
    end
    
    spectroTemporalResponseScaled = spectroTemporalResponseScaled';
    spectroTemporalResponse = spectroTemporalResponse';
    uniformTimeAxisSpectroTemporalResponse = uniformTimeAxisSpectroTemporalResponse';
    
    
    spdGain = 1000;
    figure(1)
    subplot(3,1,1);
    imagesc(timeAxis/60, wavelengthAxis, spdGain*spectroTemporalResponse);
    set(gca, 'XLim', [timeAxis(1) timeAxis(end)]);
    colorbar
    
    subplot(3,1,2);
    imagesc(uniformTimeAxis/60, wavelengthAxis, spdGain*uniformTimeAxisSpectroTemporalResponse);
    set(gca, 'XLim', [timeAxis(1) timeAxis(end)]);
    colorbar
    colormap(gray(1024));
    
    subplot(3,1,3);
    size(timeAxis)
    size(spectroTemporalResponseScaled)
    plot(timeAxis/60, spdGain*spectroTemporalResponseScaled(30,:), 'rs-');
    hold on
    plot(uniformTimeAxis/60, spdGain*uniformTimeAxisSpectroTemporalResponse(30,:), 'ks-');
    hold off;

    xlabel('time (minutes)');
    drawnow
    
    pause
    
    
    t0 = (max(uniformTimeAxis)-min(uniformTimeAxis))/2 + min(uniformTimeAxis);
    sigma = (max(uniformTimeAxis)-min(uniformTimeAxis))/(2*3);
    envelope = exp(-0.5*((uniformTimeAxis-t0)/sigma).^2);
    
    spectroTemporalResponseDiffs = bsxfun(@minus, uniformTimeAxisSpectroTemporalResponse, uniformTimeAxisSpectroTemporalResponse(:,1));
    spectroTemporalResponseDiffsWindowed = bsxfun(@times, spectroTemporalResponseDiffs, envelope);
    spectroTemporalResponseWindowed = bsxfun(@times, uniformTimeAxisSpectroTemporalResponse, envelope);
    
    
    spdGain = 1000;
    figure(2); clf;
    subplot(3,1,1);
    imagesc(uniformTimeAxis, wavelengthAxis, spdGain*uniformTimeAxisSpectroTemporalResponse);
    colorbar
    
    subplot(3,1,2);
    imagesc(uniformTimeAxis, wavelengthAxis, spdGain*spectroTemporalResponseDiffs);
    colorbar
    
    subplot(3,1,3);
    imagesc(uniformTimeAxis, wavelengthAxis, spdGain*spectroTemporalResponseDiffsWindowed);
    colorbar
    
    colormap(gray(1024));
    drawnow
    
    
    
    fftN = 2048*16;
    maxFreq = 1.0/(2.0*samplingInterval);
    maxFreqInMilliHertz = maxFreq * 1000;
    deltaFreq = maxFreq / (fftN/2);
    freqAxis = (1:(fftN/2-1))*deltaFreq;
    freqAxisInMilliHertz = freqAxis*1000.0;

    for bandNo = 1:size(uniformTimeAxisSpectroTemporalResponse,1)
        tmp = squeeze(spectroTemporalResponseDiffsWindowed(bandNo,:));
        %tmp = squeeze(spectroTemporalResponseWindowed(bandNo,:));
        FTmag(bandNo,:) = abs(fft(tmp,fftN));
    end
    
    FTmag = FTmag(:, 1:numel(freqAxis));
    FTmag = FTmag / max(FTmag(:));
    FTmagIndivBandNorm =  bsxfun(@times,  FTmag , 1.0./max(FTmag , [], 2));
    
    log10FTmag = log10(0.0001 + FTmag);
    log10FTmag(log10FTmag<-4) = -4;
    
    log10FTmagIndivBandNorm = log10(0.0001 + FTmagIndivBandNorm);
    log10FTmagIndivBandNorm(log10FTmagIndivBandNorm<-4) = -4;
    
    
    freqHourlyOscillationInMilliHertz = 1000.0/(60*60);
    freqHalfHourlyOscillationInMilliHertz = 1000.0/(30*60);
    
    
    figure(3); clf;
    subplot(2,2,1);
    pcolor(freqAxisInMilliHertz, wavelengthAxis, (4+log10FTmag)/4);
    shading flat
    hold on;
    plot(freqHourlyOscillationInMilliHertz *[1 1], [wavelengthAxis(1) wavelengthAxis(end)], 'r-','LineWidth', 2.0);
    plot(freqHalfHourlyOscillationInMilliHertz*[1 1], [wavelengthAxis(1) wavelengthAxis(end)], 'b-','LineWidth', 2.0);
    hold off;
    set(gca,  'CLim', [0 1]);
    set(gca, 'XLim', [freqAxisInMilliHertz(1) freqAxisInMilliHertz(end)/4]);
    set(gca, 'XScale', 'log');
    xlabel('frequency (milliHertz)');
    colormap(gray(1024));

    
    subplot(2,2,2);
    pcolor(freqAxisInMilliHertz, wavelengthAxis, (4+log10FTmagIndivBandNorm)/4);
    shading flat
    hold on;
    plot(freqHourlyOscillationInMilliHertz *[1 1], [wavelengthAxis(1) wavelengthAxis(end)], 'r-','LineWidth', 2.0);
    plot(freqHalfHourlyOscillationInMilliHertz*[1 1], [wavelengthAxis(1) wavelengthAxis(end)], 'b-','LineWidth', 2.0);
    hold off;
    set(gca,  'CLim', [0 1]);
    set(gca, 'XLim', [freqAxisInMilliHertz(1) freqAxisInMilliHertz(end)/4]);
    set(gca, 'XScale', 'log');
    xlabel('frequency (milliHertz)');
    colormap(gray(1024));

    
    
    subplot(2,2,3);
    plot(freqAxisInMilliHertz, log10FTmag, 'k-');
    hold on;
    plot(freqHourlyOscillationInMilliHertz *[1 1], [-10 0], 'r-', 'LineWidth', 2.0);
    plot(freqHalfHourlyOscillationInMilliHertz*[1 1], [-10 0], 'b-','LineWidth', 2.0);
    hold off
    set(gca, 'XLim', [freqAxisInMilliHertz(1) freqAxisInMilliHertz(end)/4], 'YLim', [-4 0], 'YTick', -4:0);
    set(gca, 'XScale', 'log');
    xlabel('frequency (milliHertz)');
    ylabel('log10 FTmag');
    
    subplot(2,2,4);
    plot(freqAxisInMilliHertz, log10FTmagIndivBandNorm, 'k-');
    hold on;
    plot(freqHourlyOscillationInMilliHertz*[1 1], [-10 0], 'r-','LineWidth', 2.0);
    plot(freqHalfHourlyOscillationInMilliHertz*[1 1], [-10 0], 'b-','LineWidth', 2.0);
    hold off
    set(gca, 'XLim', [freqAxisInMilliHertz(1) freqAxisInMilliHertz(end)/4], 'YLim', [-4 0], 'YTick', -4:0);
    set(gca, 'XScale', 'log');
    xlabel('frequency (milliHertz)');
    ylabel('log10 FTmag');
    
    drawnow
    
end