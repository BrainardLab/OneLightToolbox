function [correctedPrimaryValues, measuredSPD, detailedData] = OLCorrectToSPD(targetSPD, calibration, oneLight, radiometer, varargin)
% Corrects primary values iteratively to attain predicted SPD
%
% Syntax:
%   correctedPrimaryValues = OLCorrectToSPD(nominalPrimaryValues, calibration, OneLight, radiometer)
%   correctedPrimaryValues = OLCorrectToSPD(nominalPrimaryValues, calibration, SimulatedOneLight, [])
%   [correctedPrimaryValues, detailedData] = OLCorrectPrimaryValues(...)
%   correctedPrimaryValues = OLCorrectPrimaryValues(..., 'smoothness',.01)
%
% Description:
%    Use an iterative measure/adjust procedure to find primary values that
%    produce the desired spectrum. Based on a small signal approximation
%    for the adjustment.
%
% Inputs:
%    targetSPD                  - nWlsx1 column vector, where nWls is the
%                                 number of wavelength bands measured,
%                                 defining target spectral power
%                                 distribution to correct primary values
%                                 to. This is in the scaling of the
%                                 calibration structure.
%    calibration                - Struct containing calibration for oneLight
%    oneLight                   - OneLight device driver object to control 
%                                 a OneLight device. Can be real or
%                                 simulated
%    radiometer                 - Radiometer object to control a
%                                 spectroradiometer. Can be passed empty
%                                 when simulating
%
% Outputs:
%    correctedPrimaryValues     - Px1 column vector of primary values, where P
%                                 is the number of values for effective
%                                 device primaries.
%    measuredSPD                - nWlsx1 column vector, where nWls is the
%                                 number of wavelength bands measured, of
%                                 the SPD measured after correction. This
%                                 is the actual measurement, not scaled by
%                                 lightlevelScalar.
%    detailedData               - A ton of data in a structure, mainly for 
%                                 debugging purposes. See
%                                 OLCheckPrimaryCorrection
%
% Optional key/value pairs:
%    'lightlevelScalar'         - Scalar numeric, factor by which to
%                                 multiply measured SPDs to bring into 
%                                 calibration range. See
%                                 OLMeasureLightlevelScalar. Default is 1.
%    'nIterations'              - Number of iterations. Default is 20.
%    'learningRate'             - Learning rate. Default is .8.
%    'learningRateDecrease'     - Decrease learning rate over iterations?
%                                 Default is true.
%    'asympLearningRateFactor'  - If learningRateDecrease is true, the 
%                                 asymptotic learning rate is
%                                 (1-asympLearningRateFactor)*learningRate. 
%                                 Default = .5.
%    'smoothness'               - Smoothness parameter for OLSpdToPrimary.
%                                 Default .001.
%    'iterativeSearch'          - Do iterative search with fmincon on each
%                                 measurement interation? Default is true.
%    'temperatureProbe'         - LJTemperatureProbe object to drive a
%                                 LabJack temperature probe. Default empty.
%    'measureStateTrackingSPDs' - Make state tracking measurements?
%                                 Default false.
%
% See also:
%    OLValidatePrimaryValues, OLLinearDeltaPrimaries, OLIterativeDeltaPrimaries
%

% History:
%    02/09/18  jv   extracted from OLCorrectCacheFileOOC as
%                   OLCorrectPrimaryValues
%    06/29/18  npc  implemented temperature recording
%    06/30/18  npc  implemented state tracking SPD recording
%    08/16/18  jv   OLCorrectToSPD
%    08/28/18  jv   pass lightelevelScalar as optional keyword argument.

% Examples:
%{
    %% Test under simulation
    % Get calibration
    demoCalFolder = fullfile(tbLocateToolbox('OneLightToolbox'),'OLDemoCal');
    calibration = OLGetCalibrationStructure('CalibrationFolder',demoCalFolder,'CalibrationType','DemoCal');

    % Define inputs
    targetSPD = OLPrimaryToSpd(calibration,.5*ones(calibration.describe.numWavelengthBands,1));
    oneLight = OneLight('simulate',true,'plotWhenSimulating',false);

    % Correct
    [correctedPrimaryValues, measuredSPD, data] = OLCorrectToSPD(targetSPD,calibration,oneLight,[]);
%}

%% Input validation
parser = inputParser;
parser.addRequired('targetSPD',@(x)validateattributes(x,{'numeric'},{'vector','real','finite','nonnegative'}));
parser.addRequired('calibration',@isstruct);
parser.addRequired('oneLight',@(x) isa(x,'OneLight'));
parser.addRequired('radiometer',@(x) isempty(x) || isa(x,'Radiometer'));
parser.addParameter('nIterations',20,@(x)validateattributes(x,{'numeric'},{'scalar','integer','finite','nonnegative'}));
parser.addParameter('lightlevelScalar',1,@(x)validateattributes(x,{'numeric'},{'scalar','real','finite','positive'}));
parser.addParameter('learningRate', 0.8, @(x)validateattributes(x,{'numeric'},{'scalar','real','finite','positive'}));
parser.addParameter('learningRateDecrease',true,@islogical);
parser.addParameter('asympLearningRateFactor',0.5,@(x)validateattributes(x,{'numeric'},{'scalar','real','finite','positive'}));
parser.addParameter('smoothness', 0.001, @(x)validateattributes(x,{'numeric'},{'scalar','real','finite','nonnegative'}));
parser.addParameter('iterativeSearch',true, @islogical);
parser.addParameter('temperatureProbe',[],@(x) isempty(x) || isa(x,'LJTemperatureProbe'));
parser.addParameter('measureStateTrackingSPDs', false, @islogical);
parser.KeepUnmatched = true;
parser.parse(targetSPD,calibration,oneLight,radiometer,varargin{:});

nIterations = parser.Results.nIterations;
learningRate = parser.Results.learningRate;
learningRateDecrease = parser.Results.learningRateDecrease;
asympLearningRateFactor = parser.Results.asympLearningRateFactor;
smoothness = parser.Results.smoothness;
iterativeSearch = parser.Results.iterativeSearch;
temperatureProbe = parser.Results.temperatureProbe;
lightlevelScalar = parser.Results.lightlevelScalar;

%% Measure state-tracking SPDs
stateTrackingData = struct();
if (parser.Results.measureStateTrackingSPDs)
    % Generate temporary calibration struct with stateTracking info
    tmpCal = calibration;
    tmpCal.describe.stateTracking = OLGenerateStateTrackingStruct(calibration);
    
    % Take 1 measurement using the PR670
    od = []; meterToggle = [true false]; nAverage = 1;
    [~, calMeasOnly] = OLCalibrator.TakeStateMeasurements(tmpCal, oneLight, od, radiometer, ...
        meterToggle, nAverage, temperatureProbe, ...
        'standAlone', true);
    
    % Save the data
    stateTrackingData.spectralShift.spd    = calMeasOnly.raw.spectralShiftsMeas.measSpd;
    stateTrackingData.spectralShift.t      = calMeasOnly.raw.spectralShiftsMeas.t;
    stateTrackingData.powerFluctuation.spd = calMeasOnly.raw.powerFluctuationMeas.measSpd;
    stateTrackingData.powerFluctuation.t   = calMeasOnly.raw.powerFluctuationMeas.t;
    
    % Remove tmpCal
    clear('tmpCal')
end

%% Find initial primary values
initialPrimaryValues = OLSpdToPrimary(calibration, targetSPD, ...
    'primaryHeadroom',0,...
    'lambda',parser.Results.smoothness);

%% Correct
temperaturesForAllIterations = cell(1, nIterations);
nextPrimary = initialPrimaryValues; % initialize
for iter = 1:nIterations
    % Get primaries for this iteration (either initial, or the determined
    % next primaries)
    if iter > 1
        primariesThisIter = nextPrimary(:,iter-1);
    else
        primariesThisIter = initialPrimaryValues;
    end
    
    % Take the measurements
    [measuredSPD, temperaturesForAllIterations{iter}] = OLMeasurePrimaryValues(primariesThisIter,calibration,oneLight,radiometer, ...
        'temperatureProbe',parser.Results.temperatureProbe);
    
    % Set learning rate to use this iteration
    if learningRateDecrease
        learningRateThisIter = learningRate*(1-(iter-1)*asympLearningRateFactor/(nIterations-1));
    else
        learningRateThisIter = learningRate;
    end
    
    % Find delta primaries using small signal linear methods.
    deltaPrimary = OLLinearDeltaPrimaries(primariesThisIter,lightlevelScalar*measuredSPD,targetSPD,learningRateThisIter,smoothness,calibration);
    
    % Optionally use fmincon to improve the truncated learning
    % rate delta primaries by iterative search.
    if iterativeSearch
        deltaPrimary = OLIterativeDeltaPrimaries(deltaPrimary,primariesThisIter,lightlevelScalar*measuredSPD,targetSPD,learningRateThisIter,calibration);
    end
    
    % Compute and store the settings to use next time through
    nextPrimary = primariesThisIter + deltaPrimary;
    
    % Save the information for this iteration in a convenient form for later.
    SPDMeasured(:,iter) = measuredSPD;
    RMSE(:,iter) = sqrt(mean((targetSPD-lightlevelScalar*measuredSPD).^2));
    primaryUsed(:,iter) = primariesThisIter;
    deltaPrimary(:,iter) = deltaPrimary;
    nextPrimary(:,iter) = nextPrimary;
end

%% Store information about correction for return
% Business end: pick primary values with lowest RMSE
correctedPrimaryValues = primaryUsed(:, find(RMSE == min(RMSE),1));

% Metadata, e.g., parameters. While I'm not a fan of including input
% parameters in output, it is relevant here because we might have used
% defaults.
detailedData.calibration = calibration;
detailedData.nIterations = nIterations;
detailedData.learningRate = learningRate;
detailedData.learningRateDecrease = learningRateDecrease;
detailedData.asympLearningRateFactor = asympLearningRateFactor;
detailedData.smoothness = smoothness;
detailedData.iterativeSearch = iterativeSearch;

% Store target spectra and initial primaries used.  This information is
% useful for debugging the seeking procedure.
detailedData.targetSPD = targetSPD;
detailedData.initialPrimaryValues = initialPrimaryValues;
detailedData.lightlevelScalar = lightlevelScalar;
detailedData.primaryUsed = primaryUsed;
detailedData.SPDMeasured = SPDMeasured;
detailedData.deltaSPDMeasuredScaled = (lightlevelScalar*SPDMeasured) - targetSPD;
detailedData.RMSE = RMSE;
detailedData.nextPrimary = nextPrimary;
detailedData.deltaPrimary = deltaPrimary;
detailedData.correctedPrimaryValues = correctedPrimaryValues;

% Store temperature data and stateTrackingData
detailedData.temperatures = temperaturesForAllIterations;
detailedData.stateTrackingData = stateTrackingData;
end