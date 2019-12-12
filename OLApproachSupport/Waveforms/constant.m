function waveform = constant(duration, samplingFq, varargin)
% Generates waveform given duration & samplingFq, of constant power
%
% Syntax:
%   waveform = constant(duration, samplingFq);
%
% Description:
%    Produce a waveform vector defining a constant waveform at unit power 
%    (1), sampled at the given sampling frequency over the given duration.
%    Purely for convenience of not having to think about the duration *
%    samplingFq math.
%
% Inputs:
%    duration   - duration, in seconds, of waveform
%    samplingFq - sampling frequency, in Hz
%
% Outputs:
%    waveform   - numeric rowvector [1x(duration*samplingFq)] of unit power

% History:
%    12/13/18  jv  wrote it.

%% Input parser
parser = inputParser;
parser.addRequired('duration',@(x) isnumeric(x) || isduration(x));
parser.addRequired('samplingFq',@isnumeric);
parser.parse(duration, samplingFq, varargin{:});
if isduration(duration)
    duration = seconds(duration);
end

%% Generate waveform
nSamples = duration * samplingFq;
waveform = ones(1,nSamples);
end