function OLAnalyzeTempCalFile

    rootDir = '/Volumes/DropBoxDisk/Dropbox/Dropbox (Aguirre-Brainard Lab)';
    approach = 'MELA_materials/Experiments/OLApproach_Psychophysics';
    temCalFile = 'OLBoxARandomizedLongCableAEyePiece3ND00_TMP.mat';
    
    load(fullfile(rootDir, approach, 'OneLightCalData', temCalFile), 'calProgression');
    
    entriesNum = numel(calProgression);
    powerFluctuationSPDs = [];
    
    for entryIndex = 1:entriesNum 
        d = calProgression{entryIndex};
        if (isempty(fieldnames(d)))
            fprintf('Event %d has an empty data struct\n', entryIndex);
        else
            fprintf('%d: %s\n', entryIndex-1, d.methodName);
            if (contains(d.methodName, 'TakeStateMeasurements - PowerFluctuation measurement'))
                if (isempty(powerFluctuationSPDs))
                    powerFluctuationSPDs = d.spdData.spectrum';
                else
                    powerFluctuationSPDs = cat(1,powerFluctuationSPDs, d.spdData.spectrum');
                end
            end
            if (contains(d.methodName, 'TakeStateMeasurements - PowerFluctuation measurement'))
                if (isempty(powerFluctuationSPDs))
                    powerFluctuationSPDs = d.spdData.spectrum';
                else
                    powerFluctuationSPDs = cat(1,powerFluctuationSPDs, d.spdData.spectrum');
                end
            end
            allSPDs(entryIndex,:) = d.spdData.spectrum;
            tempData = d.tempertureData;
            fieldnames(tempData)
            if (~isempty(fieldnames(tempData)))
                %tempData
            else
                tempData
            end
        end
    end
    
    figure(1);
    size(powerFluctuationSPDs)
    plot(1:size(allSPDs,2), powerFluctuationSPDs , 'k-');
    set(gca, 'XLim', [1 size(allSPDs,2)], 'YLim', [-0.01 0.15]);
end

