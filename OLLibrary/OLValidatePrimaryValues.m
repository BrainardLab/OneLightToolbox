function [SPD, temperatures, stateTrackingData] = OLValidatePrimaryValues(primaryValues, calibration, oneLight, radiometer, varargin)
% Validates SPD that OneLight puts out for given primary values vector(s)
%
% Syntax:
%   SPD = OLValidatePrimaryValues(primaryValues, calibration, oneLight, radiometer)
%   SPD = OLValidatePrimaryValues(primaryValues, calibration, SimulatedOneLight,[])
%   [SPD, temperatures] = OLValidatePrimaryValues(...,'temperatureProbe',LJTemperatureProbe)
%   [SPD, temperatures, stateTrackingData] = OLValidatePrimaryValues(..., 'measureStateTracking',true)
%
% Description:
%    Sends a vector of primary values to a OneLight, measures the SPD and
%    compares that to the SPD that would be predicted from calibration
%    information. Can handle any number of vectors of primary values.
%
% Inputs:
%    primaryValues    - PxN array of primary values, where P is the number
%                       of primary values per spectrum, and N is the number
%                       of spectra to validate (i.e., a column vector per
%                       spectrum)
%    calibration      - struct containing calibration for oneLight
%    oneLight         - a oneLight device driver object to control a
%                       OneLight device, can be real or simulated
%    radiometer       - radiometer object to control a spectroradiometer.
%                       Can be passed empty when simulating
%
% Outputs:
%    results          - 1xN struct-array containing measurement information
%                       (as returned by radiometer), predictedSPD, error
%                       between the two, for all N spectra
%    temperatures     - array of structs, one struct per primary measurement, 
%                       with each struct contaning temperature and time of 
%                       measurement
%    stateStrackingData - struct with state tracking SPDs
%
% Optional key/value pairs:
%    nAverage         - number of measurements to average. Default 1.
%    temperatureProbe - LJTemperatureProbe object to drive a LabJack
%                       temperature probe
%    measureStateTrackingSPDs - boolean, indicating whether to collect
%                               state tracking data
%
% See also:
%    OLCorrectPrimary, OLValidateDirectionPrimary

% History:
%    11/29/17  jv  created. based on OLValidateCacheFileOOC
%    06/29/18  npc implemented temperature recording
%    06/30/18  npc implemented state tracking SPD recording
%    08/30/18  jv  radiometer as required argument (but can be empty)

%% Input validation
parser = inputParser;
parser.addRequired('primaryValues',@isnumeric);
parser.addRequired('calibration',@isstruct);
parser.addRequired('oneLight',@(x) isa(x,'OneLight'));
parser.addRequired('radiometer',@(x) isempty(x) || isa(x,'Radiometer'));
parser.addParameter('primaryTolerance',1e-5,@isnumeric);
parser.KeepUnmatched = true;
parser.parse(primaryValues,calibration,oneLight,radiometer,varargin{:});

radiometer = parser.Results.radiometer;

%% Predict SPD(s)
predictedSPDs = OLPrimaryToSpd(calibration,primaryValues,'primaryTolerance',parser.Results.primaryTolerance);

%% Measure SPD(s)
[measurement, temperatures, stateTrackingData] = OLMeasurePrimaryValues(primaryValues,calibration,oneLight,radiometer,...
                                                                        'primaryTolerance',parser.Results.primaryTolerance,parser.Unmatched);

%% Analyze and output
SPD = [];
for p = size(primaryValues,2):-1:1
    % Compare to prediction
    err = measurement(:,p) - predictedSPDs(:,p);
    
    % Add to results
    SPD(p).measuredSPD = measurement(:,p);
    SPD(p).predictedSPD = predictedSPDs(:,p);
    SPD(p).error = err;
end

end