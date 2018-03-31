function [waveform, timestep, waveformDuration] = OLWaveformFromName(waveformName,varargin)
% Generate a parameterized waveform from the parameter name
%
% Syntax:
%   waveform = OLWaveformFromName(waveformName)
%   [waveform, timestep, waveformDuration] = OLWaveformFromName(waveformName)
%
% Description:
%    For parameterized waveforms that are stored in
%    OLWaveformParamsDictionary, this function will pull out the parameters
%    and return the actual waveform.
%
% Inputs:
%    waveformName     - String name of a set of parameters for a waveform
%                       stored in OLWaveformParamsDictionary.
%
% Outputs:
%    waveform         - a 1xt rowvector of differentialScalar in range [0,1] at each 
%                       timepoint.
%    timestep         - Timestep used to generate waveform
%    waveformDuration - Duration of the total waveform in seconds, at the
%                       given timestep (see above)
%
% Optional key/value pairs:
%    'alternateDictionaryFunc' - String with name of alternate dictionary
%                       function to call. This must be a function on the
%                       path. Default of empty results in using this
%                       function.
%
% Notes:
%    None.
%
% See also:
%    OLWaveformParamsDictionary, OLWaveformFromParams,
%    OLWaveformParamsDefaults, OLWaveformFromParams.

% History:
%    01/30/18  jv  Created as wrapper around OLWaveformFromParams and
%                  OLWaveformParamsDictionary.
%    03/31/18  dhb  Add alternateDictionaryFunc key/value pair.

waveformParams = OLWaveformParamsFromName(waveformName,varargin{:});
[waveform, timestep, waveformDuration] = OLWaveformFromParams(waveformParams);
end