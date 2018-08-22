function [correctedPrimaryValues, measuredSPD, detailedData] = OLCorrectToContrast(targetContrasts, initialSPD, backgroundSPD, T_receptors, calibration, oneLight, radiometer, varargin)
% Corrects primary values iteratively to attain target contrasts
%
% Syntax:
%   [correctedPrimaryValues, measuredSPD, detailedData] = OLCorrectToContrast(targetContrasts, initialSPD, backgroundSPD, T_receptors, calibration, oneLight, radiometer, varargin)
%
% Description:
%   Seeks primary values that lead to spectrum with desired target
%   contrasts, with respect to passed background spectral power
%   distribution and receptor fundamentals. Works by making measurements
%   and then using fmincon together with small signal approximation and
%   calibration to try to find primaries that minimize contrast error.
%
% Inputs:
%    targetContrasts         - nReceptorsx1 column vector, giving target
%                              contrasts for each receptor class.
%    initialSPD              - nWlsx1 column vector, with an initial guess
%                              as to an SPD that will produce the desired
%                              contrasts.  Need not be exact, just to get
%                              things started. This should be unscaled, and
%                              is generally obtained using the calibration
%                              structure.
%    backgroundSPD           - nWlsx1 column vector, with background
%                              spectral power distribution with respect to
%                              which to compute contrasts.  This should be
%                              unscaled - the actual measurement.
%    T_receptors             - nReceptorsxnWls matrix specifying receptor
%                              fundamentals.
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
%                              SPD measured after correction. This is the
%                              actual measurement, not scaled by kScale.
%    detailedData            - A ton of data in a structure, for debugging purposes.
%
% Optional key/value pairs:
%    'nIterations'             - Number of iterations. Default is 20.
%    'learningRate'            - Learning rate. Default is .8.
%    'learningRateDecrease'    - Decrease learning rate over iterations?
%                                Default is true.
%    'asympLearningRateFactor' - If learningRateDecrease is true, the 
%                                asymptotic learning rate is
%                                (1-asympLearningRateFactor)*learningRate. 
%                                Default = .5.
%    'smoothness'              - Smoothness parameter for OLSpdToPrimary.
%                                Default .001.
%    'iterativeSearch'         - Do iterative search with fmincon on each
%                                measurement interation? Default is true.
%    'temperatureProbe'        - LJTemperatureProbe object to drive a LabJack
%                                temperature probe. Default empty.
%    'measureStateTrackingSPDs' - Make state tracking measurements?
%                                Default false.
%    'kScale'                  - Scale factor to bring a current measurement
%                                into the same overall scale as the
%                                calibration structure data.  Used to account
%                                for overall drift of the device during the
%                                corrections.  Default 1.
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
%    08/22/18  dhb  Drafting contrast seeking algorithm.

% Examples:
%{
    
%}

%% Input validation
parser = inputParser;
parser.addRequired('targetContrasts',@isnumeric);
parser.addRequired('initialSPD',@isnumeric);
parser.addRequired('backgroundSPD',@isnumeric);
parser.addRequired('T_receptors',@isnumeric);
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
parser.addParameter('kScale', 1, @isnumeric);
parser.KeepUnmatched = true;
parser.parse(targetContrasts, initialSPD, backgroundSPD, T_receptors, calibration, oneLight, radiometer, varargin{:});

nIterations = parser.Results.nIterations;
learningRate = parser.Results.learningRate;
learningRateDecrease = parser.Results.learningRateDecrease;
asympLearningRateFactor = parser.Results.asympLearningRateFactor;
smoothness = parser.Results.smoothness;
iterativeSearch = parser.Results.iterativeSearch;
kScale = parser.Results.kScale;

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
initialPrimaryValues = OLSpdToPrimary(calibration, initialSPD, ...
                        'primaryHeadroom',0,...
                        'lambda',parser.Results.smoothness);
                    
%% Get receptor responses for background
backgroundSPDScaled = kScale*backgroundSPD;
backgroundReceptorsScaled = T_receptors*backgroundSPDScaled;

%% Correct
temperaturesForAllIterations = cell(1, nIterations);
nextPrimaryTruncatedLearningRate = initialPrimaryValues;
for iter = 1:nIterations
    % Take the measurements
    primariesThisIter = nextPrimaryTruncatedLearningRate;
    [measuredSPD, temperaturesForAllIterations{iter}] = OLMeasurePrimaryValues(primariesThisIter,calibration,oneLight,radiometer, ...
        'temperatureProbe',parser.Results.temperatureProbe);
    
    % Scale measured SPD here
    measuredSPDScaled = kScale*measuredSPD;
    
    % Get measured contrasts.  Note that kScale does not affect contrasts, since
    % it is incorporated into both measurement and background.
    measuredReceptorsScaled = T_receptors*measuredSpdScaled;
    measuredContrasts = (measuredReceptorsScaled-backgroundReceptorsScaled) ./ backgroundReceptorsScaled;
    
    % Set learning rate to use this iteration
    if learningRateDecrease
        learningRateThisIter = learningRate*(1-(iter-1)*asympLearningRateFactor/(nIterations-1));
    else
        learningRateThisIter = learningRate;
    end
    
    % Use fmincon to estimate delta primaries that move us towards desired contrasts.
    %
    % We initialize each call at zero delta, because the previous delta has
    % been incorporated into the current measurement.
    deltaPrimaryTruncatedLearningRate = OLIterativeDeltaPrimariesContrast([],primariesThisIter,targetContrasts,measuredSpdScaled,backgroundSPDScaled,T_receptors,learningRateThisIter,calibration);
    
    % Compute and store the settings to use next time through
    nextPrimaryTruncatedLearningRate = primariesThisIter + deltaPrimaryTruncatedLearningRate;
    
    % Save the information for this iteration in a convenient form for later.
    SPDMeasured(:,iter) = measuredSPD;
    RMSE(:,iter) = sqrt(mean((targetContrasts-measuredContrasts).^2));
    PrimaryUsed(:,iter) = primariesThisIter;
    DeltaPrimaryTruncatedLearningRateAll(:,iter) = deltaPrimaryTruncatedLearningRate;
    NextPrimaryTruncatedLearningRateAll(:,iter) = nextPrimaryTruncatedLearningRate;
end

%% Store information about correction for return
%
% Business end: pick primary values with lowest RMSE.  RMSE is on
% contrasts.
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