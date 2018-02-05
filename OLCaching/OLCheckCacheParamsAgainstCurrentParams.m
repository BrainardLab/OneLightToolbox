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
        checkBackgroundParams(cacheParams.params, currentParams);
    case 'Direction'
        checkDirectionParams(cacheParams.directionParams, currentParams);
    otherwise
        error('Unknown type: ''%s''.\n', type);
end
end

function checkBackgroundParams(cacheParams, currentParams)

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

function checkDirectionParams(cacheParams, currentParams)
switch (cacheParams.type)
    case {'unipolar','bipolar'}
         fieldsToCompare = {...
             'fieldSizeDegrees', ...
             'pupilDiameterMm' , ...
             'baseModulationContrast', ...
             'maxPowerDiff', ...
             'primaryHeadRoom'};
          if ~(AreStructsEqualOnFields(cacheParams, currentParams, fieldsToCompare))
              error('DirectionParams cache data and CurrentParams differ on fields!!\n');
          end
    case 'lightfluxchrom'
         fieldsToCompare = {...
             'lightFluxDesiredXY', ...
             'lightFluxDownFactor' , ...
             };
          if ~(AreStructsEqualOnFields(cacheParams, currentParams, fieldsToCompare))
              error('DirectionParams cache data and CurrentParams differ on fields!!\n');
          end
    otherwise
        error('Unknown background type specified');
end
end


