function primaryWaveform = OLPrimaryWaveform(primaryValues, waveform)
% Combine primary values and waveform into waveform-matrix of primaries
%
% Syntax:
%   primaryWaveform = OLPrimaryWaveform(primaryValues, waveform)
%
% Description:
%
% Inputs:
%    primaryValues   - The primary values to apply to a waveform, in a PxN
%                      column vector, where P is the number of primaries on
%                      the device N is the number of primary basis
%                      functions that can be combined at each timepoint.
%                      Note that N = 1 is a useful special case.
%    waveform        - The waveform of temporal modulation, in a Nxt matrix
%                      power levels for each of the N basis functions at each
%                      timepoint t. Powerlevels must be in the range [0-1].
%
% Outputs:
%    primaryWaveform - The primary values at each timepoint t, in a Pxt
%                      matrix. If multiple primary basis vectors were and
%                      corresponding waveforms were passed in (i.e. N > 1),
%                      these have been combined into a single
%                      waveform-matrix.
%
% Optional key/value pairs:
%    None.
%
% Examples are provided in the source code.
%
% Notes:
%    None.
%
% See also:
%

% History:
%    01/29/18  jv  wrote it.

% Examples:
%{  
    %% Sinusoidally modulate all device primaries between on and off
    % Set up temporal waveform
    timebase = linspace(0,5,200*5); % 5 seconds sampled at 200 hz
    sinewave = sin(2*pi*timebase);  % sinewave carrier
    waveform = abs(sinewave);       % rectify, powerlevels are [0-1]
    
    % Create primary waveform
    primaryValues = ones(54,1);     % 54 primaries, all full-on
    primaryWaveform = OLPrimaryWaveform(primaryValues, waveform);
%}
%{
    %% Add sinusoidal flicker to a steady background
    % Shared timebase
    timebase = linspace(0,5,200*5);      % 5 seconds sampled at 200 hz
    
    % Steady background
    backgroundPrimary = .5 * ones(54,1); % 54 primaries half-on
    backgroundWaveform = ones(1,200*5);  % same powerlevel throughout

    % Sinusoidal flicker
    examplePrimary = linspace(0,1,54)';  % some primary
    sinewave = sin(2*pi*timebase);       % sinewave carrier
    flickerWaveform = abs(sinewave);     % rectify, powerlevels are [0-1]

    % Create primary waveform
    primaryValues = [backgroundPrimary, examplePrimary] % horizontal cat
    waveforms = [backgroundWaveform; flickerWaveform]   % vertical cat
    primaryWaveform = OLPrimaryWaveform(primaryValues, waveforms)
%}

%% Input validation
parser = inputParser();
parser.addRequired('primaryValues',@isnumeric);
parser.addRequired('waveform',@(x) isnumeric(x) && all(x(:)>=0) && all(x(:)<=1));
parser.parse(primaryValues,waveform);

%% Matrix multiplication
primaryWaveform = primaryValues * waveform;

end