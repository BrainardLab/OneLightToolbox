function waveformNames = OLGetWaveformNames
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
%                      OLWaveformParamsDictionary
%
% Optional key/value pairs:
%    None.
%
% Notes:
%    None.
%
% See also:
%    OLWaveformParamsDictionary,

% History:
%    01/31/18  jv  Wrote it.
waveformNames = OLGetDictionaryEntryNames('Waveform');
end