function protocolParams = ValidateDirectionCorrectedPrimaries(protocolParams,PrePost)
% ValidateCorrectedPrimaries - Measure and check the corrected primaries
%
% Description:
%     This script uses the radiometer to measure the light coming out of the eyepiece and 
%     calculates the receptor contrasts.  This is a check on how well we
%     are hitting our desired target.  Typically we run this before and
%     after the experimental session.

% 6/18/17  dhb  Added header comment.

% Update session log file
protocolParams = Psychophysics.SessionLog(protocolParams,mfilename,'StartEnd','start','PrePost',PrePost);

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
theDirections = {['Direction_MelanopsinDirectedSuperMaxMel_' protocolParams.observerID '_' protocolParams.todayDate '.mat'] ...
    ['Direction_LMSDirectedSuperMaxLMS_' protocolParams.observerID '_' protocolParams.todayDate '.mat']};
NDirections = length(theDirections);
cacheDir = fullfile(getpref(protocolParams.approach, 'DataPath'),'Experiments',protocolParams.approach, protocolParams.protocol, 'DirectionCorrectedPrimaries', protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
outDir = fullfile(getpref(protocolParams.approach, 'DataPath'),'Experiments',protocolParams.approach, protocolParams.protocol, 'DirectionValidationFiles', protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
if(~exist(outDir))
    mkdir(outDir)
end
NMeas = 1;

% Set up a counter
c = 1;
NTotalMeas = NMeas*NDirections;

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
            fullfile(cacheDir, theDirections{d}), ...
            'jryan@mail.med.upenn.edu', ...
            'PR-670', spectroRadiometerOBJ, protocolParams.spectroRadiometerOBJWillShutdownAfterMeasurement, ...
            'FullOnMeas', false, ...
            'CalStateMeas', calStateFlag, ...
            'DarkMeas', false, ...
            'OBSERVER_AGE', protocolParams.observerAgeInYrs, ...
            'ReducedPowerLevels', false, ...
            'selectedCalType', protocolParams.calibrationType, ...
            'CALCULATE_SPLATTER', false, ...
            'powerLevels', [0 1.0000], ...
            'pr670sensitivityMode', 'STANDARD', ...
            'postreceptoralCombinations', [1 1 1 0 ; 1 -1 0 0 ; 0 0 1 0 ; 0 0 0 1], ...
            'outDir', outDir, ... %'outDir', fullfile(dataPath, 'MaxPulsePsychophysics', datestr(now, 'mmddyy')), ...
            'takeTemperatureMeasurements', protocolParams.takeTemperatureMeasurements);
        
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
protocolParams = Psychophysics.SessionLog(protocolParams,mfilename,'StartEnd','end','PrePost',PrePost);
toc;

% Clear the choiceIndex. Note that this is only relevant for the
% pre-experimental validations.
clear choiceIndex;