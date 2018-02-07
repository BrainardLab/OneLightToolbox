function names = OLGetDictionaryEntryNames(dictionaryName)
% Returns list of all names defined in given parameter dictionary
%
% Syntax:
%   names = OLGetDictionaryEntryNames(dictionaryName)
%
% Description:
%
% Inputs:
%    dictionaryName - string name of the parameter dictionary to list:
%                       * Background
%                       * Direction
%                       * Waveform
%
% Outputs:
%    names          - Nx1 cell array of names for the parameters in the 
%                     given dictionary
%
% Optional key/value pairs:
%    None.
%
% Notes:
%    None.
%
% See also:
%    OLBackgroundParamsDictionary, OLDirectionParamsDictionary,
%    OLWaveformParamsDictionary.

% History:
%    01/31/18  jv  Wrote it.
dictionaryFunction = str2func(sprintf('@OL%sNominalParamsDictionary',dictionaryName));
dictionary = dictionaryFunction();
names = dictionary.keys()';
end

