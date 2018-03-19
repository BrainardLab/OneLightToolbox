function correctedDirection = OLCorrectDirection(direction, background, oneLight, varargin)
% Corrects OLDirection iteratively to attain predicted SPD
%
% Syntax:
%   correctedDirection = OLCorrectDirection(OLDirection, OneLight, radiometer)
%   correctedDirection = OLCorrectDirection(OLDirection, SimulatedOneLight)
%
% Description:
%    Detailed explanation goes here
%
% Inputs:
%    direction          - OLDirection object specifying the direction to
%                         correct.
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
%                             measurement interation? Default is false.
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
parser.addRequired('direction',@(x) isa(x,'OLDirection_unipolar'));
parser.addRequired('background',@(x) isa(x,'OLDirection_unipolar'));
parser.addRequired('oneLight',@(x) isa(x,'OneLight'));
parser.addOptional('radiometer',[],@(x) isempty(x) || isa(x,'Radiometer'));
parser.KeepUnmatched = true; % allows fastforwarding of kwargs to OLCorrectPrimaryValues
parser.parse(direction,background,oneLight,varargin{:});
radiometer = parser.Results.radiometer;

if ~isscalar(direction)
    %% Dispatch correction for each direction
	correctedDirection = [];
    for i = 1:numel(direction)
        correctedDirection = [correctedDirection, direction(i).OLCorrectDirection(background(i),oneLight,varargin{:})];
    end
else
    %% Correct a single direction
    time = now;

    %% Copy nominal primary into separate object
    nominalDirection = OLDirection_unipolar(direction.differentialPrimaryValues,direction.calibration,direction.describe);
    nominalDirection.SPDdifferentialDesired = direction.SPDdifferentialDesired;
   
    %% Correct differential primary values
    nominalCombinedPrimaryValues = direction.differentialPrimaryValues+background.differentialPrimaryValues;
    [correctedCombinedPrimaryValues, correctionData] = OLCorrectPrimaryValues(nominalCombinedPrimaryValues,direction.calibration,oneLight,radiometer,varargin{:});
    
    %% Update original OLDirection
    % Update business end
    direction.differentialPrimaryValues = correctedCombinedPrimaryValues-background.differentialPrimaryValues;
    direction.SPDdifferentialDesired = nominalDirection.SPDdifferentialDesired;

    % Update describe
    correctionDescribe = correctionData;
    correctionDescribe.time = [time now];
    correctionDescribe.background = background; 
    correctionDescribe.nominalDirection = nominalDirection;
    correctionDescribe.nominalCombinedPrimaryValues = nominalCombinedPrimaryValues;
    correctionDescribe.correctedCombinedPrimaryValues = correctedCombinedPrimaryValues;

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