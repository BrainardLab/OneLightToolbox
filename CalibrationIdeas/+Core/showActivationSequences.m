function showActivationSequences(randomizedSpectraIndices, data)

    nRepeats = size(randomizedSpectraIndices,1);
    nPrimariesNum = numel(data{1}.activation);
    nSpectraMeasured = numel(data);
    
    for repeatIndex = 1:nRepeats
        hFig = figure(1000+repeatIndex); clf;
        stimulationSequence = squeeze(randomizedSpectraIndices(repeatIndex,:));
        subplot('Position', [0.05 0.04 0.95 0.95]);
        % Show stimulation sequence for this repeat
        activationSequence = Core.retrieveActivationSequence(data, stimulationSequence);
        pcolor(1:nPrimariesNum, 1:nSpectraMeasured, activationSequence);
        xlabel('primary no');
        set(gca, 'CLim', [0 1], 'XLim', [1 nPrimariesNum], 'YLim', [0 nSpectraMeasured+1]);
        colormap(gray);
        title(sprintf('Repeat %d\n', repeatIndex));
    end
end

