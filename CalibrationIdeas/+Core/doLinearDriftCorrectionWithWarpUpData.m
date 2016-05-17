function [data, allTimes] = doLinearDriftCorrectionWithWarpUpData(warmUpData, warmUpRepeats, uncorrectedData, nRepeats)
    
    data = uncorrectedData;
    nSpectraMeasured = numel(data);
    allTimes = zeros(nRepeats*nSpectraMeasured,1);
    
    k = 0;
    for spectrumIter = 1:nSpectraMeasured
        spdType = data{spectrumIter}.spdType;
        for repeatIndex = 1:nRepeats
            k = k + 1;
            allTimes(k) = data{spectrumIter}.measurementTime(1, repeatIndex);
        end
        switch(spdType)
            case 'temporalStabilityGauge1SPD'
                temporalStabilityGauge1SPDs = data{spectrumIter}.measuredSPD;
                temporalStabilityGauge1Times = data{spectrumIter}.measurementTime;
                
            case 'temporalStabilityGauge2SPD'
                temporalStabilityGauge2SPDs = data{spectrumIter}.measuredSPD;
                temporalStabilityGauge2Times = data{spectrumIter}.measurementTime;
            otherwise
                ; % do nothing
        end
    end
    
    lastTemporalStabilityGauge1SPD = (temporalStabilityGauge1SPDs(:,nRepeats));
    lastTemporalStabilityGauge2SPD = (temporalStabilityGauge2SPDs(:,nRepeats));
    
    lastTemporalStabilityGauge1MeasTime = temporalStabilityGauge1Times(nRepeats);
    lastTemporalStabilityGauge2MeasTime = temporalStabilityGauge2Times(nRepeats);
    
    
    % find the scaling factor based on points that are > 5% of the peak SPD
    indices1 = find(lastTemporalStabilityGauge1SPD > max(lastTemporalStabilityGauge1SPD)*0.1);
    indices2 = find(lastTemporalStabilityGauge2SPD > max(lastTemporalStabilityGauge2SPD)*0.1);
    
    
    for repeatIndex = 1:nRepeats
        scaling(1,repeatIndex) = squeeze(temporalStabilityGauge1SPDs(indices1, repeatIndex)) \ lastTemporalStabilityGauge1SPD(indices1);
        scaling(2,repeatIndex) = squeeze(temporalStabilityGauge2SPDs(indices2, repeatIndex)) \ lastTemporalStabilityGauge2SPD(indices2);
    end

    
    repeatIndex = 1;
    dt1 = lastTemporalStabilityGauge1MeasTime-temporalStabilityGauge1Times(repeatIndex);
    dt2 = lastTemporalStabilityGauge2MeasTime-temporalStabilityGauge2Times(repeatIndex);
    scalingFactor1 = @(t) 1./((1-(1-scaling(1,repeatIndex))*((t-temporalStabilityGauge1Times(repeatIndex))./dt1)));
    scalingFactor2 = @(t) 1./((1-(1-scaling(2,repeatIndex))*((t-temporalStabilityGauge2Times(repeatIndex))./dt2)));
    
    % Do the spectrum scaling correction
    
    for spectrumIter = 1:nSpectraMeasured
        for repeatIndex = 1:nRepeats
            timeOfMeasurement = squeeze(data{spectrumIter}.measurementTime(1, repeatIndex));
            s1 = scalingFactor1(timeOfMeasurement);
            s2 = scalingFactor1(timeOfMeasurement);
            scalingFactor = (s1+s2)/2.0;
            data{spectrumIter}.measuredSPD(:, repeatIndex) = scalingFactor * data{spectrumIter}.measuredSPD(:, repeatIndex);
            fprintf('Scaling spectrum %d (repeat: %d) by %2.4f\n', spectrumIter, repeatIndex, scalingFactor);
        end
    end
    
    
    figure(2);
    clf;
    tt = temporalStabilityGauge1Times; % [min(allTimes) max(allTimes)];
    plot(tt/(60*60), scalingFactor1(tt), 'r--');
    hold on;
    tt = temporalStabilityGauge2Times;
    plot(tt/(60*60), scalingFactor2(tt), 'b--');
    tt = [min(allTimes) max(allTimes)];
    plot(tt/(60*60), 0.5*(scalingFactor1(tt)+scalingFactor2(tt)), 'k--');
    
    hold off;
    set(gca, 'YLim', 1 + 0.05*[-1 1], 'XLim', [min(allTimes) max(allTimes)]/(60*60));
    xlabel('time (hours)');
    title('SPD \\ SPD(last)')
    legend({'scaling factor based on temporalStabilityGaugePattern1', 'scaling factor based on temporalStabilityGaugePattern1', 'average'});
    
end