function [results, elapsedTime] = OLValidatePrimary(primary,oneLight,calibration,radiometer,powerLevels,simulate)
%OLVALIDATEPRIMARY validates that a given primary produces the
%expected spectral power distribution.
% 
% results = OLValidatePrimary(primary)
%

    % Input validation
    if simulate
        assert(oneLight.Simulate,'Trying to simulate with an actual OneLight!')
    else
        assert(oneLight.IsOpen,'OneLight not open')
    end
        
    % Get wavelength resolution of calibration
    S = calibration.describe.S;
    
    %% Define primaries to test
    % Create column vector of primary values per powerlevel (through some
    % matrix multiplication)
    primaries = (powerLevels' * primary')';
    
    % Convert column vectors of primary values ot starts and stops
    olSettings = OLPrimaryToSettings(calibration, primaries);
    [starts, stops] = OLSettingsToStartsStops(calibration, olSettings);
    
    % Predict SPDs
    predictedSPDs = OLPrimaryToSpd(calibration,primaries);
    
    %% Measure
    startTime = GetSecs;
    measurement = struct();
    if ~simulate
        try % since we're working with hardware, things can go wrong
            for p = size(predictedSPDs,2):-1:1
                oneLight.setAll(true);
                measurement(p) = OLTakeMeasurementOOC(oneLight,[],radiometer,starts(:,p),stops(:,p),[],[true,false],1);
                oneLight.setAll(false);
            end
        catch Exception
            % Turn OneLight mirrors off
            oneLight.setAll(false);

            % Close the radiometer
            if ~isempty(radiometer)
                radiometer.shutDown();
            end

            % Rethrow exception
            rethrow(Exception)
        end
    else
        for p = size(predictedSPDs,2):-1:1
            % measure
            measurement(p).pr650.spectrum = OLPrimaryToSpd(calibration,primaries(:,p));
            measurement(p).pr650.time = [0 0];
            measurement(p).pr650.S = S;
        end    
    end
    stopTime = GetSecs;
    elapsedTime = stopTime-startTime;
    
    %% Analyze and output
    results = [];
    for p = 1:size(primaries,2)
        % Compare to prediction
        err = measurement(p).pr650.spectrum - predictedSPDs(:,p);

        % Add to results
        results(p).measurement = measurement(p);
        results(p).predictedSPD = predictedSPDs(:,p);
        results(p).error = err;
        
        % Some metadata
        results(p).primary = primaries(:,p);
        results(p).settings = olSettings(:,p);
        results(p).starts = starts(p,:);
        results(p).stops = stops(p,:);
    end
end