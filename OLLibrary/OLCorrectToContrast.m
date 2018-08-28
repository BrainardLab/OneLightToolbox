function [correctedPrimaryValues, measuredContrasts, detailedData] = OLCorrectToContrast(targetContrasts, initialSPD, backgroundSPD, receptors, calibration, oneLight, radiometer, varargin)
% Corrects primary values iteratively to attain target contrasts
%
% Syntax:
%   correctedPrimaryValues = OLCorrectToContrast(targetContrasts, initialSPD, backgroundSPD, receptors, calibration, oneLight, radiometer)
%   [correctedPrimaryValues measuredSPD] = OLCorrectToContrast(...)
%   [correctedPrimaryValues measuredSPD detailedData] = OLCorrectToContrast(...)
%
% Description:
%   Seeks primary values that lead to spectrum with desired target
%   contrasts, with respect to passed background spectral power
%   distribution and receptor fundamentals. Works by making measurements
%   and then using fmincon together with small signal approximation and
%   calibration to try to find primaries that minimize contrast error.
%
% Inputs:
%    targetContrasts         - Rx1 column vector, giving target contrasts 
%                              for R receptor classes
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
%    receptors               - RxnWls matrix specifying receptor
%                              fundamentals for R receptor classes
%    calibration             - struct containing calibration for oneLight
%    oneLight                - OneLight device driver object to control a
%                              OneLight device. Can be real or simulated
%    radiometer              - Radiometer object to control a
%                              spectroradiometer. Can be passed empty when
%                              simulating
%
% Outputs:
%    correctedPrimaryValues     - Px1 column vector of primary values,
%                                 where P is the number of values for
%                                 effective device primaries.
%    measuredContrasts          - Rx1 column vector of contrasts on R
%                                 receptors, between the SPD after
%                                 correction and the measured background
%                                 SPD.
%    detailedData               - A ton of data in a structure, mainly for
%                                 debugging purposes. See
%                                 OLCheckPrimaryCorrection
%
% Optional key/value pairs:
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
%                                Default false.
%    'lightlevelScalar'         - Scalar numeric, factor by which to
%                                 multiply measured SPDs to bring into
%                                 calibration range. See
%                                 OLMeasureLightlevelScalar. Default is 1.
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
    %% Test under simulation
    % Get calibration
    demoCalFolder = fullfile(tbLocateToolbox('OneLightToolbox'),'OLDemoCal');
    calibration = OLGetCalibrationStructure('CalibrationFolder',demoCalFolder,'CalibrationType','DemoCal');

    % Define inputs
    receptors = SSTReceptorHuman('S',calibration.describe.S,'verbosity','none');
    receptors = receptors.T.T_energyNormalized;
    targetContrasts = [2 2 2 2 2]';
    backgroundSPD = .3 * OLPrimaryToSpd(calibration,ones(calibration.describe.numWavelengthBands,1));
    initialSPD = 2.9 * backgroundSPD;
    initialContrasts = SPDToReceptorContrast([backgroundSPD, initialSPD],receptors);
    initialContrasts = initialContrasts(:,1);

    oneLight = OneLight('simulate',true,'plotWhenSimulating',false);

    % Correct
    [correctedPrimaryValues, measuredContrasts, data] = OLCorrectToContrast(targetContrasts, initialSPD, backgroundSPD, receptors,calibration,oneLight,[]);
    
    % Compare
    [initialContrasts, measuredContrasts, targetContrasts]
%}

%% Input validation
parser = inputParser;
parser.addRequired('targetContrasts',@(x)validateattributes(x,{'numeric'},{'vector','real','finite','nonnegative'}));
parser.addRequired('initialSPD',@(x)validateattributes(x,{'numeric'},{'vector','real','finite','nonnegative'}));
parser.addRequired('backgroundSPD',@(x)validateattributes(x,{'numeric'},{'vector','real','finite','nonnegative'}));
parser.addRequired('receptors',@(x)validateattributes(x,{'numeric','SSTReceptor'},{'real','finite','nonnegative'}));
parser.addRequired('calibration',@isstruct);
parser.addRequired('oneLight',@(x) isa(x,'OneLight'));
parser.addRequired('radiometer',@(x) isempty(x) || isa(x,'Radiometer'));
parser.addParameter('nIterations',20,@(x)validateattributes(x,{'numeric'},{'scalar','integer','finite','nonnegative'}));
parser.addParameter('learningRate', 0.8, @(x)validateattributes(x,{'numeric'},{'scalar','real','finite','positive'}));
parser.addParameter('learningRateDecrease',true,@islogical);
parser.addParameter('asympLearningRateFactor',0.5,@(x)validateattributes(x,{'numeric'},{'scalar','real','finite','positive'}));
parser.addParameter('smoothness', 0.001, @(x)validateattributes(x,{'numeric'},{'scalar','real','finite','positive'}));
parser.addParameter('iterativeSearch',true, @islogical);
parser.addParameter('temperatureProbe',[],@(x) isempty(x) || isa(x,'LJTemperatureProbe'));
parser.addParameter('measureStateTrackingSPDs', false, @islogical);
parser.addParameter('lightlevelScalar', 1, @(x)validateattributes(x,{'numeric'},{'scalar','real','finite','positive'}));
parser.KeepUnmatched = true;
parser.parse(targetContrasts, initialSPD, backgroundSPD, receptors, calibration, oneLight, radiometer, varargin{:});

% Assert SPDs and receptors match calibration wls specification
validateattributes(initialSPD,{'numeric'},{'size',[calibration.describe.S(3) 1]},mfilename,'initialSPD',2);
validateattributes(backgroundSPD,{'numeric'},{'size',[calibration.describe.S(3) 1]},mfilename,'backgroundSPD',3);
validateattributes(receptors,{'numeric'},{'ncols',calibration.describe.S(3)},mfilename,'receptors',4);

% Assert correct number of target contrasts have been passed
validateattributes(targetContrasts,{'numeric'},{'size',[size(receptors,1),1]},mfilename,'targetContrasts',1);

nIterations = parser.Results.nIterations;
learningRate = parser.Results.learningRate;
learningRateDecrease = parser.Results.learningRateDecrease;
asympLearningRateFactor = parser.Results.asympLearningRateFactor;
smoothness = parser.Results.smoothness;
iterativeSearch = parser.Results.iterativeSearch;
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
initialPrimaryValues = OLSpdToPrimary(calibration, initialSPD, ...
                        'primaryHeadroom',0,...
                        'lambda',parser.Results.smoothness);
                    
%% Scale background SPD
backgroundSPDScaled = lightlevelScalar*backgroundSPD;

%% Correct
temperaturesForAllIterations = cell(1, nIterations);
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
    
    % Scale measured SPD here
    measuredSPDScaled = lightlevelScalar*measuredSPD;
    
    % Get measured contrasts.  Note that kScale does not affect contrasts, since
    % it is incorporated into both measurement and background.
    measuredContrasts = SPDToReceptorContrast([backgroundSPDScaled, measuredSPDScaled],receptors);
    measuredContrasts = measuredContrasts(:,1);
    
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
    deltaPrimary = OLIterativeDeltaPrimariesContrast([],primariesThisIter,targetContrasts,measuredSPDScaled,backgroundSPDScaled,receptors,learningRateThisIter,calibration);
    
    % Compute and store the settings to use next time through
    nextPrimary = primariesThisIter + deltaPrimary;
    
    % Save the information for this iteration in a convenient form for later.
    SPDMeasured(:,iter) = measuredSPD;
    contrastMeasured(:,iter) = measuredContrasts;
    RMSE(:,iter) = sqrt(mean((targetContrasts-measuredContrasts).^2));
    primaryUsed(:,iter) = primariesThisIter;
    deltaPrimary(:,iter) = deltaPrimary;
    nextPrimary(:,iter) = nextPrimary;
end

%% Store information about correction for return
%
% Business end: pick primary values with lowest RMSE.  RMSE is on
% contrasts.
detailedData.pickedIter = find(RMSE == min(RMSE),1);
correctedPrimaryValues = primaryUsed(:, detailedData.pickedIter);

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
detailedData.targetContrasts = targetContrasts;
detailedData.lightlevelScalar = lightlevelScalar;
detailedData.primaryUsed = primaryUsed;
detailedData.SPDMeasured = SPDMeasured;
detailedData.ContrastMeasured = contrastMeasured;
detailedData.RMSE = RMSE;
detailedData.NextPrimaryTruncatedLearningRate = nextPrimary;
detailedData.DeltaPrimaryTruncatedLearningRate = deltaPrimary;
detailedData.correctedPrimaryValues = correctedPrimaryValues;

% Store temperature data and stateTrackingData
detailedData.temperatures = temperaturesForAllIterations;
detailedData.stateTrackingData = stateTrackingData;
end