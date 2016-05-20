function [data, allTimes] = doLinearDriftCorrectionUsingMultipleMeasurements(uncorrectedData, nRepeats)
    
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
    
    for spectrumIter = 1:nSpectraMeasured
        for repeatIndex = 1:nRepeats
            measurementTimes((spectrumIter-1)*nRepeats+repeatIndex) = squeeze(data{spectrumIter}.measurementTime(1, repeatIndex));
        end
    end
    
    [pieceWiseLinearScalings1, pieceWiseLinearScalings2] = piecewiseLinearScalingFactor(temporalStabilityGauge1Times, temporalStabilityGauge1SPDs, temporalStabilityGauge2Times, temporalStabilityGauge2SPDs, measurementTimes);
    
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
            k = (spectrumIter-1)*nRepeats+repeatIndex;
            allTimes(k) = timeOfMeasurement;
            s1(k) = scalingFactor1(timeOfMeasurement);
            s2(k) = scalingFactor2(timeOfMeasurement);
            s3(k) = pieceWiseLinearScalings1(k);
            s4(k) = pieceWiseLinearScalings2(k);
            scalingFactor = s3(k); % 1.0; % s3(k);
            data{spectrumIter}.measuredSPD(:, repeatIndex) = scalingFactor * data{spectrumIter}.measuredSPD(:, repeatIndex);
            fprintf('Scaling spectrum %d (repeat: %d) by %2.4f\n', spectrumIter, repeatIndex, scalingFactor);
        end
    end
    
    figure(100)
    subplot(1,2,2);
    hold on;
    t = (allTimes-min(allTimes))/(60*60);
    plot(t, s1/s1(end), 'r.');
    plot(t, s2/s2(end), 'b.');
    plot(t, s3/s3(end), 'k.');
    plot(t, s4/s4(end), 'k.');
    xlabel('time (hours)');
end

function [pieceWiseScalings1, pieceWiseScalings2] = piecewiseLinearScalingFactor(times1, SPD1s, times2, SPD2s, measurementTimes)

    nRepeats = size(SPD1s,2);
    lastSPD1 = squeeze(SPD1s(:,nRepeats));
    lastSPD2 = squeeze(SPD2s(:,nRepeats));
    indices1 = find(lastSPD1 > max(lastSPD1)*0.1);
    indices2 = find(lastSPD2 > max(lastSPD2)*0.1);
    
    for repeatIndex = 1:nRepeats
        scalings1(repeatIndex) = squeeze(SPD1s(indices1, repeatIndex)) \ lastSPD1(indices1);
        scalings2(repeatIndex) = squeeze(SPD2s(indices2, repeatIndex)) \ lastSPD2(indices2);
    end
    
    tmin = min([min(times1) min(times2)]);
    tmax = max([max(times1) max(times2)]);
    
    timeRange = tmax-tmin;
    dt = timeRange/10000;
    xx = tmin:dt:tmax;
    
    method = 'linear';
    yy1 = interp1(times1, scalings1, xx, method, 'extrap');
    yy2 = interp1(times2, scalings2, xx, method, 'extrap');
    
    yy1 = yy1 / yy1(end);
    yy2 = yy2 / yy2(end);
    
    figure(100); clf; 
    subplot(1,2,1); hold on;
    plot(times1/(60*60), scalings1, 'rs-');
    plot(times2/(60*60), scalings2, 'bs-');
    pieceWiseScalings1 = interp1(times1, scalings1, measurementTimes, method, 'extrap');
    pieceWiseScalings2 = interp1(times2, scalings2, measurementTimes, method, 'extrap');
    plot(measurementTimes/(60*60), pieceWiseScalings1, 'k.');
    plot(measurementTimes/(60*60), pieceWiseScalings2, 'k.');
    xlabel('time (hours)');
end
    