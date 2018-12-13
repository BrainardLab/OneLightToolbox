function waveform = sinewave(duration, samplingFq, varargin)
% Create atomic sinewave waveform
%
% Syntax:
%   waveform = sinewave(duration, samplingFq, frequency, phase);
%
% Inputs:
%    duration   - duration, in seconds, of waveform
%    samplingFq - sampling frequency, in Hz
%    frequency  - frequency, in Hz, of waveform. Default 1.
%    phase      - phase (offset), in degrees. Default 0.
%
% Outputs:
%    waveform   - numeric rowvector [1x(duration*samplingFq)] of power in
%                 range [-1, 1]
%
% Optional key/value pairs:
%    None.
%

% History:
%    05/03/18  jv  wrote it.

%% Input parser
parser = inputParser;
parser.addRequired('duration',@(x) isnumeric(x) || isduration(x));
parser.addRequired('samplingFq',@isnumeric);
parser.addOptional('frequency',1,@isnumeric);
parser.addOptional('phase',0,@isnumeric);
parser.parse(duration, samplingFq, varargin{:});
frequency = parser.Results.frequency;
phase = parser.Results.phase;
timestep = 1/samplingFq;

%% Generate timebase
if isduration(duration)
    duration = seconds(duration);
end
timebase = 0:timestep:duration-timestep;

%% Generate waveform
waveform = sin(2*pi*frequency*timebase+(pi/180)*phase);
end