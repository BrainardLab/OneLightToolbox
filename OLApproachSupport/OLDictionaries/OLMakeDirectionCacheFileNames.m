function directionCacheFileNames = OLMakeDirectionCacheFileNames(protocolParams)
% OLMakeDirectionCacheFileNames  Assemble direction cache file name that captures key protocol param values.
%
% Usage:
%     directionCacheFileNames = OLMakeDirectionCacheFileNames(protocolParams)
%
% Description:
%     Make the names of the cache files for the directions passed as a cell array of strings.  These are just
%     'Direction_' followed by the actual direction name, so we let OLMakeApproachDirectionName do the work.
%
% Input: 
%     protocolParams (struct)    The standard protocol parameter structure.
%
% Output
%     directionCacheFileNames (cell array)  Cell array of strings containing the cache file names.
%
% Optional key/value pairs:
%     None.
%
% See also: OLMakeApproachDirectionName.

    for k = 1:numel(protocolParams.directionNames)
        directionCacheFileNames{k} = sprintf('Direction_%s',OLMakeApproachDirectionName(protocolParams.directionNames{k},protocolParams));
    end
end