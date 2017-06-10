function OLGammaTest
% OLGammaTest - Performs a quick gamma test.
%
% Syntax:
% OLGammaTest
%
% Description:
% Measured gamma functions for quick diagnostics.
%
% TO DO:
%   - Set integration time for each gamma band to get cleaner measurements.

global g_useIOPort;
g_useIOPort = 1;

whichBox = 'BoxC';%GetWithDefault('Which box are you calibrating?', 'BoxA');

% Open the OneLight device.
ol = OneLight;

% Open the Omni driver
od = OmniDriver;
od.Debug = true;

% Turn on some averaging and smoothing for the spectrum acquisition.
od.ScansToAverage = 10;
od.BoxcarWidth = 2;

% Make sure electrical dark correction is enabled.
od.CorrectForElectricalDark = true;

% Use only the Omni.
meterToggle = [0 1];

cal.describe.gammaFitType = 'betacdfpiecelin';
cal.describe.useAverageGamma = true;

% Gamma measurement parameters.  The measurements
% are spaced evenly across the effective primaries.
cal.describe.nGammaLevels = 24;

% Get the number of rows and columns
cal.describe.numRowMirrors = ol.NumRows;
cal.describe.numColMirrors = ol.NumCols;

% Definition of effective primaries, in terms of chip columns.
% We can skip a specified number of primaries at the beginning and end
cal.describe.bandWidth = 16;
cal.describe.nShortPrimariesSkip = 8;
cal.describe.nLongPrimariesSkip = 3;
cal.describe.nGammaFitLevels = 1024;
cal.describe.nGammaBands = 16;

cal.describe.timeStamp = datestr(now, 30);

% Randomize measurements. If this flag is set, the measurements
% will be done in random order. We do this to counter systematic device
% drift.
cal.describe.randomizeGammaLevels = 0;
cal.describe.randomizeGammaMeas = 0;
cal.describe.randomizePrimaryMeas = 1;

cal.describe.S = [380 2 201];
cal.describe.meterTypeNum = 5;
cal.describe.gammaNumberWlUseIndices = 5;
nAverage = 2;

% Calculate the start columns for each effective primary.
% These are indexed MATLAB style, 1:numCols.
cal.describe.primaryStartCols = 1 + (cal.describe.nShortPrimariesSkip*cal.describe.bandWidth:cal.describe.bandWidth:(ol.NumCols - (cal.describe.nLongPrimariesSkip+1)*cal.describe.bandWidth));
cal.describe.primaryStopCols = cal.describe.primaryStartCols + cal.describe.bandWidth-1;
cal.describe.numWavelengthBands = length(cal.describe.primaryStartCols);
nPrimaries = cal.describe.numWavelengthBands;

% Find and set the optimal integration time.  Subtract off a couple
% thousand microseconds just to give it a conservative value. This is for
% full-on.
ol.setAll(true);

% Depending on cables and light levels, the args to od.findIntegrationTime may
% need to be fussed with a little.
od.IntegrationTime = od.findIntegrationTime(100, 2, 1000);
od.IntegrationTime = round(0.95*od.IntegrationTime);
fprintf('- Using integration time of %d microseconds.\n', od.IntegrationTime);
ol.setAll(false);


%% Make a dark measurement
theSettings = 0*ones(nPrimaries,1);
[starts,stops] = OLSettingsToStartsStops(cal,theSettings);
od.IntegrationTime = round(0.95*od.findIntegrationTime(100, 2, 1000));
fprintf('- Using integration time of %d microseconds.\n', od.IntegrationTime);
cal.raw.omniDriver.integrationTime.darkMeas = od.IntegrationTime;
measTemp = OLTakeMeasurement(ol, od, starts, stops, cal.describe.S, meterToggle, cal.describe.meterTypeNum, nAverage);
cal.raw.omniDriver.darkMeas(:,1) = measTemp.omni.spectrum;

% Gamma measurements.
%
% We do this for cal.describe.nGammaBands of the bands, at
% cal.describe.nGammaLevels for each band.
cal.describe.gamma.gammaBands = round(linspace(1,cal.describe.numWavelengthBands,cal.describe.nGammaBands));
cal.describe.gamma.gammaLevels = linspace(1/cal.describe.nGammaLevels,1,cal.describe.nGammaLevels);

% Allocate some memory.
cal.raw.cols = zeros(ol.NumCols, cal.describe.numWavelengthBands);
cal.raw.gamma.cols = zeros(ol.NumCols, cal.describe.nGammaBands);

% Make gamma measurements for each band
gammaMeasIter = 1:cal.describe.nGammaBands;

for i = gammaMeasIter
    fprintf('\n*** Gamma measurements on gamma band set %d of %d ***\n\n', i, cal.describe.nGammaBands);
    
    % Store the columns used for this set.
    cal.raw.gamma.cols(:,i) = cal.raw.cols(:,cal.describe.gamma.gammaBands(i));
    
    % Allocate memory for the recorded spectra.
    cal.raw.gamma.omnidriver(i).meas = zeros(od.NumPixels, cal.describe.nGammaLevels);
    
    % Test each gamma level for this band.
    gammaLevelsIter = cal.describe.nGammaLevels:-1:1;
    
    for rowTest = gammaLevelsIter;
        fprintf('- Taking measurement %d of %d...', rowTest, cal.describe.nGammaLevels);
        % Set the starts/stops, measure, and store
        theSettings = zeros(nPrimaries,1);
        theSettings(cal.describe.gamma.gammaBands(i)) = cal.describe.gamma.gammaLevels(rowTest);
        [starts,stops] = OLSettingsToStartsStops(cal,theSettings);
        ol.setMirrors(starts, stops);
        % If we're at the max level for this primary, set the integration
        % time.
        if rowTest == max(gammaLevelsIter)
            od.IntegrationTime = round(0.95*od.findIntegrationTime());
            fprintf('- Using integration time of %d microseconds.\n', od.IntegrationTime);
            cal.raw.omniDriver.integrationTime.gamma(i) = od.IntegrationTime;
        end
        
        measTemp = OLTakeMeasurement(ol, od, starts, stops, cal.describe.S, meterToggle, cal.describe.meterTypeNum, nAverage);
        cal.raw.gamma.omnidriver(i).meas(:,rowTest) = measTemp.omni.spectrum;
        fprintf('Done\n');
    end
end

cal.computed.gammaInputRaw = [0 ; cal.describe.gamma.gammaLevels'];
%error('The omni code is way out of date and will need to be carefully thought about and updated');
for k = 1:size(cal.raw.gamma.omnidriver,2)
    omniGammaMeas{k} = cal.raw.gamma.omnidriver(k).meas;
    for i = 1:size(cal.raw.gamma.omnidriver(1).meas,2)
        cal.computed.omniGammaData1{k}(i) = omniGammaMeas{k}(:,end)\omniGammaMeas{k}(:,i); %#ok<*AGROW>
    end
end
cal.computed.omniGammaData = 0;
for k = 1:cal.describe.nGammaBands;
    cal.computed.omniGammaData = cal.computed.omniGammaData + cal.computed.omniGammaData1{k}';
    cal.computed.omniGammaData = cal.computed.omniGammaData/size(cal.raw.gamma.omnidriver,2);
    cal.computed.omniGammaInput = linspace(0,1,1024)';
    cal.computed.omniGammaTable = FitGamma(cal.computed.gammaInputRaw, [0 ; cal.computed.omniGammaData],cal.computed.omniGammaInput,6);
    cal.computed.omniGammaTable = MakeMonotonic(cal.computed.omniGammaTable);
    gammaTable(:, k) = cal.computed.omniGammaTable;
end

oneLightCalSubdir = 'OneLight';
SaveCalFile(cal, fullfile(oneLightCalSubdir,[whichBox '_omniGammaTest']));

% Close all figures and open a few new ones;
%close all;
%theFigPerGammaBand = figure;


% Analyze the gamma
cal.computed.gammaInputRaw = [0 ; cal.describe.gamma.gammaLevels'];
%error('The omni code is way out of date and will need to be carefully thought about and updated');
for k = 1:size(cal.raw.gamma.omnidriver,2)
    omniGammaMeas{k} = cal.raw.gamma.omnidriver(k).meas;
    [~, peakWlIdx] = max(omniGammaMeas{k}(:,end));
    omniGammaMeasSumMax(k) = omniGammaMeas{k}(peakWlIdx, end);
    for i = 1:size(cal.raw.gamma.omnidriver(1).meas,2)
        cal.computed.omniGammaData1{k}(i) = omniGammaMeas{k}(peakWlIdx-5:peakWlIdx+5,end)\omniGammaMeas{k}(peakWlIdx-5:peakWlIdx+5,i); %#ok<*AGROW>
        
    end
    screwyIndex(k) = cal.computed.omniGammaData1{k}(10);
    
    %     % Per gamma band
    %     figure(theFigPerGammaBand);
    %     subplot(1, 2, 1);
    %     plot(omniGammaMeas{k}); hold on;
    %     title({[whichBox ', gamma band ' num2str(k)], 'Spectral measurements', cal.describe.timeStamp});
    %     xlabel('Wavelength index'); ylabel('Power');
    %     pbaspect([1 1 1]);
    %
    %     subplot(1, 2, 2);
    %     plot(cal.describe.gamma.gammaLevels, cal.computed.omniGammaData1{k}, '-ok'); hold on;
    %     title({[whichBox ', gamma band ' num2str(k)], 'Gamma function', cal.describe.timeStamp});
    %     xlabel('Input fraction'); ylabel('Output fraction');
    %     pbaspect([1 1 1]); xlim([-0.1 1.1]); ylim([-0.1 1.1]);
    %
    %     % Save and close figure
    %     set(theFigPerGammaBand, 'PaperPosition', [0 0 8 5]);
    %     set(theFigPerGammaBand, 'PaperSize', [8 5]);
    %     %saveas(theFigPerGammaBand, fullfile(outDir, [whichBox '_' cal.describe.timeStamp '_omniGammaTest_gammaBand_' num2str(k, '%02g')]), 'png')
    %     close(theFigPerGammaBand);
    
    % All gamma bands
end
outDir = '~/Desktop';
theFigAllGammaBands = figure;
for k = 1:size(cal.raw.gamma.omnidriver,2)
    plot(cal.describe.gamma.gammaLevels, cal.computed.omniGammaData1{k}, '-ok'); hold on;
end

% Save out as well
pbaspect([1 1 1]); xlim([-0.1 1.1]); ylim([-0.1 1.1]);
title({whichBox, cal.describe.timeStamp, 'All gamma bands'});
xlabel('Input fraction'); ylabel('Output fraction');
set(theFigAllGammaBands, 'PaperPosition', [0 0 5 5]);
set(theFigAllGammaBands, 'PaperSize', [5 5]);
saveas(theFigAllGammaBands, fullfile(outDir, [whichBox '_' cal.describe.timeStamp '_omniGammaTest_allGammaBands']), 'png')

fprintf('\n*** ALL CALIBRATION DONE ***\n');


% figure;
% plot(omniGammaMeasSumMax, screwyIndex, '-ok'); %
%
% cal.computed.omniGammaData = 0;
% for k = 1:cal.describe.nGammaBands;
%     cal.computed.omniGammaData = cal.computed.omniGammaData + cal.computed.omniGammaData1{k}';
%     cal.computed.omniGammaData = cal.computed.omniGammaData/size(cal.raw.gamma.omnidriver,2);
%     cal.computed.omniGammaInput = linspace(0,1,1024)';
%     cal.computed.omniGammaTable = FitGamma(cal.computed.gammaInputRaw, [0 ; cal.computed.omniGammaData],cal.computed.omniGammaInput,6);
%     cal.computed.omniGammaTable = MakeMonotonic(cal.computed.omniGammaTable);
%     gammaTable(:, k) = cal.computed.omniGammaTable;
% end