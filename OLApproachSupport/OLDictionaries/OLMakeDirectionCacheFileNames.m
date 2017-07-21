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

    paramsDictionary = OLDirectionNominalParamsDictionary();
    for k = 1:numel(protocolParams.directionNames)
        % A little ugly, but we need to have the type field according to the directionType
        protocolParams.type = protocolParams.directionTypes{k};
        directionName = OLMakeApproachDirectionName(protocolParams.directionNames{k}, protocolParams); %sprintf('%s_%d_%d_%d',protocolParams.directionNames{k},round(10*protocolParams.fieldSizeDegrees),round(10*protocolParams.pupilDiameterMm),round(1000*protocolParams.baseModulationContrast));
        directionParams = paramsDictionary(directionName);
        directionCacheFileNames{k} = strrep(directionParams.cacheFile, '.mat', '');
    end
end