function OLUpdateCacheFile(cachePath, valPath)
% OLUpdateCacheFile(cachePath, valPath)
%
% Function to update a cache file given a validation.
%
% 9/5/16    ms  Wrote it.
cache = load(cachePath);
val = load(valPath);

% Replace the fields. This is brute force now.
cache.BoxDRandomizedLongCableAEyePiece2_ND06_Warmup{1}.data(32).backgroundPrimary = val.cals{end}.modulationBGMeas.primaries;
cache.BoxDRandomizedLongCableAEyePiece2_ND06_Warmup{1}.data(32).differencePrimary = val.cals{end}.modulationMaxMeas.primaries-val.cals{end}.modulationBGMeas.primaries;

% Save out
save(cachePath, '-struct', 'cache');