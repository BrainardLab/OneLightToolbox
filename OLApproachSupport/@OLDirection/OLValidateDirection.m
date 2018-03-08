function [validation, SPDs, actualContrast, predictedContrast] = OLValidateDirection(direction, background, oneLight, radiometer, varargin)
% Validate SPDs and contrasts of OLDirection
%
% Syntax:
%   validation = OLValidateDirection(OLDirection, background, oneLight, radiometer)
%   [validation, SPDs] = OLValidateDirection(OLDirection, background, oneLight, radiometer)
%   [...] = OLValidateDirection(OLDirection, background, SimulatedOneLight)
%   [...] = OLValidateDirection(...,'nAverage', nAverage)
%   [..., actualContast, predictedContrast] = OLValidateDirection(..., 'receptors', receptors)
%   [...] = OLValidateDirection(...,'LJTemperatureProbe', LJTemperatureProbe)
%
% Description:
%    Measures the SPDs of the positive contrast and negative contrast of an
%    OLDirection object, around the specified background (also measured),
%    and the error from predicted SPDs. 
%
%    Optionally calculates the actual and predicted contrast between the
%    background and each direction component. 
%
%    Saves this validation by appending it to the the describe.validation
%    field of the OLDirection.
%
% Inputs:
%    direction         - OLDirection object, with at least the following
%                        properties:
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
%                        * calibration         : OneLight calibration
%                                                struct
%                        * describe            : struct with metadata
%    background        - OLDirection object specifying the background
%                        around which to validate.
%    oneLight          - a oneLight device driver object to control a
%                        OneLight device, can be real or simulated
%    radiometer        - radiometer object to control a spectroradiometer.
%                        Can be passed empty when simulating.
%
% Outputs:
%    validation        - Labeled compilation of outputs (see below), that
%                        is also added to direction.describe.validation.
%    SPDs              - 1x3 struct-array, with one struct for each of
%                        backgroundprimary, positive and negative,
%                        with the fields:
%                        * measuredSPD
%                        * predictedSPD
%                        * error
%    actualContrast    - Rx2 array of actual contrasts on R receptors, with
%                        a column for contrast between positive and
%                        background, and negative and background.
%                        Requires optional argument 'receptors'.
%    predictedContrast - Rx2 array of predicted contrasts on R receptors,
%                        with a column for contrast between positive and
%                        background, and negative and background
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

% History:
%    02/05/18  jv  wrote it based on OLValidatePrimaryValues
%    03/06/18  jv  adapted to work with OLDirection objects

%% Input validation
parser = inputParser;
parser.addRequired('direction',@(x) isa(x,'OLDirection'));
parser.addRequired('background',@(x) isa(x,'OLDirection'));
parser.addRequired('oneLight',@(x) isa(x,'OneLight'));
parser.addOptional('radiometer',[],@(x) isempty(x) || isa(x,'Radiometer'));
parser.addParameter('receptors',[],@(x) isa(x,'SSTReceptor') || isnumeric(x));
parser.addParameter('receptorStrings',{},@iscell);
parser.addParameter('nAverage',1,@isnumeric);
parser.addParameter('temperatureProbe',[],@(x) isempty(x) || isa(x,'LJTemperatureProbe'));
parser.parse(direction,background,oneLight,varargin{:});
assert(isscalar(direction) && isscalar(background),'OneLightToolbox:OLDirection:ValidateDirection:NonScalar',...
    'Can currently only validate a single OLDirection at a time');
assert(all(matchingCalibration(direction,background)),'OneLightToolbox:OLDirection:ValidateDirection:UnequalCalibration',...
    'Directions and backgrounds do not share a calibration');
radiometer = parser.Results.radiometer;

validation.time = now;
validation.background = background;

%% Check if calculating contrasts
receptors = parser.Results.receptors;
receptorStrings = parser.Results.receptorStrings;
if nargout > 1
    assert(~isempty(receptors),'OneLightToolbox:ApproachSupport:OLValidateDirection:NoReceptors',...
        'No receptors specified to calculate contrast on');
end
if ~isempty(receptors) && isnumeric(receptors)
    assert(~isempty(receptorStrings),'OneLightToolbox:ApproachSupport:OLValidateDirection:NoreceptorStrings',...
        'T_receptors specified, but no receptorStrings specified');
end

%% Get background primary and max primaries
backgroundPrimary = background.differentialPositive;
positive = backgroundPrimary + direction.differentialPositive;
negative = backgroundPrimary + direction.differentialNegative;
primaries = [backgroundPrimary, positive, negative];

%% Measure
SPDs = OLValidatePrimaryValues(primaries,direction.calibration,oneLight,radiometer, 'nAverage', parser.Results.nAverage, 'temperatureProbe', parser.Results.temperatureProbe);

% Write direction.describe.validation output
validation.backgroundSPD = SPDs(1);
validation.positiveSPD = SPDs(2);
validation.negativeSPD = SPDs(3);

%% Calculate nominal and actual contrast
if ~isempty(receptors)
    predictedContrastPos = SPDToReceptorContrast([SPDs([1 2]).predictedSPD],receptors);
    predictedContrastNeg = SPDToReceptorContrast([SPDs([1 3]).predictedSPD],receptors);
    predictedContrast = [predictedContrastPos(:,1) predictedContrastNeg(:,1)];
    predictedContrastPostreceptoral = [ComputePostreceptoralContrastsFromLMSContrasts(predictedContrastPos(1:3,1)),...
        ComputePostreceptoralContrastsFromLMSContrasts(predictedContrastNeg(1:3,1))];
    
    actualContrastPos = SPDToReceptorContrast([SPDs([1 2]).measuredSPD],receptors);
    actualContrastNeg = SPDToReceptorContrast([SPDs([1 3]).measuredSPD],receptors);
    actualContrast = [actualContrastPos(:,1) actualContrastNeg(:,1)];
    actualContrastPostreceptoral = [ComputePostreceptoralContrastsFromLMSContrasts(actualContrastPos(1:3,1)),...
        ComputePostreceptoralContrastsFromLMSContrasts(actualContrastNeg(1:3,1))];
    
    % Write direction.describe.validation output
    validation.actualContrast = actualContrast;
    validation.predictedContrast = predictedContrast;
    validation.predictedContrastPostreceptoral = predictedContrastPostreceptoral;
    validation.actualContrastPostreceptoral = actualContrastPostreceptoral;
else
    validation.actualContrast = [];
    validation.predictedContrast = [];
    validation.predictedContrastPostreceptoral = [];
    validation.actualContrastPostreceptoral = [];
end

%% Calculate background luminance
load T_xyz1931
S = direction.calibration.describe.S;
T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);

% Write direction.describe.validation output
validation.predictedLuminances = T_xyz(2,:) * [SPDs(:).predictedSPD];
validation.actualLuminances = T_xyz(2,:) * [SPDs(:).measuredSPD];

%% Append to direction.describe.validation
validation.time = [validation.time now];
if ~isfield(direction.describe,'validation') || isempty(direction.describe.validation)
    direction.describe.validation = validation;
else
    direction.describe.validation = [direction.describe.validation validation];
end

end