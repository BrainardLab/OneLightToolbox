function OLPlotPredVsMeasValidation(file);
load(file);

% Get the wl spacing
wls = SToWls(cals{end}.describe.S);

% Get the cal
cal = cals{end}.describe.cal;

% Figure out the scale factor
fullOnCal = cal.raw.fullOn(:, 1);
fullOnNew = cals{end}.fullOnMeas.meas.pr650.spectrum;
scaleFactor = fullOnNew \ fullOnCal;

% Extract the relevants pectra
bgSpdPred = cals{end}.modulationBGMeas.predictedSpd-cal.computed.pr650MeanDark;
bgSpdMeasUnscaled = cals{end}.modulationBGMeas.meas.pr650.spectrum-cals{end}.offMeas.meas.pr650.spectrum;
modSpdPred = cals{end}.modulationMaxMeas.predictedSpd-cal.computed.pr650MeanDark;
modSpdMeasUnscaled = cals{end}.modulationMaxMeas.meas.pr650.spectrum-cals{end}.offMeas.meas.pr650.spectrum;

% Scale the spectra
modSpdMeas = scaleFactor*modSpdMeasUnscaled;
bgSpdMeas = scaleFactor*bgSpdMeasUnscaled;

% Infer primary weights
%modPrimaryInferred = cal.computed.pr650M \ modSpdMeas;
modPrimaryInferred = lsqnonneg(cal.computed.pr650M, modSpdMeas);
modPrimaryNominal = cals{end}.modulationMaxMeas.primaries;
%bgPrimaryInferred = cal.computed.pr650M \ bgSpdMeas;
bgPrimaryInferred = lsqnonneg(cal.computed.pr650M, bgSpdMeas);
bgPrimaryNominal = cals{end}.modulationBGMeas.primaries;
NPrimaries = size(cal.computed.pr650M, 2);
theGammaBands = cal.describe.gamma.gammaBands;
NGammaBands = size(cal.describe.gamma.gammaBands, 2);

% Compare the spectra
spectraCompFig = figure;

% Background spectrum
subplot(2, 3, 1);
plot(wls, bgSpdPred, '-k'); hold on;
plot(wls, bgSpdMeas, '-r');
xlabel('Wavelength [nm]'); ylabel('Power'); pbaspect([1 1 1]); set(gca, 'TickDir', 'out');
xlim([380 780]);
title('Spectra');

subplot(2, 3, 2);
plot(wls, bgSpdPred-bgSpdMeas, '-r'); hold on;
plot([380 780], [0 0], '-k');
xlabel('Wavelength [nm]'); ylabel('\DeltaPower (pred-meas)'); pbaspect([1 1 1]); set(gca, 'TickDir', 'out');
xlim([380 780]);
title('Spectral difference');

subplot(2, 3, 3);
plot(log10(bgSpdPred), log10(bgSpdMeas), '.r'); hold on;
axLim = [min(log10(bgSpdPred))-1 max(log10(bgSpdPred))+1];
xlim(axLim); ylim(axLim);
xlabel('log predicted spectrum'); ylabel('log measured spectrum'); pbaspect([1 1 1]); set(gca, 'TickDir', 'out');
plot(axLim, axLim, '-k');
title('Predicted vs. measured');

subplot(2, 3, 4);
plot(wls, modSpdPred, '-k'); hold on;
plot(wls, modSpdMeas, '-r');
xlabel('Wavelength [nm]'); ylabel('Power'); pbaspect([1 1 1]); set(gca, 'TickDir', 'out');
xlim([380 780]);

subplot(2, 3, 5);
plot(wls, modSpdPred-modSpdMeas, '-r'); hold on;
plot([380 780], [0 0], '-k');
xlabel('Wavelength [nm]'); ylabel('\DeltaPower (pred-meas)'); pbaspect([1 1 1]); set(gca, 'TickDir', 'out');
xlim([380 780]);

subplot(2, 3, 6);
plot(log10(modSpdPred), log10(modSpdMeas), '.r'); hold on;
axLim = [min(log10(modSpdPred))-1 max(log10(modSpdPred))+1];
xlim(axLim); ylim(axLim);
xlabel('log predicted spectrum'); ylabel('log measured spectrum'); pbaspect([1 1 1]); set(gca, 'TickDir', 'out');
plot(axLim, axLim, '-k');

set(spectraCompFig, 'PaperPosition', [0 0 12 6]);
set(spectraCompFig, 'PaperSize', [12 6]);
saveas(spectraCompFig, '~/Desktop/spectraComp.pdf', 'pdf');

% Figure for inferred primaries
primaryWeightsFig = figure;

subplot(2, 4, 1);
plot(1:NPrimaries, bgPrimaryNominal, '-k'); hold on;
plot(1:NPrimaries, bgPrimaryInferred, '-r');
xlim([0 NPrimaries+1]);
ylim([-0.05 1.05]);
xlabel('Primary'); ylabel('Weight');
pbaspect([1 1 1]); set(gca, 'TickDir', 'out');
title('Inferred weights');

subplot(2, 4, 2);
plot([0 NPrimaries+1], [0 0], '-k'); hold on;
plot(1:NPrimaries, bgPrimaryNominal-bgPrimaryInferred, '-or', 'MarkerFaceColor', 'r');
plot(theGammaBands, bgPrimaryNominal(theGammaBands)-bgPrimaryInferred(theGammaBands), 'sk', 'MarkerFaceColor', 'k', 'MarkerSize', 8)
xlim([0 NPrimaries+1]);
xlabel('Primary'); ylabel('\DeltaWeight (meas-inferred)');
pbaspect([1 1 1]); set(gca, 'TickDir', 'out');
title('Difference weights');

subplot(2, 4, 3);
plot(wls, bgSpdMeas, '-k'); hold on;
plot(wls, cal.computed.pr650M*bgPrimaryInferred, '-r');
xlabel('Wavelength [nm]'); ylabel('Power'); pbaspect([1 1 1]); set(gca, 'TickDir', 'out');
xlim([380 780]);
title('Spectra');

subplot(2, 4, 4);
plot(wls, bgSpdMeas-(cal.computed.pr650M*bgPrimaryInferred), '-r'); hold on;
plot([380 780], [0 0], '-k');
%plot(wls, modSpdMeasUnscaled, '--r');
xlabel('Wavelength [nm]'); ylabel('\DeltaPower (pred-meas)'); pbaspect([1 1 1]); set(gca, 'TickDir', 'out');
xlim([380 780]);
title('Spectra difference');

subplot(2, 4, 5);
plot(1:NPrimaries, modPrimaryNominal, '-k'); hold on;
plot(1:NPrimaries, modPrimaryInferred, '-r');
xlim([0 NPrimaries+1]);
ylim([-0.05 1.05]);
xlabel('Primary'); ylabel('Weight');
pbaspect([1 1 1]); set(gca, 'TickDir', 'out');

subplot(2, 4, 6);
plot([0 NPrimaries+1], [0 0], '-k'); hold on;
plot(1:NPrimaries, modPrimaryNominal-modPrimaryInferred, '-or', 'MarkerFaceColor', 'r');
plot(theGammaBands, modPrimaryNominal(theGammaBands)-modPrimaryInferred(theGammaBands), 'sk', 'MarkerFaceColor', 'k', 'MarkerSize', 8)
xlim([0 NPrimaries+1]);
xlabel('Primary'); ylabel('\DeltaWeight (meas-inferred)');
pbaspect([1 1 1]); set(gca, 'TickDir', 'out');

subplot(2, 4, 7);
plot(wls, modSpdMeas, '-k'); hold on;
plot(wls, cal.computed.pr650M*modPrimaryInferred, '-r');
xlabel('Wavelength [nm]'); ylabel('Power'); pbaspect([1 1 1]); set(gca, 'TickDir', 'out');
xlim([380 780]);

subplot(2, 4, 8);
plot(wls, modSpdMeas-(cal.computed.pr650M*modPrimaryInferred), '-r'); hold on;
plot([380 780], [0 0], '-k');
%plot(wls, modSpdMeasUnscaled, '--r');
xlabel('Wavelength [nm]'); ylabel('\DeltaPower (meas-inferred)'); pbaspect([1 1 1]); set(gca, 'TickDir', 'out');
xlim([380 780]);

set(primaryWeightsFig, 'PaperPosition', [0 0 16 6]);
set(primaryWeightsFig, 'PaperSize', [16 6]);
saveas(primaryWeightsFig, '~/Desktop/inferredWeight.pdf', 'pdf');


%
% Turn primaries into settings
bgSettingsInferred = OLPrimaryToSettings(cal, bgPrimaryInferred);
bgSettingsNominal = OLPrimaryToSettings(cal, bgPrimaryNominal);
modSettingsInferred = OLPrimaryToSettings(cal, modPrimaryInferred);
modSettingsNominal = OLPrimaryToSettings(cal, modPrimaryNominal);
axLim = [-0.01 1.01];

for ii = 1:NGammaBands
    theFig = figure;
    plot(cal.computed.gammaInput, cal.computed.gammaTableAvg, '-k'); hold on;
    plot(cal.computed.gammaInputRaw, cal.computed.gammaTableMeasuredBands(:, ii), 'ok', 'MarkerFaceColor', 'k');
    h1 = plot(bgSettingsNominal(theGammaBands(ii)), bgPrimaryNominal(theGammaBands(ii)), 'sk', 'MarkerFaceColor', 'r');
    h2 = plot(bgSettingsInferred(theGammaBands(ii)), bgPrimaryInferred(theGammaBands(ii)), 'ok', 'MarkerFaceColor', 'r');
    h3 = plot(modSettingsNominal(theGammaBands(ii)), modPrimaryNominal(theGammaBands(ii)), 'sk', 'MarkerFaceColor', 'g');
    h4 = plot(modSettingsInferred(theGammaBands(ii)), modPrimaryInferred(theGammaBands(ii)), 'ok', 'MarkerFaceColor', 'g');
    title(['Primary ' num2str(theGammaBands(ii))]);
    xlim(axLim); ylim(axLim);
    xlabel('Input (settings)');
    ylabel('Output (primary)');
    legend([h1 h2 h3 h4], 'BG_{Nominal}', 'BG_{Inferred}', 'Mod_{Nominal}', 'Mod_{Inferred}', 'Location', 'NorthWest'); legend boxoff;
    pbaspect([1 1 1]);
    box off;
    set(gca, 'TickDir', 'out');
    set(theFig, 'PaperPosition', [0 0 4 4]);
    set(theFig, 'PaperSize', [4 4]);
    saveas(theFig, ['~/Desktop/gamma' num2str(theGammaBands(ii), '%02.f') '.png'], 'png');
    close(theFig);
end
close all;