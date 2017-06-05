function OLPlotCacheValidationResults(validationFileName, cacheFileName)
% OLPlotCacheValidationResults - Plots OneLight cache validation results.
%
% Syntax:
% OLPlotCacheValidationResults(resultsFileName)
%
% Description:
% Plots the validation data results.  Compares the validation results with
% data from a particular cache file.  The validation data must find a match
% inside the cache file or an error is thrown.  Validation data stores a
% unique cache data identifier so it's not possible for validation data to
% ever match up with the wrong cache file, barring file tampering.
%
% Input:
% validationFileName (string|struct) - The name of the validation
%     results file.  File names must be an absolute path.
% cacheFileName (string) - The name of the cache file that the the
%     validation results apply to.  The file name must be an absolute path.
%
% Example Usage:
%   OLPlotCacheValidationResults('./validation/spectra2-GlobeShortCableND.mat','./spectra2.mat')
%   OLPlotCacheValidationResults('/Users/Shared/Matlab/Experiments/OneLight/OLPupilDiameter/code/cache/validation/receptorIsolationValidation10Deg-EyeTrackerLongCable.mat', '/Users/Shared/Matlab/Experiments/OneLight/OLPupilDiameter/code/cache/receptorIsolationValidation10deg.mat')

%% Validate the number of inputs.
narginchk(2, 2, );

if ischar(validationFileName)
    % Force the file to be an absolute path instead of a relative one.  We do
    % this because files with relative paths can match anything on the path,
    % which may not be what was intended.  The regular expression looks for
    % string that begins with '/' or './'.
    m = regexp(validationFileName, '^(\.\/|\/).*', 'once');
    assert(~isempty(m), 'OLPlotCacheValidationResults:InvalidPathDef', ...
        'Validation file name must be an absolute path.');
    
    % Strip .mat off the end of the file to get the simple name.
    [validationFileDir, validationFileName] = fileparts(validationFileName);
    fullName = [fullfile(validationFileDir, validationFileName), '.mat'];
    
    % Verify the file exists.
    assert(logical(exist(fullName, 'file')), 'OLPlotCacheValidationResults:NoFileFound', ...
        'Could not find validation results file: %s', fullName);
    
    % Load the file.
    results = LoadCalFile(validationFileName, [], [validationFileDir '/']);
else
    error('Input must be a string specifying full path of validation file.');
end

%% Get rid of any other plots.
close all;

%% Make directory for plot output.  These are tagged by the validation
% time, except for early versions where that wasn't stored and we
% use cache creation date as a proxy.
plotFileDir = fullfile(validationFileDir,[validationFileName,'_Plots']);
curDir = pwd;
if (~exist(plotFileDir,'dir'))
    mkdir(plotFileDir);
end
if (isfield(results,'validationDate'))
    plotSuffix = strrep(strrep(results.validationDate, ':', '-'), ' ', '_');
else
    plotSuffix = strrep(strrep(results.cacheDate, ':', '-'), ' ', '_');
end

%% Pull out the PR-650 measurements from the validation data.  Newer data
% files have multiple power levels tested, whereas older files only have a
% max power test.  Each row of the results measurements represents a single
% power level for all stimuli.  In the typical setup, the last row is the
% max power level (1.0).
if size(results.meas, 1) > 1
    % Find which row is the biggest.  The biggest should be 1, but
    % theoretically it doesn't have to be.
    [~, maxRow] = max(results.powerLevels);
    
    measPR650 = [results.meas(maxRow,:).pr650];
else
    measPR650 = [results.meas.pr650];
end

%% Find the cache data.
cacheData = OLCache.find(cacheFileName, results.calibrationType, results.cacheDate);
assert(~isempty(cacheData), 'OLPlotCacheValidationResults:NoCacheData', ...
    'Could not find any cache data matching the validation results.\n');

%% Plot the target, predicted, and measured in one three panel plot
figure('Name', 'Cache Spectra, PR-650');
set(gca,'FontName','Helvetica','FontSize',14);
set(gcf,'Position',[800 800 1600 500]);
yaxisMax = max(max([cacheData.targetSpds cacheData.predictedSpds.pr650 measPR650.spectrum]));
subplot(1,3,1);
plot(cacheData.cal.computed.pr650Wls, cacheData.targetSpds);
title('Target');
xlabel('Wavelength (nm)');
ylabel('Power');
ylim([0 yaxisMax]);

subplot(1,3,2);
plot(cacheData.cal.computed.pr650Wls, [cacheData.predictedSpds.pr650]);
title('Predicted');
xlabel('Wavelength (nm)');
ylabel('Power');
ylim([0 yaxisMax]);

subplot(1,3,3);
plot(cacheData.cal.computed.pr650Wls, [measPR650.spectrum]);
title('Measured');
xlabel('Wavelength (nm)');
ylabel('Power');
ylim([0 yaxisMax]);
cd(plotFileDir);
savefig(['PredAndMeasSpectra_' plotSuffix '.pdf'],gcf,'pdf');
savefig(['PredAndMeasSpectra_' plotSuffix '.png'],gcf,'png');
cd(curDir);

%% Plot predicted versus target, measured versus predicted
figure; clf;
set(gca,'FontName','Helvetica','FontSize',14);
set(gcf,'Position',[800 800 800 500]);
yaxisMax = max(max([cacheData.targetSpds cacheData.predictedSpds.pr650 measPR650.spectrum]));
subplot(1,2,1); hold on

plot(cacheData.targetSpds,[cacheData.predictedSpds.pr650],'ro','MarkerSize',6,'MarkerFaceColor','r');
plot([0 yaxisMax],[0 yaxisMax],'k');
title('Pred Vs Target');
xlabel('Target');
ylabel('Predicted');
xlim([0 yaxisMax]);
ylim([0 yaxisMax]);
axis('square');

subplot(1,2,2); hold on
% If we have only validated a reduced set of settings in the data sets, do
% only plot these out
if isfield(cacheData, 'whichSettingIndexToValidate');
    plot([cacheData.predictedSpds.pr650(:,cacheData.whichSettingIndexToValidate)],[measPR650.spectrum],'ro','MarkerSize',6,'MarkerFaceColor','r');
else
    plot([cacheData.predictedSpds.pr650],[measPR650.spectrum],'ro','MarkerSize',6,'MarkerFaceColor','r');
end
plot([0 yaxisMax],[0 yaxisMax],'k');
title('Measured Vs Predicted');
xlabel('Predicted');
ylabel('Measured');
xlim([0 yaxisMax]);
ylim([0 yaxisMax]);
axis('square');

cd(plotFileDir);
savefig(['MeasVersusPredSpectra_' plotSuffix '.pdf'],gcf,'pdf');
savefig(['MeasVersusPredSpectra_' plotSuffix '.png'],gcf,'png');
cd(curDir);

%% Plot full power settings for spectra
figure; clf;
set(gcf,'Position',[850 850 600 500]);
plot(cacheData.primaries);
xlim([0 1024]);
xlabel('Mirror Number');
ylabel('Linear Mirror Fraction');
title('Target Spectra Primaries');
cd(plotFileDir);
savefig(['Settings_' plotSuffix '.pdf'],gcf,'pdf');
savefig(['Settings_' plotSuffix '.png'],gcf,'png');
cd(curDir);

%% Compute retinal irradiance for each of the cache spectra
pupilDiamMM = 3;
pupilAreaMM = pi*(pupilDiamMM/2)^2;
eyeLengthMM = 17;
fprintf('\n');
for i = 1:length(measPR650)
    irradianceWatts = RadianceToRetIrradiance(measPR650(i).spectrum,measPR650(i).S,pupilAreaMM,eyeLengthMM);
    irradianceScotTrolands = RetIrradianceToTrolands(irradianceWatts, measPR650(i).S, 'Scotopic', [], eyeLengthMM);
    irradiancePhotTrolands = RetIrradianceToTrolands(irradianceWatts, measPR650(i).S, 'Photopic', [], eyeLengthMM);
    irradianceQuanta = EnergyToQuanta(measPR650(i).S,irradianceWatts);
    irradianceWattsCm2 = 10.^8*irradianceWatts;
    irradianceQuantaCm2Sec = 10.^8*irradianceQuanta;
    fprintf('Measured spectrum %d, irradiance is %0.1f log10 watts/cm^2, %0.1f log10 quanta/[cm^2-sec], %0.1f log10 phot tds, %0.1f log10 scot tds\n', ...
        i,log10(sum(irradianceWattsCm2)),log10(sum(irradianceQuantaCm2Sec)),log10(sum(irradiancePhotTrolands)),log10(sum(irradianceScotTrolands)));
end
fprintf('\n');

% Retinal irradiance for half on/off measurements.   Just look at the first of two measurements.
irradianceWatts = RadianceToRetIrradiance(results.halfOnMeas(1).pr650.spectrum,results.halfOnMeas(1).pr650.S,pupilAreaMM,eyeLengthMM);
irradianceScotTrolands = RetIrradianceToTrolands(irradianceWatts, results.halfOnMeas(1).pr650.S, 'Scotopic', [], eyeLengthMM);
irradiancePhotTrolands = RetIrradianceToTrolands(irradianceWatts, results.halfOnMeas(1).pr650.S, 'Photopic', [], eyeLengthMM);
irradianceQuanta = EnergyToQuanta(results.halfOnMeas(1).pr650.S,irradianceWatts);
irradianceWattsCm2 = 10.^8*irradianceWatts;
irradianceQuantaCm2Sec = 10.^8*irradianceQuanta;
fprintf('Measured half on, irradiance is %0.1f log10 watts/cm^2, %0.1f log10 quanta/[cm^2-sec], %0.1f log10 phot tds, %0.1f log10 scot tds\n', ...
    log10(sum(irradianceWattsCm2)),log10(sum(irradianceQuantaCm2Sec)),log10(sum(irradiancePhotTrolands)),log10(sum(irradianceScotTrolands)));
irradianceWatts = RadianceToRetIrradiance(results.offMeas(1).pr650.spectrum,results.offMeas(1).pr650.S,pupilAreaMM,eyeLengthMM);
irradianceScotTrolands = RetIrradianceToTrolands(irradianceWatts, results.offMeas(1).pr650.S, 'Scotopic', [], eyeLengthMM);
irradiancePhotTrolands = RetIrradianceToTrolands(irradianceWatts, results.offMeas(1).pr650.S, 'Photopic', [], eyeLengthMM);
irradianceQuanta = EnergyToQuanta(results.offMeas(1).pr650.S,irradianceWatts);
irradianceWattsCm2 = 10.^8*irradianceWatts;
irradianceQuantaCm2Sec = 10.^8*irradianceQuanta;
fprintf('Measured off, irradiance is %0.1f log10 watts/cm^2, %0.1f log10 quanta/[cm^2-sec], %0.1f log10 phot tds, %0.1f log10 scot tds\n', ...
    log10(sum(irradianceWattsCm2)),log10(sum(irradianceQuantaCm2Sec)),log10(sum(irradiancePhotTrolands)),log10(sum(irradianceScotTrolands)));
fprintf('\n');

%% Check as to whether spectra are linear with overall power.  Need to be a bit careful about
% how to deal with background spectrum.  But a first order approach is to subtract the
% zero measurement from everything, scale, and add it back in.
%
% Although the code below is a little obscure, what is being compared is the full power
% validated spectrum against scaled versions of itself.  So, these plots are testing the
% linearity of the OneLight in a manner not affected by overall drift in the calibration.
for i = 1:length(results.powerLevels)
    if (results.powerLevels(i) ~= 1)
        figure; clf; hold on;
        set(gcf,'Position',[850 850 1200 500]);
        
        subplot(1,2,1); hold on
        measPR650Temp = [results.meas(i,:).pr650];
        temp1 = [measPR650.spectrum] - results.offMeas(1).pr650.spectrum*ones(1,size([measPR650.spectrum],2));
        temp2 = [measPR650Temp.spectrum] - results.offMeas(1).pr650.spectrum*ones(1,size([measPR650Temp.spectrum],2));
        plot(temp1(:),temp2(:),'ro','MarkerSize',6,'MarkerFaceColor','r');
        axis([0 yaxisMax 0 yaxisMax]); axis('square');
        xlabel('Full power measurements');
        ylabel('Reduced power measurements');
        powerFactor = temp1(:)\temp2(:);
        plot(temp1(:),powerFactor*temp1(:),'k');
        title(sprintf('Expected slope = %0.2f, measured = %0.2f\n',results.powerLevels(i),powerFactor));
        subplot(1,2,2); hold on
        plot(cacheData.cal.computed.pr650Wls, [measPR650.spectrum],'r');
        plot(cacheData.cal.computed.pr650Wls, (1/powerFactor)*temp2 + results.offMeas(1).pr650.spectrum*ones(1,size([measPR650Temp.spectrum],2)),'k');
        ylim([0 yaxisMax]); axis('square');
        xlabel('Wavelength (nm)');
        ylabel('Power');
        title('Full power (red) and scaled reduced power (blk)');
        cd(plotFileDir);
        savefig(sprintf(['ReducedPower_%d_' plotSuffix '.pdf'],round(100*results.powerLevels(i))),gcf,'pdf');
        savefig(sprintf(['ReducedPower_%d_' plotSuffix '.png'],round(100*results.powerLevels(i))),gcf,'png');
        cd(curDir);
    end
end

%% Compare state of half on measurements now to those at calibration time.
%
% Assumes that omni wavelengths are the same as at calibration time, probably
% pretty safe.
OLCal = cacheData.cal;
if (OLCal.describe.useOmni)
    nSubs = 2;
else
    nSubs = 1;
end
figure; clf;
set(gcf,'Position',[850 850 800 500]);
subplot(1,nSubs,1); hold on
plot(SToWls(results.halfOnMeas(1).pr650.S),results.halfOnMeas(1).pr650.spectrum,'r');
plot(SToWls(results.halfOnMeas(2).pr650.S),results.halfOnMeas(2).pr650.spectrum,'g:');
plot(SToWls(OLCal.computed.pr650S),OLCal.raw.halfOnMeas(:,1),'k');
plot(SToWls(OLCal.computed.pr650S),OLCal.raw.halfOnMeas(:,2),'b:');
xlabel('Wavelength (nm)');
ylabel('Power PR650');
title('Half at validation (red/green) and cal (blk/blue)');
if (OLCal.describe.useOmni)
    subplot(1,nSubs,2); hold on
    plot(OLCal.describe.omniDriver.wavelengths,results.halfOnMeas(1).omni.spectrum/results.halfOnMeas(1).omni.integrationTime,'r');
    plot(OLCal.describe.omniDriver.wavelengths,results.halfOnMeas(2).omni.spectrum/results.halfOnMeas(2).omni.integrationTime,'g:');
    plot(OLCal.describe.omniDriver.wavelengths,OLCal.raw.omniDriver.halfOnMeas(:,1)/OLCal.describe.omniDriver.integrationTime,'k');
    plot(OLCal.describe.omniDriver.wavelengths,OLCal.raw.omniDriver.halfOnMeas(:,2)/OLCal.describe.omniDriver.integrationTime,'b:');
    xlabel('Wavelength (nm)');
    ylabel('Power Omni');
    title('Half at validation (red/green) and cal (blk.blue)');
end
cd(plotFileDir);
savefig(['ValVsCalTime_' plotSuffix '.pdf'],gcf,'pdf');
savefig(['ValVsCalTime_' plotSuffix '.png'],gcf,'png');
cd(curDir);
