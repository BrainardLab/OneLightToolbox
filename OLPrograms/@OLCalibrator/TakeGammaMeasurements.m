% cal = TakeGammaMeasurements(cal0, gammaBandIndex, ol, od, spectroRadiometerOBJ, meterToggle, nAverage)
%
% Takes gamma measurements.
%
% 8/13/16   npc     Wrote it
% 9/29/16   npc     Optionally record temperature
% 12/21/16  npc     Updated for new class @LJTemperatureProbe

function cal = TakeGammaMeasurements(cal0, gammaBandIndex, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, varargin)

    p = inputParser;
    p.addParameter('takeTemperatureMeasurements', false, @islogical);
    % Execute the parser
    p.parse(varargin{:});
    takeTemperatureMeasurements = p.Results.takeTemperatureMeasurements;

    cal = cal0;
    nPrimaries = cal.describe.numWavelengthBands;

    fprintf('\n<strong>Gamma measurements on gamma band set %d of %d</strong>\n\n', gammaBandIndex , cal.describe.nGammaBands);

    % Store the columns used for this set.
    cal.raw.gamma.cols(:,gammaBandIndex ) = cal.raw.cols(:,cal.describe.gamma.gammaBands(gammaBandIndex ));

    % Allocate memory for the recorded spectra.
    cal.raw.gamma.rad(gammaBandIndex ).meas = zeros(cal.describe.S(3), cal.describe.nGammaLevels);

    % Test each gamma level for this band. If the gamma randomization
    % flag is set, shuffle now. We are still storing the measurements
    % in the right order as expected.
    if cal.describe.randomizeGammaLevels
        gammaLevelsIter = Shuffle(1:cal.describe.nGammaLevels);
    else
        gammaLevelsIter = 1:cal.describe.nGammaLevels;
    end

    % If we're specifying the background, we need a measurement of that
    % background but with the settings for the specified gamma band set
    % to zero.  This is then used to subtract off the background from
    % the series of gamma measurements, rather than using the omnibus
    % dark level measurement.
    if (cal.describe.specifiedBackground)

        % See if we need to take a new set of state measurements
        if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
            cal = OLCalibrator.TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, 'takeTemperatureMeasurements', takeTemperatureMeasurements);
        end

        % Update calibration stim index
        cal.describe.stateTracking.calibrationStimIndex = cal.describe.stateTracking.calibrationStimIndex + 1;
        fprintf('- Measurement #%d: effective background for gamma band: %d ...', cal.describe.stateTracking.calibrationStimIndex, gammaBandIndex);

        % Measure effective background, which has the setting for this
        % primary set to zero.
        theSettings = GetEffectiveBackgroundSettingsForPrimary(cal.describe.gamma.gammaBands(gammaBandIndex),cal.describe.specifiedBackgroundSettings);
        [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
        measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
        cal.raw.gamma.rad(gammaBandIndex).effectiveBgMeas = measTemp.pr650.spectrum;
        cal.raw.t.gamma.rad(gammaBandIndex).effectiveBgMeas = measTemp.pr650.time(1);
        if (meterToggle(2))
            cal.raw.gamma.omniDriver(gammaBandIndex).effectiveBgMeas = measTemp.omni.spectrum;
        end
        fprintf('Done\n');
    end

    for gammaLevelIndex = gammaLevelsIter
        % See if we need to take a new set of state measurements
        if (mod(cal.describe.stateTracking.calibrationStimIndex, cal.describe.stateTracking.calibrationStimInterval) == 0)
            cal = OLCalibrator.TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, 'takeTemperatureMeasurements', takeTemperatureMeasurements);
        end

        % Update calibration stim index
        cal.describe.stateTracking.calibrationStimIndex = cal.describe.stateTracking.calibrationStimIndex + 1;
        fprintf('- Measurement #%d: gamma level %d of %d for gamma band: %d ...', cal.describe.stateTracking.calibrationStimIndex, gammaLevelIndex, cal.describe.nGammaLevels,gammaBandIndex);

        % Set the starts/stops, measure, and store
        if (cal.describe.specifiedBackground)
            theSettings = GetEffectiveBackgroundSettingsForPrimary(cal.describe.gamma.gammaBands(gammaBandIndex),cal.describe.specifiedBackgroundSettings);
        else
            theSettings = zeros(nPrimaries,1);
        end
        theSettings(cal.describe.gamma.gammaBands(gammaBandIndex)) = cal.describe.gamma.gammaLevels(gammaLevelIndex);
        [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
        measTemp = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, cal.describe.S, meterToggle, nAverage);
        cal.raw.gamma.rad(gammaBandIndex).meas(:,gammaLevelIndex) = measTemp.pr650.spectrum;
        cal.raw.t.gamma.rad(gammaBandIndex).meas(gammaLevelIndex) = measTemp.pr650.time(1);
        if (meterToggle(2))
            cal.raw.gamma.omnidriver(gammaBandIndex).meas(:,gammaLevelIndex) = measTemp.omni.spectrum;
        end
        fprintf('Done\n');
    end
end

