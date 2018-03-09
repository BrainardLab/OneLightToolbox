function primaryWaveform = OLPrimaryWaveform(direction, waveform, varargin)
% Combine OLDirection and waveform into waveform-matrix of primaries
%
% Syntax:
%   primaryWaveform = OLPrimaryWaveform(OLDirection, waveform)
%   primaryWaveform = OLPrimaryWaveform(...,'differential',false)
%   primaryWaveform = OLPrimaryWaveform(..., 'truncateGamut',true)
%
% Description:
%
% Inputs:
%    direction       - OLDirection object specifying the direction to
%                      create primary waveform for.
%    waveform        - The waveform of temporal modulation, in a Nxt matrix
%                      power levels for each of the N basis functions at
%                      each timepoint t.
%
% Outputs:
%    primaryWaveform - The primary values at each timepoint t, in a Pxt
%                      matrix. If multiple primary basis vectors were and
%                      corresponding waveforms were passed in (i.e. N > 1),
%                      these have been combined into a single
%                      waveform-matrix.
%
% Optional key/value pairs:
%    differential    - Boolean flag for treating primary values as
%                      differentials, i.e. in range [-1, +1]. Default
%                      true.
%    truncateGamut   - Boolean flag for truncating the output to be within
%                      gamut (i.e outside range [0,1]. If false, and output
%                      is out of gamut, will throw an error. If true, and
%                      output is out of gamut, will throw a warning, and
%                      proceed to truncate output to be in gamut. Default
%                      false.
%
% Notes:
%    None.
%
% See also:
%    OLPrimaryWaveform, OLDirection, OLPlotPrimaryWaveform

% History:
%    01/29/18  jv  wrote it.
%    03/09/18  jv  overloaded for OLDirection objects

%% Input validation
parser = inputParser();
parser.addRequired('direction',@(x) isa(x,'OLDirection'));
parser.addRequired('waveform',@isnumeric);
parser.addParameter('differential',true,@islogical);
parser.addParameter('truncateGamut',false,@islogical);
parser.parse(direction,waveform,varargin{:});

%% Parse waveform into positive and negative components
waveformPos = (waveform >= 0) .* waveform;
waveformNeg = (waveform < 0) .* -waveform;
waveform = [waveformPos; waveformNeg];

%% Matrix multiplication
primaryWaveform = [direction.differentialPositive, direction.differentialNegative] * waveform;

%% Check gamut
gamut = [0 1] - [parser.Results.differential 0]; % set gamut limits
if any(primaryWaveform(:) < gamut(1)-1e-10 | primaryWaveform(:) > gamut(2)+1e-10)
    if parser.Results.truncateGamut
        warning('OneLightToolbox:OLPrimaryWaveform:OutOfGamut','Primary waveform is out of gamut somewhere. This will be truncated');
        primaryWaveform(primaryWaveform < gamut(1)) = gamut(1);
        primaryWaveform(primaryWaveform > gamut(2)) = gamut(2);
    else
        error('OneLightToolbox:OLPrimaryWaveform:OutOfGamut','Primary waveform is out of gamut somewhere.');
    end
end

end