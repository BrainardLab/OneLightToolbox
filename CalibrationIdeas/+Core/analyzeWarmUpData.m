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

    figure(1);
    subplot(2,2,1);
    plot(measurementTimes(1,:), scaling(1,:), 'rs-');
    hold on;
    plot(measurementTimes(2,:), scaling(2,:), 'bs-');
    set(gca, 'YLim', 1 + 0.05*[-1 1]);
    hold off;
    title('SPD \\ SPD(last)')
    legend('stimPattern1', 'stimPattern2');
    
    subplot(2,2,2);
    plot(measurementTimes(1,:), 1000*diffs(1,:), 'rs-');
    hold on;
    plot(measurementTimes(2,:), 1000*diffs(2,:), 'bs-');
    set(gca, 'YLim', 1.0 + 1.0*[-1 1]);
    ylabel('diff SPD (mWatts)');
    hold off;
    title('max(abs(SPD - SPD(last)))')
    legend('stimPattern1', 'stimPattern2');
    
    
    subplot(2,2,3);
    plot(measurementTimes, lampCurrentBefore, 'gs');
    hold on;
    plot(measurementTimes, lampCurrentAfter, 'ms');
    hold off;
    title('lamp current')
    legend('lamp current before stimonset', 'lamp current after measurement');
    
    subplot(2,2,4);
    plot(measurementTimes, currentMonitorBefore, 'gs');
    hold on;
    plot(measurementTimes, currentMonitorAfter,  'ms');
    plot(measurementTimes, voltageMonitorBefore, 'gs');
    plot(measurementTimes, voltageMonitorAfter,  'ms');
    hold off;
    title('current and voltage monitors')
    legend('current before stimonset', 'current after measurement', 'voltage before stimonset', 'voltage after measurement');
end