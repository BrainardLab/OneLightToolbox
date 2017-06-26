%ModulationParamsDictionary
%
% Description:
%   Generate dictionary with modulation params
%
% 6/23/17  npc  Wrote it.

function d = ModulationParamsDictionary()
    % Initialize dictionary
    d = containers.Map();
    
    %% Modulation-MaxMelPulsePsychophysics-PulseMaxLMS_3s_MaxContrast3sSegment
    modulationName = 'Modulation-PulseMaxLMS_3s_MaxContrast3sSegment';
    params = defaultParams();
    % Direction identifiers
    params.direction = 'LMSDirectedSuperMaxLMS';                        % Modulation direction
    params.directionCacheFile = 'Direction_LMSDirectedSuperMaxLMS.mat'; % Cache file to be used
    ValidateDictionaryEntry(params, 'ModulationDictionary');
    d = paramsValidateAndAppendToDictionary(d, modulationName, params);
        
    
    %% Modulation-MaxMelPulsePsychophysics-PulseMaxMel_3s_MaxContrast3sSegment
    modulationName = 'Modulation-PulseMaxMel_3s_MaxContrast3sSegment';
    params = defaultParams();
    % Direction identifiers
    params.direction = 'MelanopsinDirectedSuperMaxMel';                        % Modulation direction
    params.directionCacheFile = 'Direction_MelanopsinDirectedSuperMaxMel.mat'; % Cache file to be used
    d = paramsValidateAndAppendToDictionary(d, modulationName, params);

    
    %% Modulation-MaxMelPulsePsychophysics-PulseMaxLightFlux_3s_MaxContrast3sSegment
    modulationName = 'Modulation-PulseMaxLightFlux_3s_MaxContrast3sSegment';
    params = defaultParams();
    % Direction identifiers
    params.direction = 'LightFluxMaxPulse';                         % Modulation direction
    params.directionCacheFile = 'Direction_LightFluxMaxPulse.mat';  % Cache file to be used
    d = paramsValidateAndAppendToDictionary(d, modulationName, params);
    
    fprintf('all done'\n');
    pause
end

function d = paramsValidateAndAppendToDictionary(d, modulationName, params)

    % Test that there are no extra params
    if (~all(ismember(fieldnames(params),fieldnames(defaultParams()))))
        fprintf(2,'\nParams struct contain extra params\n');
        fNames = fieldnames(params);
        idx = ismember(fieldnames(params),fieldnames(defaultParams()));
        idx = find(idx == 0);
        for k = 1:numel(idx)
            fprintf(2,'- ''%s'' \n', fNames{idx(k)});
        end
        error('Remove extra params or update defaultParams\n');
    end
    
    % Test that all expected params exist and that they have the expected type
    assert((isfield(params, 'type')                     && ischar(params.type)),                        sprintf('params.type does not exist or it does not contain a string value.'));
    assert((isfield(params, 'trialDuration')            && isnumeric(params.trialDuration)),            sprintf('params.trialDuration does not exist or it does not contain a numeric value.'));   
    assert((isfield(params, 'timeStep')                 && isnumeric(params.timeStep)),                 sprintf('params.timeStep does not exist or it does not contain a numeric value.'));
    assert((isfield(params, 'cosineWindowIn')           && islogical(params.cosineWindowIn)),           sprintf('params.cosineWindowIn does not exist or it does not contain a boolean value.'));
    assert((isfield(params, 'cosineWindowOut')          && islogical(params.cosineWindowOut)),          sprintf('params.cosineWindowOut does not exist or it does not contain a boolean value.'));
    assert((isfield(params, 'cosineWindowDurationSecs') && isnumeric(params.cosineWindowDurationSecs)), sprintf('params.cosineWindowDurationSecs does not exist or it does not contain a numeric value.'));
    assert((isfield(params, 'nFrequencies')             && isnumeric(params.nFrequencies)),             sprintf('params.nFrequencies does not exist or it does not contain a numeric value.'));
    assert((isfield(params, 'nPhases')                  && isnumeric(params.nPhases)),                  sprintf('params.nPhases does not exist or it does not contain a numeric value.'));
    assert((isfield(params, 'modulationMode')           && ischar(params.modulationMode)),              sprintf('params.modulationMode does not exist or it does not contain a string value.'));
    assert((isfield(params, 'modulationWaveForm')       && ischar(params.modulationWaveForm)),          sprintf('params.modulationWaveForm does not exist or it does not contain a string value.'));
    assert((isfield(params, 'modulationFrequencyTrials')&& isnumeric(params.modulationFrequencyTrials)),sprintf('params.modulationFrequencyTrials does not exist or it does not contain a numeric value.'));
    assert((isfield(params, 'modulationPhase')          && isnumeric(params.modulationPhase)),          sprintf('params.modulationPhase does not exist or it does not contain a numeric value.'));
    assert((isfield(params, 'phaseRandSec')             && isnumeric(params.phaseRandSec)),             sprintf('params.phaseRandSec does not exist or it does not contain a numeric value.'));
    assert((isfield(params, 'preStepTimeSec')           && isnumeric(params.preStepTimeSec)),           sprintf('params.preStepTimeSec does not exist or it does not contain a numeric value.'));
    assert((isfield(params, 'stepTimeSec')              && isnumeric(params.stepTimeSec)),              sprintf('params.stepTimeSec does not exist or it does not contain a numeric value.'));
    assert((isfield(params, 'carrierFrequency')         && isnumeric(params.carrierFrequency)),         sprintf('params.carrierFrequency does not exist or it does not contain a numeric value.'));
    assert((isfield(params, 'carrierPhase')             && isnumeric(params.carrierPhase)),             sprintf('params.carrierPhase does not exist or it does not contain a numeric value.'));
    assert((isfield(params, 'nContrastScalars')         && isnumeric(params.nContrastScalars)),         sprintf('params.nContrastScalars does not exist or it does not contain a numeric value.'));
    assert((isfield(params, 'contrastScalars')          && isnumeric(params.contrastScalars)),          sprintf('params.contrastScalars does not exist or it does not contain a numeric value.'));
    assert((isfield(params, 'maxContrast')              && isnumeric(params.maxContrast)),              sprintf('params.maxContrast does not exist or it does not contain a numeric value.'));
    assert((isfield(params, 'coneNoise')                && isnumeric(params.coneNoise)),                sprintf('params.coneNoise does not exist or it does not contain a numeric value.'));
    assert((isfield(params, 'coneNoiseFrequency')       && isnumeric(params.coneNoiseFrequency)),       sprintf('params.coneNoiseFrequency does not exist or it does not contain a numeric value.'));
    assert((isfield(params, 'direction')                && ischar(params.direction)),                   sprintf('params.direction does not exist or it does not contain a string value.'));
    assert((isfield(params, 'directionCacheFile')       && ischar(params.directionCacheFile)),          sprintf('params.directionCacheFile does not exist or it does not contain a string value.'));
    assert((isfield(params, 'stimulationMode')          && ischar(params.stimulationMode)),             sprintf('params.stimulationMode does not exist or it does not contain a string value.'));
    
    % All validations OK. Add entry to the dictionary.
    d(modulationName) = params;
end


function params = defaultParams()

    params = struct();
    % Type - * * * do we need one ? we have  params.modulationMode = 'pulse' ????? * * * *
    params.type = 'pulse';
    
    % Timing information
    params.trialDuration = 3;                   % Number of seconds to show each trial            
    params.timeStep = 1/64;                     % Number ms of each sample time
    params.cosineWindowIn = true;               % If true, have a cosine fade-in
    params.cosineWindowOut = true;              % If true, have a cosine fade-out
    params.cosineWindowDurationSecs = 0.5;      % Duration (in secs) of the cosine fade-in
    
    % Modulation information
    params.nFrequencies = 1;                    % Total number of frequencies
    params.nPhases = 1;                         % Total number of phases
    params.modulationMode = 'pulse';
    params.modulationWaveForm = 'pulse';
            
    % Modulation frequency parameters
    params.modulationFrequencyTrials = [];     % Sequence of modulation frequencies
    params.modulationPhase = [];

    params.phaseRandSec = [0];                 % Phase shifts in seconds
    params.preStepTimeSec = 0.5;               % Time before step
    params.stepTimeSec = 2; 
            
    % Carrier frequency parameters
    params.carrierFrequency = [-1];            % Sequence of carrier frequencies
    params.carrierPhase = [-1];
            
    % Contrast scaling
    params.nContrastScalars = 1;               % Number of different contrast scales
    params.contrastScalars = [1];              % Contrast scalars (as proportion of max.)
    params.maxContrast = 4;

    params.coneNoise = 0;                      % Do cone noise?
    params.coneNoiseFrequency = 8;
       
    % Direction identifiers
    params.direction = '';                     % Modulation direction
    params.directionCacheFile = '';            % Cache file to be used
    
    % Stimulation mode
    params.stimulationMode = 'maxmel';
end
