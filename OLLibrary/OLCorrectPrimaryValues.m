function [correctedPrimaryValues, data] = OLCorrectPrimaryValues(nominalPrimaryValues, calibration, oneLight, radiometer, varargin)
% Corrects primary values iteratively to attain predicted SPD
%
% Syntax:
%   correctedPrimaryValues = OLCorrectPrimaryValues(nominalPrimaryValues, calibration, OneLight, radiometer)
%   correctedPrimaryValues = OLCorrectPrimaryValues(nominalPrimaryValues, calibration, SimulatedOneLight)
%
% Description:
%    Detailed explanation goes here
%
% Inputs:
%    nominalPrimaryValues   - PxN array of primary values, where P is the
%                             number of primary values per spectrum, and N
%                             is the number of spectra to validate (i.e., a
%                             column vector per spectrum)
%    calibration            - struct containing calibration for oneLight
%    oneLight               - a OneLight device driver object to control a
%                             OneLight device, can be real or simulated
%    radiometer             - Radiometer object to control a
%                             spectroradiometer. Can be passed empty when
%                             simulating
%
% Outputs:
%    correctedPrimaryValues - PxN array of primary values, where P is the
%                             number of primary values per spectrum, and N
%                             is the number of spectra to validate (i.e., a
%                             column vector per spectrum)
%    data                   - A ton of data, for debugging purposes.
%
% Optional key/value pairs:
%    nIterations            - Number of iterations for correction. Default
%                             is 20.
%
% See also:
%    OLValidatePrimaryValues
%

% History:
%    02/09/18  jv  extracted from OLCorrectCacheFileOOC.
%

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
parser.addRequired('primaryValues',@isnumeric);
parser.addRequired('calibration',@isstruct);
parser.addRequired('oneLight',@(x) isa(x,'OneLight'));
parser.addOptional('radiometer',[],@(x) isempty(x) || isa(x,'Radiometer'));
parser.addParameter('receptors',[],@(x) isa(x,'SSTReceptor'));
parser.addParameter('nIterations',20,@isscalar);
parser.addParameter('learningRate', 0.8, @isscalar);
parser.addParameter('learningRateDecrease',true,@islogical);
parser.addParameter('asympLearningRateFactor',0.5,@isscalar);
parser.addParameter('smoothness', 0.001, @isscalar);
parser.addParameter('iterativeSearch',false, @islogical);
parser.parse(nominalPrimaryValues,calibration,oneLight,varargin{:});

nIterations = uint8(parser.Results.nIterations);
learningRate = parser.Results.learningRate;
smoothness = parser.Results.smoothness;

correctionDescribe = parser.Results;

%% Target (predited) SPD
targetSPD = OLPrimaryToSpd(calibration, nominalPrimaryValues);
spdsDesired = targetSPD;
primaryInitial = nominalPrimaryValues;

%% Correct
for iter = 1:correctionDescribe.nIterations
    
    % Only get the primaries from the cache file if it's the first
    % iteration.  In this case we also store them for future reference,
    % since they are replaced on every iteration.
    if iter == 1
        PrimaryUsed = primaryInitial;
    else
        PrimaryUsed = NextPrimaryTruncatedLearningRate;
    end
    
    % Set learning rate to use this iteration
    if (parser.Results.learningRateDecrease)
        learningRateThisIter = correctionDescribe.learningRate*(1-(iter-1)*correctionDescribe.asympLearningRateFactor/(correctionDescribe.nIterations-1));
    else
        learningRateThisIter = correctionDescribe.learningRate;
    end
    
    % Get the desired primaries for each power level and make a measurement for each one.

    % Get primary values for this power level, adding the
    % modulation difference to the , after
    % scaling by the power level.
    primariesThisIter = PrimaryUsed;

    % Convert the primaries to mirror starts/stops
    settings = OLPrimaryToSettings(calibration, primariesThisIter);
    [starts,stops] = OLSettingsToStartsStops(calibration, settings);

    % Take the measurements
    results.directionMeas(iter).meas.pr650.spectrum = OLMeasurePrimaryValues(primariesThisIter,calibration,oneLight,radiometer);

    % Save out information about this.
    results.directionMeas(iter).primariesThisIter = primariesThisIter;
    results.directionMeas(iter).settings = settings;
    results.directionMeas(iter).starts = starts;
    results.directionMeas(iter).stops = stops;
       
    modulationBGMeas = results.directionMeas(iter);
    SpdDesired = spdsDesired;
    SpdMeasured = modulationBGMeas.meas.pr650.spectrum;
    
    % If first time through, figure out a scaling factor from
    % the first measurement which puts the measured spectrum
    % into the same range as the predicted spectrum. This deals
    % with fluctuations with absolute light level.
    if iter == 1
        kScale = SpdMeasured \ SpdDesired;
    end
    
    % Find delta primaries using small signal linear methods.
    DeltaPrimaryTruncatedLearningRate = OLLinearDeltaPrimaries(PrimaryUsed,kScale*SpdMeasured,SpdDesired,learningRateThisIter,correctionDescribe.smoothness,calibration);
    
    % Optionally use fmincon to improve the truncated learning
    % rate delta primaries by iterative search.
    %
    % Put that in your pipe and smoke it!
    if (correctionDescribe.iterativeSearch)
        DeltaPrimaryTruncatedLearningRate = OLIterativeDeltaPrimaries(DeltaPrimaryTruncatedLearningRate,PrimaryUsed,kScale*SpdMeasured,SpdDesired,learningRateThisIter,calibration);
    end
    
    % Compute and store the settings to use next time through
    NextPrimaryTruncatedLearningRate = PrimaryUsed + DeltaPrimaryTruncatedLearningRate;
    
    % Save the information for this iteration in a convenient form for later.
    SpdMeasuredAll(:,iter) = SpdMeasured;
    PrimaryUsedAll(:,iter) = PrimaryUsed;
    NextPrimaryTruncatedLearningRateAll(:,iter) = NextPrimaryTruncatedLearningRate;
    DeltaPrimaryTruncatedLearningRateAll(:,iter) = DeltaPrimaryTruncatedLearningRate;
end

%% Store information about corrected modulations for return.
%
% Since this routine only does the correction for one age, we set the data for that and zero out all
% the rest, just to avoid accidently thinking we have corrected spectra where we do not.
data.correctionDescribe = correctionDescribe;
data.cal = calibration;
data.correction.kScale = kScale;

% Store the answer after the iteration.  This block is the part
% that other code cares about.
data.Primary = NextPrimaryTruncatedLearningRateAll(:, end);
correctedPrimaryValues = NextPrimaryTruncatedLearningRateAll(:, end);

% Store target spectra and initial primaries used.  This information is useful
% for debugging the seeking procedure.
data.correction.SpdDesired = SpdDesired;
data.correction.PrimaryInitial = primaryInitial;

data.correction.PrimaryUsedAll = PrimaryUsedAll;
data.correction.SpdMeasuredAll = SpdMeasuredAll;
data.correction.NextPrimaryTruncatedLearningRateAll = NextPrimaryTruncatedLearningRateAll;
data.correction.DeltaPrimaryTruncatedLearningRateAll = DeltaPrimaryTruncatedLearningRateAll;

end