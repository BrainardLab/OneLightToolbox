function [referenceBandData, interactingBandData, comboBandData, ...
    allSingletonSPDrKeys, allSingletonSPDiKeys,allComboKeys, ...
    darkSPD, darkSPDrange, steadyBandsOnlySPD, steadyBandsOnlySPDrange] = parseData(data, referenceBands, referenceBandSettingsLevels, interactingBands, interactingBandSettingsLevels)

    interactingBandData = containers.Map;
    referenceBandData = containers.Map;
    comboBandData = containers.Map;
    
    allComboKeys = {};
    allSingletonSPDiKeys = {};
    allSingletonSPDrKeys = {};
    
    nSpectraMeasured = numel(data);
    for spectrumIndex = 1:nSpectraMeasured
        
        % average over all reps
        data{spectrumIndex}.meanSPD = mean(data{spectrumIndex}.measuredSPD, 2);

        % compute min over all reps
        data{spectrumIndex}.minSPD  = min(data{spectrumIndex}.measuredSPD, [], 2);
        
        % compute max over all reps
        data{spectrumIndex}.maxSPD  = max(data{spectrumIndex}.measuredSPD, [], 2);
        
        referenceBandIndex = data{spectrumIndex}.referenceBandIndex;
        interactingBandsIndex = data{spectrumIndex}.interactingBandsIndex;
        referenceBandSettingsIndex = data{spectrumIndex}.referenceBandSettingsIndex;
        interactingBandSettingsIndex = data{spectrumIndex}.interactingBandSettingsIndex;
        
        if (isempty(interactingBandsIndex))
            theInteractingBands = [];
        else
            theInteractingBands = interactingBands{interactingBandsIndex}; 
        end
        theReferenceBand = referenceBands(data{spectrumIndex}.referenceBandIndex);
        
        % Extract data
        dataStruct = struct(...
            'referenceBandIndex',    data{spectrumIndex}.referenceBandIndex, ...
            'interactingBandsIndex', data{spectrumIndex}.interactingBandsIndex, ...
            'activation',            data{spectrumIndex}.activation, ...
            'settingsValue',         [], ...
            'settingsIndex',         [], ...
            'meanSPD',               data{spectrumIndex}.meanSPD, ...
            'minSPD',                data{spectrumIndex}.minSPD, ...
            'maxSPD',                data{spectrumIndex}.maxSPD, ...
            'allSPDs',               data{spectrumIndex}.measuredSPD, ...
            'allSPDtimes',           squeeze(data{spectrumIndex}.measurementTime(1, :)), ...
            'allSPDmaxDeviationsFromMean', [] ...
            );
        
        spdType = data{spectrumIndex}.spdType;
        switch (spdType)
            
            case 'singletonSPDi'   
                % add spdType-specific data
                dataStruct.settingsValue = interactingBandSettingsLevels(data{spectrumIndex}.interactingBandSettingsIndex);
                dataStruct.settingsIndex = data{spectrumIndex}.interactingBandSettingsIndex;
            
                % Generate dictionary key
                interactingBandsForThisCondition = theReferenceBand+theInteractingBands;
                interactingBandsString = sprintf('%d \n', interactingBandsForThisCondition);
                key = sprintf('activationIndex: %d, bands: %s', interactingBandSettingsIndex, interactingBandsString);
                
                % add to dictionary
                interactingBandData(key) = dataStruct;
                
                % Sort keys
                allSingletonSPDiKeys{numel(allSingletonSPDiKeys)+1} = key; 
                
            case 'singletonSPDr'
                % add spdType-specific data
                dataStruct.settingsValue = referenceBandSettingsLevels(data{spectrumIndex}.referenceBandSettingsIndex);
                dataStruct.settingsIndex = data{spectrumIndex}.referenceBandSettingsIndex;
                dataStruct.referenceBandIndex = data{spectrumIndex}.referenceBandIndex;
                
                % Generate dictionary key
                referenceBandsString = sprintf('%d \n', theReferenceBand);
                key = sprintf('activationIndex: %d, bands: %s', referenceBandSettingsIndex, referenceBandsString);
                
                % Add to dictionary
                referenceBandData(key) = dataStruct;
                
                % Sort keys
                allSingletonSPDrKeys{numel(allSingletonSPDrKeys)+1} = key;
            
            case 'comboSPD'
                % Get interacting bands for this combo
                interactingBandsForThisCondition = theReferenceBand+theInteractingBands;
                interactingBandsString = sprintf('%d \n', interactingBandsForThisCondition);
                referenceBandsString = sprintf('%d \n', theReferenceBand);
                
                % add spdType-specific data
                dataStruct.settingsValue        = referenceBandSettingsLevels(data{spectrumIndex}.referenceBandSettingsIndex);
                dataStruct.settingsIndex        = data{spectrumIndex}.referenceBandSettingsIndex;
                dataStruct.referenceBandKey     = sprintf('activationIndex: %d, bands: %s', referenceBandSettingsIndex, referenceBandsString);
                dataStruct.interactingBandKey   = sprintf('activationIndex: %d, bands: %s', interactingBandSettingsIndex, interactingBandsString);
                dataStruct.predictionSPD        = [];
                
                % Generate dictionary key
                key = sprintf('activationIndices: [Reference=%d, Interacting=%d], Reference bands:%s Interacting bands:%s', referenceBandSettingsIndex, interactingBandSettingsIndex, referenceBandsString, interactingBandsString);
      
                % Add to dictionary
                comboBandData(key) = dataStruct;
                
                % Sort keys so we get gamma data for each condition
                comboKeyIndex = (referenceBandIndex-1) * (numel(interactingBands)) * (numel(interactingBandSettingsLevels)) * (numel(referenceBandSettingsLevels)) + ...
                            (interactingBandsIndex-1) * (numel(interactingBandSettingsLevels)) * (numel(referenceBandSettingsLevels)) + ...
                            (interactingBandSettingsIndex-1) * numel(referenceBandSettingsLevels) + referenceBandSettingsIndex;
                allComboKeys{comboKeyIndex} = key; 
                
            case 'steadyBandsOnly'
                steadyBandsOnlySPD = data{spectrumIndex}.meanSPD;
                steadyBandsOnlySPDrange(1,:) = data{spectrumIndex}.minSPD;
                steadyBandsOnlySPDrange(2,:) = data{spectrumIndex}.maxSPD;
                
            case 'dark'
                darkSPD = data{spectrumIndex}.meanSPD;
                darkSPDrange(1,:) = data{spectrumIndex}.minSPD;
                darkSPDrange(2,:) = data{spectrumIndex}.maxSPD;
                
            case 'temporalStabilityGauge1SPD'
                ; % do nothing 
                
            case 'temporalStabilityGauge2SPD'
                ; % do nothing 
        end % switch
        
    end % spectrumIndex
    
    if (~exist('steadyBandsOnlySPD', 'var'))
        fprintf(2,'Did not find ''steadyBandsOnly'' spd data. Using all zeros. PLEASE CHECK YOUR PROGRAM TO MAKE SURE THERE IS NO STEADY BANDS INDEED.\n');
        fprintf(2,'Hit enter to continue\n');
        pause;
        steadyBandsOnlySPD = darkSPD*0;
        steadyBandsOnlySPDrange(1,:) = steadyBandsOnlySPD;
        steadyBandsOnlySPDrange(2,:) = steadyBandsOnlySPD;
    end
    
end
