function [results, timing] = OLValidatePrimary(primary,oneLight,calibration,radiometer,varargin)
% Validates the SPD that the OneLight puts out for a primary
%
% Syntax:
%   results = OLValidatePrimary(primary, oneLight, calibration, radiometer)
%
% Description:
%    Send a primary to a OneLight, measures the SPD and compares that to
%    the SPD that would be predicted from calibration information.
%
% Inputs:
%    primary     - PxN array of primary values, where P is the number of
%                  primary values per spectrum, and N is the number of
%                  spectra to validate (i.e., a column vector per
%                  spectrum)
%    oneLight    - a oneLight object to control the device
%    calibration - struct containing calibration information for oneLight
%    radiometer  - radiometer object to control a spectroradiometer
%
% Outputs:
%    results     - 1xN struct-array containing measurement information (as
%                  returned by radiometer), predictedSPD, error between
%                  the two, and descriptive metadata, for all N spectra
%    timing      - total time the entire validation took
%
% Optional key/value pairs:
%    'simulate'  - true/false whether to actually measure the SPD, or
%                  predict using calibration information (default false).
%
% See also: OLVALIDATEDIRECTIONPRIMARY,

% History:
%   11/29/17  jv  create. based on OLValidateCacheFileOOC
%

    % Input validation
    parser = inputParser;
    parser.addParameter('simulate',false,@islogical);
    parser.parse(varargin{:});
    simulate = parser.Results.simulate;
    
    if simulate
        assert(oneLight.Simulate,'Trying to simulate with an actual OneLight!');
        % this should not actually matter, since we won't call the OneLight
        % object. Good to throw an error, I guess.
    else
        assert(oneLight.IsOpen,'OneLight not open')
    end
        
    % Get wavelength resolution of calibration
    S = calibration.describe.S;
    
    %% Define primaries to test
    % Convert column vectors of primary values to starts and stops
    olSettings = OLPrimaryToSettings(calibration, primary);
    [starts, stops] = OLSettingsToStartsStops(calibration, olSettings);
    
    % Predict SPDs
    predictedSPDs = OLPrimaryToSpd(calibration,primary);
    
    %% Measure
    startTime = GetSecs;
    measurement = struct();
    if ~simulate
        try % since we're working with hardware, things can go wrong
            for p = size(primary,2):-1:1
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
        for p = size(primary,2):-1:1
            % measure
            measurement(p).pr650.spectrum = OLPrimaryToSpd(calibration,primary(:,p));
            measurement(p).pr650.time = [0 0];
            measurement(p).pr650.S = S;
        end    
    end
    stopTime = GetSecs;
    timing = stopTime-startTime;
    
    %% Analyze and output
    results = [];
    for p = 1:size(primary,2)
        % Compare to prediction
        err = measurement(p).pr650.spectrum - predictedSPDs(:,p);

        % Add to results
        results(p).measurement = measurement(p);
        results(p).predictedSPD = predictedSPDs(:,p);
        results(p).error = err;
        
        % Some metadata
        results(p).primary = primary(:,p);
        results(p).settings = olSettings(:,p);
        results(p).starts = starts(p,:);
        results(p).stops = stops(p,:);
    end
end