% cal = TakeWigglyMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, varargin)
%
% Takes wiggly spectrum measurements.
%
% 8/13/16   npc     Wrote it
% 9/29/16   npc     Optionally record temperature
% 12/21/16  npc     Updated for new class @LJTemperatureProbe
% 06/13/18  npc     Updated with option to save progression of cal

function cal = TakeWigglyMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, varargin)

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
    
    cal = cal0;
    nPrimaries = cal.describe.numWavelengthBands;

    % See if we need to take a new set of state measurements
    if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
        cal = OLCalibrator.TakeStateMeasurements(cal, ol, od, ...
            spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, ...
            'takeTemperatureMeasurements', takeTemperatureMeasurements, ...
            'calProgressionTemporaryFileName', calProgressionTemporaryFileName);
    end

    % Update calibration stim index
    cal.describe.stateTracking.calibrationStimIndex = cal.describe.stateTracking.calibrationStimIndex + 1;
    fprintf('- Measurement #%d: Wiggly pattern ...', cal.describe.stateTracking.calibrationStimIndex);
    theSettings = 0.1*ones(nPrimaries,1);
    theSettings(2:8:end) = 0.8;
    [starts,stops] = OLSettingsToStartsStops(cal,theSettings);

    measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
    cal.raw.wigglyMeas.settings(:,measurementIndex) = theSettings;
    cal.raw.wigglyMeas.measSpd(:,measurementIndex) = measTemp.pr650.spectrum;
    cal.raw.t.wigglyMeas.t(:,measurementIndex) = measTemp.pr650.time(1);
    if (meterToggle(2))
        cal.raw.omniDriver.wigglyMeas(:,measurementIndex) = measTemp.omni.spectrum;
    end
    
    if (~isempty(calProgressionTemporaryFileName))
        % make spdData struct
        spdData = struct(...
            'time', measTemp.pr650.time(1), ...
            'spectrum', measTemp.pr650.spectrum);
        
        % empty temperature struct as we do not collect tempoeratures in this method
        temperatureData = struct();
        
        methodName = sprintf('Completed %s', mfilename());
        OLCalibrator.SaveCalProgressionData(...
            calProgressionTemporaryFileName, methodName, ...
            spdData, temperatureData);
    end
    
    fprintf('Done\n');
end