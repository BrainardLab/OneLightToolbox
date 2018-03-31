function names = OLGetDictionaryEntryNames(dictionaryName,varargin)
% Returns list of all names defined in given parameter dictionary
%
% Syntax:
%   names = OLGetDictionaryEntryNames(dictionaryName)
%
% Description:
%      Returns list of all names defined in given type of parameter
%      dictionary.
%
%      Respects the alternateDictionaryFunc key/value pair as long as the
%      underlying dictionary in the OneLightToolbox does.
%
% Inputs:
%     dictionaryName - String name of the parameter dictionary to list. Thes
%                      can be 'X' as long as there is a dictionary in the
%                      OneLightToolbox whose name has the form
%                      'OLXParamsDictionary.  Examples include.
%                       * 'Background'
%                       * 'Direction'
%                       * 'Waveform'
%
% Outputs:
%    names           - Nx1 cell array of names for the parameters in the 
%                      given dictionary
%
% Optional key/value pairs:
%    'alternateDictionaryFunc' - String with name of alternate dictionary
%                      function to call. This must be a function on the
%                      path. Default of empty results in using this
%                      function.
%
% Notes:
%    None.
%
% See also:
%    OLBackgroundParamsDictionary, OLDirectionParamsDictionary,
%    OLWaveformParamsDictionary.

% History:
%    01/31/18  jv  Wrote it.
%    03/31/18  dhb  Add alternateDictionaryFunc key/value pair.

dictionaryFunction = str2func(sprintf('@OL%sParamsDictionary',dictionaryName));
dictionary = dictionaryFunction(varargin{:});
names = dictionary.keys()';
end

