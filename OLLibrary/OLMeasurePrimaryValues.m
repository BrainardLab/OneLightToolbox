function [SPD, temperatures] = OLMeasurePrimaryValues(primaryValues,calibration,oneLight,varargin)
% Measure the SPD put out by the given primary values vector(s)
%
% Syntax:
%   [SPD, temperatures] = OLMeasurePrimary(primaryValues, calibration, oneLight, radiometer)
%   [SPD, temperatures] = OLMeasurePrimary(primaryValues, calibration, oneLight, radiometer, nAverage)
%   [SPD, temperatures] = OLMeasurePrimary(primaryValues, calibration, SimulatedOneLight)
%
% Description:
%    Sends a vector of primary values to a OneLight, measures the SPD and
%    compares that to the SPD that would be predicted from calibration
%    information. Can handle any number of vectors.
%
% Inputs:
%    primaryValues    - PxN array of primary values, where P is the number
%                       of primary values per spectrum, and N is the number
%                       of spectra to validate (i.e., a column vector per
%                       spectrum)
%    calibration      - struct containing calibration information for 
%                       oneLight
%    oneLight         - a OneLight object to control a OneLight device. If
%                       the oneLight object is simulated, the returned SPD
%                       is predicted from just the calibration information.
%    radiometer       - (OPTIONAL when simulating) radiometer object to 
%                       control a spectroradiometer
% Outputs:
%    SPD              - nWlsxN array of spectral power, where N is the
%                       number of vector of primary values to measure
%    temperatures     - array of structs, one struct per primary measurement, 
%                       with each struct contaning temperature and time of 
%                       measurement
%
% Optional key/value pairs:
%    nAverage         - number of measurements to average. 
%                       Default 1.
%    temperatureProbe - LJTemperatureProbe object to drive a LabJack
%                       temperature probe
%    primaryTolerance - tolerance for primary values being out of gamut.
%                       Default 1e-7.

% History:
%    12/14/17  jv  created.
%    06/29/18  npc implemented temperature recording

%% Validate input
parser = inputParser;
parser.addRequired('primaryValues',@isnumeric);
parser.addRequired('calibration',@isstruct);
parser.addRequired('oneLight',@(x) isa(x,'OneLight'));
parser.addOptional('radiometer',[]);
parser.addParameter('nAverage',1,@isnumeric);
parser.addParameter('temperatureProbe',[],@(x) isempty(x) || isa(x,'LJTemperatureProbe'));
parser.addParameter('primaryTolerance',1e-5,@isnumeric);
parser.parse(primaryValues,calibration,oneLight,varargin{:});

radiometer = parser.Results.radiometer;
theLJDev = parser.Results.temperatureProbe;

%% Convert primary values to starts and stops
olSettings = OLPrimaryToSettings(calibration, primaryValues, 'primaryTolerance', parser.Results.primaryTolerance);
[starts, stops] = OLSettingsToStartsStops(calibration, olSettings);

%% Measure (or simulate)
SPD = [];
temperatures = {};

if ~isempty(radiometer)
    % Actually measure
    oneLight.setAll(true);
            
    % Loop over primary values vectors
    for p = 1:size(primaryValues,2)
        for i = 1:parser.Results.nAverage
            SPDall = [];
            
            oneLight.setMirrors(starts(p,:),stops(p,:));

            % Take temperature measurement
            if (~isempty(theLJDev))
                [~, temperatureValue] = theLJDev.measure();
                temperatures{p,i} = struct('value', temperatureValue, 'time', mglGetSecs());
            end
        
            % Radiometeric measurement
            SPDall(:,i) = radiometer.measure();
        end
        SPD(:,p) = mean(SPDall,2);
    end
    
    % Turn all mirrors off
    oneLight.setAll(false);
else
    % Simulate
    SPD = OLPrimaryToSpd(calibration,primaryValues);
end


end