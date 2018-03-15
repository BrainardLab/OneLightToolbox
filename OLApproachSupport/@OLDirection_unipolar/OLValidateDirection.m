function [validation, SPDs, excitations, contrasts] = OLValidateDirection(direction, oneLight, varargin)
% Validate SPDs of OLDirection_unipolar
%
% Syntax:
%   validation = OLDirection_unipolar.OLValidateDirection(oneLight, radiometer)
%   validation = OLValidateDirection(OLDirection_unipolar, oneLight, radiometer)
%   [validation, SPDs] = OLValidateDirection(OLDirection_unipolar, oneLight, radiometer)
%   [...] = OLValidateDirection(OLDirection, SimulatedOneLight)
%   [...] = OLValidateDirection(...,'nAverage', nAverage)
%   [..., excitation, contrasts] = OLValidateDirection(..., 'receptors', SSTReceptor)
%   [..., excitation, contrasts] = OLValidateDirection(..., 'receptors', T_receptors)

%
% Description:
%    Measures the SPD of an OLDirection_unipolar, and compares it to the
%    desired SPD.
%
%    Optionally calculates the actual and predicted change in excitation on
%    a given set of receptors, and contrasts on receptors between multiple
%    directions.
%
%    Saves this validation by appending it to the the describe.validation
%    field of the OLDirection.
%
% Inputs:
%    direction   - OLDirection_unipolar object specifying the direction to 
%                  validate.
%    oneLight    - a oneLight device driver object to control a OneLight 
%                  device, can be real or simulated
%    radiometer  - radiometer object to control a spectroradiometer. Can be
%                  passed empty when simulating.
%
% Outputs:
%    validation  - Struct containing labeled compilation of outputs (SPDs,
%                  excitations, contrasts) for all directions. A smaller
%                  version of this, specific to each direction, also gets
%                  added to direction.describe.validation.
%    SPDs        - structarray (struct per direction) with the fields:
%                  * predictedSPD: predicted from primary values)
%                  * measuredSPD: measured
%                  * errorSPD: predictedSPD-measuredSPD
%    excitations - single struct with three fields (each is a RxN vector of
%                  excitations on R receptors by each of N directions)
%                  * desiredExcitation: based on direction.SPDdesired
%                  * predictedExcitation: based on predicted SPD
%                  * actualExcitation: based on measured SPD
%    contrasts   - single struct with three fields:
%                  * desiredContrasts: based on direction.SPDdesired
%                  * predictedContrasts: based on predicted SPD
%                  * actualContrasts: based on measured SPD
%                  Each field is an NxNxR array of all pairwise contrasts
%                  between the N directions, on R receptors. (Simplifies
%                  for N=2, see SPDToReceptorContrast).
%
% Optional key/value pairs:
%    receptors        - an SSTReceptor object, specifying the receptors on 
%                       which to calculate contrasts.
%    nAverage         - number of measurements to average. Default 1.
%    temperatureProbe - TODO: LJTemperatureProbe object to drive a
%                       LabJack temperature probe
%
% See also:
%    OLValidatePrimaryValues, OLMeasurePrimaryValues, SPDToReceptorContrast

% History:
%    02/05/18  jv  wrote it based on OLValidatePrimaryValues
%    03/06/18  jv  adapted to work with OLDirection objects
%    03/15/18  jv  specified to OLDirection_unipolar object, support for
%                  multiple OLDirection_unipolar directions.

%% Input validation
parser = inputParser;
parser.addRequired('direction',@(x) isa(x,'OLDirection_unipolar'));
parser.addRequired('oneLight',@(x) isa(x,'OneLight'));
parser.addOptional('radiometer',[],@(x) isempty(x) || isa(x,'Radiometer'));
parser.addParameter('receptors',[],@(x) isa(x,'SSTReceptor') || isnumeric(x));
parser.addParameter('nAverage',1,@isnumeric);
parser.addParameter('temperatureProbe',[],@(x) isempty(x) || isa(x,'LJTemperatureProbe'));
parser.parse(direction,oneLight,varargin{:});

if ~isscalar(direction)
    assert(all(matchingCalibration(direction(1),direction(2:end))));
end

% Check if calculating contrasts
receptors = parser.Results.receptors;
if nargout > 2
    assert(~isempty(receptors),'OneLightToolbox:ApproachSupport:OLValidateDirection:NoReceptors',...
        'No receptors specified to calculate excitation for');
end

radiometer = parser.Results.radiometer;

validation.time = now; % take stock of how long taking

%% Copy desired SPDs
% For nominal directions, the desired SPD should be predicted from the
% differential primary values and the calibration. This is done by
% OLDirection.ToPredictedSPD. When an OLDirection_unipolar is constructed,
% this predicted automatically gets added to direction.SPDdesired.
%
% For corrected directions, however, this desired SPD can no longer be
% predicted from the primary values and the calibration. Instead,
% OLCorrectDirection(direction) does NOT change direction.SPDdesired.
%
% When validating a direction, the information in direction.SPDdesired as
% the desired SPD for a direction. However, if this is empty, our best bet
% is to used the predicted SPD as the desired SPD.
%
% [NOTE: JV - since directions contain differential primary values, the SPD
%  returned by direction.ToPredictedSPD is a differentialSPD. This does not
%  have the mean dark SPD added in to it. This is what is stored in
%  .SPDdesired, because it makes the desired SPD independent of starting
%  location, i.e. it preserves that adding nominal directions is equal to
%  adding their desired SPDs (aside from floating point error). One wrinkle
%  is that we have to take the dark SPD into account when calculating error
%  from measured SPD]
for i = 1:numel(direction)
    if isempty(direction(i).SPDdesired)
        validation.SPDdesired(:,i) = direction(i).ToPredictedSPD;
    else
        validation.SPDdesired(:,i) = direction(i).SPDdesired;
    end
end

%% Measure SPDs
% Call OLValidatePrimaryValues on all the differentialPrimaryValues of all
% directions
SPDs = OLValidatePrimaryValues([direction.differentialPrimaryValues],direction(1).calibration,oneLight,radiometer, 'nAverage', parser.Results.nAverage, 'temperatureProbe', parser.Results.temperatureProbe);

% Write direction.describe.validation output
validation.SPDmeasured = [SPDs.measuredSPD];
validation.SPDpredicted = [SPDs.predictedSPD];
% [NOTE: JV - SPDs.predictedSPD has the mean dark SPD incorporated. This
%  means it likely won't match the SPDdesired]

% Calculate error in SPD, as measured SPD subtracted from desired SPD (with
% added mean dark SPD)
validation.SPDerror = (validation.SPDdesired+direction(1).calibration.computed.pr650MeanDark)-validation.SPDmeasured;

%% Calculate nominal and actual excitation
if ~isempty(receptors)
    excitations.desiredExcitation = SPDToReceptorExcitation([validation.SPDdesired],receptors);
    excitations.predictedExcitation = direction.ToReceptorExcitation(receptors);
    excitations.actualExcitation = SPDToReceptorExcitation([validation.SPDmeasured],receptors);
    
    contrasts.desiredContrasts = ReceptorExcitationToReceptorContrast(excitations.desiredExcitation);
    contrasts.predictedContrasts = ReceptorExcitationToReceptorContrast(excitations.predictedExcitation);
    contrasts.actualContrasts = ReceptorExcitationToReceptorContrast(excitations.actualExcitation);
    
%     predictedContrastPos = SPDToReceptorContrast([SPDs([1 2]).predictedSPD],receptors);
%     predictedContrastNeg = SPDToReceptorContrast([SPDs([1 3]).predictedSPD],receptors);
%     predictedContrast = [predictedContrastPos(:,1) predictedContrastNeg(:,1)];
%     predictedContrastPostreceptoral = [ComputePostreceptoralContrastsFromLMSContrasts(predictedContrastPos(1:3,1)),...
%         ComputePostreceptoralContrastsFromLMSContrasts(predictedContrastNeg(1:3,1))];

    % Write direction.describe.validation output
    validation.excitationDesired = excitations.desiredExcitation;
    validation.excitationPredicted = excitations.predictedExcitation;
    validation.excitationActual = excitations.actualExcitation;
else
    validation.excitationDesired = [];
    validation.excitationPredicted = [];
    validation.excitationActual = [];
end

%% Calculate direction luminance
load T_xyz1931
S = direction(1).calibration.describe.S;
T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);

% Write direction.describe.validation output
validation.luminanceDesired = T_xyz(2,:) * [validation.SPDdesired];
validation.luminancePredicted = T_xyz(2,:) * [validation.SPDpredicted];
validation.luminanceActual = T_xyz(2,:) * [validation.SPDmeasured];

%% Append to each directions .describe.validation
validation.time = [validation.time now];
for i = 1:numel(direction)
    % Extract information for just this direction(i)
    validationForDirection.time = validation.time;
    validationForDirection.primaryValues = direction(i).differentialPrimaryValues;
    validationForDirection.SPDdesired = validation.SPDdesired(:,i);
    validationForDirection.SPDpredicted = validation.SPDpredicted(:,i);
    validationForDirection.SPDmeasured = validation.SPDmeasured(:,i);
    validationForDirection.SPDerror = validation.SPDerror(:,i);
    validationForDirection.excitationPredicted = validation.excitationPredicted(:,i);
    validationForDirection.excitationDesired = validation.excitationDesired(:,i);
    validationForDirection.excitationActual = validation.excitationActual(:,i);
    validationForDirection.luminanceDesired = validation.luminanceDesired(i);
    validationForDirection.luminancePredicted = validation.luminancePredicted(i);
    validationForDirection.luminanceActual = validation.luminanceActual(i);
    
    % Add to direction(i).describe; append if validations already present
    if ~isfield(direction(i).describe,'validation') || isempty(direction(i).describe.validation)
        direction(i).describe.validation = validationForDirection;
    else
        direction(i).describe.validation = [direction(i).describe.validation validationForDirection];
    end
end

end