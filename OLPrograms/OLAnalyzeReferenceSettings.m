function OLAnalyzeReferenceSettings(fileName)
% OLAnalyzeReferenceSettings(fileName)
%
% Analyze reference measurements.
%
% 2/9/14    ms   Wrote it.

% Load the file
load(fullfile(CalDataFolder, 'OneLight', fileName));
nMeasurements = length(cals);

% Extract the name and make a folder to save plots into.
[~, saveName] = fileparts(fileName);
saveDir = fullfile(CalDataFolder, 'OneLight', 'Plots', cals{end}.describe.calType.CalFileName, ['Bulb' num2str(cals{end}.describe.bulbNumber, '%03.f')]);
if ~isdir(saveDir)
   mkdir(saveDir);
end

% Standard wavelength spacing
S = [380 2 201];

%% Load CIE functions.
load T_xyz1931
T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);
figure;
for i = 1:nMeasurements
    subplot(1, 3, 1);
    plot(cals{i}.raw.darkMeas); hold on;
    subplot(1, 3, 2);
    plot(cals{i}.raw.halfOnMeas); hold on;
    subplot(1, 3, 3);
    plot(cals{i}.raw.fullOnMeas); hold on;
    fullOnMeas = cals{i}.raw.fullOnMeas;
    fullOnXYZ(:, i) = mean(T_xyz*fullOnMeas,2);
    fullOnXYZErr(:, i) = var(T_xyz*fullOnMeas, [], 2);
    fullOnXYZMax(:, i) = max(T_xyz*fullOnMeas, [], 2);
    fullOnXYZMin(:, i) = min(T_xyz*fullOnMeas, [], 2);
    fullOnLuminance(i) = fullOnXYZ(2, i);
    fullOnLuminanceErr(i) = fullOnXYZErr(2, i);
    fullOnLuminanceMax(i) = fullOnXYZMax(2, i);
    fullOnLuminanceMin(i) = fullOnXYZMin(2, i);
    halfOnMeas = cals{i}.raw.halfOnMeas;
    halfOnXYZ(:, i) = mean(T_xyz*halfOnMeas,2);
    halfOnXYZErr(:, i) = var(T_xyz*halfOnMeas, [], 2);
    halfOnXYZMax(:, i) = max(T_xyz*halfOnMeas, [], 2);
    halfOnXYZMin(:, i) = min(T_xyz*halfOnMeas, [], 2);
    halfOnLuminance(i) = halfOnXYZ(2, i);
    halfOnLuminanceErr(i) = halfOnXYZErr(2, i);
    halfOnLuminanceMax(i) = halfOnXYZMax(2, i);
    halfOnLuminanceMin(i) = halfOnXYZMin(2, i);
    darkMeas = cals{i}.raw.darkMeas;
    darkXYZ(:, i) = mean(T_xyz*darkMeas,2);
    darkXYZErr(:, i) = var(T_xyz*darkMeas, [], 2);
    darkXYZMax(:, i) = max(T_xyz*darkMeas, [], 2);
    darkXYZMin(:, i) = min(T_xyz*darkMeas, [], 2);
    darkLuminance(i) = darkXYZ(2, i);
    darkLuminanceErr(i) = darkXYZErr(2, i);
    darkLuminanceMax(i) = darkXYZMax(2, i);
    darkLuminanceMin(i) = darkXYZMin(2, i);
    time(i) = cals{i}.describe.startMeasTime;
end
%% Plot out the luminance
theLumTracking = figure;

% We'll correct the time approximately by assuming regular spaced
% measurement intervals. We'll use the median of the time differences
% between measurements for that.
timeStep = median(diff(time));
time_corrected = (0:timeStep:(nMeasurements-1)*timeStep)/3600;
extrapolationHours = max(time_corrected)*0.1;

% Dark
subplot(1, 3, 1);
boundedline((time_corrected), darkLuminance, [-(darkLuminanceMin-darkLuminance)' (darkLuminanceMax-darkLuminance)'], '-');  hold on;
plot((time_corrected), darkLuminance, 'sk', 'MarkerFaceColor', 'k', 'MarkerSize', 2);
xlim([-0.2 max((time_corrected))+extrapolationHours]);
YL = get(gca,'ylim'); set(gca, 'ylim',[0 YL(2)+0.2*YL(2)]);
xlabel('Operating time [h]');
ylabel('Photopic luminance [cd/m^2]');
title('Dark');
pbaspect([1 1 1]);

% Half on
subplot(1, 3, 2);
boundedline((time_corrected), halfOnLuminance, [-(halfOnLuminanceMin-halfOnLuminance)' (halfOnLuminanceMax-halfOnLuminance)'], '-');  hold on;
plot((time_corrected), halfOnLuminance, 'sk', 'MarkerFaceColor', 'k', 'MarkerSize', 2);
xlim([-0.2 max((time_corrected))+extrapolationHours]);
YL = get(gca,'ylim'); set(gca, 'ylim',[0 YL(2)+0.2*YL(2)]);
xlabel('Operating time [h]');
ylabel('Photopic luminance [cd/m^2]');
title('Half-on');
pbaspect([1 1 1]);

% Full on
subplot(1, 3, 3);
boundedline((time_corrected), fullOnLuminance, [-(fullOnLuminanceMin-fullOnLuminance)' (fullOnLuminanceMax-fullOnLuminance)'], '-');  hold on;
plot((time_corrected), fullOnLuminance, 'sk', 'MarkerFaceColor', 'k', 'MarkerSize', 2);
YL = get(gca,'ylim'); set(gca, 'ylim',[0 YL(2)+0.2*YL(2)]);
title('Full-on');
ylabel('Photopic luminance [cd/m^2]');
pbaspect([1 1 1]);

% Figure out best fit for exponential with two terms
ft = fittype('exp2');
cf = fit(time_corrected',fullOnLuminance',ft)
theX = linspace(0, max(time_corrected)+extrapolationHours, 1000);
theY = feval(cf, theX);
theExpFit = plot(theX, theY, '-r', 'LineWidth', 1.5);
xlim([-0.2 max((time_corrected))+extrapolationHours]);
desiredLuminance = max(fullOnLuminance)/2;
objective = @(t) cf(t) - desiredLuminance;
desiredHourExp = fzero(objective, max(fullOnLuminance));

% Figure out best fit for linear with two terms
P = polyfit(time_corrected,fullOnLuminance,1);
theY = P(2)+P(1)*theX;
theLinearFit = plot(theX, theY, 'Color', [0 0.5 0], 'LineWidth', 1.5);
desiredHourLinear = fzero(@(x)(P(2)+P(1)*x-desiredLuminance), 80);
legend([theExpFit theLinearFit], ['T_{1/2, exp}: ' num2str(desiredHourExp) 'h'], ['T_{1/2, linear}: ' num2str(desiredHourLinear) 'h']);
legend boxoff;

title('Full-on');
xlabel('Operating time [h]');

set(theLumTracking, 'PaperPosition', [0 0 10 5]); %Position plot at left hand corner with width 15 and height 6.
set(theLumTracking, 'PaperSize', [10 5]); %Set the paper to have width 15 and height 6.
saveas(theLumTracking, fullfile(saveDir, [saveName '_AllMeas.pdf']), 'pdf');

%% Only plot the full on
% Full on
theFullOnTracking = figure;
boundedline((time_corrected), fullOnLuminance, [-(fullOnLuminanceMin-fullOnLuminance)' (fullOnLuminanceMax-fullOnLuminance)'], '-');  hold on;
plot((time_corrected), fullOnLuminance, 'sk', 'MarkerFaceColor', 'k', 'MarkerSize', 2);
YL = get(gca,'ylim'); set(gca, 'ylim',[0 YL(2)+0.2*YL(2)]);
title('Full-on');
ylabel('Photopic luminance [cd/m^2]');
pbaspect([1 1 1]);

% Figure out best fit for exponential with two terms
ft = fittype('exp2');
cf = fit(time_corrected',fullOnLuminance',ft)
theX = linspace(0, max(time_corrected)+extrapolationHours, 1000);
theY = feval(cf, theX);
theExpFit = plot(theX, theY, '-r', 'LineWidth', 1);
xlim([-0.2 max((time_corrected))+extrapolationHours]);
desiredLuminance = max(fullOnLuminance)/2;
objective = @(t) cf(t) - desiredLuminance;
desiredHourExp = fzero(objective, max(fullOnLuminance));

% Figure out best fit for linear with two terms
P = polyfit(time_corrected,fullOnLuminance,1);
theY = P(2)+P(1)*theX;
theLinearFit = plot(theX, theY, 'Color', [0 0.5 0], 'LineWidth', 1);
desiredHourLinear = fzero(@(x)(P(2)+P(1)*x-desiredLuminance), 80);

% Plot out a linear curve with half life on 2000h
theIdealPrediction = plot([0 2000], [max(fullOnLuminance) max(fullOnLuminance)/2], '--k');

legend([theExpFit theLinearFit theIdealPrediction], ['T_{1/2, exp2}: ' num2str(desiredHourExp) 'h'], ['T_{1/2, linear}: ' num2str(desiredHourLinear) 'h'], ['T_{1/2, linear}: 2000h'], 'Location', 'South');
legend boxoff;


[~, calIDTitle1] = OLGetCalID(cals{1});
title({'Full-on measurements' ; calIDTitle1});
xlabel('Operating time [h]');
box on;

set(theFullOnTracking, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 15 and height 6.
set(theFullOnTracking, 'PaperSize', [5 5]); %Set the paper to have width 15 and height 6.
saveas(theFullOnTracking, fullfile(saveDir, [saveName '_FullOn.pdf']), 'pdf');



%%
theLumTrackingOneFigure = figure;
errorbar(time_corrected, darkLuminance, darkLuminanceErr, '-ok', 'MarkerFaceColor', 'k'); hold on;
errorbar(time_corrected, halfOnLuminance, halfOnLuminanceErr, '-ok', 'MarkerFaceColor', 'w');
errorbar(time_corrected, fullOnLuminance, fullOnLuminanceErr, '-^k', 'MarkerFaceColor', 'k');
legend('Dark', 'Half on', 'Full on');
xlim([-20 max(time_corrected)+20]);
xlabel('Time from first measurement [s]');
ylabel('Photopic luminance [cd/m^2]');
title('Measurements');
%% Plot out relative spectra
subplot(2, 2, 1);
plot(SToWls([380 2 201]), mean(cals{1}.raw.fullOnMeas, 2), '-k'); hold on;
plot(SToWls([380 2 201]), mean(cals{end}.raw.fullOnMeas, 2), '--k');
scalarVal = mean(cals{end}.raw.fullOnMeas, 2) \ mean(cals{1}.raw.fullOnMeas, 2);
plot(SToWls([380 2 201]), scalarVal*mean(cals{end}.raw.fullOnMeas, 2), '-r');
xlim([380 700])
xlabel('Wavelength [nm]');
ylabel('Power');
legend('First spectrum', 'Last spectrum (unscaled)', 'Last spectrum (scaled)', 'Location', 'SouthEast'); legend boxoff;
pbaspect([1 1 1]);
subplot(2, 2, 2);
plot(SToWls([380 2 201]), scalarVal*mean(cals{end}.raw.fullOnMeas, 2) - mean(cals{1}.raw.fullOnMeas, 2), '-r')
xlim([380 700])
xlabel('Wavelength [nm]');
pbaspect([1 1 1]);
ylabel('Power difference');
title('Difference spectrum');
subplot(2, 2, 3);
plot(mean(cals{1}.raw.omniDriver.fullOnMeas, 2), '-k'); hold on;
plot(mean(cals{end}.raw.omniDriver.fullOnMeas, 2), '--k');
scalarVal = mean(cals{end}.raw.omniDriver.fullOnMeas, 2) \ mean(cals{1}.raw.omniDriver.fullOnMeas, 2);
plot(scalarVal*mean(cals{end}.raw.omniDriver.fullOnMeas, 2), '-r');
%xlim([380 700])
%xlabel('Wavelength [nm]');
ylabel('Power');
legend('First spectrum', 'Last spectrum (unscaled)', 'Last spectrum (scaled)', 'Location', 'SouthEast'); legend boxoff;
pbaspect([1 1 1]);
subplot(2, 2, 4);
plot(scalarVal*mean(cals{end}.raw.omniDriver.fullOnMeas, 2) - mean(cals{1}.raw.omniDriver.fullOnMeas, 2), '-r')
%xlim([380 700])
%xlabel('Wavelength [nm]');
pbaspect([1 1 1]);
ylabel('Power difference');
title('Difference spectrum');
%savefig([saveName '_relativeSpectrumTracking.png'], gcf, 'png');