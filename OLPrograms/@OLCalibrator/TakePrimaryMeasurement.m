% [cal, primaryMeasurement] = TakePrimaryMeasurement(cal0, primaryIndex, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, theLJdev)
%
% Takes primary SPD measurements.
%
% 8/13/16   npc     Wrote it
% 9/29/16   npc     Optionally record temperature
% 12/21/16  npc     Updated for new class @LJTemperatureProbe
% 06/13/18  npc     Updated with option to save progression of cal

function [cal, primaryMeasurement] = TakePrimaryMeasurement(cal0, primaryIndex, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, varargin)

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
        
        methodName = sprintf('Starting %s - Primary #%d', mfilename(), primaryIndex);
        OLCalibrator.SaveCalProgressionData(...
            calProgressionTemporaryFileName, methodName, ...
            spdData, temperatureData);
    end
    
    cal = cal0;
    nPrimaries = cal.describe.numWavelengthBands;

    % Record the band start and end.
    primaryMeasurement.bandRange = [cal.describe.primaryStartCols(primaryIndex), cal.describe.primaryStopCols(primaryIndex)];

    % If we are using a specified background, we need to measure for all
    % primaries except the one being characterized at the specified
    % level. (If not, we just use the dark measurement for this
    % purpose.  Which is used to produce the actual calibration data is
    % handled when we post-process the measurements.)
    if (cal.describe.specifiedBackground)

        % See if we need to take a new set of state measurements
        if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
            cal = OLCalibrator.TakeStateMeasurements(cal, ol, od, ...
                spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, ...
                'takeTemperatureMeasurements', takeTemperatureMeasurements, ...
                'calProgressionTemporaryFileName', calProgressionTemporaryFileName);
        end

        % Update calibration stim index
        cal.describe.stateTracking.calibrationStimIndex = cal.describe.stateTracking.calibrationStimIndex + 1;
        fprintf('- Measurement #%d: effective background for effective primary %d ...', cal.describe.stateTracking.calibrationStimIndex, primaryIndex);

        % Get the background settings for this primary, and measure.  The
        % background for this primary has this primary set to zero, but all
        % the others on.
        theSettings = GetEffectiveBackgroundSettingsForPrimary(primaryIndex,cal.describe.specifiedBackgroundSettings);
        [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
        measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
        primaryMeasurement.effectiveBackgroundSpectrum = measTemp.pr650.spectrum;
        primaryMeasurement.effectiveBackgroundTime = measTemp.pr650.time(1);
        if (meterToggle(2))
            primaryMeasurement.effectiveBackgroundSpectrumOD = measTemp.omni.spectrum;
        end
        fprintf('Done\n');
        
        if (~isempty(calProgressionTemporaryFileName))
            % make spdData struct
            spdData = struct(...
                'time', measTemp.pr650.time(1), ...
                'spectrum', measTemp.pr650.spectrum);

            % empty temperature struct as we do not collect tempoeratures in this method
            temperatureData = struct();

            methodName = sprintf('Completed %s - Background for primary #%d (1/2)', mfilename(), primaryIndex);
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
    fprintf('- Measurement #%d: effective primary %d of %d...', cal.describe.stateTracking.calibrationStimIndex, primaryIndex, length(cal.describe.primaryStartCols));

    % Set the starts/stops for this effective primary, relative to the
    % measurement background, and take the measurement.
    if (cal.describe.specifiedBackground)
        theSettings = GetEffectiveBackgroundSettingsForPrimary(primaryIndex,cal.describe.specifiedBackgroundSettings);
    else
        theSettings = zeros(nPrimaries,1);
    end
    theSettings(primaryIndex) = 1;
    [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
    measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
    primaryMeasurement.lightSpectrum = measTemp.pr650.spectrum;
    primaryMeasurement.time = measTemp.pr650.time(1);
    if (meterToggle(2))
        primaryMeasurement.lightSpectrumOD = measTemp.omni.spectrum;
    end
    fprintf('Done\n');
    
    if (~isempty(calProgressionTemporaryFileName))
        % make spdData struct
        spdData = struct(...
            'time', measTemp.pr650.time(1), ...
            'spectrum', measTemp.pr650.spectrum);
        
        % empty temperature struct as we do not collect tempoeratures in this method
        temperatureData = struct();
        
        methodName = sprintf('Completed %s - Primary #%d (2/2)', mfilename(), primaryIndex);
        OLCalibrator.SaveCalProgressionData(...
            calProgressionTemporaryFileName, methodName, ...
            spdData, temperatureData);
    end
end

