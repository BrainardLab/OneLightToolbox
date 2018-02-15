function correctedDirection = OLCorrectDirection(directionStruct, calibration, oneLight, radiometer, varargin)
% Corrects direction struct iteratively to attain predicted SPD
%
% Syntax:
%   correctedDirectionStruct = OLCorrectDirection(directionStruct, calibration, OneLight, radiometer)
%   correctedDirectionStruct = OLCorrectDirection(directionStruct, calibration, SimulatedOneLight)
%
% Description:
%    Detailed explanation goes here
%
% Inputs:
%    directionStruct    - a single struct defining a direction, with at
%                         least the following fields:
%                         * backgroundPrimary   : the primary values for
%                                                 the background.
%                         * differentialPositive: the difference in primary
%                                                 values to be added to the
%                                                 background primary to
%                                                 create the positive
%                                                 direction
%                         * differentialNegative: the difference in primary
%                                                 values to be added to the
%                                                 background primary to
%                                                 create the negative
%                                                 direction
%                         * describe            : structure with additional
%                                                 metadata; data about
%                                                 corrections gets added to
%                                                 this
%    calibration        - struct containing calibration for oneLight
%    oneLight           - a OneLight device driver object to control a
%                         OneLight device, can be real or simulated
%    radiometer         - Radiometer object to control a
%                         spectroradiometer. Can be passed empty when
%                         simulating
%
% Outputs:
%    correctedDirection - the updated directionStruct, with the corrected
%                         primaries. Additional meta- and
%                         debugging-information got added to the structure
%                         in the 'describe' field.
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
%    OLCorrectPrimaryValues, OLValidatePrimaryValues
%

% History:
%    02/09/18  jv  created around OLCorrectPrimaryValues, based on
%                  OLCorrectCacheFileOOC.

%% Input validation
parser = inputParser;
parser.addRequired('direction',@isstruct);
parser.addRequired('calibration',@isstruct);
parser.addRequired('oneLight',@(x) isa(x,'OneLight'));
parser.addOptional('radiometer',[],@(x) isempty(x) || isa(x,'Radiometer'));
parser.KeepUnmatched = true; % allows fastforwarding of kwargs to OLCorrectPrimaryValues
parser.parse(directionStruct,calibration,oneLight,radiometer,varargin{:});

%% Save pre-correction primaries into describe
correctedDirection.describe.nominal = directionStruct.describe;
correctedDirection.describe.nominal.backgroundPrimary = directionStruct.backgroundPrimary;
correctedDirection.describe.nominal.differentialPositive = directionStruct.differentialPositive;
correctedDirection.describe.nominal.differentialNegative = directionStruct.differentialNegative;

%% Get initial primaries background, directionPositive, directionNegative
backgroundPrimaryInitial = directionStruct.backgroundPrimary;
directionPositiveInitial = directionStruct.backgroundPrimary + directionStruct.differentialPositive;
directionNegativeInitial = directionStruct.backgroundPrimary + directionStruct.differentialNegative;

%% Correct background
[backgroundPrimaryCorrected, dataBackground] = OLCorrectPrimaryValues(backgroundPrimaryInitial,calibration,oneLight,radiometer,varargin{:});

%% Correct positive differential, but only if nonzero
if any(directionStruct.differentialPositive)
    [directionPositiveCorrected, dataDirectionPositive] = OLCorrectPrimaryValues(directionPositiveInitial,calibration,oneLight,radiometer,varargin{:});
else
    directionPositiveCorrected = backgroundPrimaryCorrected;
    dataDirectionPositive = dataBackground;
end

%% Correct negative differential, but only if nonzero
if any(directionStruct.differentialNegative)
    [directionNegativeCorrected, dataDirectionNegative] = OLCorrectPrimaryValues(directionNegativeInitial,calibration,oneLight,radiometer,varargin{:});
else
    directionNegativeCorrected = backgroundPrimaryCorrected;
    dataDirectionNegative = dataBackground;
end

%% Repackage into directionStruct
correctedDirection.backgroundPrimary = backgroundPrimaryCorrected;
correctedDirection.differentialPositive = directionPositiveCorrected - backgroundPrimaryCorrected;
correctedDirection.differentialNegative = directionNegativeCorrected - backgroundPrimaryCorrected;
correctedDirection.calibration = calibration;
correctedDirection.describe.correction.background = dataBackground;
correctedDirection.describe.correction.directionPositive = dataDirectionPositive;
correctedDirection.describe.correction.directionNegative = dataDirectionNegative;
end