% OLGammaTestAnalyze.m
%
% Analyzes a gamma calibration done with the Omni.%
%
% 12/16/14      ms      Written it.

% Which box do we want to look at?
whichBox = 'BoxC';

% Save on the desktop
outDir = '~/Desktop';

% Load the cal file
cal = LoadCalFile([whichBox '_omniGammaTest']);

% Close all figures and open a few new ones;
close all;
%theFigPerGammaBand = figure;
theFigAllGammaBands = figure;

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
%     saveas(theFigPerGammaBand, fullfile(outDir, [whichBox '_' cal.describe.timeStamp '_omniGammaTest_gammaBand_' num2str(k, '%02g')]), 'png')
%     close(theFigPerGammaBand);
%     
    % All gamma bands
    figure(theFigAllGammaBands);
    plot(cal.describe.gamma.gammaLevels, cal.computed.omniGammaData1{k}, '-ok'); hold on;
end

% Save out as well
pbaspect([1 1 1]); xlim([-0.1 1.1]); ylim([-0.1 1.1]);
title({whichBox, cal.describe.timeStamp, 'All gamma bands'});
xlabel('Input fraction'); ylabel('Output fraction');
set(theFigAllGammaBands, 'PaperPosition', [0 0 5 5]);
set(theFigAllGammaBands, 'PaperSize', [5 5]);
saveas(theFigAllGammaBands, fullfile(outDir, [whichBox '_' cal.describe.timeStamp '_omniGammaTest_allGammaBands']), 'png')


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