function dictionary = OLWaveformParamsDictionary
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
%    None.
%
% Notes:
%    * When you add a new type, you need to add that type to the 
%      corresponding switch statement in 
%      OLCheckCacheParamsAgainstCurrentParams.
%
% See also: 
%    OLWaveformParamsDefaults, OLWaveformParamsValidate,
%    OLMakeModulationPrimaries, 

%    OLDirectionNominalParamsDictionary, OLMakeDirectionNominalPrimaries,
%
%    OLCheckCacheParamsAgainstCurrentParams

% History:
%    06/23/17  npc  Wrote it.
%    07/19/17  npc  Added a type for each modulation. For now, there is only one type: 'basic'. 
%                   Defaults and checking are done according to type.
%                   Isomorphic direction name and cache filename.
%    09/25/17  dhb  Cleaned up Michael Barnett's method of adding new modulation to dictionary. 
%                   (Don't modify the defaults to do this, add a new entry and override the defaults explicitly.)
%    01/25/18  jv   Extract default params generation, validation.

%% Initialize dictionary
dictionary = containers.Map();

%% MaxContrast3sPulse
modulationName = 'MaxContrast3sPulse';
type = 'pulse';

params = OLWaveformParamsDefaults(type);
params.name = modulationName;
params.stimulusDuration = 3;

if OLWaveformParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxContrast4sPulse
modulationName = 'MaxContrast4sPulse';
type = 'pulse';

params = OLWaveformParamsDefaults(type);
params.name = modulationName;
params.stimulusDuration = 4;

if OLWaveformParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxContrast3sSinusoid
modulationName = 'MaxContrast3sSinusoid';
type = 'sinusoid';

params = OLWaveformParamsDefaults(type);
params.name = modulationName;
params.stimulusDuration = 3;                
params.cosineWindowDurationSecs = 0.5;      

if OLWaveformParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxContrast12sSinusoid
modulationName = 'MaxContrast12sSinusoid';
type = 'sinusoid';

params = OLWaveformParamsDefaults(type);
params.name = modulationName;
params.stimulusDuration = 12;                  
params.cosineWindowDurationSecs = 3;            
                
if OLWaveformParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

end