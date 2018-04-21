% OneLightToolboxLocalHookTemplate
%
% Template for setting preferences and other configuration things, for the
% OneLightLabToolbox.

% 6/27/17  dhb    Wrote it.

%% Clear prefs
% 
% We use these, clear before setting below.
if (ispref('OneLightToolbox'))
    rmpref('OneLightToolbox');
end

%% Clear prefs
%
% This clears old legacy code preference.
if (ispref('OneLight'))
    rmpref('OneLight');
end

%% Calibration file
setpref('OneLightToolbox','OneLightCalData',fullfile(tbLocateToolbox('OneLightToolbox'),'OLDemoCal'));

%% Set bulb logs location
[~, userID] = system('whoami');
userID = strtrim(userID);
BulbLogsDir = fullfile('/','Users',userID,'Dropbox (Aguirre-Brainard Lab)',...
    'MELA_admin','OneLight_Documentation','Tracking','Bulb tracking');
assert(exist(BulbLogsDir,'dir')==7,'OneLightToolbox:LocalHook:InvalidBulbLogsDir',...
    'Specified bulb log directory (%s) does not exist. Update local hook.',BulbLogsDir);
setpref('OneLightToolbox','BulbLogsDir',BulbLogsDir);