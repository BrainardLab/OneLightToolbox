function OLReceptorIsolateSaveCache(cacheData, olCache, params)
% OLReceptorIsolateSaveCache - Saves cache as produced by OLReceptorIsolateFindIsolatingPrimarySettings
%
% Syntax:
% OLReceptorIsolateSaveCache(cacheData, olCache, params)
%
% Input:
% cacheData (struct) - Cache struct as produced by OLReceptorIsolateFindIsolatingPrimarySettings
% olCache (class) - Cache class
% params (struct) - Params struct as produced by OLReceptorIsolatePrepareCOnfig
%
% See also:
%   OLReceptorIsolateFindIsolatingPrimarySettings, OLReceptorIsolatePrepareConfig
%
% 4/19/13   dhb, ms     Update for new convention for desired contrasts in routine ReceptorIsolate.
% 2/25/14   ms          Modularized.

% Setup the directories we'll use.  We count on the
% standard relative directory structure that we always
% use in our (BrainardLab) experiments.
baseDir = fileparts(fileparts(which('OLReceptorIsolateSaveCache')));
configDir = fullfile(baseDir, 'config', 'stimuli');
cacheDir = fullfile(baseDir, 'cache', 'stimuli');

if ~isdir(cacheDir)
    mkdir(cacheDir);
end

% Create the cache file name.
[~, cacheFileName] = fileparts(params.cacheFile);

% Look to see if the cache data already exists.
cacheExists = olCache.exist(cacheFileName);

% Save the cache data.
fprintf('\n> Saving out cache file to %s...', cacheFileName);
olCache.save(cacheFileName, cacheData);
fprintf('Done.');
fprintf('\n*** COMPLETE ***\n');