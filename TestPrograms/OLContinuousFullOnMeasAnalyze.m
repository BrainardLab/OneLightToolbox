%% Box A
whichFile1 = 'BoxA_20151205_ContFullOn.csv';
[~, whichFileBase1] = fileparts(whichFile1);
tmp = csvread(fullfile('/Users/Shared/MATLAB/Toolboxes/PsychCalLocalData/OneLight/', whichFile1));
timeStamp = tmp(:, 1)/3600;
photopicLuminanceCdM2 = tmp(:, 2);
x = timeStamp;
y = (photopicLuminanceCdM2/mean(photopicLuminanceCdM2(1:20)))*100;
X = [ones(length(x), 1) x];
b = X\y;

%f = fit(x, y, 'exp2');
%h = plot(f, '-r', x, y, '.k'); set(h(2), 'LineWidth', 5); legend boxoff; hold on;
h1 = plot(x, y, '.r'); hold on; plot(x, X*b, '-k', 'LineWidth', 5);

%% Box D
whichFile2 = 'BoxD_20151204_ContFullOn.csv';
[~, whichFileBase2] = fileparts(whichFile2);
tmp = csvread(fullfile('/Users/Shared/MATLAB/Toolboxes/PsychCalLocalData/OneLight/', whichFile2));
timeStamp = tmp(:, 1)/3600;
photopicLuminanceCdM2 = tmp(:, 2);
x = timeStamp;
y = (photopicLuminanceCdM2/mean(photopicLuminanceCdM2(1:20)))*100;
X = [ones(length(x), 1) x];
b = X\y;

%f = fit(x, y, 'exp2');
%h = plot(f, '-r', x, y, '.k'); set(h(2), 'LineWidth', 5); legend boxoff;
h2 = plot(x, y, '.b'); hold on; plot(x, X*b, '-k', 'LineWidth', 5);

%% Box A with D bulb
whichFile3 = 'BoxA_BoxDBulb_20151206_ContFullOn.csv';
[~, whichFileBase3] = fileparts(whichFile3);
tmp = csvread(fullfile('/Users/Shared/MATLAB/Toolboxes/PsychCalLocalData/OneLight/', whichFile3));
timeStamp = tmp(:, 1)/3600;
photopicLuminanceCdM2 = tmp(:, 2);
x = timeStamp;
y = (photopicLuminanceCdM2/mean(photopicLuminanceCdM2(1:20)))*100;
X = [ones(length(x), 1) x];
b = X\y;

%f = fit(x, y, 'exp2');
%h = plot(f, '-r', x, y, '.k'); set(h(2), 'LineWidth', 5); legend boxoff;
h3 = plot(x, y, '.g'); hold on; plot(x, X*b, '-k', 'LineWidth', 5);

%% Box D with A bulb
whichFile3 = 'BoxD_BoxABulb_20151207_ContFullOn.csv';
[~, whichFileBase3] = fileparts(whichFile3);
tmp = csvread(fullfile('/Users/Shared/MATLAB/Toolboxes/PsychCalLocalData/OneLight/', whichFile3));
timeStamp = tmp(:, 1)/3600;
photopicLuminanceCdM2 = tmp(:, 2);
x = timeStamp;
y = (photopicLuminanceCdM2/mean(photopicLuminanceCdM2(1:20)))*100;
X = [ones(length(x), 1) x];
b = X\y;

%f = fit(x, y, 'exp2');
%h = plot(f, '-r', x, y, '.k'); set(h(2), 'LineWidth', 5); legend boxoff;
h4 = plot(x, y, '.m'); hold on; plot(x, X*b, '-k', 'LineWidth', 5);

xlabel('Time since start [h]');
ylabel('Photopic luminance [% from mean of 1st 20 meas.]');
xlim([0 24]); ylim([86 102]);
set(gca, 'XTick', [0 6 12 18 24]);
pbaspect([1 1 1]); set(gca, 'TickDir', 'out'); box off;
title({'Continuous full-on measurements'});


legend([h1 h2 h3 h4], 'Box A', 'Box D', 'Box A with Box D bulb', 'Box D with Box A bulb', 'Location', 'SouthWest');
legend boxoff;

set(gcf, 'PaperPosition', [0 0 5 5]);
set(gcf, 'PaperSize', [5 5]);
saveas(gcf, ['LampTest.png'], 'png');

%% Omni measurements
%% Box A
whichFile4 = 'BoxA_20151216_ContFullOn.csv';
[~, whichFileBase4] = fileparts(whichFile4);
tmp = csvread(fullfile('/Users/Shared/MATLAB/Toolboxes/PsychCalLocalData/OneLight/', whichFile4));
timeStamp = tmp(:, 1)/3600;
photopicLuminanceCdM2 = tmp(:, 2);
x = timeStamp;
y = (photopicLuminanceCdM2/mean(photopicLuminanceCdM2(1:20)))*100;
X = [ones(length(x), 1) x];
b = X\y;

%f = fit(x, y, 'exp2');
%h = plot(f, '-r', x, y, '.k'); set(h(2), 'LineWidth', 5); legend boxoff;
h5 = plot(x, y, '.g'); hold on; plot(x, X*b, '-k', 'LineWidth', 5);

legend([h1 h2 h5], 'Box A', 'Box D', 'Box A lamp adjusted', 'Location', 'SouthWest');
legend boxoff;

set(gcf, 'PaperPosition', [0 0 5 5]);
set(gcf, 'PaperSize', [5 5]);
saveas(gcf, ['LampTest.png'], 'png');


xlabel('Time since start [h]');
ylabel('Photopic luminance [% from mean of 1st 20 meas.]');
xlim([0 24]); ylim([86 102]);
set(gca, 'XTick', [0 6 12 18 24]);
pbaspect([1 1 1]); set(gca, 'TickDir', 'out'); box off;
title({'Continuous full-on measurements'});