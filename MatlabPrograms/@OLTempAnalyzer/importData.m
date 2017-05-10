function importData(obj)

    [obj.calData.allTemperatureData, obj.calData.DateStrings, obj.calData.fullFileName] = retrieveTemperatureData(obj, obj.calibrationFile, 'cals');
    [obj.testData.allTemperatureData, obj.testData.DateStrings, obj.testData.fullFileName] = retrieveTemperatureData(obj, obj.testFile, []);

end

function [allTemperatureData, dateStrings, fileName] = retrieveTemperatureData(obj, dataFile, theTargetCalType)

    allTemperatureData = [];
    dateStrings = {};
    
    % Load the file
    fileName = fullfile(obj.rootDir, dataFile);
    s = load(fileName);
    
    availableCalTypes = fieldnames(s);
    if (isempty(theTargetCalType))
        theTargetCalType = availableCalTypes{1};
        if (numel(availableCalTypes)>1)
            fprintf(2,'Found more than 1 calTypes in that file. Analyzing the first one (''%s'')\n', theTargetCalType);  
        end
    else
        if (~ismember(theTargetCalType, availableCalTypes))
            fprintf(2,'''%s'' cal type not found in ''%s''.\n', theTargetCalType, fullfile(pathName,theValidationCacheFile));
            fprintf(2,'Cal types found:\n');
            for k = 1:numel(availableCalTypes)
                fprintf(2,'%d: ''%s''\n', k, availableCalTypes{k});
            end
            return
        end
    end
    s = s.(theTargetCalType);

    % Attempt to extract temperature data
    for calibrationIndex = 1:numel(s)
        foundTemperatureData(calibrationIndex) = false;
        
        theMeasurementData = s{calibrationIndex};
        if (~isstruct(theMeasurementData))
            fprintf(2, ' ''theMeasurementData'' is not a struct. A struct is expected. Skipping ...\n');
        else
            if (isfield(theMeasurementData, 'temperatureData'))
                allTemperatureData(calibrationIndex,:,:,:) = theMeasurementData.temperatureData.modulationAllMeas;
                foundTemperatureData(calibrationIndex) = true;
            elseif (isfield(theMeasurementData, 'temperature'))
                allFieldNames = fieldnames(theMeasurementData.temperature);
                for k = 1:numel(allFieldNames)
                    allTemperatureData(calibrationIndex,k,:,:) = theMeasurementData.temperature.(allFieldNames{k});
                end
                foundTemperatureData(calibrationIndex) = true;
            elseif (isfield(theMeasurementData, 'raw')) && (isfield(theMeasurementData.raw, 'temperature'))
                allFieldNames = fieldnames(theMeasurementData.raw.temperature);
                if (ismember('value', allFieldNames))
                    allTemperatureData(calibrationIndex,1,:,:) = theMeasurementData.raw.temperature.value;
                    foundTemperatureData(calibrationIndex) = true;
                else
                    allFieldNames
                    error('Did not find ''value'' field.');
                end
            else 
                fprintf('[calibration index: %d]: There were no ''temperatureData'' or ''temperature'' fields found in ''theMeasurementData'' struct of ''%s''.\n', calibrationIndex, fullfile(pathName,theValidationCacheFile));
                theMeasurementData
            end
        end
        
        if (isfield(theMeasurementData, 'date'))
            dateStrings{calibrationIndex} = sprintf('%s\nDate:%s', strrep(theTargetCalType, '_', ''),theMeasurementData.date);
        elseif (isfield(theMeasurementData,'describe')) &&  (isfield(theMeasurementData.describe, 'validationDate'))
            dateStrings{calibrationIndex} = sprintf('%s\nDate:%s', strrep(theTargetCalType, '_', ''), theMeasurementData.describe.validationDate);
        elseif (isfield(theMeasurementData, 'describe')) && (isfield(theMeasurementData.describe, 'date'))
            dateStrings{calibrationIndex} = sprintf('%s\nDate:%s', strrep(theTargetCalType, '_', ''), theMeasurementData.describe.date);
        else
            dateStrings{calibrationIndex} = sprintf('%s\nDate: could not be determined from the data file. Contact Nicolas.\n', strrep(theTargetCalType, '_', ''));
        end
        
    end
    
    if (any(foundTemperatureData) == 0)
        fprintf('None of the %d calibrations contain temperature data. Exiting\n', numel(s));
        return;
    end
  
    if (ndims(allTemperatureData) ~= 4)
        error('Something went wrong with the assumption of how temperature data are stored.\n');
    end
    clear 's'
end


