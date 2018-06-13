% cal = TakeDarkMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, varargin)
%
% Takes dark measurements.
%
% 8/13/16   npc     Wrote it
% 9/29/16   npc     Optionally record temperature
% 12/21/16  npc     Updated for new class @LJTemperatureProbe
% 06/13/18  npc     Updated with option to save progression of cal

function cal = TakeDarkMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, varargin)
    
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
        
        % empty temperature struct as we do not collect tempoeratures in this method
        temperatureData = struct();
        
        methodName = sprintf('Starting %s', mfilename());
        OLCalibrator.SaveCalProgressionData(...
            calProgressionTemporaryFileName, methodName, ...
            spdData, temperatureData);
    end
    
    % Take a dark measurement at the end.  Use special case provided by OLSettingsToStartsStops that turns all mirrors off.
    cal = cal0;
    nPrimaries = cal.describe.numWavelengthBands;

    % See if we need to take a new set of state measurements
    if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
        cal = OLCalibrator.TakeStateMeasurements(cal, ol, od, ...
            spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, ...
            'takeTemperatureMeasurements', takeTemperatureMeasurements, ...
            'calProgressionTemporaryFileName', calProgressionTemporaryFileName);
    end

    % Update calibration stim index and take dark measurement
    cal.describe.stateTracking.calibrationStimIndex = cal.describe.stateTracking.calibrationStimIndex + 1;
    fprintf('- Measurement #%d: Dark...', cal.describe.stateTracking.calibrationStimIndex);
    spectroRadiometerOBJ.setOptions('sensitivityMode', 'EXTENDED');
    theSettings = 0*ones(nPrimaries,1);
    [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
    measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
    cal.raw.darkMeas(:,measurementIndex) = measTemp.pr650.spectrum;
    cal.raw.t.darkMeas(:,measurementIndex) = measTemp.pr650.time(1);
    if (meterToggle(2))
        cal.raw.omniDriver.darkMeas(:,measurementIndex) = measTemp.omni.spectrum;
    end
    fprintf('Done\n');
    
    if (~isempty(calProgressionTemporaryFileName))
        % make spdData struct
        spdData = struct(...
            'time', measTemp.pr650.time(1), ...
            'spectrum', measTemp.pr650.spectrum);
        
        % empty temperature struct as we do not collect tempoeratures in this method
        temperatureData = struct();
        
        methodName = sprintf('Completed %s (1/2)', mfilename());
        OLCalibrator.SaveCalProgressionData(...
            calProgressionTemporaryFileName, methodName, ...
            spdData, temperatureData);
    end
    
    % See if we need to take a new set of state measurements
    if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
        cal = OLCalibrator.TakeStateMeasurements(cal, ol, od, ...
            spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, ...
            'calProgressionTemporaryFileName', calProgressionTemporaryFileName);
    end

    % Update calibration stim index and take check dark measurement.
    % Use setAll(false) instead of our starts/stops code.
    cal.describe.stateTracking.calibrationStimIndex = cal.describe.stateTracking.calibrationStimIndex + 1;
    fprintf('- Measurement #%d: Dark (now using setAll(false) instead of starts/stops code) ...', cal.describe.stateTracking.calibrationStimIndex);
    ol.setAll(false);
    cal.raw.darkMeasCheck(:,measurementIndex) = spectroRadiometerOBJ.measure('userS', cal.describe.S);
    cal.raw.t.darkMeasCheck(:,measurementIndex) = mglGetSecs;
    spectroRadiometerOBJ.setOptions('sensitivityMode', 'STANDARD');
    
    fprintf('Done\n');
    
    if (~isempty(calProgressionTemporaryFileName))
        % make spdData struct
        spdData = struct(...
            'time', squeeze(cal.raw.t.darkMeasCheck(:,measurementIndex)), ...
            'spectrum', squeeze(cal.raw.darkMeasCheck(:,measurementIndex)));
        
        % empty temperature struct as we do not collect tempoeratures in this method
        temperatureData = struct();
        
        methodName = sprintf('Completed %s - CheckDark (2/2)', mfilename());
        OLCalibrator.SaveCalProgressionData(...
            calProgressionTemporaryFileName, methodName, ...
            spdData, temperatureData);
    end
    
end
