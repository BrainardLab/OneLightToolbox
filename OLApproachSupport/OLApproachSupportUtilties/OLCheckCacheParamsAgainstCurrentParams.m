function cacheIsStale = OLCheckCacheParamsAgainstCurrentParams(cacheParams, currentParams, type)
% OLCheckCacheParamsAgainstCurrentParams - Checks cached vs. current params to determine if cache is stale.
%
% Usage:
%     cacheIsStale = OLCheckCacheParamsAgainstCurrentParams(cacheParams, currentParams, type)
%
% Description:
%     Check wether the cached and the current params agree or not. If they do not the cache is labeled as stale.
%
% Input:
%     cacheParams          Parameters loaded from the cache
%
%     currentParams        Current Parameters 
%
%     type                  String describing the type of cache, so as to
%                           do a more intelligent comparison

% 7/19/17    npc        Wrote it.

switch (type)
    case 'BackgroundNominalPrimaries'
        cacheIsStale = checkBackgroundNominalParams(cacheParams, currentParams);
    case 'DirectionNominalPrimaries'
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
    fprintf('For now skipping this comparison, and setting cacehIsStale = false\n');
    cacheIsStale = false;
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
end


