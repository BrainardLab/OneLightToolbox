% OLOpenAndSetHalfOn
%
% Little utility to open the OneLight, turn the mirrors half on, wait
% and then shut down.
%
% Useful for simple measurements.
%
% 6/13/13  dhb  Wrote it.

% Clear
clear; close all;

% Open OneLight
ol = OneLight;

% Set mirrors half on
starts = zeros(1, ol.NumCols);
stops = round(ones(1, ol.NumCols) * (ol .NumRows - 1) * 0.5);
ol.setMirrors(starts, stops); 

% Wait
fprintf('OneLight mirrors set to half on.\n\n');

fprintf('Hit any key to shut down OneLight.\n');
fprintf('After OneLight cools down and its fan turns off,\n');
fprintf('power it down before running ol.close (or clear all).\n');
commandwindow;
pause;

% Shut off
ol.shutdown;