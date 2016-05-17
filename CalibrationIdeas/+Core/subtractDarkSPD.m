function dataDictionary = subtractDarkSPD(rawDataDictionary, darkSPD)

    dataDictionary = rawDataDictionary;

    theKeys = keys(dataDictionary);
    for keyIndex = 1:numel(theKeys)
        key = theKeys{keyIndex};
        s = dataDictionary(key);
        
        % compute deviations of each single trial from the mean SPD
        allSPDdiffs = abs(bsxfun(@minus, s.allSPDs, s.meanSPD));
        s.allSPDmaxDeviationsFromMean = squeeze(max(allSPDdiffs,[],1));
        
        % compute darkSPD subtracted SPDs
        s.meanSPD = s.meanSPD - darkSPD;
        s.minSPD = s.minSPD - darkSPD;
        s.maxSPD = s.maxSPD - darkSPD;
        
        dataDictionary(key) = s;
    end


end

