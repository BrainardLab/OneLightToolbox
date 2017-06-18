function activationSequence = retrieveActivationSequence(data, presentationIndices)  
    activationSequence = zeros(numel(presentationIndices), numel(data{1}.activation));
    for spectrumIter = 1:numel(presentationIndices)
        % Get presentation index
        spectrumIndex = presentationIndices(spectrumIter);
        activationSequence(spectrumIter,:) = data{spectrumIndex}.activation;
    end
end