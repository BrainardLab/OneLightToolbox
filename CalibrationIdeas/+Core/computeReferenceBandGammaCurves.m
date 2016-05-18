function gamma = computeReferenceBandGammaCurves(effectiveSPDcomputationMethod, comboBandData, referenceBandData, interactingBandData, steadyBandsOnlySPD, steadyBandsActivation, darkSPD)

    gamma = containers.Map();
    
    if (strcmp(effectiveSPDcomputationMethod, 'Combo - Interacting'))
        
        % Pass-1: allocate memory
        theComboBandKeys = keys(comboBandData);
        for keyIndex = 1:numel(theComboBandKeys)
            key = theComboBandKeys{keyIndex};
            comboDataStruct = comboBandData(key);
            interactingDataStruct = interactingBandData(comboDataStruct.interactingBandKey);
            gammaKey = sprintf('iBandsSettingsIndex: %d, iBandsIndex: %d', interactingDataStruct.settingsIndex, interactingDataStruct.interactingBandsIndex);
            gamma(gammaKey) = struct(...
                'effectiveSPDcomputationMethod', effectiveSPDcomputationMethod, ...
                'effectiveAllSPDs',[], ...
                'effectiveMeanSPD',[], ...
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
            gammaKey = sprintf('iBandsSettingsIndex: %d, iBandsIndex: %d', interactingDataStruct.settingsIndex, interactingDataStruct.interactingBandsIndex);
            theGamma = gamma(gammaKey);
            theGamma.settingsValue(referenceDataStruct.settingsIndex) = referenceDataStruct.settingsValue;
            for repeatIndex = 1:size(comboDataStruct.allSPDs,2)
                theGamma.effectiveAllSPDs(repeatIndex,referenceDataStruct.settingsIndex,:) = (comboDataStruct.allSPDs(:,repeatIndex) - darkSPD) - interactingDataStruct.meanSPD;
            end
            theGamma.effectiveMeanSPD(referenceDataStruct.settingsIndex,:) = (comboDataStruct.meanSPD - darkSPD) - interactingDataStruct.meanSPD;
            theGamma.effectiveMeanSPDComboComponent(referenceDataStruct.settingsIndex,:) = comboDataStruct.meanSPD - darkSPD;
            theGamma.effectiveMeanSPDInteractingComponent(referenceDataStruct.settingsIndex,:) = interactingDataStruct.meanSPD;
            theGamma.effectiveActivation(referenceDataStruct.settingsIndex,:) = comboDataStruct.activation - interactingDataStruct.activation;
            theGamma.actualActivation(referenceDataStruct.settingsIndex,:) = comboDataStruct.activation;
            gamma(gammaKey) = theGamma;
        end
        
    elseif (strcmp(effectiveSPDcomputationMethod, 'Reference - Steady'))
        
        % Pass-1: allocate memory
        theReferenceBandKeys = keys(referenceBandData);
        for keyIndex = 1:numel(theReferenceBandKeys)
            key = theReferenceBandKeys{keyIndex};
            referenceDataStruct = referenceBandData(key);
            gammaKey = sprintf('rBand index: %d', referenceDataStruct.referenceBandIndex);
            gamma(gammaKey) = struct(...
                'effectiveSPDcomputationMethod', effectiveSPDcomputationMethod, ...
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
            gammaKey = sprintf('rBand index: %d', referenceDataStruct.referenceBandIndex);
            theGamma = gamma(gammaKey);
            theGamma.settingsValue(referenceDataStruct.settingsIndex) = referenceDataStruct.settingsValue;
            for repeatIndex = 1:size(referenceDataStruct.allSPDs,2)
                theGamma.effectiveAllSPDs(repeatIndex,referenceDataStruct.settingsIndex,:) = referenceDataStruct.allSPDs(:,repeatIndex) - steadyBandsOnlySPD;
            end
            theGamma.effectiveMeanSPD(referenceDataStruct.settingsIndex,:) = referenceDataStruct.meanSPD - (steadyBandsOnlySPD - darkSPD);
            theGamma.effectiveMeanSPDComboComponent(referenceDataStruct.settingsIndex,:) = referenceDataStruct.meanSPD;
            theGamma.effectiveMeanSPDInteractingComponent(referenceDataStruct.settingsIndex,:) = steadyBandsOnlySPD - darkSPD;
            theGamma.effectiveActivation(referenceDataStruct.settingsIndex,:) = referenceDataStruct.activation - steadyBandsActivation;
            theGamma.actualActivation(referenceDataStruct.settingsIndex,:) = referenceDataStruct.activation;
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
        
        maxSettingsMeanSPD = squeeze(theGamma.effectiveMeanSPD(end,:));
        a = reshape(maxSettingsMeanSPD, [numel(maxSettingsMeanSPD) 1]);
        indices = find(a > 0.1*max(a));
        
        for settingsIndex = 1:size(theGamma.effectiveMeanSPD,1)
            theSettingsMeanSPD = squeeze(theGamma.effectiveMeanSPD(settingsIndex,:));
            b = reshape(theSettingsMeanSPD, [numel(theSettingsMeanSPD) 1]);
            theGamma.primaryOutMean(settingsIndex) = a(indices) \ b(indices);
        end
        
        for repeatIndex = 1:size(theGamma.effectiveAllSPDs,1)
            for settingsIndex = 1:size(theGamma.effectiveAllSPDs,2)
                theSettingsSingleTrialSPD = squeeze(theGamma.effectiveAllSPDs(repeatIndex,settingsIndex,:));
                b = reshape(theSettingsSingleTrialSPD, [numel(theSettingsSingleTrialSPD) 1]);
                theGamma.primaryOutSingleTrials(repeatIndex,settingsIndex) = a(indices) \ b(indices);
            end
        end
        gamma(gammaKey) = theGamma;
    end
    
end
