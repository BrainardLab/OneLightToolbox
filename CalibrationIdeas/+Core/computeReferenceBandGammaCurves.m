function gamma = computeReferenceBandGammaCurves(effectiveSPDcomputationMethod, comboBandData, referenceBandData, interactingBandData, steadyBandsOnlySPD, steadyBandsActivation, darkSPD)

    gamma = containers.Map();
    
    if (strcmp(effectiveSPDcomputationMethod, 'Combo - Interacting'))
        
        % Pass-1: allocate memory
        theComboBandKeys = keys(comboBandData);
        for keyIndex = 1:numel(theComboBandKeys)
            key = theComboBandKeys{keyIndex};
            comboDataStruct = comboBandData(key);
            interactingDataStruct = interactingBandData(comboDataStruct.interactingBandKey);
            gammaKey = sprintf('interactingBandsSettingsIndex: %d, interactingBandsIndex: %d', interactingDataStruct.settingsIndex, interactingDataStruct.interactingBandsIndex);
            gamma(gammaKey) = struct(...
                'effectiveSPD',[], ...
                'effectiveActivation', [], ...
                'settingsValue', [], ...
                'primaryOut', [] ...
                );
        end
    
        % Pass-2: Compute effective SPD 
        for keyIndex = 1:numel(theComboBandKeys)
            key = theComboBandKeys{keyIndex};
            comboDataStruct = comboBandData(key);
            referenceDataStruct = referenceBandData(comboDataStruct.referenceBandKey);
            interactingDataStruct = interactingBandData(comboDataStruct.interactingBandKey);
            gammaKey = sprintf('interactingBandsSettingsIndex: %d, interactingBandsIndex: %d', interactingDataStruct.settingsIndex, interactingDataStruct.interactingBandsIndex);
            theGamma = gamma(gammaKey);
            theGamma.settingsValue(referenceDataStruct.settingsIndex) = referenceDataStruct.settingsValue;
            theGamma.effectiveSPD(referenceDataStruct.settingsIndex,:) = (comboDataStruct.meanSPD - darkSPD) - interactingDataStruct.meanSPD;
            theGamma.effectiveActivation(referenceDataStruct.settingsIndex,:) = comboDataStruct.activation - interactingDataStruct.activation;
            gamma(gammaKey) = theGamma;
        end
        
    elseif (strcmp(effectiveSPDcomputationMethod, 'Reference - Steady'))
        
        % Pass-1: allocate memory
        theReferenceBandKeys = keys(referenceBandData);
        for keyIndex = 1:numel(theReferenceBandKeys)
            key = theReferenceBandKeys{keyIndex};
            referenceDataStruct = referenceBandData(key);
            gammaKey = sprintf('reference band index: %d', referenceDataStruct.referenceBandIndex);
            gamma(gammaKey) = struct(...
                'effectiveSPD',[], ...
                'effectiveActivation', [], ...
                'settingsValue', [], ...
                'primaryOut', [] ...
                );
        end
        
        % Pass-2
        for keyIndex = 1:numel(theReferenceBandKeys)
            key = theReferenceBandKeys{keyIndex};
            referenceDataStruct = referenceBandData(key);
            gammaKey = sprintf('reference band index: %d', referenceDataStruct.referenceBandIndex);
            theGamma = gamma(gammaKey);
            theGamma.settingsValue(referenceDataStruct.settingsIndex) = referenceDataStruct.settingsValue;
            theGamma.effectiveSPD(referenceDataStruct.settingsIndex,:) = referenceDataStruct.meanSPD - steadyBandsOnlySPD;
            theGamma.effectiveActivation(referenceDataStruct.settingsIndex,:) = referenceDataStruct.activation - steadyBandsActivation;
            gamma(gammaKey) = theGamma;
        end
       
    else
       error('Unknown effectiveSPDcomputationMethod (''%s'')', effectiveSPDcomputationMethod);
    end  
    
    
    % Pass-3: compute SPD scalars (gammaOut)
    gammaKeys = keys(gamma);
    for keyIndex = 1:numel(gammaKeys)
        gammaKey = gammaKeys{keyIndex};
        theGamma = gamma(gammaKey);
        maxSettingsSPD = squeeze(theGamma.effectiveSPD(end,:));
        for settingsIndex = 1:size(theGamma.effectiveSPD,1)
            theGamma.primaryOut(settingsIndex) = squeeze(maxSettingsSPD)' \ squeeze(theGamma.effectiveSPD(settingsIndex,:))';
        end
        gamma(gammaKey) = theGamma;
    end
    
end
