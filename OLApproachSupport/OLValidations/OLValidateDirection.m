function [SPDs, actualContrast, predictedContrast] = OLValidateDirection(directionStruct, calibration, oneLight, radiometer, varargin)
% Validate SPDs and contrasts of direction (background + differentials)
%
% Syntax:
%   SPDs = OLValidateDirection(directionStruct, calibration, oneLight, radiometer)
%   SPDs = OLValidateDirection(directionStruct, calibration, SimulatedOneLight)
%   [SPDs, actualContast, predictedContrast] = OLValidateDirection(..., receptors)
%
% Description:
%    Measures the SPDs of the background, maximum positive contrast and
%    maximum negative contrast of a direction, and the error from predicted
%    SPD. Optionally calculates the actual and predicted contrast between
%    the background and each direction component.
%
% Inputs:
%    directionStruct   - a single struct defining a direction, with at 
%                        least the following fields:
%                        * backgroundPrimary   : the primary values for the
%                                                background.
%                        * differentialPositive: the difference in primary
%                                                values to be added to the
%                                                background primary to
%                                                create the positive
%                                                direction
%                        * differentialNegative: the difference in primary
%                                                values to be added to the
%                                                background primary to
%                                                create the negative
%                                                direction
%    calibration       - struct containing calibration for oneLight
%    oneLight          - a oneLight device driver object to control a 
%                        OneLight device, can be real or simulated
%    radiometer        - radiometer object to control a spectroradiometer. 
%                        Can be passed empty when simulating.
%    receptors         - [OPTIONAL] an SSTReceptor object, specifying the 
%                        receptors on which to calculate contrasts.
%
% Outputs:
%    SPDs              - 1x3 struct-array, with one struct for each of
%                        backgroundprimary, maxPositive and maxNegative, 
%                        with the fields:
%                        * measuredSPD
%                        * predictedSPD
%                        * error
%    actualContrast    - Rx2 array of actual contrasts on R receptors, with 
%                        a column for contrast between maxPositive and
%                        background, and maxNegative and background.
%                        Requires optional argument 'receptors'.
%    predictedContrast - Rx2 array of predicted contrasts on R receptors,
%                        with a column for contrast between maxPositive and
%                        background, and maxNegative and background
%                        Requires optional argument 'receptors'.
%
% Optional key/value pairs:
%    None.
%
% See also:
%    OLValidatePrimaryValues, OLMeasurePrimaryValues, SPDToReceptorContrast
%
% History:
%    02/05/18  jv  wrote it based on OLValidatePrimaryValues


%% Input validation
parser = inputParser;
parser.addRequired('direction',@isstruct);
parser.addRequired('calibration',@isstruct);
parser.addRequired('oneLight',@(x) isa(x,'OneLight'));
parser.addOptional('radiometer',[],@(x) isempty(x) || isa(x,'Radiometer'));
parser.addOptional('receptors',[],@(x) isa(x,'SSTReceptor'));
parser.parse(directionStruct,calibration,oneLight,radiometer,varargin{:});

%% Check if calculating contrasts
receptors = parser.Results.receptors;
if nargout > 1
    assert(~isempty(receptors),'OneLightToolbox:ApproachSupport:OLValidateDirection:NoReceptors',...
        'No receptors specified to calculate contrast on');
end

%% Get background primary and max primaries
backgroundPrimary = directionStruct.backgroundPrimary;
maxPositive = backgroundPrimary + directionStruct.differentialPositive;
maxNegative = backgroundPrimary + directionStruct.differentialNegative;
primaries = [backgroundPrimary, maxPositive, maxNegative];

%% Measure
SPDs = OLValidatePrimaryValues(primaries,calibration,oneLight,radiometer);

%% Calculate nominal and actual contrast
if ~isempty(receptors)
    predictedContrastPos = SPDToReceptorContrast([SPDs([1 2]).predictedSPD],receptors);
    predictedContrastNeg = SPDToReceptorContrast([SPDs([1 3]).predictedSPD],receptors);
    predictedContrast = [predictedContrastPos(:,1) predictedContrastNeg(:,1)];
    
    actualContrastPos = SPDToReceptorContrast([SPDs([1 2]).measuredSPD],receptors);
    actualContrastNeg = SPDToReceptorContrast([SPDs([1 3]).measuredSPD],receptors); 
    actualContrast = [actualContrastPos(:,1) actualContrastNeg(:,1)];
end

end