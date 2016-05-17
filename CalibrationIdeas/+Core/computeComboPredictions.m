function  [comboBandData, maxSPD] = computeComboPredictions(originalComboBandData, referenceBandData, interactingBandData, darkSPD)
    comboBandData = originalComboBandData;
    
    theComboKeys = keys(comboBandData);
    maxSPD = 0;
    
    for keyIndex = 1:numel(theComboKeys)
        key = theComboKeys{keyIndex};
        comboDataStruct = comboBandData(key);
        
        % deviations of each single trial from the mean SPD
        allSPDdiffs = abs(bsxfun(@minus, comboDataStruct.allSPDs, comboDataStruct.meanSPD));
        comboDataStruct.allSPDmaxDeviationsFromMean = squeeze(max(allSPDdiffs,[],1));
        
        % compute prediction SPD
        referenceDataStruct = referenceBandData(comboDataStruct.referenceBandKey);
        interactingDataStruct = interactingBandData(comboDataStruct.interactingBandKey);
        
        
        figure(123);
        subplot(3,1,1);
        bar(1:numel(comboDataStruct.activation), comboDataStruct.activation, 1)
        set(gca, 'YLim', [0 1]);
        title(sprintf('Combo activation (ref settings: %2.1f, interacting settings: %2.1f)', referenceDataStruct.settingsValue, interactingDataStruct.settingsValue));
        
        subplot(3,1,2);
        bar(1:numel(referenceDataStruct.activation), referenceDataStruct.activation, 1)
        set(gca, 'YLim', [0 1]);
        title('reference activation');
        
        subplot(3,1,3);
        bar(1:numel(interactingDataStruct.activation), interactingDataStruct.activation, 1)
        set(gca, 'YLim', [0 1]);
        title('interacting activation');
        pause
        
        comboDataStruct.predictionSPD = darkSPD + referenceDataStruct.meanSPD + interactingDataStruct.meanSPD;
       
        % compute maxSPD
        thisMax = max([max(comboDataStruct.predictionSPD) max(comboDataStruct.meanSPD)]);
        if (thisMax > maxSPD)
            maxSPD = thisMax;
        end
        comboBandData(key) = comboDataStruct;
    end
end

