function d = OLModulationParamsDictionary
%ModulationParamsDictionary  Generate dictionary with modulation params.
%
% Description:
%     Generate dictionary with modulation params.
%
% Note:
%     When you add a new type, you need to add that type to the corresponding switch statment
%     in OLCheckCacheParamsAgainstCurrentParams.
%
% See also: OLCheckCacheParamsAgainstCurrentParams.

% 6/23/17  npc  Wrote it.
% 7/19/17  npc  Added a type for each modulation. For now, there is only one type: 'basic'. 
%               Defaults and checking are done according to type.
%               Isomorphic direction name and cache filename.

% Initialize dictionary
d = containers.Map();

%% MaxContrast3sSegment
modulationName = 'MaxContrast3sSegment';
type = 'pulse';

params = defaultParams(type);
params.name = modulationName;
d = paramsValidateAndAppendToDictionary(d, params);

end

function d = paramsValidateAndAppendToDictionary(d, params)

% Get all the expected field names for this type
allFieldNames = fieldnames(defaultParams(params.type));

% Test that there are no extra params
if (~all(ismember(fieldnames(params),allFieldNames)))
    fprintf(2,'\nParams struct contain extra params\n');
    fNames = fieldnames(params);
    idx = ismember(fieldnames(params),allFieldNames);
    idx = find(idx == 0);
    for k = 1:numel(idx)
        fprintf(2,'- ''%s'' \n', fNames{idx(k)});
    end
    error('Remove extra params or update defaultParams\n');
end

% Test that all expected params exist and that they have the expected type
% We know about several types:
%   'pulse'  Unidirectional pulse.  Frequency and phase have no meaning.
switch (params.type)
    case 'pulse'
        assert((isfield(params, 'dictionaryType')           && ischar(params.dictionaryType)),              sprintf('params.dictionaryType does not exist or it does not contain a string value.'));
        assert((isfield(params, 'type')                     && ischar(params.type)),                        sprintf('params.type does not exist or it does not contain a string value.'));
        assert((isfield(params, 'name')                     && ischar(params.name)),                        sprintf('params.name does not exist or it does not contain a string value.'));
        assert((isfield(params, 'trialDuration')            && isnumeric(params.trialDuration)),            sprintf('params.trialDuration does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'timeStep')                 && isnumeric(params.timeStep)),                 sprintf('params.timeStep does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'cosineWindowIn')           && islogical(params.cosineWindowIn)),           sprintf('params.cosineWindowIn does not exist or it does not contain a boolean value.'));
        assert((isfield(params, 'cosineWindowOut')          && islogical(params.cosineWindowOut)),          sprintf('params.cosineWindowOut does not exist or it does not contain a boolean value.'));
        assert((isfield(params, 'cosineWindowDurationSecs') && isnumeric(params.cosineWindowDurationSecs)), sprintf('params.cosineWindowDurationSecs does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'contrast')                 && isnumeric(params.contrast)),                 sprintf('params.contrast does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'coneNoise')                && isnumeric(params.coneNoise)),                sprintf('params.coneNoise does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'coneNoiseFrequency')       && isnumeric(params.coneNoiseFrequency)),       sprintf('params.coneNoiseFrequency does not exist or it does not contain a numeric value.'));
  case 'sinusoid'
        assert((isfield(params, 'dictionaryType')           && ischar(params.dictionaryType)),              sprintf('params.dictionaryType does not exist or it does not contain a string value.'));
        assert((isfield(params, 'type')                     && ischar(params.type)),                        sprintf('params.type does not exist or it does not contain a string value.'));
        assert((isfield(params, 'name')                     && ischar(params.name)),                        sprintf('params.name does not exist or it does not contain a string value.'));
        assert((isfield(params, 'trialDuration')            && isnumeric(params.trialDuration)),            sprintf('params.trialDuration does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'timeStep')                 && isnumeric(params.timeStep)),                 sprintf('params.timeStep does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'cosineWindowIn')           && islogical(params.cosineWindowIn)),           sprintf('params.cosineWindowIn does not exist or it does not contain a boolean value.'));
        assert((isfield(params, 'cosineWindowOut')          && islogical(params.cosineWindowOut)),          sprintf('params.cosineWindowOut does not exist or it does not contain a boolean value.'));
        assert((isfield(params, 'cosineWindowDurationSecs') && isnumeric(params.cosineWindowDurationSecs)), sprintf('params.cosineWindowDurationSecs does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'contrast')                 && isnumeric(params.contrast)),                 sprintf('params.contrast does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'frequency')                && isnumeric(params.frequency)),                sprintf('params.frequency does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'phaseDegs')                && isnumeric(params.phaseDegs)),                sprintf('params.phaseDegs does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'coneNoise')                && isnumeric(params.coneNoise)),                sprintf('params.coneNoise does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'coneNoiseFrequency')       && isnumeric(params.coneNoiseFrequency)),       sprintf('params.coneNoiseFrequency does not exist or it does not contain a numeric value.'));
    otherwise
        error('Unknown modulation starts/stops type');
end

% All validations OK. Add entry to the dictionary.
d(params.name) = params;
end


function params = defaultParams(type)

params = struct();
params.type = type;
params.name = '';

switch (type)
    case 'pulse'
        % Unipolar pulse.  Frequency and phase have no meaning.
        params.dictionaryType = 'Modulation';       % What type of dictionary is this?
        params.timeStep = 1/64;                     % Number ms of each sample time
        
        
        % Pulse timing parameters
        params.cosineWindowIn = true;               % If true, have a cosine fade-in
        params.cosineWindowOut = true;              % If true, have a cosine fade-out
        params.trialDuration = 3;                   % Number of seconds to show each trial
        params.cosineWindowDurationSecs = 0.5;      % Duration (in secs) of the cosine fade-in/out
         
        % Contrast scaling
        params.contrast = 1;                         % Contrast scalars (as proportion of max specified in the direction)
        
        % Cone noise parameters. 
        params.coneNoise = 0;                        % Set to 1 for cone noise
        params.coneNoiseFrequency = -1;              % Frequency of cone noise
        
    case 'sinusoid'
        % Sinusoidal flicker.
        params.dictionaryType = 'Modulation';       % What type of dictionary is this?
        params.timeStep = 1/64;                     % Number ms of each sample time
        
        
        % Pulse timing parameters
        params.cosineWindowIn = true;               % If true, have a cosine fade-in
        params.cosineWindowOut = true;              % If true, have a cosine fade-out
        params.trialDuration = 3;                   % Number of seconds to show each trial
        params.cosineWindowDurationSecs = 0.5;      % Duration (in secs) of the cosine fade-in/out
         
        % Contrast scaling
        params.contrast = 1;                        % Contrast scalars (as proportion of max specified in the direction)
        
        % Frequency and phase
        params.frequency = 5;                       % Frequency in Hz
        params.phaseDegs = 0;                       % Phase in degrees
        
        % Cone noise parameters. 
        params.coneNoise = 0;                        % Set to 1 for cone noise
        params.coneNoiseFrequency = -1;              % Frequency of cone noise

    case 'AM'
        error('Need to implement AM type in the dictionary before you may use it.')
        % % Carrier frequency parameters
        % params.carrierFrequency = [-1];            % Sequence of carrier frequencies
        % params.carrierPhase = [-1];
        
    otherwise
        error('Unknown modulation starts/stops type: ''%s''.\n', type);
end
end


