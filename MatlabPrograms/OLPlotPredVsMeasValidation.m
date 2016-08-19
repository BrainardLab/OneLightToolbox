function OLPlotPredVsMeasValidation(file);
load(file);

wls = SToWls(cals{end}.describe.S);
bgSpdPred = cals{end}.modulationBGMeas.predictedSpd;
bgSpdMeas = cals{end}.modulationBGMeas.meas.pr650.spectrum;
bgFig = figure;
plot(wls, bgSpdPred, '-k'); hold on;
plot(wls, bgSpdMeas, '-r');
xlabel('Wavelength [nm]'); ylabel('Power'); pbaspect([1 1 1]); set(gca, 'TickDir', 'out');
set(bgFig, 'PaperPosition', [0 0 4 4]);
set(bgFig, 'PaperSize', [4 4]);
title('Background');
saveas(bgFig, '~/Desktop/bg.png', 'png');

modSpdPred = cals{end}.modulationMaxMeas.predictedSpd;
modSpdMeas = cals{end}.modulationMaxMeas.meas.pr650.spectrum;
modFig = figure;
plot(wls, modSpdPred, '-k'); hold on;
plot(wls, modSpdMeas, '-r');
xlabel('Wavelength [nm]'); ylabel('Power'); pbaspect([1 1 1]); set(gca, 'TickDir', 'out');
set(modFig, 'PaperPosition', [0 0 4 4]);
set(modFig, 'PaperSize', [4 4]);
title('Modulation');
saveas(modFig, '~/Desktop/mod.png', 'png');
