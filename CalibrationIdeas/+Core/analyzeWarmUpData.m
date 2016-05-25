function analyzeWarmUpData(warmUpData, warmUpRepeats, completionStatus, wavelengthAxis)

    stimPatternsNum = numel(warmUpData);
    for stimPattern = 1:stimPatternsNum
        % Check completion status
        if (strfind(completionStatus, 'Failed'))
            [~, completedRepeats] = size(warmUpData{stimPattern}.measuredSPD);
            warmUpRepeats = completedRepeats-1;
        end
        
        lastWarmUpSPD(stimPattern,:) = warmUpData{stimPattern}.measuredSPD(:, warmUpRepeats);
        firstWarmUpSPD(stimPattern,:) = warmUpData{stimPattern}.measuredSPD(:, 1);
        a = squeeze(lastWarmUpSPD(stimPattern,:));
        indices = find(a > 0.1*max(a));
        validSPDindices{stimPattern} = indices;
    end


    
    for repeatIndex = 1:warmUpRepeats
        for stimPattern = 1:stimPatternsNum
            theLastSPD = (lastWarmUpSPD(stimPattern,:))';
            theFirstSPD = (firstWarmUpSPD(stimPattern,:))';
            theSPD = squeeze(warmUpData{stimPattern}.measuredSPD(:, repeatIndex));
            
            a = theSPD(validSPDindices{stimPattern});
            b = theLastSPD(validSPDindices{stimPattern});
            scaling(stimPattern,repeatIndex) = a \ b;
            
            a = theFirstSPD(validSPDindices{stimPattern});
            fullLengthScaling = a\b;
            
            warmUpData{stimPattern}.scaledSPD(:, repeatIndex) = warmUpData{stimPattern}.measuredSPD(:, repeatIndex) * fullLengthScaling;
            
            measurementTimes(stimPattern, repeatIndex) = warmUpData{stimPattern}.measurementTime(1, repeatIndex);
%             lampCurrentBefore(stimPattern, repeatIndex)     = warmUpData{stimPattern}.oneLightStateBeforeStimOnset{repeatIndex}.LampCurrent;
%             lampCurrentAfter(stimPattern, repeatIndex)      = warmUpData{stimPattern}.oneLightStateAfterMeasurement{repeatIndex}.LampCurrent;
%             currentMonitorBefore(stimPattern, repeatIndex)  = warmUpData{stimPattern}.oneLightStateBeforeStimOnset{repeatIndex}.CurrentMonitor;
%             currentMonitorAfter(stimPattern, repeatIndex)   = warmUpData{stimPattern}.oneLightStateAfterMeasurement{repeatIndex}.CurrentMonitor;
%             voltageMonitorBefore(stimPattern, repeatIndex)  = warmUpData{stimPattern}.oneLightStateBeforeStimOnset{repeatIndex}.VoltageMonitor;
%             voltageMonitorAfter(stimPattern, repeatIndex)   = warmUpData{stimPattern}.oneLightStateAfterMeasurement{repeatIndex}.VoltageMonitor;
        end
    end

    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
                   'rowsNum', stimPatternsNum/2, ...
                   'colsNum', 3, ...
                   'heightMargin',   0.02, ...
                   'widthMargin',    0.02, ...
                   'leftMargin',     0.02, ...
                   'rightMargin',    0.001, ...
                   'bottomMargin',   0.02, ...
                   'topMargin',      0.00);
               
    hFig = figure(1); clf;
    gainSPD = 1000;
    for stimPattern = 1:stimPatternsNum
        row = floor((stimPattern-1)/2)+1;
        col = mod(stimPattern-1,2)+1;
        subplot('Position', subplotPosVectors(row,col).v);
        hold on
        meanSPD = mean(warmUpData{stimPattern}.scaledSPD,2);
        minSPD = meanSPD - min(warmUpData{stimPattern}.scaledSPD, [], 2);
        maxSPD = meanSPD - max(warmUpData{stimPattern}.scaledSPD, [], 2);
        
        stdSPD = std(warmUpData{stimPattern}.scaledSPD,0, 2);
        plot(wavelengthAxis, gainSPD * stdSPD, 'k-', 'LineWidth', 2.0);
        plot(wavelengthAxis, -gainSPD * stdSPD, 'k-', 'LineWidth', 2.0);
        hold on;
        plot(wavelengthAxis, gainSPD * minSPD, 'r-', 'LineWidth', 2.0);
        plot(wavelengthAxis, gainSPD * maxSPD, 'b-', 'LineWidth', 2.0);
        
%         for repeatIndex = 1:warmUpRepeats
%             plot(wavelengthAxis, gainSPD * squeeze(squeeze(warmUpData{stimPattern}.scaledSPD(:, repeatIndex)-meanSPD)), 'k-');
%         end
        set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)], 'YLim', [-2 2])
    end
    drawnow;

    
    hFig = figure(2); clf; 
    yRange = [min(scaling(:)) max(scaling(:))];
    stimPatternColors = jet(stimPatternsNum);
    for stimPattern = 1:stimPatternsNum
            relativeTimeAxis = (measurementTimes(stimPattern,:) - measurementTimes(stimPattern,1))/60;
            plot(relativeTimeAxis, squeeze(scaling(stimPattern,:)), '-', 'Color', squeeze(stimPatternColors(stimPattern,:)), 'LineWidth', 2.0);
            if (stimPattern == 1)
                hold on;
            end
    end
    hold off;
    set(gca, 'XLim', [0 max(measurementTimes(:)) - min(measurementTimes(:))]/60, 'YLim', yRange)
    xlabel('time (minutes)')


 
end