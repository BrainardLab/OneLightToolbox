% cal = TakeIndependenceMeasurements(cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, varargin)
%
% Takes SPD measurements to assess primary independence
%
% 8/13/16   npc     Wrote it
% 9/29/16   npc     Optionally record temperature
% 12/21/16  npc     Updated for new class @LJTemperatureProbe
% 06/13/18  npc     Updated with option to save progression of cal

function cal = TakeIndependenceMeasurements(cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, varargin)

    p = inputParser;
    p.addParameter('takeTemperatureMeasurements', false, @islogical);
    p.addParameter('calProgressionTemporaryFileName', '', @ischar);
    
    % Execute the parser
    p.parse(varargin{:});
    takeTemperatureMeasurements = p.Results.takeTemperatureMeasurements;
    calProgressionTemporaryFileName = p.Results.calProgressionTemporaryFileName;
    
    if (~isempty(calProgressionTemporaryFileName))
        % make spdData struct
        spdData = struct();

        % empty temperature struct as we do not collect temperatures in this method
        temperatureData = struct();

        methodName = sprintf('Starting %s - Independence measurement', mfilename());
        OLCalibrator.SaveCalProgressionData(...
            calProgressionTemporaryFileName, methodName, ...
            spdData, temperatureData);
    end
    
    cal = cal0;
    nPrimaries = cal.describe.numWavelengthBands;

    fprintf('\n<strong>Independence Test</strong>\n\n');
    % Store some measurement data regarding the independence test.
    cal.describe.independence.gammaBands = cal.describe.gamma.gammaBands;
    cal.describe.independence.nGammaBands = cal.describe.nGammaBands;
    cal.raw.independence.cols = zeros(ol.NumCols, cal.describe.nGammaBands);

    % Test column sets individually
    for i = 1:cal.describe.independence.nGammaBands

        % See if we need to take a new set of state measurements
        if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
            cal = OLCalibrator.TakeStateMeasurements(cal, ol, od, ...
                spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, ...
                'takeTemperatureMeasurements', takeTemperatureMeasurements, ...
                'calProgressionTemporaryFileName', calProgressionTemporaryFileName);
        end

        % Update calibration stim index
        cal.describe.stateTracking.calibrationStimIndex = cal.describe.stateTracking.calibrationStimIndex + 1;
        fprintf('- Measurement #%d: column set %d of %d ...', cal.describe.stateTracking.calibrationStimIndex, i, cal.describe.independence.nGammaBands);

        % Store column set used for this measurement.
        cal.raw.independence.cols(:,i) = cal.raw.cols(:,cal.describe.independence.gammaBands(i));

        % Take a measurement.  Here we are ignoring the specified
        % background.
        if (cal.describe.specifiedBackground)
            theSettings = zeros(nPrimaries,1);
        else
            theSettings = zeros(nPrimaries,1);
        end
        theSettings(cal.describe.independence.gammaBands(i)) = 1;
        [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
        measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
        cal.raw.independence.meas(:,i) = measTemp.pr650.spectrum;
        cal.raw.t.independence.meas(i) = measTemp.pr650.time(1);
        if (meterToggle(2))
            cal.raw.independence.measOD(:,i) = measTemp.omni.spectrum;
        end
        fprintf('Done\n');
        
        if (~isempty(calProgressionTemporaryFileName))
            % make spdData struct
            spdData = struct(...
                'time', measTemp.pr650.time(1), ...
                'spectrum', measTemp.pr650.spectrum);

            % empty temperature struct as we do not collect temperatures in this method
            temperatureData = struct();

            methodName = sprintf('Completed %s - Independence measurement (column #%d/%d)', mfilename(), i, cal.describe.independence.nGammaBands);
            OLCalibrator.SaveCalProgressionData(...
                calProgressionTemporaryFileName, methodName, ...
                spdData, temperatureData);
        end
    end

    % See if we need to take a new set of state measurements
    if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
        cal = OLCalibrator.TakeStateMeasurements(cal, ol, od, ...
            spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, ...
            'takeTemperatureMeasurements', takeTemperatureMeasurements, ...
            'calProgressionTemporaryFileName', calProgressionTemporaryFileName);
    end

    % Update calibration stim index
    cal.describe.stateTracking.calibrationStimIndex = cal.describe.stateTracking.calibrationStimIndex + 1;

    % Now take a cumulative measurement.
    fprintf('- Measurement #%d: cumulative column sets ...', cal.describe.stateTracking.calibrationStimIndex);

    cal.raw.independence.colsAll = sum(cal.raw.independence.cols, 2);
    if (cal.describe.specifiedBackground)
        theSettings = zeros(nPrimaries,1);
    else
        theSettings = zeros(nPrimaries,1);
    end
    for i = 1:cal.describe.independence.nGammaBands
        theSettings(cal.describe.independence.gammaBands(i)) = 1;
    end
    [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
    measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
    cal.raw.independence.measAll = measTemp.pr650.spectrum;
    cal.raw.t.independence.measAll = measTemp.pr650.time(1);
    if (meterToggle(2))
        cal.raw.independence.measODAll = measTemp.omni.spectrum;
    end
    fprintf('Done\n');

    if (~isempty(calProgressionTemporaryFileName))
        % make spdData struct
        spdData = struct(...
            'time', measTemp.pr650.time(1), ...
            'spectrum', measTemp.pr650.spectrum);

        % empty temperature struct as we do not collect temperatures in this method
        temperatureData = struct();

        methodName = sprintf('Completed %s - Independence measurement (cumulative)', mfilename());
        OLCalibrator.SaveCalProgressionData(...
            calProgressionTemporaryFileName, methodName, ...
            spdData, temperatureData);
    end
        
end

