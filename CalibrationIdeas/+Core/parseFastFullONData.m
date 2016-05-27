function parseFastFullONData(data, wavelengthAxis)

    stimPattern = 1;
    [passesNum, nAveragesPerPass, ~] = size(data{stimPattern}.measuredSPDallSpectraToBeAveraged);
    averageIter = 1:nAveragesPerPass;
    
    passIter = 1;
    % Resample so we are on a time axis with constant sampling
    timeAxis = data{stimPattern}.measuredSPDallSpectraToBeAveragedTimes(passIter, averageIter);
    spectroTemporalResponse = squeeze(data{stimPattern}.measuredSPDallSpectraToBeAveraged(passIter, averageIter,:));
    
    diffTimeAxis = diff(timeAxis);
    uniformTimeAxis = timeAxis(1):min(diffTimeAxis):timeAxis(end);
    uniformTimeAxisSpectroTemporalResponse = zeros(numel(uniformTimeAxis), size(spectroTemporalResponse,2));
    for bandNo = 1:size(spectroTemporalResponse,2)
        uniformTimeAxisSpectroTemporalResponse(:,bandNo) = interp1(timeAxis, squeeze(spectroTemporalResponse(:,bandNo), uniformTimeAxis), 'linear');
    end
    
    spectroTemporalResponse = spectroTemporalResponse';
    uniformTimeAxisSpectroTemporalResponse = uniformTimeAxisSpectroTemporalResponse';
    size(spectroTemporalResponse)
    
    
    spdGain = 1000;
    figure(1)
    subplot(2,1,1);
    imagesc(timeAxis, wavelengthAxis, spdGain*spectroTemporalResponse);
    set(gca, 'XLim', [timeAxis(1) timeAxis(end)]);
    colorbar
    
    subplot(2,1,2);
    imagesc(uniformTimeAxis, wavelengthAxis, spdGain*uniformTimeAxisSpectroTemporalResponse);
    set(gca, 'XLim', [timeAxis(1) timeAxis(end)]);
    colorbar
    colormap(gray(1024));
    drawnow
    
    
    
    spectroTemporalResponseDiffs = bsxfun(@minus, uniformTimeAxisSpectroTemporalResponse, uniformTimeAxisSpectroTemporalResponse(:,1));
    
    t0 = (max(uniformTimeAxis)-min(uniformTimeAxis))/2 + min(uniformTimeAxis);
    sigma = (max(uniformTimeAxis)-min(uniformTimeAxis))/(2*3);
    envelope = exp(-0.5*((uniformTimeAxis-t0)/sigma).^2);
    
    for bandNo = 1:size(uniformTimeAxisSpectroTemporalResponse,1)
        tmp = squeeze(uniformTimeAxisSpectroTemporalResponse(bandNo,:)) .* envelope;
        FTmag = abs(fft(tmp,2048));
    end
    
    
    
    
    
    
    spdGain = 1000;
    figure()
    subplot(2,1,1);
    imagesc(timeAxis, wavelengthAxis, spdGain*(spectroTemporalResponse)');
    colorbar
    
    subplot(2,1,2);
    imagesc(timeAxis, wavelengthAxis, spdGain*(spectroTemporalResponseDiffs)');
    colorbar
    colormap(gray(1024));
    drawnow
    
end