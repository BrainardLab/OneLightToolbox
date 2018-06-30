function correctedDirection = OLCorrectDirection(direction, background, oneLight, radiometer, varargin)
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
%                         correct
%    background         - OLDirection_unipolar object specifying the
%                         background to correct the direction around
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
% Optional key/value pairs:
%    legacyMode             - Boolean. If true, use an older version of 
%                             corrections algorithm, by calling
%                             OLCorrectCacheFileOOC. If false, use the
%                             refactored approach by calling
%                             OLCorrectPrimaryValues. Defaults to true.
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
%    06/29/18  npc implemented temperature recording

%% Input validation
parser = inputParser;
parser.addRequired('direction',@(x) isa(x,'OLDirection_unipolar'));
parser.addRequired('background',@(x) isa(x,'OLDirection_unipolar'));
parser.addRequired('oneLight',@(x) isa(x,'OneLight'));
parser.addRequired('radiometer',@(x) isempty(x) || isa(x,'Radiometer'));
parser.addParameter('smoothness',.001,@isnumeric);
parser.addParameter('legacyMode',true,@islogical);
parser.addParameter('temperatureProbe',[],@(x) isempty(x) || isa(x,'LJTemperatureProbe'));
parser.addParameter('measureStateTrackingSPDs',false,islogical);

parser.KeepUnmatched = true; % allows fastforwarding of kwargs to OLCorrectPrimaryValues
parser.parse(direction,background,oneLight,radiometer,varargin{:});
radiometer = parser.Results.radiometer;

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
    time = now;

    %% Copy nominal primary into separate object
    nominalDirection = direction.copy(); % store unlinked copy of nominalDirection
    nominalDirection.SPDdifferentialDesired = direction.SPDdifferentialDesired;
    nominalBackground = background.copy(); % store unlinked copy of nominalBackground
    nominalBackground.SPDdifferentialDesired = background.SPDdifferentialDesired;
   
    if parser.Results.legacyMode 
        %% Use MatlabLibrary/OLCorrectCacheFileOOC. 
        % That routine was rolled-back from 01/06/17.
        %
        % We think that algorithm is more robust, although we don't know
        % whether that is true, or why.
        
        %% Turn into fake cache-structure
        % Rolled-back code requires a cache-structure, this function creates
        % one from the OLDirection_unipolar object
        directionData = makeFakeCache(direction, background);

        %% Correct
        calibration = direction.calibration;
        correctedDirectionData = OLCorrectCacheFileOOC(directionData, calibration, oneLight, radiometer, ...
            'OBSERVER_AGE', 32, 'smoothness', parser.Results.smoothness, ...
            'takeTemperatureMeasurements', isa(parser.Results.temperatureProbe,'LJTemperatureProbe'), ...
            'measureStateTrackingSPDs', parser.Results.measureStateTrackingSPDs);

        %% Update original OLDirection
        % Update direction business end
        direction.differentialPrimaryValues = correctedDirectionData.data(32).differencePrimary;
        direction.SPDdifferentialDesired = nominalDirection.SPDdifferentialDesired;

        % Update background business end
        background.differentialPrimaryValues = correctedDirectionData.data(32).backgroundPrimary;
        background.SPDdifferentialDesired = nominalBackground.SPDdifferentialDesired;
        
        % Update describe
        correctionDescribe = correctedDirectionData.data(32).correction;
        
        % Add temperature data
        correctionDescribe.temperatures = correctedDirectionData.temperature;
        
        % Add state tracking data
        correctionDescribe.stateTrackingData = correctedDirectionData.stateTrackingData;
    else
        %% Use refactored code, by calling OLCorrectPrimaryValues
        
        %% Correct differential primary values
        % Correcting a direction (on top of a background) means correcting the
        % primary values that would combine direction and background into the
        % desired combined SPD, then subtracting the background primary values,
        % to end up with the differential primary values to add to the
        % background, i.e., the direction.
        desiredCombinedSPD = direction.SPDdifferentialDesired + background.SPDdifferentialDesired;

        % To get the combined primary values, the direction and background have
        % to be added. However, when calling this routine, the background may
        % already have been corrected. In that case, the summed direction and
        % background primary values no longer correspond to the desired
        % combined SPD. Instead, convert the desiredCombinedSPD to some initial
        % primary values predicted to produce it, and correct those.
        nominalCombinedPrimaryValues = OLSpdToPrimary(direction.calibration,desiredCombinedSPD,'lambda',parser.Results.smoothness, 'primaryHeadroom', 0);
        [correctedCombinedPrimaryValues, correctionData] = OLCorrectPrimaryValues(nominalCombinedPrimaryValues,direction.calibration,oneLight,radiometer,varargin{:});

        % Update business end
        direction.differentialPrimaryValues = correctedCombinedPrimaryValues-background.differentialPrimaryValues;
        
        % Update describe
        correctionDescribe = correctionData;
    end
    
    % Update describe
    correctionDescribe.legacyMode = parser.Results.legacyMode;
    correctionDescribe.time = [time now];
    correctionDescribe.background = background; 
    correctionDescribe.nominalDirection = nominalDirection;
    correctionDescribe.nominalBackground = nominalBackground;
    correctionDescribe.correctedBackground = background;
    %correctionDescribe.nominalCombinedPrimaryValues = nominalCombinedPrimaryValues;
    %correctionDescribe.correctedCombinedPrimaryValues = correctedCombinedPrimaryValues;
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