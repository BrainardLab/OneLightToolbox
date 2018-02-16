function params = OLWaveformParamsDefaults(type)
% Returns structure with default parameters for a modulation type
%
% Syntax:
%   params = OLModulationDictionaryDefaults(type)
%
% Description:
%    Since a lot of modulation specifications are small variations, this
%    function generates a set of default parameters; the parameters of
%    interest can then be overridden afterwards (either in the 
%    OLWaveformParamsDictionary, or elsewhere), before using the
%    parameters to generate modulation primary values.
%
% Inputs:
%    type   - string name of the type of modulation. Currently available:
%               'pulse'   :   unidirectional step up and back down
%               'sinusoid':   sinusoidal modulation of contrast
%
% Outputs:
%    params - a struct with the default parameters for the given type of
%             modulation
%
% Optional key/value pairs:
%    None.
%
% See also:
%    OLWaveformParamsValidate, OLWaveformParamsDictionary 

% History:
%    01/25/18  jv  Extracted from OLModulationParamsDictionary

params = struct();
params.type = type;
params.name = '';

%% Set type-independent parameter defaults
params.dictionaryType = 'Modulation'; % What type of parameter structure?

% Timing parameters
params.timeStep = 1/64;                     % Number ms of each sample time     
params.stimulusDuration = 3;                % Number of seconds to show each trial

% Contrast scaling
params.contrast = 1;                         % Contrast scalars (as proportion of max specified in the direction)

% Windowing
params.cosineWindowIn = true;               % If true, have a cosine fade-in
params.cosineWindowOut = true;              % If true, have a cosine fade-out
params.cosineWindowDurationSecs = 0.5;      % Duration (in secs) of the cosine fade-in/out

%% Set type-dependent parameter defaults
switch params.type
    case 'sinusoid'
        % Sinusoidal bipolar flicker.
       
        % Frequency and phase
        params.frequency = 2;                       % Frequency in Hz
        params.phaseDegs = 0;                       % Phase in degrees
        
        % Cone noise parameters. 
        params.coneNoise = 0;                        % Set to 1 for cone noise
        params.coneNoiseFrequency = -1;              % Frequency of cone noise    

    case 'squarewave'
        % Sinusoidal bipolar flicker.
       
        % Frequency and phase
        params.frequency = 2;                       % Frequency in Hz
        params.phaseDegs = 0;                       % Phase in degrees
        
        % Cone noise parameters. 
        params.coneNoise = 0;                        % Set to 1 for cone noise
        params.coneNoiseFrequency = -1;              % Frequency of cone noise    
        
    case 'pulse'
        % Unipolar pulse.  
        % Frequency and phase have no meaning.
         
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

