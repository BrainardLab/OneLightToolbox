function showActivationSequences(randomizedSpectraIndices, data)

    nRepeats = size(randomizedSpectraIndices,1);
    nPrimariesNum = numel(data{1}.activation);
    nSpectraMeasured = numel(data);
    
    hFig = figure(10); clf;
    width = 0.9/nRepeats;
    for repeatIndex = 1:nRepeats
        stimulationSequence = squeeze(randomizedSpectraIndices(repeatIndex,:));
        subplot('Position', [0.04+(repeatIndex-1)*(width+0.01) 0.04 width 0.95]);
        % Show stimulation sequence for this repeat
        pcolor(1:nPrimariesNum, 1:nSpectraMeasured, Core.retrieveActivationSequence(data, stimulationSequence));
        xlabel('primary no');
        set(gca, 'CLim', [0 1], 'XLim', [1 nPrimariesNum], 'YLim', [0 nSpectraMeasured+1], 'YTick', []);
        colormap(gray);
        title(sprintf('Repeat %d\n', repeatIndex));
    end
end

