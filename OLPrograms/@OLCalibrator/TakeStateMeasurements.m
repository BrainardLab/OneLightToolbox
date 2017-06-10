% [cal calMeasOnly] = TakeStateMeasurements(cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, varargin)
%
% Takes state measurements for a OneLight calibration. In stand alone mode,
% the data are added to a barebones calibration structure.
%
% 8/13/16   npc     Wrote it
% 9/2/16    ms      Some updates
% 9/29/16   npc     Added parser for optional params: 'standAlone' and 'takeTemperatureMeasurements'
% 12/21/16  npc     Updated for new class @LJTemperatureProbe

function [cal, calMeasOnly] = TakeStateMeasurements(cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, varargin)

p = inputParser;
p.addParameter('standAlone', false, @islogical);
p.addParameter('takeTemperatureMeasurements', false, @islogical);
% Execute the parser
p.parse(varargin{:});
standAlone = p.Results.standAlone;
takeTemperatureMeasurements = p.Results.takeTemperatureMeasurements;

if standAlone
    calMeasOnly.describe = cal0.describe;
    calMeasOnly.describe.dateStateMeas = datestr(now);
end

cal = cal0;
cal.describe.stateTracking.stateMeasurementIndex = cal.describe.stateTracking.stateMeasurementIndex + 1;

theSettings = cal.describe.stateTracking.stimSettings.powerFluctuationsStim;
[starts,stops] = OLSettingsToStartsStops(cal,theSettings);
measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
if (standAlone)
    % SPD
    calMeasOnly.raw.powerFluctuationMeas.measSpd = measTemp.pr650.spectrum;
    calMeasOnly.raw.powerFluctuationMeas.t = measTemp.pr650.time(1);
    % Temperature
    if (takeTemperatureMeasurements)
        [~, calMeasOnly.raw.temperature.value] = theLJdev.measure();
        calMeasOnly.raw.temperature.t = measTemp.pr650.time(1);
    end
else
    % SPD
    fprintf('-- Power fluctuation state measurement #%d ...', cal.describe.stateTracking.stateMeasurementIndex);
    cal.raw.powerFluctuationMeas.measSpd(:, cal.describe.stateTracking.stateMeasurementIndex) = measTemp.pr650.spectrum;
    cal.raw.powerFluctuationMeas.t(:, cal.describe.stateTracking.stateMeasurementIndex) = measTemp.pr650.time(1);
    % Temperature
    if (takeTemperatureMeasurements)
        [~, cal.raw.temperature.value(cal.describe.stateTracking.stateMeasurementIndex,:)] = theLJdev.measure();
        cal.raw.temperature.t(cal.describe.stateTracking.stateMeasurementIndex,:) = measTemp.pr650.time(1);
    end
end
fprintf('Done\n');

theSettings = cal.describe.stateTracking.stimSettings.spectralShiftsStim;
[starts,stops] = OLSettingsToStartsStops(cal,theSettings);
measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
if (standAlone)
    calMeasOnly.raw.spectralShiftsMeas.measSpd = measTemp.pr650.spectrum;
    calMeasOnly.raw.spectralShiftsMeas.t = measTemp.pr650.time(1);
else
    fprintf('-- Spectral shift state measurement #%d    ...', cal.describe.stateTracking.stateMeasurementIndex);
    cal.raw.spectralShiftsMeas.measSpd(:, cal.describe.stateTracking.stateMeasurementIndex) = measTemp.pr650.spectrum;
    cal.raw.spectralShiftsMeas.t(:, cal.describe.stateTracking.stateMeasurementIndex) = measTemp.pr650.time(1);
    fprintf('Done\n');
end
end
