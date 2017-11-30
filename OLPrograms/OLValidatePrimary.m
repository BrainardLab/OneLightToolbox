function [results, elapsedTime] = OLValidatePrimary(primary,oneLight,calibration,radiometer,varargin)
% Validates the spectral power distribution of a primary
%
% Description:
%   Send a primary to a OneLight, measures the SPD and compares that to the
%   SPD that would be predicted from calibration information.
%
% Syntax:
%   results = OLValidatePrimary(primary, oneLight, calibration, radiometer)
%
% Inputs:
%    primary - the primary to validate
%    oneLight - a oneLight object to control the device
%    calibration - struct containing calibration information for oneLight
%    radiometer - radiometer object to control a spectroradiometer
%
% Optional key/value pairs:
%    'powerLevels'   array of levels ([0, 1]) of primary to validate
%                    (default 1)
%
%    'simulate'      true/false whether to actually measure the SPD, or
%                    predict using calibration information (default false).
%
% Outputs:
%    results - struct containing measurement information (as returned by
%    radiometer), predictedSPD, error between the two, and descriptive
%    metadata
%
% See also: 

    % Input validation
    parser = inputParser;
    parser.addParameter('powerLevels',[1],@(x)(isnumeric() & all(x >= 0) & all(x <= 1)));
    parser.addParameter('simulate',false,@islogical);
    parser.parse(varargin{:});
    simulate = parser.Results.simulate;
    powerLevels = parser.Results.powerLevels;
    
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