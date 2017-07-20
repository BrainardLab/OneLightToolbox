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
if (~strcmp(cacheParams.dictionaryType,currentParams.dictionaryType))
    error('Cached and current params are not of same dictionary type.');
end

%% Farm out check based on dictionary type
switch (currentParams.dictionaryType)
    case 'Background'
        cacheIsStale = checkBackgroundNominalParams(cacheParams, currentParams);
    case 'Direction'
        cacheIsStale = checkDirectionNominalParams(cacheParams, currentParams);
    otherwise
        error('Unknown type: ''%s''.\n', type);
end
end

function cacheIsStale = checkBackgroundNominalParams(cacheParams, currentParams)
% NCP: Right here need to compare cacheData.describe.params with the
% currently passed parameters.  If any fields differ, then a recompute
% should be forced.
%
%  It's possible that some parameters beyond what was returned by the dictionary
%  were added to params, such as the output file path.  This might lead to
%  false alarms.  You can look.
%
%  I'd add a printout on recomputing (controlled by a verbose key/value pair)
%  and make sure this isn't triggered in some nuisance manner.
fprintf('Checking weather the BackgroundNominalParams cache is stale.\n');
fprintf('Cache params:\n');
cacheParams
fprintf('Current params:\n');
currentParams
fprintf('Here we need to actually check if the two sets of params agree in order to determine if the cache is stale.\n');

switch (cacheParams.type)
    case 'optimized'
    case 'lightfluxchrom'
    otherwise
        error('Unknown background type specified');
end
end

function cacheIsStale = checkDirectionNominalParams(cacheParams, currentParams)
% NCP: Right here need to compare cacheData.describe.params with the
% currently passed parameters.  If any fields differ, then a recompute
% should be forced.
%
%  It's possible that some parameters beyond what was returned by the dictionary
%  were added to params, such as the output file path.  This might lead to
%  false alarms.  You can look.
%
%  I'd add a printout on recomputing (controlled by a verbose key/value pair)
%  and make sure this isn't triggered in some nuisance manner.
fprintf('Checking weather the DirectionNominalParams cache is stale.\n')
fprintf('Cache params:\n');
cacheParams
fprintf('Current params:\n');
currentParams
fprintf('Here we need to actually check if the two sets of params agree in order to determine if the cache is stale.\n');
fprintf('For now skipping this comparison, and setting cacehIsStale = false\n');
cacheIsStale = false;

switch (cacheParams.type)
    case 'pulse'
%         AreStructsEqualOnFields(    );
%         protocolParams.fieldSizeDegrees = 27.5;
%         protocolParams.pupilDiameterMm = 8;
%         protocolParams.baseModulationContrast = 4/6;
%         protocolParams.maxPowerDiff = 10^(-1);
%         protocolParams.primaryHeadroom = 0.01;
    otherwise
        error('Unknown background type specified');
end
end


