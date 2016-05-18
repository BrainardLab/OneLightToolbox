function analyzeWarmUpData(warmUpData, warmUpRepeats)

    for stimPattern = 1:numel(warmUpData)
        lastWarmUpSPD(stimPattern,:) = warmUpData{stimPattern}.measuredSPD(:, warmUpRepeats);
    end

    for repeatIndex = 1:warmUpRepeats
        for stimPattern = 1:numel(warmUpData)
            theLastSPD = (lastWarmUpSPD(stimPattern,:))';
            theSPD = squeeze(warmUpData{stimPattern}.measuredSPD(:, repeatIndex));
            scaling(stimPattern,repeatIndex) = theSPD \ theLastSPD;
            diffs(stimPattern,repeatIndex) = max(abs(theSPD - theLastSPD));
            measurementTimes(stimPattern, repeatIndex)      = warmUpData{stimPattern}.measurementTime(1, repeatIndex);
            lampCurrentBefore(stimPattern, repeatIndex)     = warmUpData{stimPattern}.oneLightStateBeforeStimOnset{repeatIndex}.LampCurrent;
            lampCurrentAfter(stimPattern, repeatIndex)      = warmUpData{stimPattern}.oneLightStateAfterMeasurement{repeatIndex}.LampCurrent;
            currentMonitorBefore(stimPattern, repeatIndex)  = warmUpData{stimPattern}.oneLightStateBeforeStimOnset{repeatIndex}.CurrentMonitor;
            currentMonitorAfter(stimPattern, repeatIndex)   = warmUpData{stimPattern}.oneLightStateAfterMeasurement{repeatIndex}.CurrentMonitor;
            voltageMonitorBefore(stimPattern, repeatIndex)  = warmUpData{stimPattern}.oneLightStateBeforeStimOnset{repeatIndex}.VoltageMonitor;
            voltageMonitorAfter(stimPattern, repeatIndex)   = warmUpData{stimPattern}.oneLightStateAfterMeasurement{repeatIndex}.VoltageMonitor;
        end
    end

    hFig = figure(1); clf;
    set(hFig, 'Name', 'Initial warm up data', 'Position', [100 100 1173 633]);
    
    subplot(2,2,1);
    t1 = squeeze(measurementTimes(1,:));
    t1 = t1 - t1(1);
    t2 = squeeze(measurementTimes(2,:));
    t2 = t2 - t2(1);
    plot(t1, scaling(1,:), 'rs-');
    hold on;
    plot(t2, scaling(2,:), 'bs-');
    set(gca, 'YLim', 1 + 0.05*[-1 1]);
    hold off;
    ylabel('SPD \\ SPD(last)');
    xlabel('measurement time (seconds)');
    legend('stimPattern1', 'stimPattern2');
    
    subplot(2,2,2);
    plot(t1, 1000*diffs(1,:), 'rs-');
    hold on;
    plot(t2, 1000*diffs(2,:), 'bs-');
    set(gca, 'YLim', 1.0 + 1.0*[-1 1]);
    ylabel('diff SPD (mWatts)');
    xlabel('measurement time (seconds)');
    hold off;
    title('max(abs(SPD - SPD(last)))')
    legend('stimPattern1', 'stimPattern2');
    
    
    subplot(2,2,3);
    t = measurementTimes;
    t = t - min(measurementTimes(:));
    plot(t, lampCurrentBefore, 'gs');
    hold on;
    plot(t, lampCurrentAfter, 'ms');
    hold off;
    title('lamp current')
    legend({'lamp current before stimonset', 'lamp current after measurement'});
    
    subplot(2,2,4);
    plot(t, currentMonitorBefore, 'gs');
    hold on;
    plot(t, currentMonitorAfter,  'ms');
    plot(t, voltageMonitorBefore, 'gs');
    plot(t, voltageMonitorAfter,  'ms');
    hold off;
    title('current and voltage monitors')
    legend({'current before stimonset', 'current after measurement', 'voltage before stimonset', 'voltage after measurement'});
    pause
end