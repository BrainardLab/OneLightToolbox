function [waveform, timestep, waveformDuration] = OLWaveformFromName(waveformName)
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
%    None.
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
waveformParams = OLWaveformParamsFromName(waveformName);
[waveform, timestep, waveformDuration] = OLWaveformFromParams(waveformParams);
end