function waveformNames = OLGetWaveformNames(varargin)
% Returns list of all named waveforms in WaveformParamsDictionary
%
% Syntax:
%   waveformNames = OLGetWaveformNames
%
% Description:
%    For all parameterized waveforms that are stored under their name in
%    OLWaveformParamsDictionary, this function will return the name of
%    the parameter set.
%
% Inputs:
%    None.
%
% Outputs:
%    waveformNames - Nx1 cell array of names for the parameters in
%                    OLWaveformParamsDictionary
%
% Optional key/value pairs:
%    'alternateDictionaryFunc' - String with name of alternate dictionary
%                    function to call. This must be a function on the
%                    path. Default of empty string results in using the
%                    OneLightToolbox dictionary.
%
% Notes:
%    None.
%
% See also:
%    OLWaveformParamsDictionary,

% History:
%    01/31/18  jv  Wrote it.
%    03/31/18  dhb  Add alternateDictionaryFunc key/value pair.

waveformNames = OLGetDictionaryEntryNames('Waveform',varargin{:});
end