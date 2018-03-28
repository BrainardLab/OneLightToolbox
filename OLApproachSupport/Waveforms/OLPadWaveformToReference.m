function paddedWaveform = OLPadWaveformToReference(waveform, reference, varargin)
% Pad waveform to have same duration as reference waveform
% 
% Syntax:
%   paddedWaveform = OLPadWaveformToReference(waveform, reference)
%   paddedWaveform = OLPadWaveformToReference(..., 'leadingTrailing','leading')
%   paddedWaveform = OLPadWaveformToReference(..., 'leadingTrailing','trailing')
%   paddedWaveform = OLPadWaveformToReference(..., 'leadingTrailing','both')
%   paddedWaveform = OLPadWaveformToReference(..., 'padValue', padValue)
%
% Description:
%    Pads a waveform a given waveform until it has the same number of
%    values as the reference waveform. Assuming that both waveforms have
%    the same timestep, this result in the waveforms matching in duration.
%    Padding is done either leading, trailing, or on both ends (default),
%    and with any value (default 0))
%
% Inputs:
%    waveform        - numeric vector defining waveform to pad
%    reference       - numeric vector defining waveform whose length to pad 
%                      to
%
% Outputs:
%    paddedWaveform  - numeric vector containing padded waveform
%                      (length(paddedWaveform) == length(reference)
%
% Optional key/value pairs:
%    leadingTrailing - which side to pad: 'leading', 'trailing', or 'both'.
%                      If padding both ends with an odd number of frames, 1
%                      more trailing frame will be added. Default is 'both'
%    padValue        - numeric value to pad with. Default is 0
%
% See also:
%

% History:
%    03/28/18  jv  wrote it.

%% Input validation
parser = inputParser;
parser.addRequired('waveform',@(x) isnumeric(x) && isrow(x));
parser.addRequired('reference',@(x) isnumeric(x) && isrow(x));
parser.addParameter('leadingTrailing','both',@(x) ischar(x) || isstring(x))
parser.addParameter('padValue',0,@(x) isnumeric(x) && isscalar(x));
parser.parse(waveform, reference, varargin{:});

if length(reference) > length(waveform)
    %% Pad
    framesToAdd = length(reference) - length(waveform);
    switch parser.Results.leadingTrailing
        case 'leading'
            leadingFrames = framesToAdd;
            trailingFrames = 0;
        case 'trailing'
            leadingFrames = 0;
            trailingFrames = framesToAdd;
        case 'both'
            leadingFrames = floor(framesToAdd / 2);
            trailingFrames = framesToAdd - leadingFrames;
    end
    paddedWaveform = [zeros(1,leadingFrames) waveform zeros(1, trailingFrames)];
else
    paddedWaveform = waveform;
end

end