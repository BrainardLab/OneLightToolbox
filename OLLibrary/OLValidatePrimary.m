function [results, timing] = OLValidatePrimary(primaryValues, calibration, oneLight, radiometer, varargin)
% Validates SPD that OneLight puts out for given primary values vector(s)
%
% Syntax:
%   results = OLValidatePrimaryValues(primaryValues, oneLight, calibration, radiometer)
%   results = OLValidatePrimaryValues(primaryValues, calibration, 'simulate', true)
%
% Description:
%    Sends a vector of primary values to a OneLight, measures the SPD and
%    compares that to the SPD that would be predicted from calibration
%    information. Can handle any number of vectors.
%
% Inputs:
%    primaryValues - PxN array of primary values, where P is the number of
%                    primary values per spectrum, and N is the number of
%                    spectra to validate (i.e., a column vector per
%                    spectrum)
%    calibration   - struct containing calibration information for oneLight
%    oneLight      - (OPTIONAL when simulating) a oneLight object to 
%                    control a OneLight device
%    radiometer    - (OPTIONAL when simulating) radiometer object to 
%                    control a spectroradiometer
%
% Outputs:
%    results       - 1xN struct-array containing measurement information
%                    (as returned by radiometer), predictedSPD, error
%                    between the two, and descriptive metadata, for all N
%                    spectra
%    timing        - total time the entire validation took
%
% Optional key/value pairs:
%    'simulate' - (true/false) predict SPD using calibration information,
%                  or actually measure the SPD (default false).
%
% See also:
%    OLVALIDATEDIRECTIONPRIMARY

% History:
%    11/29/17  jv  created. based on OLValidateCacheFileOOC
%

%% Input validation
parser = inputParser;
parser.addRequired('primaryValues',@isnumeric);
parser.addOptional('oneLight',[],@(x) isa(x,'OneLight'));
parser.addRequired('calibration',@isstruct);
parser.addOptional('radiometer',[],@(x) isa(x,'Radiometer'));
parser.addParameter('simulate',false,@islogical);
parser.parse(primaryValues,oneLight,calibration,radiometer,varargin{:});

primaryValues = parser.Results.primaryValues;
calibration = parser.Results.calibration;
simulate = parser.Results.simulate;

if ~simulate
    oneLight = parser.Results.oneLight;
    assert(~isempty(oneLight),'OneLightToolbox:OLValidatePrimaryValues:InvalidOneLight',...
        'Real validation specified, but no OneLight object passed');
    assert(oneLight.IsOpen,'OneLightToolbox:OLValidatePrimaryValues:InvalidOneLight','OneLight not open')
    
    radiometer = parser.Results.radiometer;
    assert(~isempty(radiometer),'OneLightToolbox:OLValidatePrimaryValues:InvalidRadiometer',...
        'Real validation specified, but no Radiometer object passed');
end

% Get wavelength resolution of calibration
S = calibration.describe.S;

%% Define primaries to test
% Convert column vectors of primary values to starts and stops
olSettings = OLPrimaryToSettings(calibration, primaryValues);
[starts, stops] = OLSettingsToStartsStops(calibration, olSettings);

% Predict SPDs
predictedSPDs = OLPrimaryToSpd(calibration,primaryValues);

%% Measure
startTime = GetSecs;
measurement = struct([]);
if ~simulate
    try % since we're working with hardware, things can go wrong
        for p = 1:size(primaryValues,2)
            oneLight.setAll(true);
            measurement = [measurement, OLTakeMeasurementOOC(oneLight,[],radiometer,starts(p,:),stops(p,:),[],[true,false],1)];
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
    for p = 1:size(primaryValues,2)
        % simulate measurement
        measurement(p).pr650.spectrum = OLPrimaryToSpd(calibration,primaryValues(:,p));
        measurement(p).pr650.time = [0 0];
        measurement(p).pr650.S = S;
    end
end
stopTime = GetSecs;
timing = stopTime-startTime;

%% Analyze and output
results = [];
for p = size(primaryValues,2):-1:1
    % Compare to prediction
    err = measurement(p).pr650.spectrum - predictedSPDs(:,p);
    
    % Add to results
    results(p).measurement = measurement(p);
    results(p).measuredSpd = measurement(p).pr650.spectrum;
    results(p).predictedSpd = predictedSPDs(:,p);
    results(p).error = err;
    
    % Some metadata
    results(p).primaries = primaryValues(:,p);
    results(p).settings = olSettings(:,p);
    results(p).starts = starts(p,:);
    results(p).stops = stops(p,:);
end
end