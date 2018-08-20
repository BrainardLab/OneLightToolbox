function correctedDirection = OLCorrectDirection(direction, background, oneLight, radiometer, varargin)
% Corrects OLDirection_bipolar iteratively to attain predicted SPD
%
% Syntax:
%   correctedDirection = OLCorrectDirection(OLDirection_bipolar, background, OneLight, radiometer)
%   correctedDirection = OLCorrectDirection(OLDirection_bipolar, background, SimulatedOneLight)
%
% Description:
%    Detailed explanation goes here
%
% Inputs:
%    direction          - OLDirection_bipolar object specifying the
%                         direction to correct.
%    background         - OLDirection_unipolar object specifying the
%                         background to correct the direction around.
%    oneLight           - a OneLight device driver object to control a
%                         OneLight device, can be real or simulated
%    radiometer         - Radiometer object to control a
%                         spectroradiometer. Can be passed empty when
%                         simulating
%
% Outputs:
%    correctedDirection - the corrected OLDirection, with the corrected
%                         primaries. Additional meta- and
%                         debugging-information got added to the structure
%                         in the 'describe' property.
%
% Optional key/value pairs:
%    nIterations            - Number of iterations. Default is 20.
%    learningRate           - Learning rate. Default is .8.
%    learningRateDecrease   - Decrease learning rate over iterations?
%                             Default is true.
%    asympLearningRateFactor- If learningRateDecrease is true, the
%                             asymptotic learning rate is
%                             (1-asympLearningRateFactor)*learningRate.
%                             Default = .5.
%    smoothness             - Smoothness parameter for OLSpdToPrimary.
%                             Default .001.
%    iterativeSearch        - Do iterative search with fmincon on each
%                             measurement interation? Default is true.
%
% See also:
%    OLCorrectPrimaryValues, OLValidateDirection, OLValidatePrimaryValues
%

% History:
%    02/09/18  jv  created around OLCorrectPrimaryValues, based on
%                  OLCorrectCacheFileOOC.
%    03/15/18  jv  adapted for OLDirection_unipolar objects.

%% Input validation
parser = inputParser;
parser.addRequired('direction',@(x) isa(x,'OLDirection_bipolar'));
parser.addRequired('background',@(x) isa(x,'OLDirection_unipolar'));
parser.addRequired('oneLight',@(x) isa(x,'OneLight'));
parser.addRequired('radiometer',@(x) isempty(x) || isa(x,'Radiometer'));
parser.addParameter('smoothness',.001,@isnumeric);
parser.KeepUnmatched = true; % allows fastforwarding of kwargs to OLCorrectPrimaryValues
parser.parse(direction,background,oneLight,radiometer,varargin{:});

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
   
    %% Correct differential primary values
    % Correcting a direction (on top of a background) means correcting the
    % primary values that would combine direction and background into the
    % desired combined SPD, then subtracting the background primary values,
    % to end up with the differential primary values to add to the
    % background, i.e., the direction.
    desiredCombinedSPD = direction.SPDdifferentialDesired + background.SPDdifferentialDesired + direction.calibration.computed.pr650MeanDark;
    
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
    correctionDescribe(1).correctedCombinedPrimaryValues = correctedCombinedPrimaryValuesPositive;
    correctionDescribe(2).correctedCombinedPrimaryValues = correctedCombinedPrimaryValuesNegative;
    
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