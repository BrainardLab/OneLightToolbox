function correctedDirection = OLCorrectDirection(direction, background, oneLight, radiometer, varargin)
% Corrects OLDirection iteratively to attain desired SPD
%
% Syntax:
%   correctedDirection = OLCorrectDirection(OLDirection, OneLight, radiometer)
%   correctedDirection = OLCorrectDirection(OLDirection, SimulatedOneLight)
%
% Description:
%    Use an iterative measure/adjust procedure to correct the direction to
%    produce the desired SPD. Based on a small signal approximation for the
%    adjustment.
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
%    06/29/18  npc  implemented temperature recording

%% Input validation
parser = inputParser;
parser.addRequired('direction',@(x) isa(x,'OLDirection_unipolar'));
parser.addRequired('background',@(x) isa(x,'OLDirection_unipolar'));
parser.addRequired('oneLight',@(x) isa(x,'OneLight'));
parser.addRequired('radiometer',@(x) isempty(x) || isa(x,'Radiometer'));
parser.addParameter('receptors',[],@(x) isnumeric(x) || isa(x,'SSTReceptor'));
parser.addParameter('smoothness',.001,@isnumeric);
parser.addParameter('temperatureProbe',[],@(x) isempty(x) || isa(x,'LJTemperatureProbe'));
parser.addParameter('measureStateTrackingSPDs',false, @islogical);
parser.KeepUnmatched = true; % allows fastforwarding of kwargs to OLCorrectToSPD

parser.parse(direction,background,oneLight,radiometer,varargin{:});
radiometer = parser.Results.radiometer;
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
    nominalBackground = background.copy(); % store unlinked copy of nominalBackground
    nominalBackground.SPDdifferentialDesired = background.SPDdifferentialDesired;
    
    %% Measure background SPD
    desiredBackgroundSPD = background.SPDdifferentialDesired + background.calibration.computed.pr650MeanDark;
    measuredBackgroundSPD = OLMeasurePrimaryValues(background.differentialPrimaryValues,background.calibration,oneLight,radiometer);
    
    %% Correct to contrast?
    if ~isempty(receptors)
        %% Calculate target contrasts
        targetContrasts = direction.ToDesiredReceptorContrast(background, receptors);
        
        %% Measure initial SPD
        combinedDirection = direction + background;
        initialSPD = OLMeasurePrimaryValues(combinedDirection.differentialPrimaryValues,combinedDirection.calibration,oneLight, radiometer);
        
        %% Correct
        [correctedCombinedPrimaryValues, measuredContrast, correctionDescribe] = OLCorrectToContrast(targetContrasts,initialSPD, measuredBackgroundSPD,receptors, direction.calibration,...
            oneLight,radiometer,...
            varargin{:},'lambda',parser.Results.smoothness);        
        
    else
        %% Get desired combined SPD
        % Correcting a direction (on top of a background) means correcting the
        % primary values that would combine direction and background into the
        % desired combined SPD, then subtracting the background primary values,
        % to end up with the differential primary values to add to the
        % background, i.e., the direction.
        desiredCombinedSPD = direction.SPDdifferentialDesired + desiredBackgroundSPD;

        %% Correct differential primary values to SPD
        % To get the combined primary values, the direction and background have
        % to be added. However, when calling this routine, the background may
        % already have been corrected. In that case, the summed direction and
        % background primary values no longer correspond to the desired
        % combined SPD. Instead, convert the desiredCombinedSPD to some initial
        % primary values predicted to produce it, and correct those.
        [correctedCombinedPrimaryValues, correctedSPD, correctionDescribe] = OLCorrectToSPD(desiredCombinedSPD,direction.calibration,...
            oneLight,radiometer,...
            varargin{:},'lambda',parser.Results.smoothness);
    end
    
    %% Update business end
    direction.differentialPrimaryValues = correctedCombinedPrimaryValues - background.differentialPrimaryValues;
    direction.SPDdifferentialDesired = nominalDirection.SPDdifferentialDesired;   % should not be necessary, but good to enforce anyway
    
    %% Update describe
    correctionDescribe.time = [time datetime];
    correctionDescribe.nominalDirection = nominalDirection;
    correctionDescribe.background = background;
    correctionDescribe.desiredBackgroundSPD = desiredBackgroundSPD;
    
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