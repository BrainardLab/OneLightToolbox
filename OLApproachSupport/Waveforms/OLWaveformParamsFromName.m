function waveformParams = OLWaveformParamsFromName(waveformName,varargin)
% Returns parameters stored in under name in dictionary
%
% Syntax:
%   waveformParams = OLWaveformParamsFromName(waveformName)
%
% Description:
%    For parameterized waveforms that are stored under their name in
%    OLWaveformParamsDictionary, this function will return the
%    parameters.
%
% Inputs:
%    waveformName   - String name of a set of parameters for a waveform
%                       stored in OLWaveformNominalStructParamsDictionary
%
% Outputs:
%    waveformParams - struct defining the parameters for a type of
%                       waveform. Can be generated using
%                       OLWaveformParamsDefaults
%
% Optional key/value pairs:
%    'alternateDictionaryFunc' - String with name of alternate dictionary
%                       function to call. This must be a function on the
%                       path. Default of empty string results in using the
%                       OneLightToolbox dictionary.
%
% Notes:
%    None.
%
% See also:
%    OLWaveformParamsDictionary,
%    OLWaveformNominalPrimaryFromParams, OLWaveformParamsDefaults,
%    OLWaveformParamsValidate.

% History:
%    01/31/18  jv  Wrote it.
%    03/31/18  dhb  Add alternateDictionaryFunc key/value pair.

waveformParamsDictionary = OLWaveformParamsDictionary(varargin{:});
waveformParams = waveformParamsDictionary(waveformName);
end