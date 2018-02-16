function fig = PlotPrimaryCorrectionIteration(correctionDebuggingData, calibration, iterationNo, varargin)
% Plots snapshot of a single iteration of primary values correction
% 
% Syntax:
%   PlotPrimaryCorrectionIteration(correctionDebuggingData, calibration, iterationNo)
%   figHandle = PlotPrimaryCorrectionIteration(...);
%
% Inputs:
%    correctionDebuggingData - output (second argout) of
%                              OLCorrectPrimaryValues. 
%    calibration             - struct containing calibration information
%                              for OneLight, used to run correction
%    iterationNo             - which iteration to plot.
%    fig                     - [OPTIONAL] figure to plot in
%                              (i.e., draw over)
%
% Outputs:
%    fig                     - handle to the created/updated figure
%
% Optional key/value pairs:
%    None.
%
% See also:
%    CheckPrimaryCorrection

% History:
%    02/15/18  jv  Wrote it, based on OLCheckPrimaryCorrection
%

%% Input validation
parser = inputParser();
parser.addRequired('correctionDebuggingData', @isstruct);
parser.addRequired('iterationNo', @isscalar);
parser.addOptional('fig',figure);
parser.parse(correctionDebuggingData, calibration, iterationNo, varargin{:});

%% 
wls = SToWls([380 2 201]);
ii = iterationNo;

nPrimaries = size(correctionDebuggingData.primaryUsedAll, 1);

kScale = correctionDebuggingData.kScale;

initialPrimaryValues = correctionDebuggingData.initialPrimaryValues;
targetSPD = correctionDebuggingData.targetSPD;
initialSPD = kScale*correctionDebuggingData.SPDMeasuredAll(:,1);
spectrumMeasuredScaled = kScale*correctionDebuggingData.SPDMeasuredAll(:,ii);
primaryUsed = correctionDebuggingData.primaryUsedAll(:,ii);
nextPrimary = correctionDebuggingData.NextPrimaryTruncatedLearningRateAll(:,ii);
deltaPrimary = correctionDebuggingData.DeltaPrimaryTruncatedLearningRateAll(:,ii);
nextPredictedSPD = OLPredictSpdFromDeltaPrimaries(deltaPrimary,primaryUsed,spectrumMeasuredScaled,calibration);
deltaPredictedSPDNextTime = targetSPD-nextPredictedSPD;

%% PLOT
% Black is the spectrum our little heart desires.
% Green is what we measured.
% Red is what our procedure thinks we'll get on the next iteration.
figure(parser.Results.fig); clf;
subplot(2,2,1); hold on
plot(wls,initialSPD,'r:','LineWidth',2);
plot(wls,targetSPD,'g:','LineWidth',2);
plot(wls,spectrumMeasuredScaled,'k','LineWidth',3);
xlabel('Wavelength'); ylabel('SPD Power'); title(sprintf('SPD, iter %d',ii));
legend({'Initial','Desired','Measured'},'Location','NorthWest');

% Black is the initial primaries we started with
% Green is what we used to measure the spectra on this iteration.
% Blue is the primaries we'll ask for next iteration.
subplot(2,2,2); hold on
stem(1:nPrimaries,initialPrimaryValues,'r:','LineWidth',2);
stem(1:nPrimaries,primaryUsed,'g','LineWidth',3);
stem(1:nPrimaries,nextPrimary,'b:','LineWidth',2);
xlabel('Primary Number'); ylabel('Primary Value'); title(sprintf('Primary values, iter %d',ii));
legend({'Initial','Used','Next'},'Location','NorthEast');

% % Green is the difference between what we want and what we measured.
% % Black is what we predicted it would be on this iteration.
% % Red is what we think it will be on the the next iteration.
% subplot(2,2,3); hold on
% plot(wls,targetSPD-SpectrumMeasuredScaled,'g','LineWidth',5);
% if (ii > 1)
%     plot(wls,DeltaPredictedLastTime,'k:','LineWidth',5);
% else
%     plot(NaN,NaN);
% end
% plot(wls,targetSPD-NextSpectrumPredictedTruncatedLearningRate,'r','LineWidth',5);
% plot(wls,targetSPD-NextSpectrumPredictedTruncatedLearningRateAgain1,'c','LineWidth',  3);
% if (correctDescribe.iterativeSearch)
%     plot(wls,targetSPD-NextSpectrumPredictedTruncatedLearningRateAgain,'k:','LineWidth',1);
% end
% title('Predicted delta spectrum on next iteration');
% xlabel('Wavelength'); ylabel('Delta Spd Power'); title(sprintf('Spd Deltas, iter %d',ii));
% legend({'Measured Current Delta','Predicted Current Delta','Predicted Next Delta','Predicted Other Start'},'Location','NorthWest');
% 
% ylim([-10e-4 10e-4]);

% Blue is the difference between the primaries we will ask for on the
% next iteration and those we just used.
subplot(2,2,4); hold on
stem(1:nPrimaries,nextPrimary-primaryUsed,'b','LineWidth',2);
ylim([-0.5 0.5]);
xlabel('Primary Number'); ylabel('Primary Value');
title('Delta primary for next iteration');

end

