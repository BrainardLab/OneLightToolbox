function SPD = OLMeasurePrimaryValues(primaryValues,calibration,oneLight,varargin)
% Measure the SPD put out by the given primary values vector(s)
%
% Syntax:
%   SPD = OLMeasurePrimary(primaryValues, calibration, oneLight, radiometer)
%   SPD = OLMeasurePrimary(primaryValues, calibration, oneLight)
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
%    oneLight      - a oneLight object to control a OneLight device. If
%                    the oneLight object is simulated, the returned SPD is
%                    predicted from just the calibration information.
%    radiometer    - (OPTIONAL when simulating) radiometer object to 
%                    control a spectroradiometer
% Outputs:
%    SPD           - nWlsxN array of spectral power, where N is the number
%                    of vector of primary values to measure
%
% Optional key/value pairs:
%    None.
%
% See also:
%    OLTakeMeasurementOOC, OLValidatePrimary

% History:
%    12/14/17  jv  created.

%% Validate input
parser = inputParser;
parser.addRequired('primaryValues',@isnumeric);
parser.addRequired('calibration',@isstruct);
parser.addRequired('oneLight',@(x) isa(x,'OneLight'));
parser.addOptional('radiometer',[]);
parser.parse(primaryValues,calibration,oneLight,varargin{:});

radiometer = parser.Results.radiometer;

%% Convert primary values to starts and stops
olSettings = OLPrimaryToSettings(calibration, primaryValues);
[starts, stops] = OLSettingsToStartsStops(calibration, olSettings);

%% Measure (or simulate)
SPD = [];
if ~isempty(radiometer)
    
    % Actually measure
    oneLight.setAll(true);
            
    % Loop over primary values vectors
    for p = 1:size(primaryValues,2)
        measurement = OLTakeMeasurementOOC(oneLight,[],radiometer,starts(p,:),stops(p,:),[],[true,false],1);
        
        % Extract SPDs
        SPD = [SPD reshape(measurement.pr650.spectrum(:),[numel(measurement.pr650.spectrum),1])];
    end
    
    % Turn all mirrors off
    oneLight.setAll(false);
else
    % Simulate
    SPD = OLPrimaryToSpd(calibration,primaryValues);
end


end