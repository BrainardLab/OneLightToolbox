function [validation, SPDs, excitations, contrasts] = OLValidateDirection(direction, background, oneLight, varargin)
% Validate SPDs of OLDirection_unipolar
%
% Syntax:
%   validation = OLDirection_unipolar.OLValidateDirection(background, oneLight, radiometer)
%   validation = OLValidateDirection(OLDirection_unipolar, background, oneLight, radiometer)
%   [validation, SPDs] = OLValidateDirection(...)
%   [...] = OLValidateDirection(OLDirection, background, SimulatedOneLight)
%   [...] = OLValidateDirection(...,'nAverage', nAverage)
%   [..., excitation, contrasts] = OLValidateDirection(..., 'receptors', SSTReceptor)
%   [..., excitation, contrasts] = OLValidateDirection(..., 'receptors', T_receptors)
%
% Description:
%    Measures the SPD of an OLDirection_unipolar, and compares it to the
%    desired SPD. Since OLDirections store differential SPDs, a validation
%    must occur around a background.
%
%    Optionally calculates the actual and predicted change in excitation on
%    a given set of receptors, and contrasts on receptors between multiple
%    directions.
%
%    Two (sets of) excitations, receptor contrasts and postreceptoral
%    contrasts are returned:
%     1) the desired (nominal) excitations/contrasts, calculated from the
%        desired SPDs of the direction and background
%     2) the actual excitations/contrasts, calculated from the measured
%        SPDs
%
%    This method saves a validation by appending it to the the
%    describe.validation field of the OLDirection.
%
% Inputs:
%    direction   - OLDirection_unipolar object specifying the direction to
%                  validate.
%    background  - OLDirection_unipolar object specifying the background
%                  around which to validate.
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
%    SPDs        - structarray, with one struct for background, one
%                  struct for the combined backgounrd+direction, and one
%                  struct for the differential direction, with the fields:
%                  * predictedSPD: predicted from primary values
%                  * measuredSPD: measured
%                  * errorSPD: predictedSPD-measuredSPD
%                  * desiredSPD: pulled from
%                                direction.SPDdifferentialDesired
%    excitations - single struct with three fields (each is a RxN vector of
%                  excitations on R receptors by each of N directions)
%                  * desired: based on direction.SPDdesired
%                  * predicted: based on predicted SPD
%                  * actual: based on measured SPD
%    contrasts   - single struct with three fields:
%                  * desired: based on direction.SPDdesired
%                  * predicted: based on predicted SPD
%                  * actual: based on measured SPD
%                  Each field is an NxNxR array of all pairwise contrasts
%                  between the N directions, on R receptors. (Simplifies
%                  for N=2, see SPDToReceptorContrast).
%
% Optional key/value pairs:
%    receptors        - an SSTReceptor object, specifying the receptors on
%                       which to calculate contrasts.
%    nAverage         - number of measurements to average. Default 1.
%    temperatureProbe - LJTemperatureProbe object to drive a
%                       LabJack temperature probe
%    label            - user-defined string to label validation with (ends
%                       up in validation.label)
%
% See also:
%    OLValidatePrimaryValues, OLMeasurePrimaryValues, SPDToReceptorContrast

% History:
%    02/05/18  jv  wrote it based on OLValidatePrimaryValues
%    03/06/18  jv  adapted to work with OLDirection objects
%    03/15/18  jv  specified to OLDirection_unipolar object, support for
%                  multiple OLDirection_unipolar directions.
%    03/19/18  jv  validation must be around a background (to allow
%                  validation of differential directions).
%    06/29/18  npc implemented temperature recording
%    06/30/18  npc implemented state tracking SPD recording

%% Input validation
parser = inputParser;
parser.addOptional('radiometer',[],@(x) isempty(x) || isa(x,'Radiometer'));
parser.addParameter('receptors',[],@(x) isa(x,'SSTReceptor') || isnumeric(x));
parser.addParameter('label',"");
parser.KeepUnmatched = true;
parser.parse(varargin{:});

% Check if calculating contrasts
receptors = parser.Results.receptors;
if nargout > 2
    assert(~isempty(receptors),'OneLightToolbox:ApproachSupport:OLValidateDirection:NoReceptors',...
        'No receptors specified to calculate excitation for');
end

if ~isscalar(direction)
    %% Dispatch each direction
    assert(numel(direction) == numel(background),'OneLightToolbox:ApproachSupport:OLValidateDirection:MismatchSize',...
        'Number of backgrounds must equal number of directions');
    validation = [];   
    for i = 1:numel(direction)
        args = parser.Results;
        if ~isempty(parser.Results.label)
            assert(numel(args.label) == numel(direction),'OneLightToolbox:ApproachSupport:OLValidateDirection:MismatchSize',...
                'Number of labels does not equal number of directions');
            args.label = string(args.label);
            args.label = args.label(i);
        end
        validation = [validation OLValidateDirection(direction(i),background(i), oneLight, args)];
    end
else
    %% Validate single direction
    if isempty(background)
        background = OLDirection_unipolar.Null(direction.calibration);
    else
        assert(matchingCalibration(direction,background),'OneLightToolbox:ApproachSupport:OLValidateDirection:MismatchedCalibration',...
            'Direction and background do not share a calibration.');
    end
    radiometer = parser.Results.radiometer;

    validation.background = background;
    validation.time = datetime; % take stock of how long taking

    %% Determine desired SPDs
    % An OLDirection defines a differerntial direction: a set of primary
    % values to be added to some other vector in primary space, to get a
    % desired change in SPD. Thus, an OLDireciton stores differential
    % primary values (direction.differentialPrimaryValues), and a
    % differential desired SPD (direction.SPDdifferentialDesired). This
    % makes the desired SPD independent of starting location, i.e. it
    % preserves that adding nominal directions is equal to adding their
    % desired SPDs (aside from floating point error).
    %
    % For nominal directions, the desired differential SPD should be
    % predicted from the differential primary values and the calibration.
    % This is done by OLDirection.ToPredictedSPD. When an
    % OLDirection_unipolar is constructed, this predicted automatically
    % gets added to direction.SPDdifferentialDesired.
    %
    % For corrected directions, however, this desired differential SPD can
    % no longer be predicted from the primary values and the calibration.
    % Instead, OLCorrectDirection(direction) does NOT change
    % direction.SPDdifferentialDesired.
    %
    % When validating a direction, the information in
    % direction.SPDdiffererntialDesired as the desired differential SPD for
    % a direction. However, if this is empty, our best bet is to used the
    % predicted SPD as the desired differential SPD.

    if isempty(direction.SPDdifferentialDesired)
        SPDdifferentialDesired = direction.ToPredictedSPD;
    else
        SPDdifferentialDesired = direction.SPDdifferentialDesired;
    end

    % Since differential directions/SPDs cannot be measured directly, the
    % desired differential SPD of a direction has to be combined with the
    % SPD of a background (and the mean dark SPD), in order to be measured.
    if isempty(background.SPDdifferentialDesired)
        SPDbackgroundDesired = background.ToPredictedSPD;
    else
        SPDbackgroundDesired = background.SPDdifferentialDesired;
    end
    SPDbackgroundDesired = SPDbackgroundDesired + background.calibration.computed.pr650MeanDark;
    SPDcombinedDesired = SPDdifferentialDesired + SPDbackgroundDesired;

    %% Measure SPDs
    % Call OLValidatePrimaryValues on all the differentialPrimaryValues of
    % all directions
    validation.differentialPrimaryValues = direction.differentialPrimaryValues;
    validation.measuredPrimaryValues = [background.differentialPrimaryValues, direction.differentialPrimaryValues+background.differentialPrimaryValues];
    [SPDs, temperatures, stateTrackingData] = OLValidatePrimaryValues([background.differentialPrimaryValues, direction.differentialPrimaryValues+background.differentialPrimaryValues],...
        direction.calibration,oneLight,radiometer, ...
        parser.Unmatched);

    % Add temperatures to validation
    validation.temperatures = temperatures;
    
    % Add stateTrackingData to validation
    validation.stateTrackingData = stateTrackingData;
    
    % Add desired SPDs to the SPDs structarray
    SPDs(1).desiredSPD = SPDbackgroundDesired; % background
    SPDs(2).desiredSPD = SPDcombinedDesired;   % direction

    %% Determine differential SPD, add to SPDs struct array
    SPDdifferentialMeasured = SPDs(2).measuredSPD - SPDs(1).measuredSPD;
    SPDs(3).desiredSPD = SPDdifferentialDesired;
    SPDs(3).predictedSPD = direction.ToPredictedSPD;
    SPDs(3).measuredSPD = SPDdifferentialMeasured;
    SPDs(3).error = SPDdifferentialDesired - SPDdifferentialMeasured;

    %% Calculate nominal and actual excitation
    if ~isempty(receptors)       
        excitations.desired = SPDToReceptorExcitation([SPDs.desiredSPD],receptors);
        %excitations.predicted = SPDToReceptorExcitation([SPDs.predictedSPD],receptors);
        excitations.actual = SPDToReceptorExcitation([SPDs.measuredSPD],receptors);

        contrasts.desired = ReceptorExcitationToReceptorContrast(excitations.desired(:,1:2));
        %contrasts.predicted = ReceptorExcitationToReceptorContrast(excitations.predicted(:,1:2));
        contrasts.actual = ReceptorExcitationToReceptorContrast(excitations.actual(:,1:2));

        %     predictedContrastPostreceptoral = [ComputePostreceptoralContrastsFromLMSContrasts(predictedContrastPos(1:3,1)),...
        %         ComputePostreceptoralContrastsFromLMSContrasts(predictedContrastNeg(1:3,1))];
        % placeholder as we add the ability to calculate postreceptoral
        % contrast
        validation.postreceptoralContrastDesired = ComputePostreceptoralContrastsFromLMSContrasts(contrasts.desired(1:3,1));
        %validation.postreceptoralContrastPredicted = ComputePostreceptoralContrastsFromLMSContrasts(contrasts.predicted(1:3,1));
        validation.postreceptoralContrastActual = ComputePostreceptoralContrastsFromLMSContrasts(contrasts.actual(1:3,1));
        
        % Write direction.describe.validation output
        validation.receptors = receptors;
        validation.excitationDesired = excitations.desired;
        %validation.excitationPredicted = excitations.predicted;
        validation.excitationActual = excitations.actual;
        validation.contrastDesired = contrasts.desired;
        %validation.contrastPredicted = contrasts.predicted;
        validation.contrastActual = contrasts.actual;
    else
        validation.receptors = [];
        validation.excitationDesired = [];
        %validation.excitationPredicted = [];
        validation.excitationActual = [];
        validation.contrastDesired = [];
        %validation.contrastPredicted = [];
        validation.contrastActual = [];
    end

    %% Calculate direction luminance
    load T_xyz1931
    S = direction(1).calibration.describe.S;
    T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);

    % Write direction.describe.validation output
    validation.luminanceDesired = T_xyz(2,:) * [SPDs.desiredSPD];
    %validation.luminancePredicted = T_xyz(2,:) * [SPDs.predictedSPD];
    validation.luminanceActual = T_xyz(2,:) * [SPDs.measuredSPD];

    %% Append to each directions .describe.validation
    validation.time = [validation.time datetime];
    validation.label = parser.Results.label;

    % Extract information for just this direction(i)
    validation.SPDbackground = SPDs(1);
    validation.SPDcombined = SPDs(2);
    validation.SPDdifferential = SPDs(3);
    
    % Add to direction(i).describe; append if validations already present
    if ~isfield(direction.describe,'validation') || isempty(direction.describe.validation)
        direction.describe.validation = validation;
    else
        direction.describe.validation = [direction.describe.validation validation];
    end
end

end