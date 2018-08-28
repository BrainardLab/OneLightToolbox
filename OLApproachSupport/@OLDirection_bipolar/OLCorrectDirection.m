function correctedDirection = OLCorrectDirection(direction, background, oneLight, radiometer, varargin)
% Corrects OLDirection_bipolar iteratively to attain desired SPD
%
% Syntax:
%   correctedDirection = OLCorrectDirection(OLDirection_bipolar, background, OneLight, radiometer)
%   correctedDirection = OLCorrectDirection(OLDirection_bipolar, background, SimulatedOneLight)
%
% Description:
%    Use an iterative measure/adjust procedure to correct the direction to
%    produce the desired SPDs. Based on a small signal approximation for
%    the adjustment.
%
% Inputs:
%    direction          - OLDirection_bipolar object specifying the
%                         direction to correct.
%    background         - OLDirection_unipolar object specifying the
%                         background to correct the direction around.
%    oneLight           - a OneLight device driver object to control a
%                         OneLight device, can be real or simulated
%    radiometer         - Radiometer object to control a
%                         spectroradiometer. Can be passed the empty matrix
%                         [] when simulating
%
% Outputs:
%    correctedDirection - the corrected OLDirection, with the corrected
%                         primaries. Additional meta- and
%                         debugging-information got added to the structure
%                         in the 'describe' property.
%
% Optional keyword arguments:
%    'receptors'            -
%    'smoothness'           - Smoothness parameter for OLSpdToPrimary.
%                             Default .001
%    any keyword argument for OLCorrectToSPD can be passed here as well
%
% See also:
%    OLCorrectToSPD, OLValidateDirection, OLValidatePrimaryValues
%

% History:
%    02/09/18  jv   created around OLCorrectPrimaryValues, based on
%                   OLCorrectCacheFileOOC.
%    03/15/18  jv   adapted for OLDirection_unipolar objects.
%    08/27/18  jv   removed legacy mode

%% Input validation
parser = inputParser;
parser.addRequired('direction',@(x) isa(x,'OLDirection_bipolar'));
parser.addRequired('background',@(x) isa(x,'OLDirection_unipolar'));
parser.addRequired('oneLight',@(x) isa(x,'OneLight'));
parser.addRequired('radiometer',@(x) isempty(x) || isa(x,'Radiometer'));
parser.addParameter('receptors',[],@(x) isnumeric(x) || isa(x,'SSTReceptor'));
parser.addParameter('smoothness',.001,@isnumeric);
parser.KeepUnmatched = true; % allows fastforwarding of kwargs to OLCorrectPrimaryValues
parser.parse(direction,background,oneLight,radiometer,varargin{:});

receptors = parser.Results.receptors;

if ~isscalar(direction)
    %% Dispatch correction for each direction
    correctedDirection = [];
    for i = 1:numel(direction)
        correctedDirection = [correctedDirection, direction(i).OLCorrectDirection(background(i),oneLight,varargin{:})];
    end
else
    %% Correct a single direction
    assert(matchingCalibration(direction,background),'OneLightToolbox:ApproachSupport:OLCorrectDirection:MismatchedCalibration',...
        'Direction and background do not share a calibration');
    time = datetime;
    
    %% Copy nominal primary into separate object
    nominalDirection = direction.copy(); % store unlinked copy of nominalDirection
    nominalDirection.SPDdifferentialDesired = direction.SPDdifferentialDesired;
    
    %% Measure background SPD
    desiredBackgroundSPD = background.SPDdifferentialDesired + background.calibration.computed.pr650MeanDark;
    measuredBackgroundSPD = OLMeasurePrimaryValues(background.differentialPrimaryValues,background.calibration,oneLight,radiometer);
    
    %% Correct to contrast?
    if ~isempty(receptors)
        %% Calculate target contrasts
        targetContrasts = direction.ToDesiredReceptorContrast(background, receptors);
        
        %% Measure initial SPDs
        combinedDirectionPos = background + direction;
        combinedDirectionNeg = background - direction;        
        initialSPD = OLMeasurePrimaryValues([combinedDirectionPos.differentialPrimaryValues combinedDirectionNeg.differentialPrimaryValues],combinedDirectionPos.calibration,oneLight, radiometer);
        
        %% Correct
        [correctedCombinedPrimaryValuesPositive, measuredContrast, correctionDataPositive] = OLCorrectToContrast(targetContrasts,initialSPD(:,1), measuredBackgroundSPD,receptors, direction.calibration,...
            oneLight,radiometer,...
            varargin{:},'lambda',parser.Results.smoothness);   
        
        [correctedCombinedPrimaryValuesNegative, measuredContrast, correctionDataNegative] = OLCorrectToContrast(-targetContrasts,initialSPD(:,2), measuredBackgroundSPD,receptors, direction.calibration,...
            oneLight,radiometer,...
            varargin{:},'lambda',parser.Results.smoothness);        
        
    else
        %% Get combined desired SPD
        % Correcting a direction (on top of a background) means correcting the
        % primary values that would combine direction and background into the
        % desired combined SPD, then subtracting the background primary values,
        % to end up with the differential primary values to add to the
        % background, i.e., the direction.
        desiredCombinedSPD = direction.SPDdifferentialDesired + background.SPDdifferentialDesired + direction.calibration.computed.pr650MeanDark;

        %% Correct differential primary values to SPD
        % To get the combined primary values, the direction and background have
        % to be added. However, when calling this routine, the background may
        % already have been corrected. In that case, the summed direction and
        % background primary values no longer correspond to the desired
        % combined SPD. Instead, convert the desiredCombinedSPD to some initial
        % primary values predicted to produce it, and correct those.
        [correctedCombinedPrimaryValuesPositive, correctedSPD, correctionDataPositive] = OLCorrectToSPD(desiredCombinedSPD(:,1),direction.calibration,...
            oneLight,radiometer,...
            varargin{:},'lambda',parser.Results.smoothness);
        [correctedCombinedPrimaryValuesNegative, correctedSPD, correctionDataNegative] = OLCorrectToSPD(desiredCombinedSPD(:,2),direction.calibration,...
            oneLight,radiometer,...
            varargin{:},'lambda',parser.Results.smoothness);
    end
    
    %% Update original OLDirection
    % Update business end
    direction.differentialPositive = correctedCombinedPrimaryValuesPositive-background.differentialPrimaryValues;
    direction.differentialNegative = correctedCombinedPrimaryValuesNegative-background.differentialPrimaryValues;
    direction.SPDdifferentialDesired = nominalDirection.SPDdifferentialDesired;
    
    % Update describe
    correctionDescribe = [correctionDataPositive, correctionDataNegative];
    correctionDescribe(1).time = [time datetime];
    correctionDescribe(2).time = [time datetime];
    correctionDescribe(1).background = background;
    correctionDescribe(2).background = background;
    correctionDescribe(1).nominalDirection = nominalDirection;
    correctionDescribe(2).nominalDirection = nominalDirection;
    
    % Add to direction.describe; append if correction already present
    if ~isfield(direction.describe,'correction') || isempty(direction.describe.correction)
        direction.describe.correction = correctionDescribe;
    else
        direction.describe.correction = [direction.describe.correction correctionDescribe];
    end
    
    % Return direction
    correctedDirection = direction;
end

end