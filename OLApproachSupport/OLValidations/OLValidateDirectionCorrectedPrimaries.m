function protocolParams = OLValidateDirectionCorrectedPrimaries(protocolParams,PrePost)
%OLValidateCorrectedPrimaries  Measure and check the corrected primaries
%
% Description:
%     This script uses the radiometer to measure the light coming out of the eyepiece and 
%     calculates the receptor contrasts.  This is a check on how well we
%     are hitting our desired target.  Typically we run this before and
%     after the experimental session.

% 6/18/17  dhb  Added header comment.

% Update session log file
protocolParams = OLSessionLog(protocolParams,mfilename,'StartEnd','start','PrePost',PrePost);

% Assign the default choice index the first time we run this script. We
% clear this after the pre-experimental validation.
choiceIndex = 1;

tic;

% Prompt the user to state if we're before or after the experiment
if ~exist('choiceIndex', 'var')
    choiceIndex = ChoiceMenuFromList({'Before the experiment', 'After the experiment'}, '> Validation before or after the experiment?');
end

% Set up some parameters
spectroRadiometerOBJ = [];
theDirectionCacheFileNames = OLMakeDirectionCacheFileNames(protocolParams);

NDirections = length(theDirectionCacheFileNames);
cacheDir = fullfile(getpref(protocolParams.approach, 'DataPath'),'Experiments',protocolParams.approach, protocolParams.protocol, 'DirectionCorrectedPrimaries', protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
outDir = fullfile(getpref(protocolParams.approach, 'DataPath'),'Experiments',protocolParams.approach, protocolParams.protocol, 'DirectionValidationFiles', protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
if(~exist(outDir))
    mkdir(outDir)
end
NMeas = 1;

% Set up a counter
c = 1;
NTotalMeas = NMeas*NDirections;

% Obtain correction params from OLCorrectionParamsDictionary, according
% to the boxName specified in protocolParams.boxName
d = OLCorrectionParamsDictionary();
correctionParams = d(protocolParams.boxName);

for ii = 1:NMeas;
    for d = 1:NDirections
        % Inform the user where we are in the validation
        fprintf('*** Validation %g / %g in total ***\n', c, NTotalMeas);
        
        % We also take state measurements, which we define here
        if (choiceIndex == 1) && (c == 1)
            calStateFlag = true;
        elseif (choiceIndex == 2) && (c == NTotalMeas)
            calStateFlag = true;
        else
            calStateFlag = false;
        end
        
        % Take the measurement
        [~, ~, ~, spectroRadiometerOBJ] = OLValidateCacheFileOOC(protocolParams, ...
            fullfile(cacheDir, sprintf('%s.mat', theDirectionCacheFileNames{d})), ...
            'jryan@mail.med.upenn.edu', ...
            'PR-670', spectroRadiometerOBJ, protocolParams.spectroRadiometerOBJWillShutdownAfterMeasurement, ...
            'pr670sensitivityMode',         'STANDARD', ...
            'CalStateMeas',                 calStateFlag, ...
            'outDir',                       outDir, ...
            'OBSERVER_AGE',                 protocolParams.observerAgeInYrs, ...
            'selectedCalType',              protocolParams.calibrationType, ...
            'takeTemperatureMeasurements',  protocolParams.takeTemperatureMeasurements, ...
            'FullOnMeas',                   correctionParams.fullOnMeas, ...
            'DarkMeas',                     correctionParams.darkMeas, ...
            'ReducedPowerLevels',           correctionParams.reducedPowerLevels, ...
            'CALCULATE_SPLATTER',           correctionParams.calculateSplatter, ...
            'powerLevels',                  correctionParams.powerLevels, ...
            'postreceptoralCombinations',   correctionParams.postreceptoralCombinations...
            );
        % Increment the counter
        c = c+1;
    end
end

if (~isempty(spectroRadiometerOBJ))
    spectroRadiometerOBJ.shutDown();
    spectroRadiometerOBJ = [];
end
fprintf('\n************************************************');
fprintf('\n*** <strong>Validation all complete</strong> ***');
fprintf('\n************************************************\n');
protocolParams = OLSessionLog(protocolParams,mfilename,'StartEnd','end','PrePost',PrePost);
toc;

% Clear the choiceIndex. Note that this is only relevant for the
% pre-experimental validations.
clear choiceIndex;