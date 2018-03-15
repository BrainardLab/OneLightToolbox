function correctedDirection = OLCorrectDirection(direction, oneLight, varargin)
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
parser.addRequired('oneLight',@(x) isa(x,'OneLight'));
parser.addOptional('radiometer',[],@(x) isempty(x) || isa(x,'Radiometer'));
parser.KeepUnmatched = true; % allows fastforwarding of kwargs to OLCorrectPrimaryValues
parser.parse(direction,oneLight,varargin{:});
assert(isscalar(direction),'OneLightToolbox:OLDirection:ValidateDirection:NonScalar',...
    'Can currently only validate a single OLDirection at a time');
% assert(all(matchingCalibration(direction,background)),'OneLightToolbox:OLDirection:ValidateDirection:UnequalCalibration',...
%     'Directions and backgrounds do not share a calibration');
radiometer = parser.Results.radiometer;

time = now;

%% Copy nominal primary into separate object
nominalDirection = OLDirection_unipolar(direction.differentialPrimaryValues,direction.calibration,direction.describe);
nominalDirection.SPDdesired = direction.SPDdesired;

%% Correct differential primary values
[correctedDifferentialPrimaryValues, correctionData] = OLCorrectPrimaryValues(direction.differentialPrimaryValues,direction.calibration,oneLight,radiometer,varargin{:});

%% Update original OLDirection
% Update business end
direction.differentialPrimaryValues = correctedDifferentialPrimaryValues;
direction.SPDdesired = nominalDirection.SPDdesired;

% Update describe
correctionDescribe = correctionData;
correctionDescribe.time = [time now];

% Add to direction.describe; append if correction already present
if ~isfield(direction.describe,'correction') || isempty(direction.describe.correction)
    direction.describe.correction = correctionDescribe;
else
    direction.describe.corection = [direction.describe.correction correctionDescribe];
end

end