% cal = TakeWigglyMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage)
%
% Takes wiggly spectrum measurements.
%
% 8/13/16   npc     Wrote it
% 9/29/16   npc     Optionally record temperature
%
function cal = TakeWigglyMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, varargin)

    p = inputParser;
    p.addParameter('takeTemperatureMeasurements', false, @islogical);
    % Execute the parser
    p.parse(varargin{:});
    takeTemperatureMeasurements = p.Results.takeTemperatureMeasurements;
    
    cal = cal0;
    nPrimaries = cal.describe.numWavelengthBands;

    % See if we need to take a new set of state measurements
    if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
        cal = OLCalibrator.TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, 'takeTemperatureMeasurements', takeTemperatureMeasurements);
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
    fprintf('Done\n');
end