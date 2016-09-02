% cal = TakeDarkMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage)
%
% Takes dark measurements.
%
% 8/13/16   npc     Wrote it

function cal = TakeDarkMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage)
    % Take a dark measurement at the end.  Use special case provided by OLSettingsToStartsStops that turns all mirrors off.
    cal = cal0;
    nPrimaries = cal.describe.numWavelengthBands;

    % See if we need to take a new set of state measurements
    if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
        cal = TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
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

    % See if we need to take a new set of state measurements
    if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
        cal = TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
    end

    % Update calibration stim index and take check dark measurement.
    % Use setAll(false) instead of our starts/stops code.
    cal.describe.stateTracking.calibrationStimIndex = cal.describe.stateTracking.calibrationStimIndex + 1;
    fprintf('- Measurement #%d: Dark (now using setAll(false) instead of starts/stops code) ...', cal.describe.stateTracking.calibrationStimIndex);
    ol.setAll(false);
    cal.raw.darkMeasCheck(:,measurementIndex) = spectroRadiometerOBJ.measure('userS', cal.describe.S);
    cal.raw.t.darkMeasCheck(:,measurementIndex) = mglGetSecs;
    fprintf('Done\n');

    spectroRadiometerOBJ.setOptions('sensitivityMode', 'STANDARD');
end
