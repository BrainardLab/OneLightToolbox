function parseFastFullONData(data, wavelengthAxis)

    stimPattern = 1;
    [passesNum, nAveragesPerPass, ~] = size(data{stimPattern}.measuredSPDallSpectraToBeAveraged);
    averageIter = 1:nAveragesPerPass;
    
    passIter = 1;
    spectroTemporalResponse = squeeze(data{stimPattern}.measuredSPDallSpectraToBeAveraged(passIter, averageIter,:));
    spectroTemporalResponseDiffs = bsxfun(@minus, spectroTemporalResponse, spectroTemporalResponse(1,:));
   % timeAxis = data{stimPattern}.measuredSPDallSpectraToBeAveragedTimes(passIter, averageIter);
    timeAxis = 1:nAveragesPerPass;
    
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