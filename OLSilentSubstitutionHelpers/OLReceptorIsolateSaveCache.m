function OLReceptorIsolateSaveCache(cacheData, olCache, params)
% OLReceptorIsolateSaveCache - Saves cache as produced by OLReceptorIsolate routines
%
% Syntax:
% OLReceptorIsolateSaveCache(cacheData, olCache, params)
%
% Input:
% cacheData (struct) - Cache struct as produced by OLReceptorIsolateMakeModulationNominalPrimaries
% olCache (class) - Cache class
% params (struct) - Params struct as produced by OLReceptorIsolatePrepareConfig
%
% See also:
%   OLReceptorIsolateMakeModulationNominalPrimaries, OLReceptorIsolatePrepareConfig
%
% 4/19/13   dhb, ms     Update for new convention for desired contrasts in routine ReceptorIsolate.
% 2/25/14   ms          Modularized.

% Create the cache file name.
[~, cacheFileName] = fileparts(params.cacheFile);

% Save the cache data.
fprintf('\n> Saving out cache file to %s...', cacheFileName);
olCache.save(cacheFileName, cacheData);
fprintf('Done.');
fprintf('\n*** COMPLETE ***\n');