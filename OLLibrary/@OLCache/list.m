function cacheList = list(obj)
% list - Lists the available cache files.
%
% Syntax:
% obj.list
%
% Description:
% Looks in the cache directory associated with the OLCache object and
% returns a list of available cache files.
%
% Output:
% cacheList (Mx1 struct) - Array of structs describing all cache files.
%     The results look the same as the output of the Matlab command "dir".
%     If no cache files exist, then the result is empty.

cacheList = dir(fullfile(obj.CacheDirectory, '*.mat'));
