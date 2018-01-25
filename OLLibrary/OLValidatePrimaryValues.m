function [results, actualContrasts, nominalContrasts] = OLValidatePrimaryValues(primaryValues, calibration, oneLight, varargin)
% Validates SPD that OneLight puts out for given primary values vector(s)
%
% Syntax:
%   results = OLValidatePrimary(primaryValues, calibration, OneLight, radiometer)
%   results = OLValidatePrimary(primaryValues, calibration, SimulatedOneLight)
%   [results, actualContrast, nominalContrasts] = OLValidatePrimary(..., 'receptors',SSTReceptor)
%
% Description:
%    Sends a vector of primary values to a OneLight, measures the SPD and
%    compares that to the SPD that would be predicted from calibration
%    information. Can handle any number of vectors. Can optionally also
%    calculate the actual and nominal contrasts for a given set of
%    photoreceptors.
%
% Inputs:
%    primaryValues   - PxN array of primary values, where P is the number 
%                      of primary values per spectrum, and N is the number 
%                      of spectra to validate (i.e., a column vector per
%                      spectrum)
%    calibration     - struct containing calibration for oneLight
%    oneLight        - a oneLight device driver object to control a 
%                      OneLight device, can be real or simulated
%    radiometer      - radiometer object to control a spectroradiometer. 
%                      Can be passed empty when simulating
%
% Outputs:
%    results         - 1xN struct-array containing measurement information
%                      (as returned by radiometer), predictedSPD, error
%                      between the two, and descriptive metadata, for all N
%                      spectra
%    actualContrast  - NxNxR array of contrasts between N measured SPDs on 
%                      R receptors.
%    nominalContrast - NxNxR array of contrasts between N predicted SPDs on 
%                      R receptors.
%
% Optional key/value pairs:
%    'receptors'    - SSTReceptor object defining a set of receptors. If
%                     two or more vectors of primary values or passed,
%                     calculate contrasts on these receptors. Default none.
%
% See also:
%    OLCorrectPrimary, OLValidateDirectionPrimary

% History:
%    11/29/17  jv  created. based on OLValidateCacheFileOOC
%

%% Input validation
parser = inputParser;
parser.addRequired('primaryValues',@isnumeric);
parser.addRequired('calibration',@isstruct);
parser.addRequired('oneLight',@(x) isa(x,'OneLight'));
parser.addOptional('radiometer',[],@(x) isempty(x) || isa(x,'Radiometer'));
parser.addParameter('receptors',[],@(x) isa(x,'SSTReceptor'));
parser.parse(primaryValues,calibration,oneLight,varargin{:});

primaryValues = parser.Results.primaryValues;
calibration = parser.Results.calibration;
radiometer = parser.Results.radiometer;
receptors = parser.Results.receptors;

if nargout > 1
    assert(~isempty(receptors),'OneLightToolbox:OLValidatePrimary:InvalidReceptors',...
        'No receptors specified for which to calculate contrasts');
end

%% Predict SPD(s)
predictedSPDs = OLPrimaryToSpd(calibration,primaryValues);

%% Measure SPD(s)
measurement = OLMeasurePrimaryValues(primaryValues,calibration,oneLight,radiometer);

%% Analyze and output
results = [];
for p = size(primaryValues,2):-1:1
    % Compare to prediction
    err = measurement(:,p) - predictedSPDs(:,p);
    
    % Add to results
    results(p).measuredSpd = measurement(:,p);
    results(p).predictedSpd = predictedSPDs(:,p);
    results(p).error = err;
    
    % Some metadata
    results(p).primaries = primaryValues(:,p);
end

%% Calculate nominal and actual contrasts
if ~isempty(receptors)
    nominalContrasts = SPDToReceptorContrast([results.predictedSpd],receptors);
    actualContrasts = SPDToReceptorContrast([results.measuredSpd],receptors);
end
end