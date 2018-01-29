function primaryWaveform = OLPrimaryWaveform(primaryValues, waveform)
% Combine primary values and waveform into waveform-matrix of primaries
%
% Syntax:
%   primaryWaveform = OLPrimaryWaveform(primaryValues, waveform)
%
% Description:
%
% Inputs:
%    primaryValues   - The primary values to apply to a waveform, in a Px1
%                      column vector, where P is the number of primaries on
%                      the device.
%                      Can also be a PxN matrix, of N such vectors of
%                      primary values. In this case, N waveforms have to
%                      be specified as well (see below).
%    waveform        - The waveform of temporal modulation, in a 1xt row
%                      vector of power levels of the primary, at each
%                      timepoint t. Powerlevels must be in the range [0-1].
%                      Can also be a Nxt matrix, of N such waveforms. N
%                      must match N of primaryValues.
%
% Outputs:
%    primaryWaveform - The primary values at each timepoint t, in a Pxt
%                      matrix. If multiple vectors of primary values and
%                      corresponding waveforms were passed in, these have
%                      been combined into a single waveform-matrix.
%
% Optional key/value pairs:
%    None.
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
parser.addRequired('primaryValues',@(x) isnumeric(x) && all(x(:)>=0) && all(x(:)<=1))
parser.addRequired('waveform',@(x) isnumeric(x) && all(x(:)>=0) && all(x(:)<=1))
parser.parse(primaryValues,waveform);

%% Matrix multiplication
primaryWaveform = primaryValues * waveform;

end