function [ output_args ] = OLCheckCorrection(direction, varargin)
% Steps through correction data to help evaluate OLDirection correction
%
% Syntax:
%
% Description:
%   Detailed explanation goes here
%
% Input:
%    direction - OLDirection_unipolar object
%    receptors - 
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

% We multiply measurements by kScale to bring everything into a consistent space
initialPrimaryValues = correction.initialPrimaryValues;
targetSPD = correction.targetSPD;

SPDMeasuredAll = [];
primaryUsedAll = [];

for ii = 1:nIterationsMeasured
    % Pull out some data for convenience
    spectrumMeasuredScaled = kScale*correction.SPDMeasured(:,ii);
    primaryUsed = correction.primaryUsed(:,ii);
    nextPrimaryTruncatedLearningRate = correction.NextPrimaryTruncatedLearningRate(:,ii);
    deltaPrimaryTruncatedLearningRate  = correction.DeltaPrimaryTruncatedLearningRate(:,ii);
    if (any(nextPrimaryTruncatedLearningRate ~= primaryUsed + deltaPrimaryTruncatedLearningRate))
        error('Background Hmmm.');
    end
    nextSpectrumPredictedTruncatedLearningRate = OLPredictSpdFromDeltaPrimaries(deltaPrimaryTruncatedLearningRate,primaryUsed,spectrumMeasuredScaled,calibration);
      
    % Find delta primaries for next iter from scratch here.  This is to
    % verify that we know how we did it, so that we can then explore other
    % methods of doing so.
    if (correction.learningRateDecrease)
        learningRateThisIter = correction.learningRate*(1-(ii-1)*0.75/(correction.nIterations-1));
    else
        learningRateThisIter = correction.learningRate;
    end
    deltaPrimaryTruncatedLearningRateAgain = OLLinearDeltaPrimaries(primaryUsed,spectrumMeasuredScaled,targetSPD,learningRateThisIter,correction.smoothness,calibration);
    if (correction.iterativeSearch)
        [deltaPrimaryTruncatedLearningRateAgain,nextSpectrumPredictedTruncatedLearningRateAgain] = ...
            OLIterativeDeltaPrimaries(deltaPrimaryTruncatedLearningRateAgain,primaryUsed,spectrumMeasuredScaled,targetSPD,learningRateThisIter,calibration);
    end
    nextSpectrumPredictedTruncatedLearningRateAgain1 = OLPredictSpdFromDeltaPrimaries(deltaPrimaryTruncatedLearningRateAgain,primaryUsed,spectrumMeasuredScaled,calibration);

    % We can build up a correction matrix for predcition of delta spds from
    % delta primaries, based on what we've measured so far.
    if (ii == 1)
        initialSPD = spectrumMeasuredScaled;
    else
        SPDMeasuredAll = [SPDMeasuredAll spectrumMeasuredScaled];
        primaryUsedAll = [primaryUsedAll primaryUsed];
        spectraPredicted = calibration.computed.pr650M*primaryUsedAll+calibration.computed.pr650MeanDark(:,ones(size(primaryUsedAll,2),1));
        for kk = 1:size(SPDMeasuredAll,2)
            primariesRecovered(:,kk) = lsqnonneg(calibration.computed.pr650M,SPDMeasuredAll(:,kk)-calibration.computed.pr650MeanDark);
        end
        spectraPredictedFromRecovered = calibration.computed.pr650M*primariesRecovered+calibration.computed.pr650MeanDark(:,ones(size(primaryUsedAll,2),1));
        
%         whichPrimaries = [25,35,48];
%         theColors = ['r' 'g' 'b' 'k' 'c'];
%         figure(primaryFig); clf; hold on
%         for kk = 1:length(whichPrimaries)
%             whichColor = rem(kk,length(theColors)) + 1;
%             plot(primaryUsedAll(whichPrimaries(kk),:),primariesRecovered(whichPrimaries(kk),:),theColors(whichColor),'LineWidth',3);
%         end
%         plot([0 1],[0 1],'k:');
%         xlabel('Primaries Used'); ylabel('Primaries Recovered');
%         xlim([0 1]); ylim([-1 1]);
%         
%         figure; clf; 
%         lastFigIndex = 0;
%         for kk = 1:2
%             subplot(1,2,kk); hold on;
%             plot(SPDMeasuredAll(:,lastFigIndex+kk),'ro');
%             plot(spectraPredicted(:,lastFigIndex+kk) ,'bx');
%             plot(spectraPredictedFromRecovered(:,lastFigIndex+kk),'r');
%         end 
%         lastFigIndex = lastFigIndex + 2;
%         
%         whichPrimaries = [25,35,48];
%         theColors = ['r' 'g' 'b' 'k' 'c'];
%         figure(primaryFig); clf; hold on
%         for kk = 1:length(whichPrimaries)
%             whichColor = rem(kk,length(theColors)) + 1;
%             plot(primaryUsedAll(whichPrimaries(kk),:),primariesRecovered(whichPrimaries(kk),:),theColors(whichColor),'LineWidth',3);
%         end
%         plot([0 1],[0 1],'k:');
%         xlabel('Primaries Used'); ylabel('Primaries Recovered');
%         xlim([0 1]); ylim([-1 1]);
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
    % Black is the spectrum our little heart desires.
    % Green is what we measured.
    % Red is what our procedure thinks we'll get on the next iteration.
    subplot(3,2,1); cla; hold on;
    plot(wls,initialSPD,'r:','LineWidth',2);
    plot(wls,targetSPD,'g:','LineWidth',2);
    plot(wls,spectrumMeasuredScaled,'k','LineWidth',3);
    xlabel('Wavelength'); ylabel('SPD Power'); title(sprintf('SPD, iter %d',ii));
    legend({'Initial','Desired','Measured'},'Location','NorthWest');
    xlim([min(wls),max(wls)]);

    %% Primaries: used, initial, next
    % Black is the initial primaries we started with
    % Green is what we used to measure the spectra on this iteration.
    % Blue is the primaries we'll ask for next iteration.
    subplot(3,2,2); cla; hold on;
    stem(1:nPrimaries,initialPrimaryValues,'r:','LineWidth',1);
    stem(1:nPrimaries,primaryUsed,'k','LineWidth',2);
    stem(1:nPrimaries,nextPrimaryTruncatedLearningRate,'b:','LineWidth',1);
    xlabel('Primary Number'); ylabel('Primary Value'); title(sprintf('Primary values, iter %d',ii));
    legend({'Initial','Used','Next'},'Location','NorthEast');
    xlim([1, nPrimaries]);
    
    %% Delta SPD: measured current, predicted next
    % Green is the difference between what we want and what we measured.
    % Black is what we predicted it would be on this iteration.
    % Red is what we think it will be on the the next iteration.
    subplot(3,2,3); cla; hold on 
    plot(wls,targetSPD-spectrumMeasuredScaled,'k','LineWidth',3);
    plot(wls,targetSPD-nextSpectrumPredictedTruncatedLearningRate,'b:','LineWidth',2);
    plot(wls,targetSPD-nextSpectrumPredictedTruncatedLearningRateAgain1,'r:','LineWidth',  2);
    labels = {'Measured Current Delta','Predicted Next Delta','Predicted Other Start'};
    if (correction.iterativeSearch)
        plot(wls,targetSPD-nextSpectrumPredictedTruncatedLearningRateAgain,'k:','LineWidth',2);
    end
    if (ii > 1)
        plot(wls,DeltaPredictedLastTime,'r:','LineWidth',2);
        labels = [labels 'Predicted Current Delta'];
    else
        plot(NaN,NaN);
    end
    title('Predicted delta spectrum on next iteration');
    xlabel('Wavelength'); ylabel('Delta Spd Power'); title(sprintf('SPD Deltas, iter %d',ii));
    legend(labels,'Location','NorthWest');
    DeltaPredictedLastTime = targetSPD-nextSpectrumPredictedTruncatedLearningRate;
    ylim([-10e-3 10e-3]);
    xlim([min(wls),max(wls)]);
    
    %% Delta primaries: used next
    % Green is the difference between the primaries we will ask for on the
    % next iteration and those we just used.
    subplot(3,2,4); cla; hold on
    stem(1:nPrimaries,nextPrimaryTruncatedLearningRate-primaryUsed,'b','LineWidth',2);
    ylim([-0.5 0.5]);
    xlabel('Primary Number'); ylabel('Primary Value');
    title('Delta primary for next iteration');
    xlim([1, nPrimaries]);
    
    %% Contrast
    if ~isempty(receptors)
        subplot(3,1,3); hold on;
        
        backgroundSPD = correction.background.SPDdifferentialDesired;
        desiredContrast = SPDToReceptorContrast([backgroundSPD, targetSPD],receptors);
        measuredContrast = SPDToReceptorContrast([kScale*backgroundSPD, spectrumMeasuredScaled],receptors);
        predictedNextContrast = SPDToReceptorContrast([kScale*backgroundSPD, nextSpectrumPredictedTruncatedLearningRate],receptors);
        
        plot([ii ii+1],[measuredContrast(:,1) predictedNextContrast(:,1)]);
        
        if ii == 1
            xlim([0,nIterationsMeasured]); xticks(0:nIterationsMeasured);
            ylim([-4 4]);
            plot([0,nIterationsMeasured],[0 0],'k:');
            plot(repmat([0,nIterationsMeasured],[size(receptors,1) 1])',[desiredContrast(:,1)'; desiredContrast(:,1)'],'--');
        end
    end    
         
%     % Compute contrasts
% 
%     % NEED TO GET PHOTORECEPTORS FROM DIRECTION CACHE FILE AND/OR GENERATE THEM.  SEE
%     % OLAnalyzeDirectionCorrectedPrimaries for the basic way this looks.  THEN SHOULD
%     % BE ABLE TO PLOT CONTRASTS PRETTY EASILY.
%     %
%     % Grab cell array of photoreceptor classes.  Use what was in the direction file
%     % if it is there, otherwise standard L, M, S and Mel.
%     %
%     % This might not be the most perfect check for what is stored with the nominal direction primaries,
%     % but until it breaks we'll go with it.
%     if false %isfield(directionCacheData.directionParams,'photoreceptorClasses')
%         if (directionCacheData.data(protocolParams.observerAgeInYrs).describe.params.fieldSizeDegrees ~=  protocolParams.fieldSizeDegrees)
%             error('Field size used for direction does not match that specified in protocolPrams.');
%         end
%         if (directionCacheData.data(protocolParams.observerAgeInYrs).describe.params.pupilDiameterMm ~=  protocolParams.pupilDiameterMm)
%             error('Pupil diameter used for direction does not match that specified in protocolPrams.');
%         end
%         photoreceptorClasses = directionCacheData.data(protocolParams.observerAgeInYrs).describe.photoreceptors;
%         T_receptors = directionCacheData.data(protocolParams.observerAgeInYrs).describe.T_receptors;
%     else
%         S = [380 2 201];
%         photoreceptorClasses = {'LConeTabulatedAbsorbance'  'MConeTabulatedAbsorbance'  'SConeTabulatedAbsorbance'  'Melanopsin'};
%         T_receptors = GetHumanPhotoreceptorSS(S,photoreceptorClasses,protocolParams.fieldSizeDegrees,protocolParams.observerAgeInYrs,protocolParams.pupilDiameterMm,[],[]);
%     end
% 
%     Receptors = T_receptors*SpectrumMeasuredScaled;
%     modulationReceptors = T_receptors*modulationSpectrumMeasuredScaled;
%     contrasts(:,ii) = (modulationReceptors-Receptors) ./ Receptors;
%     
%     % Contrast figure
%     figure(contrastPlot);
%     subplot(1,2,1);
%     hold off;
%     plot(1:ii, 100*contrasts(1, 1:ii), '-sr', 'MarkerFaceColor', 'r'); hold on
%     plot(1:ii, 100*contrasts(2, 1:ii), '-sg', 'MarkerFaceColor', 'g');
%     plot(1:ii, 100*contrasts(3, 1:ii), '-sb', 'MarkerFaceColor', 'b');
%     xlabel('Iteration #'); xlim([0 nIterations+1]);
%     ylabel('LMS Contrast'); %ylim(]);
%     subplot(1,2,2);
%     hold off;
%     plot(1:ii,contrasts(4, 1:ii), '-sc', 'MarkerFaceColor', 'c'); hold on
%     xlabel('Iteration #'); xlim([0 nIterations+1]);
%     ylabel('Mel Contrast');
    
    % Force draw
    commandwindow;
    drawnow;
    pause;
    
end

end