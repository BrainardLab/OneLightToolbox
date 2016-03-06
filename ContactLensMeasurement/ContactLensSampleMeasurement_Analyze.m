% NOTE: In transmittance_sample_ContactLensMaterial_0_5mm_12-Jan-2016.mat,
% the measWithoutSample and measWithSample are actually switched.
fileName = 'transmittance_sample_ContactLensMaterial_0_5mm_12-Jan-2016.mat';
[~, id] = fileparts(fileName);
load(fullfile(CalDataFolder, 'OneLight', 'xContactLenses', fileName));
wls = SToWls(cal.measWithSample.pr650.S);

subplot(1, 2, 1);
h1 = plot(wls, cal.measWithoutSample.pr650.spectrum, '-k', 'LineWidth', 1.5);
hold on;
h2 = plot(wls, cal.measWithSample.pr650.spectrum, '-b', 'LineWidth', 1.5);
pbaspect([1 1 1]); set(gca, 'TickDir', 'out'); box off;
xlim([350 800]);
legend([h1 h2], 'w/ sample', 'w/o sample', 'Location', 'NorthWest'); legend boxoff;
xlabel('Wavelength [nm]');
ylabel('Spectral power');
title('Spectral measurements');

subplot(1, 2, 2);
h1 = plot(wls, smooth(cal.measWithoutSample.pr650.spectrum ./ cal.measWithSample.pr650.spectrum, 5), '-k', 'LineWidth', 2); hold on
h2 = plot(wls, cal.measWithoutSample.pr650.spectrum ./ cal.measWithSample.pr650.spectrum, '-r', 'LineWidth', 1); hold on
pbaspect([1 1 1]); set(gca, 'TickDir', 'out'); box off;
xlim([350 800]); ylim([0.85 1]);
legend([h2 h1], 'Raw', 'Smoothed', 'Location', 'NorthWest'); legend boxoff;
xlabel('Wavelength [nm]');
ylabel('Transmittance [%]');
title('Transmittance');

set(gcf, 'PaperPosition', [0 0 8 4]);
set(gcf, 'PaperSize', [8 4]);
saveas(gcf, fullfile(CalDataFolder, 'OneLight', 'xContactLenses', [id '.pdf']), 'pdf');


% Save out the data from the contact lenses into a filter structure
unattenSpd  = cal.measWithSample.pr650.spectrum;
attenSpd = cal.measWithoutSample.pr650.spectrum;
S_filter_ContactLens_0_5mm  = cal.measWithSample.pr650.S;
srf_filter_ContactLens_0_5mm = smooth(cal.measWithoutSample.pr650.spectrum ./ cal.measWithSample.pr650.spectrum, 5);
outFileName = 'srf_filter_ContactLens_0_5mm_011216.mat';
save(fullfile('/Users/Shared/MATLAB/Toolboxes/PsychCalLocalData/OneLight/xNDFilters/', outFileName), 'unattenSpd', 'attenSpd', 'S_filter_ContactLens_0_5mm', 'srf_filter_ContactLens_0_5mm');