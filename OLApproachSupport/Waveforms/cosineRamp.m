function waveform = cosineRamp(duration, samplingFq, varargin)
% Generates a cosine-ramp waveform
%
% Syntax:
%   waveform = cosineRamp(duration, samplingFq);
%
% Description:
%    Produce a waveform vector defining a half-cosine window ramp from 0 to
%    1, sampled at the given sampling frequency over the given duration.
%
% Inputs:
%    duration   - duration, in seconds, of waveform
%    samplingFq - sampling frequency, in Hz
%
% Outputs:
%    waveform   - numeric rowvector [1x(duration*samplingFq)] of power in
%                 range [0, 1]

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
waveform = ((cos(pi + linspace(0, 1, nSamples)*pi)+1)/2);
end