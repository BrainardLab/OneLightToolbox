function OLAnalyzeCal
% OLAnalyzeCal - Analyzes OneLight calibration data.
%
% Syntax:
% OLAnalyzeCal
%
% Description:
% Analyzes a OneLight calibration.  If no calibration file or data is
% specified to the function, then the user is prompted for a calibration
% file to analyze.
%
% Input:
% cal (struct|string) - Calibration data or the name of the calibration
%     file to load.  If empty, the calibration file is prompted for.
%
% TODO
%   Make titles of plots include cal type and date.
%
% 4/1/13  dhb  Fix plot file dir to match date calibration was run, not date analysis was run.
%              Add spectral invariance plot.
% 5/31/13 dhb  Make focus command window before subsequent plots.
% 6/2/13  dhb  Postpend date to figure names.
% 1/19/14 dhb, ms Update cal.power -> cal.gamma.
% 3/14/14 dhb  Added some gamma debugging plots, optionally.
% 9/15/15 ms   Updated savefigghost -> FigureSave.
% 4/9/16  dhb  Update for case where calibration is done around a specified
%                background.
%              Strip out omni code.
%              Have inline function returnScaleFactor return 1 if
%                cal.describe.correctForDrift is false, and then get rid of
%                all the other conditionals on this variable.
%              Fixed a figure legend that was generating a warning.

%% Close figs
close all;

%% Parameters
nBandsToPlot = 6;

% Get the calibration file
cal = OLGetCalibrationStructure;

% Backwards compatibility via OLInitCal
if (~isfield(cal.describe,'numWavelengthBands'))
    fprintf('This is an old calibration file.  Running OLInit (but not saving)\n');
    cal = OLInitCal(cal);
end
if (~isfield(cal.describe,'specifiedBackground'))
    cal = OLInitCal(cal);
end
if (cal.describe.useOmni)
    error('We do not use the omni for calibration.')
end

% Find the directory we store our calibration files.
oneLightCalSubdir = 'OneLight';
calFolderInfo = what(fullfile(CalDataFolder, oneLightCalSubdir));
calFolder = calFolderInfo.path;

%% Title and plot folder stuff
[calID calIDTitle] = OLGetCalID(cal);

% We'll store the plots under a folder with a unique timestamp.  We'll
% remap the ' ' and ':' characters to '-' and '.', respectively found
% in the date string.
originalDir = pwd;
calFileName = char(cal.describe.calType);
s = strrep(cal.describe.date, ' ', '-');
s = strrep(s, ':', '.');
plotFolder = fullfile(calFolder, 'Plots', calFileName, s);

% Make the proper subdirectory to store the plots if necessary.
if ~exist(plotFolder, 'dir')
    [status, statMessage] = mkdir(plotFolder);
    assert(status, 'OLAnalyzeCal:mkdir', statMessage);
end

%% Print out some numbers
load T_xyz1931
T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,cal.computed.pr650S);
darkXYZ = mean(T_xyz*cal.raw.darkMeas,2);
halfOnXYZ = mean(T_xyz*cal.raw.halfOnMeas,2);
fprintf('Half on luminance: %0.1f cd/m2, dark luminance: %0.1f cd/m2\n',halfOnXYZ(2),darkXYZ(2));

%% Plot sample spectral measurements
whichIndex = round(linspace(1,cal.describe.numWavelengthBands,nBandsToPlot));
figs.SingleBandMeas = figure; clf; hold on
plot(cal.computed.pr650Wls, cal.computed.pr650M(:,whichIndex)); hold on;
legend(strread(num2str(whichIndex),'%s')); legend boxoff;
pbaspect([1 1 1]); xlim([380 780]);
xlabel('Wavelength [nm]');
ylabel('Power per wavelength band');
title({calIDTitle; 'Single band measurements'});

%% Use the half on measurement to lock the scale of the PR-650 and the OmniDriver spectral measurements.
pr650HalfOnPre = cal.raw.halfOnMeas(:,1) - cal.computed.pr650MeanDark;
pr650HalfOnPost = cal.raw.halfOnMeas(:,2) - cal.computed.pr650MeanDark;
pr650HalfOnMean = mean([pr650HalfOnPre pr650HalfOnPost],2);
figs.HalfOnMeas = figure; clf; hold on
plot(cal.computed.pr650Wls,pr650HalfOnMean,'k');
plot(cal.computed.pr650Wls,pr650HalfOnPre,'-r');
plot(cal.computed.pr650Wls,pr650HalfOnPost,'-g');
legend('Half-on (mean)', 'Half-on (pre-cal)', 'Half-on (post-cal)');
xlabel('Wavelength [nm]');
ylabel('Power per wavelength band');
pbaspect([1 1 1]); xlim([380 780]);
title({calIDTitle; 'Half-on Measurements'});

%% Specified background figure, how repeatable
if (cal.describe.specifiedBackground)
    figs.specifiedBackground = figure; clf; hold on
    pr650SpecifiedBgPre = cal.raw.specifiedBackgroundMeas(:,1);
    pr650SpecifiedBgPost = cal.raw.specifiedBackgroundMeas(:,2);
    pr650SpecifiedBgMean = mean([pr650SpecifiedBgPre pr650SpecifiedBgPost],2);
    plot(cal.computed.pr650Wls,pr650SpecifiedBgMean,'k');
    plot(cal.computed.pr650Wls,pr650SpecifiedBgPre,'-r');
    plot(cal.computed.pr650Wls,pr650SpecifiedBgPost,'-g');
    legend('SpecifiedBg (mean)', 'SpecifiedBg (pre-cal)', 'SpecifiedBg (post-cal)');
    xlabel('Wavelength [nm]');
    ylabel('Power per wavelength band');
    pbaspect([1 1 1]); xlim([380 780]);
    title({calIDTitle; 'Specified Background Measurements'});
end

%% Plot full set of PR-650 calibration data
maxPow = max(cal.computed.pr650M(:));
figs.CalData = figure; clf; hold on
plot(SToWls(cal.computed.pr650S), cal.computed.pr650M);
xlabel('Wavelength [nm]');
ylabel('Power');
pbaspect([1 1 1]);
title({calIDTitle; 'Calibration Data'});
fprintf('Calibration primary column width: %d, calibration primary column step: %d, calibration columns: %d, calibration rows: %d\n',...
    cal.describe.bandWidth, cal.describe.bandWidth, size(cal.computed.pr650M,2), size(cal.computed.pr650M,1));

%% Plot the gamma data
plotColors = ['r' 'g' 'b' 'k' 'c' 'm'];
figs.DeviceGamma = figure; clf; hold on
plotColorIndex = 1;
for k = 1:length(cal.computed.gammaData1)
    plot(cal.computed.gammaInputRaw, cal.computed.gammaTableMeasuredBands(:,k),[plotColors(plotColorIndex) 'o']);
    plot(cal.computed.gammaInput, cal.computed.gammaTableMeasuredBandsFit(:,k),[plotColors(plotColorIndex)]);
    if (plotColorIndex == length(plotColors))
        plotColorIndex = 1;
    else
        plotColorIndex = plotColorIndex+1;
    end
end

% Plot the average gamma
if cal.describe.useAverageGamma
    h = plot(cal.computed.gammaInput, cal.computed.gammaTableAvg, '-k', 'LineWidth', 1.5);
    legend(h, 'Median', 'Location', 'SouthEast'); legend boxoff;
end
xlabel('Input Fraction');
ylabel('Relative Power');
pbaspect([1 1 1]); xlim([0 1]); ylim([0 1]); plot([0 1], [0 1], '--k');
title({calIDTitle; 'Device Gamma'});

%% Debugging gamma plots.
%
% These are crude but provide information unpacked by primary
% in a way that is easier to see what is happening for each
% primary than our standard summary plots.
GAMMADEBUGPLOTS = true;
if (GAMMADEBUGPLOTS)
    if (length(cal.computed.gammaData1) <= 16)
        figs.GammaDebugFig = figure; clf;
        set(gcf,'Position',[180 50 1900 1250]);
    end
    plotColorIndex = 1;
    for k = 1:length(cal.computed.gammaData1)
        
        % Individual gamma curve fit figures
        gammaFigTitle{k} = {calIDTitle; ['Gamma Band ' num2str(k)]};
        eval(sprintf('GammaFig%d = figure;',k)); clf;
        set(gcf,'Position',[180 50 1250 400]);
        subplot(1,3,1); hold on
        plot(cal.computed.gammaInputRaw, cal.computed.gammaTableMeasuredBands(:,k),[plotColors(plotColorIndex) 'o']);
        plot(cal.computed.gammaInput, cal.computed.gammaTableMeasuredBandsFit(:,k),[plotColors(plotColorIndex)]);
        title(sprintf('Gamma function for primary %d',k));
        xlabel('Normalized input');
        ylabel('Normalized output');
        axis('square');
        xlim([-0.1 1.1]);
        ylim([-0.1 1.1]);
        title(gammaFigTitle{k});
        
        % Gamma measurements unscaled
        meanDark = mean(cal.raw.darkMeas,2);
        subplot(1,3,2); hold on
        temp = cal.raw.gamma.rad(k).meas-meanDark*ones(1,size(cal.raw.gamma.rad(k).meas,2));
        maxLimVal = max(temp(:));
        plot(SToWls(cal.describe.S),temp);
        axis('square');
        ylim([-0.1*maxLimVal 1.1*maxLimVal]);
        xlabel('Wavelength'); ylabel('Power');
        title(gammaFigTitle{k});
        
        % Gamma measurements scaled
        subplot(1,3,3); hold on
        clear scaledGamma
        % cal.computed.gammaTableMeasuredBands(:,k)
        for l = 1:size(cal.raw.gamma.rad(k).meas,2)
            scaledGamma(:,l) = (cal.raw.gamma.rad(k).meas(:,l)-meanDark)/cal.computed.gammaData1{k}(l);
        end
        plot(SToWls(cal.describe.S),scaledGamma(:,1:3),'r');
        plot(SToWls(cal.describe.S),scaledGamma(:,4:end),'b');
        axis('square');
        ylim([-0.1*maxLimVal 1.1*maxLimVal]);
        xlabel('Wavelength'); ylabel('Power normalized to max meas');
        temp = gammaFigTitle{k};
        temp{end+1} = 'Lowest 3 in red';
        title(temp);
        
        % Save the individual debugging gamma plots in subdir, if they were generated
        cd(plotFolder);
        if (~exist('GammaDebugPlots','dir'))
            [status, statMessage] = mkdir('GammaDebugPlots');
            assert(status, 'OLAnalyzeCal:mkdir', statMessage);
        end
        cd('GammaDebugPlots');
        eval(sprintf('FigureSave(''GammaFig%d'',GammaFig%d,''png'');',k,k));
        eval(sprintf('close(GammaFig%d);',k));
        cd(originalDir)
        
        % Same thing onto each row of a a composite figure
        if (length(cal.computed.gammaData1) <= 16)
            figure(figs.GammaDebugFig);
            subplot(length(cal.computed.gammaData1),3,3*(k-1)+1); hold on
            plot(cal.computed.gammaInputRaw, cal.computed.gammaTableMeasuredBands(:,k),[plotColors(plotColorIndex) 'o']);
            plot(cal.computed.gammaInput, cal.computed.gammaTableMeasuredBandsFit(:,k),[plotColors(plotColorIndex)]);
            if (plotColorIndex == length(plotColors))
                plotColorIndex = 1;
            else
                plotColorIndex = plotColorIndex+1;
            end
            ylim([-0.1 1.1]);
            
            % Gamma measurements, unscaled
            subplot(length(cal.computed.gammaData1),3,3*(k-1)+2); hold on
            plot(SToWls(cal.describe.S),cal.raw.gamma.rad(k).meas-meanDark*ones(1,size(cal.raw.gamma.rad(k).meas,2)));
            xlabel('Wavelength'); ylabel('Power');
            ylim([-0.1*maxLimVal 1.1*maxLimVal]);
            
            % Gamma measurements scaled
            subplot(length(cal.computed.gammaData1),3,3*(k-1)+3); hold on
            plot(SToWls(cal.describe.S),scaledGamma);
            xlabel('Wavelength'); ylabel('Power normalized to max meas');
            ylim([-0.1*maxLimVal 1.1*maxLimVal]);
        end
    end
end

%% Plot the scaled gamma data to check for spectral invariance with light level.
figs.SpectralInvariance = figure; clf;
set(gcf,'Position',[607         518        1880         711]);
nSpectra = length(cal.raw.gamma.rad);
meanDark = mean(cal.raw.darkMeas,2);
nSkip = 3;
subplotCols = 4;
if (rem(nSpectra,subplotCols ) == 0)
    subplotRows = nSpectra/subplotCols;
else
    subplotRows = floor((nSpectra+subplotCols)/subplotCols);
end
for i = 1:nSpectra
    subplot(subplotRows,subplotCols,i); hold on
    plotColorIndex = 1;
    maxSpectrum = cal.raw.gamma.rad(i).meas(:,end)-meanDark;
    for k = nSkip:size(cal.raw.gamma.rad(i).meas,2)
        thisSpectrum = cal.raw.gamma.rad(i).meas(:,k)-meanDark;
        plot(SToWls(cal.describe.S),thisSpectrum*(max(maxSpectrum)/max(thisSpectrum)),plotColors(plotColorIndex));
        plotColorIndex = plotColorIndex+1;
        if (plotColorIndex > length(plotColors))
            plotColorIndex = 1;
        end
        xlim([380 780]);
        %YL = get(gca,'ylim'); set(gca, 'ylim',[-0.00001 YL(2)]);
    end
    xlabel('Wavelength [nm]');
    ylabel('Normalized Power');
    title(['Scaled spectra, band ' num2str(i)]);
end
suptitle([calIDTitle sprintf('\nSpectral Invariance, upper %d of %d spectra\n',size(cal.raw.gamma.rad(i).meas,2)-nSkip,size(cal.raw.gamma.rad(i).meas,2))]);

%% Plot linearity check
%
% Figure out the scalar to correct for the linear drift
if cal.describe.correctLinearDrift
    fullOn0 = cal.raw.fullOn(:,1);
    fullOn1 = cal.raw.fullOn(:,2);
    s = fullOn0 \ fullOn1;
    t0 = cal.raw.t.fullOn(1);
    t1 = cal.raw.t.fullOn(2);
    returnScaleFactor = @(t) 1./((1-(1-s)*((t-t0)./(t1-t0))));
else
    returnScaleFactor = @(t) 1;
end

figs.AdditivityCheck = figure; clf; hold on;
nIndMeas = size(cal.raw.independence.meas,2);
pred = 0;
if (cal.describe.specifiedBackground)
    for i = 1:nIndMeas
        pred = pred + cal.raw.independence.meas(:,i)*returnScaleFactor(cal.raw.t.independence.meas(i))-cal.computed.pr650MeanSpecifiedBackground;
    end
    actual = cal.raw.independence.measAll*returnScaleFactor(cal.raw.t.independence.measAll)-cal.computed.pr650MeanSpecifiedBackground;
else
    for i = 1:nIndMeas
        pred = pred + cal.raw.independence.meas(:,i)*returnScaleFactor(cal.raw.t.independence.meas(i))-cal.computed.pr650MeanDark;
    end
    actual = cal.raw.independence.measAll*returnScaleFactor(cal.raw.t.independence.measAll)-cal.computed.pr650MeanDark;
end
plot(cal.computed.pr650Wls, pred, 'r');
plot(cal.computed.pr650Wls, actual, 'g');
legend('Predicted', 'Actual'); legend boxoff;
xlim([380 780]);
YL = get(gca,'ylim'); set(gca, 'ylim',[-0.00001 YL(2)]);
xlabel('Wavelength [nm]');
ylabel('Power');
pbaspect([1 1 1]);
title({calIDTitle; 'Additivity check' });

%% Plot ambient before an after, along with mean.
figs.DarkLight = figure; clf; hold on;
plot(cal.computed.pr650Wls, cal.computed.pr650MeanDark,'k','LineWidth',3);
plot(cal.computed.pr650Wls, cal.raw.darkMeas(:,1), 'g','LineWidth',3);
plot(cal.computed.pr650Wls, cal.raw.darkMeas(:,2), 'r','LineWidth',3);
plot(cal.computed.pr650Wls, cal.raw.darkMeas(:,1), 'b','LineWidth',1);
plot(cal.computed.pr650Wls, cal.raw.darkMeas(:,2), 'c','LineWidth',1);
legend('Mean', 'First', 'Second', 'First Check', 'Second Check','Location','NorthWest'); legend boxoff;
xlim([380 780]);
YL = get(gca,'ylim'); set(gca, 'ylim',[-0.00001 YL(2)]);
xlabel('Wavelength [nm]');
ylabel('Power');
pbaspect([1 1 1]);
title({calIDTitle; 'Dark Light' })

%% Look at FWHM of the effective primaries
% Get wls
PLOTvPRIMARIES = true;
wls = SToWls(cal.computed.pr650S);
for i = 1:cal.describe.numWavelengthBands
    [~, j] = max(cal.computed.pr650M(:, i));
    wlBandMax(i) = wls(j);
    wlBandFWHM(i) = fwhm(wls, cal.computed.pr650M(:, i), 0);
end

figs.FWHMs = figure; clf; hold on;
if (PLOTvPRIMARIES)
    xVals = 1:cal.describe.numWavelengthBands;
else
    xVals = wlBandMax;
end
for i = 1:cal.describe.numWavelengthBands
    plot([xVals(i) xVals(i)], [0 wlBandFWHM(i)], '-k'); hold on;
    plot(xVals(i), wlBandFWHM(i), 'ok', 'MarkerFaceColor', 'k');
end

% Plot the mean
if (PLOTvPRIMARIES)
    plot([1 cal.describe.numWavelengthBands], [nanmean(wlBandFWHM) nanmean(wlBandFWHM)], '--r');
    xlim([1 cal.describe.numWavelengthBands]);
    xlabel('Primary number');
    title({calIDTitle; 'FWHM of primaries versus primary number'});
else
    plot([380 780], [nanmean(wlBandFWHM) nanmean(wlBandFWHM)], '--r');
    xlim([380 780]);
    xlabel('Peak wavelength [nm]');
    title({calIDTitle; 'FWHM of primaries versus primary peak wavelength'});
end
pbaspect([1 1 1]);
ylabel('FWHM [nm]');
fprintf('FWHM: mean %.2f, min %.2f, max %.2f\n',nanmean(wlBandFWHM), min(wlBandFWHM), max(wlBandFWHM));

%% Plot the cuts of the gamma function
figs.GammaCuts = figure;
% subplot(1, 2, 1);
% theCuts = linspace(0, 1, 9);
% theColors = copper(9);
% for i = 2:length(theCuts)-1
%     plot(SettingsToPrimary(cal.computed, theCuts(i)*ones(cal.describe.numWavelengthBands, 1)), 'Marker', '.', 'Color', theColors(i, :)); hold on;
% end
% xlabel('Primary band'); ylabel('Output');
% xlim([0 cal.describe.numWavelengthBands]);
% title('Primary # vs. primary intensity for output level');
% pbaspect([1 1 1]);
%subplot(1, 2, 2);
if (PLOTvPRIMARIES)
    xVals = 1:cal.describe.numWavelengthBands;
else
    xVals = wlBandMax;
end

% Two loops so legend comes out nicely.
theCuts = linspace(0, 1, 9);
theColors = copper(9);
for i = 2:length(theCuts)-1
    thePrimaryVals = SettingsToPrimary(cal.computed, theCuts(i)*ones(cal.describe.numWavelengthBands, 1));
    plot(xVals, thePrimaryVals, 'Marker', '.', 'Color', theColors(i, :)); hold on;
    plot(xVals(cal.describe.gamma.gammaBands), thePrimaryVals(cal.describe.gamma.gammaBands), 'LineStyle', 'none', 'Marker', 'o', 'Color', 'k', 'MarkerFaceColor', theColors(i, :));
end
for i = 2:length(theCuts)-1
    thePrimaryVals = SettingsToPrimary(cal.computed, theCuts(i)*ones(cal.describe.numWavelengthBands, 1));
    plot(xVals(cal.describe.gamma.gammaBands), thePrimaryVals(cal.describe.gamma.gammaBands), 'LineStyle', 'none', 'Marker', 'o', 'Color', 'k', 'MarkerFaceColor', theColors(i, :));
end

legend(strread(num2str(theCuts(2:end-1)),'%s'), 'Location', 'NorthEastOutside'); legend boxoff;
if (PLOTvPRIMARIES)
    xlim([1 cal.describe.numWavelengthBands]);
    xlabel('Primary number'); ylabel('Primary intensity');
    title({calIDTitle ; 'Gamma cut versus primary number'});
else
    xlim([380 780]);
    xlabel('Peak wavelength of primary [nm]'); ylabel('Primary intensity');
    title({calIDTitle ; 'Gamma cut versus primary peak wavelength'});
end
pbaspect([1 1 1]);


%% Look at the measured half-on spectra compared to what we predict
% from the calibration file.
halfOnSpd1 = cal.raw.halfOnMeas(:, 1);
halfOnSpd2 = cal.raw.halfOnMeas(:, 2);
halfOnSettings = 0.5*ones(cal.describe.numWavelengthBands,1);
halfOnPrimaries = OLSettingsToPrimary(cal, halfOnSettings);
predictedSpd = OLPrimaryToSpd(cal, halfOnPrimaries);

figs.HalfOnCheckPredVsMeas = figure;
plot(wls, predictedSpd, '-k'); hold on;
plot(wls, halfOnSpd1, '-r');
plot(wls, halfOnSpd2, '-b');
pbaspect([1 1 1]); xlabel('Wavelength [nm]'); ylabel('Power [W/sr/m2/nm]');
box off;
set(gca, 'TickDir', 'out');
legend('Predicted half-on', 'Measured half-on [1]', 'Measured half-on [2]'); legend boxoff;
title({calIDTitle 'Half-on, comparison to calibration prediction',});

figs.HalfOnCheckDiff = figure;
plot(wls, predictedSpd-halfOnSpd1, '-r'); hold on;
plot(wls, predictedSpd-halfOnSpd2, '-b');
pbaspect([1 1 1]); xlabel('Wavelength [nm]'); ylabel('Diff power [W/sr/m2/nm]');
box off;
set(gca, 'TickDir', 'out');
legend('Diff half-on [1]', 'Diff half-on [2]'); legend boxoff;
title({calIDTitle 'Half-on, difference with calibration prediction'});

%% Look at the wiggly spectrum
wigglySpd1 = cal.raw.wigglyMeas.measSpd(:, 1);
wigglySpd2 = cal.raw.wigglyMeas.measSpd(:, 2);
wigglySettings = cal.raw.wigglyMeas.settings(:, 1);
wigglyPrimaries = OLSettingsToPrimary(cal, wigglySettings);
predictedSpd = OLPrimaryToSpd(cal, wigglyPrimaries);

figs.wigglyCheckPredVsMeas = figure;
plot(wls, predictedSpd, '-k'); hold on;
plot(wls, wigglySpd1, '-r');
plot(wls, wigglySpd2, '-b');
pbaspect([1 1 1]); xlabel('Wavelength [nm]'); ylabel('Power [W/sr/m2/nm]');
box off;
set(gca, 'TickDir', 'out');
legend('Predicted wiggly', 'Measured wiggly [1]', 'Measured wiggly [2]'); legend boxoff;
title({calIDTitle 'Half-on'});

%% Look at the diagnostic additivity/gamma tests
plot(cal.raw.diagnostics.additivity.midPrimary.flankersSep0On(1, 1).predictedSpd)

%% Look at nth and n-1th calibrations.
% This is quick and dirty.  Assumes that
% the calibration parameters match, and has
% constants put in by hand to make the plots
% pretty.
commandwindow;
CHECKCALSTABILITY = GetWithDefault('Compare with a previous calibration?',0);
if (CHECKCALSTABILITY)
    nSubs = 3;
    oneLightCal1 = cal;
    oneLightCal2 = OLGetCalibrationStructure;
    fieldName = sprintf('Compare_%s_%s_%s_with_%s_%s_%s',...
        oneLightCal1.describe.date(1:2),oneLightCal1.describe.date(4:6),oneLightCal1.describe.date(8:11), ...
        oneLightCal2.describe.date(1:2),oneLightCal2.describe.date(4:6),oneLightCal2.describe.date(8:11));
    eval(['figs.' fieldName ' = figure;']); clf;
    set(gcf,'Position',[51         609        1300         662]);
    subplot(1,nSubs,1); hold on
    plot(cal.computed.pr650Wls, oneLightCal1.raw.lightMeas(:,[2 20 40]),'r');
    plot(cal.computed.pr650Wls, oneLightCal2.raw.lightMeas(:,[2 20 40]),'b');
    axis('square');
    xlabel('Wavelength (nm)'); ylabel('Power');
    subplot(1,nSubs,2); hold on;
    plot(oneLightCal1.raw.lightMeas(:), oneLightCal2.raw.lightMeas(:),'ko','MarkerSize',2,'MarkerFaceColor','k');
    maxVal = max([oneLightCal1.raw.lightMeas(:) ; oneLightCal2.raw.lightMeas(:)]);
    plot([0 maxVal],[0 maxVal],'r');
    axis([0 maxVal 0 maxVal]);
    axis('square');
    xlabel(oneLightCal1.describe.date); ylabel(oneLightCal2.describe.date);
    title({calIDTitle ; 'PR-650'});
    
    subplot(1,nSubs,3); hold on;
    pr650HalfOnPre1 = oneLightCal1.raw.halfOnMeas(:,1) - oneLightCal1.computed.pr650MeanDark;
    pr650HalfOnPost1 = oneLightCal1.raw.halfOnMeas(:,2) - oneLightCal1.computed.pr650MeanDark;
    pr650HalfOnMean1 = mean([pr650HalfOnPre1 pr650HalfOnPost1],2);
    pr650HalfOnPre2 = oneLightCal2.raw.halfOnMeas(:,1) - oneLightCal2.computed.pr650MeanDark;
    pr650HalfOnPost2 = oneLightCal2.raw.halfOnMeas(:,2) - oneLightCal2.computed.pr650MeanDark;
    pr650HalfOnMean2 = mean([pr650HalfOnPre2 pr650HalfOnPost2],2);
    plot(cal.computed.pr650Wls,pr650HalfOnMean1,'r','LineWidth',2);
    plot(cal.computed.pr650Wls,pr650HalfOnMean2,'g','LineWidth',2);
    plot(cal.computed.pr650Wls,pr650HalfOnMean2*(pr650HalfOnMean2\pr650HalfOnMean1),'k');
    xlabel('Wavelength (nm)')
    ylabel('Power')
    title({calIDTitle ; 'Half on now (red), then (grn), scaled then to now (blk)'});
    axis('square');
    
    % Print out numeric comparisons
    dark1XYZ = mean(T_xyz*oneLightCal1.raw.darkMeas,2);
    dark2XYZ = mean(T_xyz*oneLightCal2.raw.darkMeas,2);
    halfOn1XYZ = mean(T_xyz*oneLightCal1.raw.halfOnMeas,2);
    halfOn2XYZ = mean(T_xyz*oneLightCal2.raw.halfOnMeas,2);
    fprintf('Half on luminance: %0.1f cd/m2 (now) %0.1f cd/m2 (then), dark luminance: %0.2f cd/m2 (now) %0.2f cd/m2 (then)\n',halfOn1XYZ(2),halfOn2XYZ(2),dark1XYZ(2),dark2XYZ(2));
end

% Ask if the user would like to save the figures.
commandwindow;
if GetWithDefault('Save the figures?', 1)
    % For whatever reason, FigureSave wants us to cd to the directory we'll
    % save to.  When we're done, we'll cd back.
    cd(plotFolder);
    
    % All the figure handles are stored in the 'figs' struct.  Each field
    % represents a figure we want to save, with the field name being the
    % name of the saved plot.
    %
    % We postpend the date to all fields except the Compare, which already
    % has the two dates in the field name.
    %
    % I'm not sure why FigureSave generates a warning with the date string in
    % the filename, but after screwing around for a while I just supressed
    % and then reset the relevant warning.  It seems to produce the right
    % files.
    fnames = fieldnames(figs);
    warnState = warning('off','pax:FigureSave:inputError');
    for i = 1:length(fnames)
        if (~strncmp(fnames{i},'Compare',7))
            figName = [fnames{i} '_' calID];
        else
            figName = fnames{i};
        end
        figName = strrep(figName, ' ', '_');
        figName = strrep(figName, '-', '_');
        figName = strrep(figName, ':', '.');
        eval(['figHandle = figs.' fnames{i} ';']);
        FigureSave(figName, figHandle, 'png');
    end
    warning(warnState.state,warnState.identifier);
    
    cd(originalDir);
end
