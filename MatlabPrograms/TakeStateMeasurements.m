function [cal calMeasOnly] = TakeStateMeasurements(cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, mergeCalStruct)
% [cal calMeasOnly] = TakeStateMeasurements(cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, mergeCalStruct)
%
% Takes state measurements for a OneLight calibration.
%
% 7/xx/16   npc     Written.

cal = cal0;
cal.describe.stateTracking.stateMeasurementIndex = cal.describe.stateTracking.stateMeasurementIndex + 1;

fprintf('-- Power fluctuation state measurement #%d ...', cal.describe.stateTracking.stateMeasurementIndex);
theSettings = cal.describe.stateTracking.stimSettings.powerFluctuationsStim;
[starts,stops] = OLSettingsToStartsStops(cal,theSettings);
measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
cal.raw.powerFluctuationMeas.measSpd(:, cal.describe.stateTracking.stateMeasurementIndex) = measTemp.pr650.spectrum;
cal.raw.powerFluctuationMeas.t(:, cal.describe.stateTracking.stateMeasurementIndex) = measTemp.pr650.time(1);
fprintf('Done\n');

fprintf('-- Spectral shift state measurement #%d    ...', cal.describe.stateTracking.stateMeasurementIndex);
theSettings = cal.describe.stateTracking.stimSettings.spectralShiftsStim;
[starts,stops] = OLSettingsToStartsStops(cal,theSettings);
measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
cal.raw.spectralShiftsMeas.measSpd(:, cal.describe.stateTracking.stateMeasurementIndex) = measTemp.pr650.spectrum;
cal.raw.spectralShiftsMeas.t(:, cal.describe.stateTracking.stateMeasurementIndex) = measTemp.pr650.time(1);
fprintf('Done\n');
end