% cal = TakeFullOnMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage)
%
% Takes full ON measurements.
%
% 8/13/16   npc     Wrote it

function cal = TakeFullOnMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage)

    cal = cal0;
    nPrimaries = cal.describe.numWavelengthBands;

    % See if we need to take a new set of state measurements
    if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
        cal = OLCalibrator.TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
    end

    % Update calibration stim index
    cal.describe.stateTracking.calibrationStimIndex = cal.describe.stateTracking.calibrationStimIndex + 1;
    fprintf('- Measurement #%d: Full ON pattern ...', cal.describe.stateTracking.calibrationStimIndex);
    theSettings = ones(nPrimaries,1);
    [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
    measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);

    cal.raw.fullOn(:,measurementIndex) = measTemp.pr650.spectrum;
    cal.raw.t.fullOn(:,measurementIndex) = measTemp.pr650.time(1);
    if (meterToggle(2))
        cal.raw.omniDriver.fullOnMeas(:,measurementIndex) = measTemp.omni.spectrum;
    end
    fprintf('Done\n');

end