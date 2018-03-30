function [ output_args ] = OLCheckCorrection(direction, varargin)
% Steps through correction data to help evaluate OLDirection correction
%
% Syntax:
%   OLCheckCorrection(direction)
%   direction.OLCheckCorrection;
%   OLCheckCorrection(direction, receptors)
%   direction.OLCheckCorrection(receptors)
%
% Description:
%    Detailed explanation goes here
%
% Input:
%    direction - OLDirection_unipolar object
%    receptors - SSTReceptor object, or T_receptors matrix, defining
%                fundamentals of the receptors to calculate contrast on
%
% Output:
%    None.
%
% Optional key/value pairs:
%    None.
%
% See also:
%    OLCorrectDirection

% History:
%    03/28/18  jv  wrote it.
%    03/30/18  jv  added RMSE plot, contrast figure

%% Input validation
parser = inputParser;
parser.addRequired('direction',@(x) isa(x,'OLDirection_unipolar'));
parser.addOptional('receptors',[],@(x) isempty(x) || isa(x,'SSTReceptor') || isnumeric(x));
parser.parse(direction, varargin{:});

receptors = parser.Results.receptors;
correction = direction.describe.correction;

%% Print some diagnostic information
kScale = correction.kScale;
fprintf('<strong>kScale                    :</strong> %0.2f\n', kScale);

nIterationsSpecified = correction.nIterations;
fprintf('<strong>nIterations specified     :</strong> %0.2f\n', nIterationsSpecified);

nIterationsMeasured = size(correction.SPDMeasured, 2);
fprintf('<strong>nIterations measured      :</strong> %0.2f\n', nIterationsMeasured);

nPrimaries = size(correction.primaryUsed, 1);
fprintf('<strong>Number of device primaries:</strong> %0.2f\n', nPrimaries);

iterativeSearch = correction.iterativeSearch;
labels = {'no','yes'};
fprintf('<strong>Iterative search          :</strong> %s\n', labels{iterativeSearch+1});

%% Clean up cal file primaries by zeroing out light we don't think is really there.
zeroItWLRangeMinus = 100;
zeroItWLRangePlus = 100;
calibration = OLZeroCalPrimariesAwayFromPeak(direction.calibration,zeroItWLRangeMinus,zeroItWLRangePlus);
wls = MakeItWls(calibration.describe.S);

%% Plot what we got
Plot = figure();
ContrastPlot = figure();

% We multiply measurements by kScale to bring everything into a consistent space
initialPrimaryValues = correction.initialPrimaryValues;
targetSPD = correction.targetSPD;

for ii = 1:nIterationsMeasured
    % Pull out some data for convenience
    spectrumMeasuredScaled = kScale*correction.SPDMeasured(:,ii);
    primaryUsed = correction.primaryUsed(:,ii);
    nextPrimaryTruncatedLearningRate = correction.NextPrimaryTruncatedLearningRate(:,ii);
    if (correction.learningRateDecrease)
        learningRateThisIter = correction.learningRate*(1-(ii-1)*0.75/(correction.nIterations-1));
    else
        learningRateThisIter = correction.learningRate;
    end
    
    if (ii == 1)
        initialSPD = spectrumMeasuredScaled;
    end
    
    % Report some things we might want to know
    nZeroPrimaries(ii) = length(find(correction.primaryUsed(:,ii) == 0));
    nOnePrimaries(ii) = length(find(correction.primaryUsed(:,ii) == 1));
    fprintf('\n<strong>Iteration %d:</strong>\n',ii);
    fprintf('\t<strong>Learning rate:</strong> %0.4f\n',learningRateThisIter);
    fprintf('\t<strong>number 0 primaries</strong>: %d<strong>, 1 primaries</strong>: %d\n',nZeroPrimaries(ii),nOnePrimaries(ii));
    fprintf('\t<strong>RMSQE:</strong>%0.4f\n',correction.RMSQE(ii));
    
    figure(Plot);
    
    %% SPD: measured, desired
    % Red is the initial measured SPD (before any correction)
    % Green is the desired SPD
    % Black is the SPD measured this iteration
    figure(Plot);
    subplot(3,2,1); cla; hold on;
    plot(wls,initialSPD,'r:','LineWidth',2);
    plot(wls,spectrumMeasuredScaled,'k','LineWidth',3);
    plot(wls,targetSPD,'g:','LineWidth',2);
    xlabel('Wavelength'); ylabel('SPD Power'); title(sprintf('SPD, iter %d',ii));
    legend({'Initial','Measured','Desired'},'Location','NorthWest');
    xlim([min(wls),max(wls)]);
    
    %% Primaries: used, initial, next
    % Red is the initial primaries we started with
    % Black is what we used to measure the spectra on this iteration.
    % Blue is the primaries we'll ask for next iteration.
    subplot(3,2,2); cla; hold on;
    stem(1:nPrimaries,initialPrimaryValues,'r:','LineWidth',1);
    stem(1:nPrimaries,primaryUsed,'k','LineWidth',2);
    stem(1:nPrimaries,nextPrimaryTruncatedLearningRate,'b:','LineWidth',1);
    xlabel('Primary Number'); ylabel('Primary Value'); title(sprintf('Primary values, iter %d',ii));
    legend({'Initial','Used','Next'},'Location','NorthEast');
    xlim([1, nPrimaries]);
    
    %% Delta SPD: measured current, predicted next
    % Black is the difference between what we want and what we measured.
    % Red is what we got last iteration.
    subplot(3,2,3); cla; hold on
    plot(wls,targetSPD-spectrumMeasuredScaled,'k','LineWidth',3);
    if (ii > 1)
        plot(wls,previousDelta,'r:','LineWidth',2);
        labels = {'Current Delta','Previous Delta'};
    else
        labels = {'Current Delta'};
    end
    title(sprintf('Delta SPD on iter %d',ii));
    xlabel('Wavelength'); ylabel('Delta SPD Power'); title(sprintf('SPD Deltas, iter %d',ii));
    legend(labels,'Location','NorthWest');
    previousDelta = targetSPD-spectrumMeasuredScaled;
    ylim([-10e-3 10e-3]);
    xlim([min(wls),max(wls)]);
    
    %% Delta primaries: used next
    % Blue is the difference between the primaries we will ask for on the
    % next iteration and those we just used.
    subplot(3,2,4); cla; hold on
    stem(1:nPrimaries,nextPrimaryTruncatedLearningRate-primaryUsed,'b','LineWidth',2);
    ylim([-0.5 0.5]);
    xlabel('Primary Number'); ylabel('Primary Value');
    title('Delta primary for next iteration');
    xlim([1, nPrimaries]);
    
    %% RMSQE
    subplot(3,1,3); cla; hold on
    plot(1:ii,correction.RMSQE(1:ii));
    title('Root mean squared error (desired SPD - measured SPD)');
    xlim([0,nIterationsMeasured]); xticks(0:nIterationsMeasured);
    
    %% Contrast over iterations
    %     if ~isempty(receptors)
    %         subplot(3,1,3); cla; hold on;
    %
    %         backgroundSPD = correction.background.SPDdifferentialDesired;
    %         desiredContrast = SPDToReceptorContrast([backgroundSPD, targetSPD],receptors);
    %         measuredContrastThisIter = SPDToReceptorContrast([kScale*backgroundSPD, spectrumMeasuredScaled],receptors);
    %         if ii == 1
    %             measuredContrast = measuredContrastThisIter;
    %         else
    %         	measuredContrast = [measuredContrast, measuredContrastThisIter(:,1)];
    %         end
    %
    %         plot(1:ii,measuredContrast(:,1:ii));
    %
    %         xlim([0,nIterationsMeasured]); xticks(0:nIterationsMeasured);
    %         ylim([-4 4]);
    %         plot([0,nIterationsMeasured],[0 0],'k:');
    %         plot(repmat([0,nIterationsMeasured],[size(receptors,1) 1])',[desiredContrast(:,1)'; desiredContrast(:,1)'],'--');
    %     end
    
    %% Contrasts in separate figure
    if ~isempty(receptors)
        % Calculate contrasts
        backgroundSPD = correction.background.SPDdifferentialDesired;
        desiredContrast = SPDToReceptorContrast([backgroundSPD, targetSPD],receptors);
        contrastActual = SPDToReceptorContrast([kScale*backgroundSPD, spectrumMeasuredScaled],receptors);
        if ii == 1
            contrastActualPrevious = zeros(numel(desiredContrast),1);
        end
        
        figure(ContrastPlot);
        for r = 1:size(desiredContrast,1)
            % subplot per receptor
            subplot(1,size(desiredContrast,1),r); cla;
            bar([desiredContrast(r,1), contrastActualPrevious(r), contrastActual(r)],'k'); hold on;
            ylim(max(abs(ylim)) * [-1.1 1.1]);
            title(sprintf('Contrast on receptor %d',r));
            xticklabels({'desired','last iter','current'});
            ylabel('contrast');
        end
        
        contrastActualPrevious = contrastActual;
    end
    
    %% Force draw
    commandwindow;
    drawnow;
    pause;
    
end

end