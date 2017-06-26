function dParams = MergeBaseParamsWithParamsFromDictionaryEntry(baseParams, paramsDictionary, dictionaryKey)
    % Check that requested directionName is valid and print available directions if it is not
    if (~paramsDictionary.isKey(dictionaryKey))
        availableKeys = keys(paramsDictionary);
        fprintf(2,'Dictionary contain the following entries:\n');
        for k = 1:numel(availableKeys)
            fprintf(2,'[%d] ''%s''\n', k, availableKeys{k});
        end
        error('''%s'' is not a valid modulation direction', dictionaryKey);
    end
    % Get the direction specific params
    specificParams = paramsDictionary(dictionaryKey);
    % Update the params
    dParams = baseParams;
    for fn = fieldnames(specificParams)'
        dParams.(fn{1}) = specificParams.(fn{1});
    end
end