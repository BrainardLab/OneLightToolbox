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