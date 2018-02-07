function valid = OLWaveformParamsValidate(params)
% Validate passed modulation parameters
%
% Syntax:
%   valid = OLWaveformParamsValidate(entry)
%
% Description:
%    This function checks whether a given params struct has all the
%    appropriate fields, and no additional fields. The exact fields
%    required, are those returned by OLWaveformParamsDefaults, for the
%    modulation type specified in params. Throws an error if additional
%    fields are present, or if a field is missing or contains an unexpected
%    value.
%
% Inputs:
%    params - the params to be validated and added to the dictionary
%
% Outputs:
%    valid  - logical boolean. True if entry contains all those fields, and 
%             only those fields, returned by
%             OLWaveformParamsDefaults for the given type. False if 
%             missing or additional fields.
%
% Optional key/value pairs:
%    None.
%
% See also:
%    OLWaveformParamsDefaults, OLWaveformParamsDictionary

% History:
%    01/25/18  jv  Extracted from OLModulationParamsDictionary


%% Get all the expected field names for this type
allFieldNames = fieldnames(OLWaveformParamsDefaults(params.type));

%% Test that there are no extra params
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

%% Test that expected type-independent params exist, and that they have the
% expected type
assert((isfield(params, 'dictionaryType')           && ischar(params.dictionaryType)),              sprintf('params.dictionaryType does not exist or it does not contain a string value.'));
assert((isfield(params, 'type')                     && ischar(params.type)),                        sprintf('params.type does not exist or it does not contain a string value.'));
assert((isfield(params, 'name')                     && ischar(params.name)),                        sprintf('params.name does not exist or it does not contain a string value.'));
assert((isfield(params, 'stimulusDuration')         && isnumeric(params.stimulusDuration)),         sprintf('params.stimulusDuration does not exist or it does not contain a numeric value.'));
assert((isfield(params, 'timeStep')                 && isnumeric(params.timeStep)),                 sprintf('params.timeStep does not exist or it does not contain a numeric value.'));
assert((isfield(params, 'contrast')                 && isnumeric(params.contrast)),                 sprintf('params.contrast does not exist or it does not contain a numeric value.'));
assert((isfield(params, 'cosineWindowIn')           && islogical(params.cosineWindowIn)),           sprintf('params.cosineWindowIn does not exist or it does not contain a boolean value.'));
assert((isfield(params, 'cosineWindowOut')          && islogical(params.cosineWindowOut)),          sprintf('params.cosineWindowOut does not exist or it does not contain a boolean value.'));
assert((isfield(params, 'cosineWindowDurationSecs') && isnumeric(params.cosineWindowDurationSecs)), sprintf('params.cosineWindowDurationSecs does not exist or it does not contain a numeric value.'));

%% Test that expected type-dependent params exist, and that they have the
% expected type We know about several types:
%   'pulse'  Unidirectional pulse.  Frequency and phase have no meaning.
%   'sinusoid' sinusoidal modulation of contrast.
switch (params.type)
    case 'pulse'
        assert((isfield(params, 'coneNoise')                && isnumeric(params.coneNoise)),                sprintf('params.coneNoise does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'coneNoiseFrequency')       && isnumeric(params.coneNoiseFrequency)),       sprintf('params.coneNoiseFrequency does not exist or it does not contain a numeric value.'));
    case 'sinusoid'
        assert((isfield(params, 'frequency')                && isnumeric(params.frequency)),                sprintf('params.frequency does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'phaseDegs')                && isnumeric(params.phaseDegs)),                sprintf('params.phaseDegs does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'coneNoise')                && isnumeric(params.coneNoise)),                sprintf('params.coneNoise does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'coneNoiseFrequency')       && isnumeric(params.coneNoiseFrequency)),       sprintf('params.coneNoiseFrequency does not exist or it does not contain a numeric value.'));
    otherwise
        error('Unknown modulation starts/stops type');
end

%% Return
valid = true;

end

