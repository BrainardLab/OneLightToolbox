function [validation, SPDs, actualContrast, predictedContrast] = OLValidateDirection(directionStruct, calibration, oneLight, radiometer, varargin)
% Validate SPDs and contrasts of direction (background + differentials)
%
% Syntax:
%   validation = OLValidateDirection(directionStruct, calibration, oneLight, radiometer)
%   [validation, SPDs] = OLValidateDirection(directionStruct, calibration, oneLight, radiometer)
%   [...] = OLValidateDirection(directionStruct, calibration, SimulatedOneLight)
%   [...] = OLValidateDirection(...,'nAverage', nAverage)
%   [..., actualContast, predictedContrast] = OLValidateDirection(..., 'receptors', receptors)
%   [...] = OLValidateDirection(...,'LJTemperatureProbe', LJTemperatureProbe)
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
%
% Outputs:
%    validation        - Labeled compilation of outputs (see below) that
%                        to be added to directionStruct.describe.
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
%    receptors         - an SSTReceptor object, specifying the
%                        receptors on which to calculate contrasts.
%    nAverage          - number of measurements to average. Default 1.
%    temperatureProbe  - TODO: LJTemperatureProbe object to drive a LabJack
%                        temperature probe
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
parser.addParameter('receptors',[],@(x) isa(x,'SSTReceptor') || isnumeric(x));
parser.addParameter('receptorStrings',{},@iscell);
parser.addParameter('nAverage',1,@isnumeric);
parser.addParameter('temperatureProbe',[],@(x) isempty(x) || isa(x,'LJTemperatureProbe'));
parser.parse(directionStruct,calibration,oneLight,radiometer,varargin{:});

%% Check if calculating contrasts
receptors = parser.Results.receptors;
receptorStrings = parser.Results.receptorStrings;
if nargout > 1
    assert(~isempty(receptors),'OneLightToolbox:ApproachSupport:OLValidateDirection:NoReceptors',...
        'No receptors specified to calculate contrast on');
end
if isnumeric(receptors)
    assert(~isempty(receptorStrings),'OneLightToolbox:ApproachSupport:OLValidateDirection:NoreceptorStrings',...
        'T_receptors specified, but no receptorStrings specified');
end

%% Get background primary and max primaries
backgroundPrimary = directionStruct.backgroundPrimary;
maxPositive = backgroundPrimary + directionStruct.differentialPositive;
maxNegative = backgroundPrimary + directionStruct.differentialNegative;
primaries = [backgroundPrimary, maxPositive, maxNegative];

%% Measure
SPDs = OLValidatePrimaryValues(primaries,calibration,oneLight,radiometer, 'nAverage', parser.Results.nAverage, 'temperatureProbe', parser.Results.temperatureProbe);

% Write directionStruct.describe output
validation.backgroundSPD = SPDs(1);
validation.positiveSPD = SPDs(2);
validation.negativeSPD = SPDs(3);

%% Calculate nominal and actual contrast using SSTReceptor object
if ~isempty(receptors) && isa(receptors,'SSTReceptor')
    predictedContrastPos = SPDToReceptorContrast([SPDs([1 2]).predictedSPD],receptors);
    predictedContrastNeg = SPDToReceptorContrast([SPDs([1 3]).predictedSPD],receptors);
    predictedContrast = [predictedContrastPos(:,1) predictedContrastNeg(:,1)];
    
    actualContrastPos = SPDToReceptorContrast([SPDs([1 2]).measuredSPD],receptors);
    actualContrastNeg = SPDToReceptorContrast([SPDs([1 3]).measuredSPD],receptors);
    actualContrast = [actualContrastPos(:,1) actualContrastNeg(:,1)];
    
    % Write directionStruct.describe output
    validation.actualContrast = actualContrast;
    validation.predictedContrast = predictedContrast;
end

%% Calculate nominal and actual contrast using T_receptors matrix
if ~isempty(receptors) && isnumeric(receptors)
    [predictedContrastPos, predictedPostReceptoralPos] = ComputeAndReportContrastsFromSpds("",receptorStrings,receptors,SPDs(1).predictedSPD,SPDs(2).predictedSPD,'verbose',false);
    [predictedContrastNeg, predictedPostReceptoralNeg] = ComputeAndReportContrastsFromSpds("",receptorStrings,receptors,SPDs(1).predictedSPD,SPDs(3).predictedSPD,'verbose',false);
    predictedContrast = [predictedContrastPos predictedContrastNeg];
    predictedContrastPostReceptoral = [predictedPostReceptoralPos, predictedPostReceptoralNeg];
    
    [actualContrastPos, actualPostReceptoralPos] = ComputeAndReportContrastsFromSpds("",receptorStrings,receptors,SPDs(1).measuredSPD,SPDs(2).measuredSPD,'verbose',false);
    [actualContrastNeg, actualPostReceptoralNeg] = ComputeAndReportContrastsFromSpds("",receptorStrings,receptors,SPDs(1).measuredSPD,SPDs(3).measuredSPD,'verbose',false);
    actualContrast = [actualContrastPos actualContrastNeg];
    actualContrastPostReceptoral = [actualPostReceptoralPos, actualPostReceptoralNeg];
    
    % Add to output struct
    validation.actualContrast = actualContrast;
    validation.predictedContrast = predictedContrast;
    validation.predictedContrastPostReceptoral = predictedContrastPostReceptoral;
    validation.actualContrastPostReceptoral = actualContrastPostReceptoral;
end

%% Calculate background luminance
load T_xyz1931
S = calibration.describe.S;
T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);

validation.predictedLuminances = T_xyz(2,:) * [SPDs(:).predictedSPD];
validation.actualLuminances = T_xyz(2,:) * [SPDs(:).measuredSPD];

end