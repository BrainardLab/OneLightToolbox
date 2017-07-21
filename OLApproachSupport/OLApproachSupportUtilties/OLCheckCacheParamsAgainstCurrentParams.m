function OLCheckCacheParamsAgainstCurrentParams(cacheParams, currentParams)
% OLCheckCacheParamsAgainstCurrentParams - Checks cached vs. current params to determine if cache is stale.
%
% Usage:
%     OLCheckCacheParamsAgainstCurrentParams(cacheParams, currentParams, type)
%
% Description:
%     Check wether the cached and the current params agree or not. If they do not, throw an error and
%     make the user think about what is going on.
%
% Input:
%     cacheParams          Parameters loaded from the cache
%
%     currentParams        Current Parameters

% 7/19/17    npc        Wrote it.

%% Basic check

%% Farm out check based on dictionary type
switch (currentParams.dictionaryType)
    case 'Background'
        checkBackgroundNominalParams(cacheParams.params, currentParams);
    case 'Direction'
        checkDirectionNominalParams(cacheParams.directionParams, currentParams);
    otherwise
        error('Unknown type: ''%s''.\n', type);
end
end

function checkBackgroundNominalParams(cacheParams, currentParams)

if (~strcmp(cacheParams.dictionaryType,currentParams.dictionaryType))
    error('Cached and current Background params are not of same dictionary type.');
end

switch (cacheParams.type)
    case 'optimized'
    case 'lightfluxchrom'
    otherwise
        error('Unknown background type specified');
end
end

function checkDirectionNominalParams(cacheParams, currentParams)
switch (cacheParams.type)
    case 'pulse'
         fieldsToCompare = {...
             'fieldSizeDegrees', ...
             'pupilDiameterMm' , ...
             'baseModulationContrast', ...
             'maxPowerDiff', ...
             'primaryHeadRoom'};
          if ~(AreStructsEqualOnFields(cacheParams, currentParams, fieldsToCompare))
              error('DirectionNominalParams cache data and CurrentParams differ on fields!!\n');
          end
    otherwise
        error('Unknown background type specified');
end
end


