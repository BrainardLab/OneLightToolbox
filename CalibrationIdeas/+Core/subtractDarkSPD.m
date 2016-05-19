function dataDictionary = subtractDarkSPD(rawDataDictionary, darkSPD)

    dataDictionary = rawDataDictionary;

    theKeys = keys(dataDictionary);
    for keyIndex = 1:numel(theKeys)
        
        key = theKeys{keyIndex};
        s = dataDictionary(key);
        
        % compute darkSPD subtracted SPDs
        s.meanSPD = s.meanSPD - darkSPD;
        s.minSPD = s.minSPD - darkSPD;
        s.maxSPD = s.maxSPD - darkSPD;
        
        dataDictionary(key) = s;
    end


end

