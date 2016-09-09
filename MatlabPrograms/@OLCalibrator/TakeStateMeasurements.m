% [cal calMeasOnly] = TakeStateMeasurements(cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, standAlone)
%
% Takes state measurements for a OneLight calibration. In stand alone mode,
% the data are added to a barebones calibration structure.
%
% 8/13/16   npc     Wrote it
% 9/2/16    ms      Some updates

function [cal, calMeasOnly] = TakeStateMeasurements(cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, standAlone)

if ~exist('standAlone', 'var') || isempty(standAlone)
    standAlone = false;
end

if standAlone
    calMeasOnly.describe = cal0.describe;
    calMeasOnly.describe.dateStateMeas = datestr(now);
end
cal = cal0;
cal.describe.stateTracking.stateMeasurementIndex = cal.describe.stateTracking.stateMeasurementIndex + 1;

theSettings = cal.describe.stateTracking.stimSettings.powerFluctuationsStim;
[starts,stops] = OLSettingsToStartsStops(cal,theSettings);
measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
if standAlone
    calMeasOnly.raw.powerFluctuationMeas.measSpd = measTemp.pr650.spectrum;
    calMeasOnly.raw.powerFluctuationMeas.t = measTemp.pr650.time(1);
else
    fprintf('-- Power fluctuation state measurement #%d ...', cal.describe.stateTracking.stateMeasurementIndex);
    cal.raw.powerFluctuationMeas.measSpd(:, cal.describe.stateTracking.stateMeasurementIndex) = measTemp.pr650.spectrum;
    cal.raw.powerFluctuationMeas.t(:, cal.describe.stateTracking.stateMeasurementIndex) = measTemp.pr650.time(1);
end
fprintf('Done\n');

theSettings = cal.describe.stateTracking.stimSettings.spectralShiftsStim;
[starts,stops] = OLSettingsToStartsStops(cal,theSettings);
measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
if standAlone
    calMeasOnly.raw.spectralShiftsMeas.measSpd = measTemp.pr650.spectrum;
    calMeasOnly.raw.spectralShiftsMeas.t = measTemp.pr650.time(1);
else
    fprintf('-- Spectral shift state measurement #%d    ...', cal.describe.stateTracking.stateMeasurementIndex);
    cal.raw.spectralShiftsMeas.measSpd(:, cal.describe.stateTracking.stateMeasurementIndex) = measTemp.pr650.spectrum;
    cal.raw.spectralShiftsMeas.t(:, cal.describe.stateTracking.stateMeasurementIndex) = measTemp.pr650.time(1);
    fprintf('Done\n');
end
end
