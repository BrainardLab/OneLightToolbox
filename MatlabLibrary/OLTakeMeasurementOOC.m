function [meas, omniSpectrumSaturated] = OLTakeMeasurementOOC(ol, od, prOBJ, starts, stops, S, meterToggle,  nAverage)
% OLTakeMeasurement - Takes a spectrum measurement using the PR-6XX and/or the OmniDriver.
%
% Syntax:
% meas = OLTakeMeasurement(ol, od, prOBJ, starts, stops, S);
% meas = OLTakeMeasurement(ol, od, prOBJ, starts, stops, S, meterToggle);
% meas = OLTakeMeasurement(ol, od, prOBJ, starts, stops, S, meterToggle);
% meas = OLTakeMeasurement(ol, od, prOBJ, starts, stops, S, meterToggle, nAverage);
%
% Description:
% Takes a spectrum measurement using the PR-6XX and/or the OmniDriver.
%
% Input:
% ol (OneLight)      - OneLight class object to control the device.  If empty,
%                      the function doesn't set the mirrors, i.e. starts and stops are
%                      ignored.
% od (OmniDriver)    - OmniDriver class object to control the OmniDriver.
% prOBJ              - PR650/PR670 class object to control the PR650 or PR670.
%                      These objects must be instantiated by the parent
%                      method (see OOC_PR650_PR670_Usage.m in BrainardLabToolbox for example usage).
% starts (1xNumCols) - starts vector as accepted by the setMirrors method of an OL object.
% stops (1xNumCols)  - stops vector as accepted by the setMirrors method of an OL object.
% S (1x3)            - Wavelength sampling parameter used to sample the SPD by the PR-650/PR670dev objects.
% meterToggle (1x2)  - Logical array specifying which meter(s) to use.  The
%                      first element represents the PR-6XX, the second represents the
%                      OmniDriver.  Defaults to [true, false].
% nAverage           - number of PR-6XX measurements to average.  Defaults to 1.
%
% Output:
% meas (struct) - Contains the measurements and some support data for the
%     two device measurements.  The struct contains 2 fields: pr650 and
%     omni.  Both fields contain 2 subfields: spectrum and time.  The
%     spectrum is the result of the device measure commands.  The time
%     variable is a 2 element vector containing the result of mglGetSeconds
%     before and after the measurements were taken.  If a particular device
%     wasn't toggled, then its subfield will be empty, e.g. meas.pr650 = [].
%
% Omni measurements are normalized by integration time.
%
% 1/17/14  dhb, ms   Comment tuning.
% 4/15/16  npc       Adapted to use PR650dev/PR670dev objects

% Print out information aboutt he measurement?
verboseInfo = false;

% Check the number of input arguments.
error(nargchk(6, 8, nargin));

% Take a measurement with both meters if not specified.
if (nargin <= 6 | isempty(meterToggle))
    meterToggle = [true false];
end

if (nargin <= 7 | isempty(nAverage))
    nAverage = 1;
end

OneLightStateVars = {'LampStatus', 'LampCurrent', 'CurrentMonitor', 'VoltageMonitor', 'FanSpeed'};
 
if ~isempty(ol)
    % capture OneLightState before measurement
    for varIter = 1:numel(OneLightStateVars)
        eval(sprintf('meas.oneLightState1.%s = ol.%s;', OneLightStateVars{varIter}, OneLightStateVars{varIter}));
    end

    % Set the mirrors.
    ol.setMirrors(starts, stops);
    
    % Wait for the mirrors to settle.  In theory the mirrors settle in a fraction
    % of a millisecond, but we wait a bit just in case there was some USB
    % communication lag.
    pause(0.1);
end

% Take a reading with the PR-650.
if meterToggle(1)
    meas.pr650.time(1) = mglGetSecs;
    radMeasAvg = 0;
    for i = 1:nAverage
        if verboseInfo
            fprintf('> [%s] Starting PR-6XX measurement...\n', datestr(now));
        end
        
        % ORIGINAL: [radMeas, qual] = MeasSpd(S,prWhichMeter,'off');
        theTime = mglGetSecs;
        radMeas = prOBJ.measure('userS', S);

        assert(prOBJ.measurementQuality == 0 || prOBJ.measurementQuality == -8, 'OLCalibrate:MeasSpd:LightSpectrum', 'Radiometer returned a quality code of %d', prOBJ.measurementQuality);
        if verboseInfo
            fprintf('- [%s] Done with PR-6XX measurement...\n', datestr(now));
        end
        
        if (i == 1)
            meas.pr650.allSpectra = zeros(nAverage, numel(radMeas));
            meas.pr650.allSpectraTimes = zeros(nAverage);
        end
        meas.pr650.allSpectraTimes(i) = theTime;
        meas.pr650.allSpectra(i,:) = radMeas;
        radMeasAvg = radMeasAvg + radMeas;
    end
    radMeasAvg = radMeasAvg/nAverage;
    meas.pr650.spectrum = radMeasAvg;
    meas.pr650.time(2) = theTime;
    meas.pr650.S = S;
else
    meas.pr650 = [];
end

% capture OneLightState after PR650 measurement
for varIter = 1:numel(OneLightStateVars)
        eval(sprintf('meas.oneLightState2.%s = ol.%s;', OneLightStateVars{varIter}, OneLightStateVars{varIter}));
end
    
% Take a reading with the OmniDriver.
if meterToggle(2)
    radMeasAvg = 0;
    if verboseInfo
        fprintf('> [%s] Starting Omni measurement...\n', datestr(now));
    end
    for i = 1:nAverage
        try
            radMeas = od.getSpectrum' / od.IntegrationTime;
        catch e
            omniSpectrumSaturated = true;
        end
        radMeasAvg = radMeasAvg + radMeas;
    end
    meas.omni.spectrum = radMeasAvg/nAverage;
    meas.omni.integrationTime = od.IntegrationTime;
    if verboseInfo
        fprintf('> [%s] Done with Omni measurement...\n', datestr(now));
    end
    omniSpectrumSaturated = false;
else
    meas.omni = [];
    omniSpectrumSaturated = [];
end

% capture OneLightState after omni measurement
for varIter = 1:numel(OneLightStateVars)
        eval(sprintf('meas.oneLightState3.%s = ol.%s;', OneLightStateVars{varIter}, OneLightStateVars{varIter}));
end
