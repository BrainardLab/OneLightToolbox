
function [allTemperatureData, stabilitySpectra, dateStrings, fileName] = retrieveData(obj, dataFile, theTargetCalType)

    allTemperatureData = [];
    dateStrings = {};
    stabilitySpectra = {};
    
    % Load the file
    fileName = fullfile(obj.rootDir, dataFile);
    s = load(fileName);

    availableCalTypes = fieldnames(s);
    if (isempty(theTargetCalType))
        theTargetCalType = availableCalTypes{1};
        if (numel(availableCalTypes)>1)
            fprintf(2,'Found more than 1 calTypes in that file. Analyzing the first one (''%s'')\n', theTargetCalType); 
            fprintf(2,'Cal types found:\n');
            for k = 1:numel(availableCalTypes)
                fprintf(2,'%d: ''%s''\n', k, availableCalTypes{k});
            end
            fprintf('Hit enter to continue\n');
            pause
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
    entriesNum = numel(s);
    
    fprintf('File ''%s'' contains %d entries\n', dataFile, entriesNum);

    % Attempt to extract temperature data
    for entryIndex = 1:entriesNum
        
        foundTemperatureData(entryIndex) = false;
        theMeasurementData = s{entryIndex}
        
        if (~isstruct(theMeasurementData))
            fprintf(2, ' ''theMeasurementData'' is not a struct. A struct is expected. Skipping ...\n');
        else
            if (isfield(theMeasurementData, 'temperatureData'))
                fprintf('A cache file ?\n');
                allTemperatureData(entryIndex,:,:,:) = theMeasurementData.temperatureData.modulationAllMeas;
                foundTemperatureData(entryIndex) = true;
                
            elseif (isfield(theMeasurementData, 'temperature'))
                fprintf('A spot check file ?\n');
                allFieldNames = fieldnames(theMeasurementData.temperature);
                for k = 1:numel(allFieldNames)
                    allTemperatureData(entryIndex,k,:,:) = theMeasurementData.temperature.(allFieldNames{k});
                end
                foundTemperatureData(entryIndex) = true;

                if (isempty(theMeasurementData.describe.calStateMeas))
                    fprintf(2, 'There were no state spectra saved in ''%s''.\n', dataFile);
                else
                    stabilitySpectra{entryIndex} = struct(...
                        'wavelengthSupport', SToWls(theMeasurementData.describe.S), ...
                        'powerFluctuationsData', theMeasurementData.describe.calStateMeas.raw.powerFluctuationMeas, ...
                        'spectraShiftsData', theMeasurementData.describe.calStateMeas.raw.spectralShiftsMeas ...
                        );
                end
                
            elseif (isfield(theMeasurementData, 'data'))
                fprintf('What kind of file is this?\n');
                theMeasurementData
                theMeasurementData.cal
                theMeasurementData.cal.describe
                theMeasurementData.cal.describe.stateTracking
                theMeasurementData.data
                theMeasurementData.data.describe
                
            elseif (isfield(theMeasurementData, 'raw')) && (isfield(theMeasurementData.raw, 'temperature'))
                fprintf('A calibration file ?\n');
                % This is a calibration file
                stabilitySpectra{entryIndex} = struct(...
                    'wavelengthSupport', SToWls(theMeasurementData.describe.S), ...
                	'powerFluctuationsData', theMeasurementData.raw.powerFluctuationMeas, ...
                	'spectraShiftsData', theMeasurementData.raw.spectralShiftsMeas ...
                    );

                allFieldNames = fieldnames(theMeasurementData.raw.temperature);
                if (ismember('value', allFieldNames))
                    allTemperatureData(entryIndex,1,:,:) = theMeasurementData.raw.temperature.value;
                    foundTemperatureData(entryIndex) = true;
                else
                    allFieldNames
                    error('Did not find ''value'' field.');
                end
            else 
                fprintf('[calibration index: %d]: There were no ''temperatureData'' or ''temperature'' fields found in ''theMeasurementData'' struct of ''%s''.\n', entryIndex, dataFile);
                theMeasurementData
            end
        end

        [stabilitySpectra{entryIndex}.combPeakTimeSeries, obj.combSPDActualPeaks{entryIndex}, stabilitySpectra{entryIndex}.gainTimeSeries] = obj.computeSpectralShiftTimeSeries(stabilitySpectra, entryIndex);
        
        if (isfield(theMeasurementData, 'date'))
            dateStrings{entryIndex} = theMeasurementData.date;
        elseif (isfield(theMeasurementData,'describe')) &&  (isfield(theMeasurementData.describe, 'validationDate'))
            dateStrings{entryIndex} = theMeasurementData.describe.validationDate;
        elseif (isfield(theMeasurementData, 'describe')) && (isfield(theMeasurementData.describe, 'date'))
            dateStrings{entryIndex} = theMeasurementData.describe.date;
        else
            dateStrings{entryIndex} = sprintf('unknown');
        end
    end % entryIndex
    
    if (any(foundTemperatureData) == 0)
        fprintf('None of the %d calibrations contain temperature data. Exiting\n', numel(s));
        return;
    end
  
    if (ndims(allTemperatureData) ~= 4)
        error('Something went wrong with the assumption of how temperature data are stored.\n');
    end
    clear 's'
end