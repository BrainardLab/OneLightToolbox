% OneLightToolboxLocalHookTemplate
%
% Template for setting preferences and other configuration things, for the
% OneLightLabToolbox.

% 6/27/17  dhb    Wrote it.

%% Clear prefs
if (ispref('OneLightToolbox'))
    rmpref('OneLightToolbox');
end

%% Clear prefs
if (ispref('OneLight'))
    rmpref('OneLight');
end

%% Calibration file
setpref('OneLightToolbox','OneLightCalData',fullfile(tbLocateToolbox('OneLightToolbox'),'OLDemoCal'));