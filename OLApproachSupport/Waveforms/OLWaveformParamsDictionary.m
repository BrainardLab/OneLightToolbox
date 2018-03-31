function dictionary = OLWaveformParamsDictionary(varargin)
% Defines a dictionary with parameters for named modulations
%
% Syntax:
%   dictionary = OLWaveformParamsDictionary()
%
% Description:
%    Define a dictionary of named timeseries of modulation, with
%    corresponding nominal parameters. Types of modulations, and their
%    corresponding fields, are defined in OLWaveformParamsDefaults
%    and validated by OLWaveformParamsValidate.
%
% Inputs:
%    None.
%
% Outputs:
%    dictionary - dictionary with all parameters for all desired
%                 backgrounds
%
% Optional key/value pairs:
%    'alternateDictionaryFunc' - String with name of alternate dictionary
%                 function to call. This must be a function on the
%                  path. Default of empty results in using this
%                  function.
%
% Notes:
%    None.
%
% See also: 
%    OLWaveformParamsDefaults, OLWaveformParamsValidate,
%    OLMakeModulationPrimaries, OLDirectionParamsDictionary,
%    OLMakeDirectionNominalPrimaries.
%

% History:
%    06/23/17  npc  Wrote it.
%    07/19/17  npc  Added a type for each modulation. For now, there is only one type: 'basic'. 
%                   Defaults and checking are done according to type.
%                   Isomorphic direction name and cache filename.
%    09/25/17  dhb  Cleaned up Michael Barnett's method of adding new modulation to dictionary. 
%                   (Don't modify the defaults to do this, add a new entry and override the defaults explicitly.)
%    01/25/18  jv   Extract default params generation, validation.
%    03/31/18  dhb  Add alternateDictionaryFunc key/value pair.
%              dhb  Delete obsolete notes and see alsos.

%% Parse input
p = inputParser;
p.KeepUnmatched = true;
p.addParameter('alternateDictionaryFunc','',@ischar);
p.parse(varargin{:});

%% Check for alternate dictionary, call if so and then return.
% Otherwise this is the dictionary function and we execute it.
% The alternate function must be on the path.
if (~isempty(p.Results.alternateDictionaryFunc))
    dictionaryFunction = str2func(sprintf('@%s',p.Results.alternateDictionaryFunc));
    dictionary = dictionaryFunction();
    return;
end

%% Initialize dictionary
dictionary = containers.Map();

%% MaxContrast3sPulse
modulationName = 'MaxContrastPulse';
type = 'pulse';

params = OLWaveformParamsDefaults(type);
params.name = modulationName;
params.stimulusDuration = 0;

if OLWaveformParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxContrast3sSinusoid
modulationName = 'MaxContrastSinusoid';
type = 'sinusoid';

params = OLWaveformParamsDefaults(type);
params.name = modulationName;
params.stimulusDuration = 0;                
params.cosineWindowDurationSecs = 0.5;      

if OLWaveformParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxContrastSquarewave
modulationName = 'MaxContrastSquarewave';
type = 'squarewave';

params = OLWaveformParamsDefaults(type);
params.name = modulationName;
params.stimulusDuration = 0;
params.cosineWindowDurationSecs = 0.5;

if OLWaveformParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

end