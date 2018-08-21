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
%    Detailed explanation goes here
%
% Inputs:
%    targetSPD               - nWlsx1 column vector, where nWls is the
%                              number of wavelength bands measured,
%                              defining target Spectral Power Distribution
%                              to correct primary values to.
%    calibration             - struct containing calibration for oneLight
%    oneLight                - OneLight device driver object to control a
%                              OneLight device. Can be real or simulated
%    radiometer              - Radiometer object to control a
%                              spectroradiometer. Can be passed empty when
%                              simulating
%
% Outputs:
%    correctedPrimaryValues  - Px1 column vector of primary values, where P
%                              is the number of values for effective device
%                              primaries.
%    measuredSPD             - nWlsx1 column vector, where nWls is the
%                              number of wavelength bands measured, of the
%                              SPD measured after correction
%    detailedData            - A ton of data, for debugging purposes.
%
% Optional key/value pairs:
%    nIterations             - Number of iterations. Default is 20.
%    learningRate            - Learning rate. Default is .8.
%    learningRateDecrease    - Decrease learning rate over iterations?
%                              Default is true.
%    asympLearningRateFactor - If learningRateDecrease is true, the 
%                              asymptotic learning rate is
%                              (1-asympLearningRateFactor)*learningRate. 
%                              Default = .5.
%    smoothness              - Smoothness parameter for OLSpdToPrimary.
%                              Default .001.
%    iterativeSearch         - Do iterative search with fmincon on each
%                              measurement interation? Default is true.
%    temperatureProbe        - LJTemperatureProbe object to drive a LabJack
%                              temperature probe
%
% See also:
%    OLValidatePrimaryValues
%

% History:
%    02/09/18  jv   extracted from OLCorrectCacheFileOOC as
%                   OLCorrectPrimaryValues
%    06/29/18  npc  implemented temperature recording
%    06/30/18  npc  implemented state tracking SPD recording
%    08/16/18  jv   OLCorrectToSPD


% Examples:
%{
    %% Test under simulation
    % Get calibration
    demoCalFolder = fullfile(tbLocateToolbox('OneLightToolbox'),'OLDemoCal');
    calibration = OLGetCalibrationStructure('CalibrationFolder',demoCalFolder,'CalibrationType','OLDemoCal');

    % Define inputs
    primaryValues = .5 * ones([calibration.describe.numWavelengthBands,1]);
    oneLight = OneLight('simulate',true);

    % Correct
    [correctedPrimaryValues, data] = OLCorrectPrimaryValues(primaryValues,calibration,oneLight,[]);
    assert(all(correctedPrimaryValues == primaryValues));
    assert(all(data.correction.SpdMeasuredAll(:,end) == OLPrimaryToSpd(calibration, primaryValues)));
%}

%% Input validation
parser = inputParser;
parser.addRequired('targetSPD',@isnumeric);
parser.addRequired('calibration',@isstruct);
parser.addRequired('oneLight',@(x) isa(x,'OneLight'));
parser.addRequired('radiometer',@(x) isempty(x) || isa(x,'Radiometer'));
parser.addParameter('nIterations',20,@isscalar);
parser.addParameter('learningRate', 0.8, @isscalar);
parser.addParameter('learningRateDecrease',true,@islogical);
parser.addParameter('asympLearningRateFactor',0.5,@isscalar);
parser.addParameter('smoothness', 0.001, @isscalar);
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
NextPrimaryTruncatedLearningRate = initialPrimaryValues; % initialize
for iter = 1:nIterations
    % Take the measurements
    primariesThisIter = NextPrimaryTruncatedLearningRate;
    [measuredSPD, temperaturesForAllIterations{iter}] = OLMeasurePrimaryValues(primariesThisIter,calibration,oneLight,radiometer, ...
        'temperatureProbe',parser.Results.temperatureProbe);
    
    % If first time through, figure out a scaling factor from the first
    % measurement which puts the measured spectrum into the same range as
    % the predicted spectrum. This deals with fluctuations with absolute
    % light level.
    if iter == 1
        kScale = measuredSPD \ targetSPD;
    end
    
    % Set learning rate to use this iteration
    if learningRateDecrease
        learningRateThisIter = learningRate*(1-(iter-1)*asympLearningRateFactor/(nIterations-1));
    else
        learningRateThisIter = learningRate;
    end
    
    % Find delta primaries using small signal linear methods.
    DeltaPrimaryTruncatedLearningRate = OLLinearDeltaPrimaries(primariesThisIter,kScale*measuredSPD,targetSPD,learningRateThisIter,smoothness,calibration);
    
    % Optionally use fmincon to improve the truncated learning
    % rate delta primaries by iterative search.
    if iterativeSearch
        DeltaPrimaryTruncatedLearningRate = OLIterativeDeltaPrimaries(DeltaPrimaryTruncatedLearningRate,primariesThisIter,kScale*measuredSPD,targetSPD,learningRateThisIter,calibration);
    end
    
    % Compute and store the settings to use next time through
    NextPrimaryTruncatedLearningRate = primariesThisIter + DeltaPrimaryTruncatedLearningRate;
    
    % Save the information for this iteration in a convenient form for later.
    SPDMeasured(:,iter) = measuredSPD;
    RMSE(:,iter) = sqrt(mean((targetSPD-kScale*measuredSPD).^2));
    PrimaryUsed(:,iter) = primariesThisIter;
    DeltaPrimaryTruncatedLearningRateAll(:,iter) = DeltaPrimaryTruncatedLearningRate;
    NextPrimaryTruncatedLearningRateAll(:,iter) = NextPrimaryTruncatedLearningRate;
end

%% Store information about correction for return
% Business end: pick primary values with lowest RMSE
correctedPrimaryValues = PrimaryUsed(:, find(RMSE == min(RMSE),1));

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
detailedData.initialPrimaryValues = initialPrimaryValues;
detailedData.targetSPD = targetSPD;
detailedData.kScale = kScale;
detailedData.primaryUsed = PrimaryUsed;
detailedData.SPDMeasured = SPDMeasured;
detailedData.deltaSPDMeasured = SPDMeasured - targetSPD;
detailedData.RMSE = RMSE;
detailedData.NextPrimaryTruncatedLearningRate = NextPrimaryTruncatedLearningRateAll;
detailedData.DeltaPrimaryTruncatedLearningRate = DeltaPrimaryTruncatedLearningRateAll;
detailedData.correctedPrimaryValues = correctedPrimaryValues;

% Store temperature data and stateTrackingData
detailedData.temperatures = temperaturesForAllIterations;
detailedData.stateTrackingData = stateTrackingData;
end