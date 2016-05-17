function [data, allTimes] = doLinearDriftCorrection(uncorrectedData, nRepeats)
    data = uncorrectedData;
    nSpectraMeasured = numel(data);
    allTimes = zeros(nRepeats*nSpectraMeasured,1);
   
    % Find the spectumIndex with the max activation
    maxActivation = 0;
    k = 0;
    for repeatIndex = 1:nRepeats
        for spectrumIndex = 1:nSpectraMeasured
            k = k + 1;
            totalActivation = sum(data{spectrumIndex}.activation);
            if (totalActivation > maxActivation)
                maxActivation = totalActivation;
                maxActivationSpectrumIndex = spectrumIndex;
            end
            allTimes(k) = data{spectrumIndex}.measurementTime(1, repeatIndex);
        end
    end
    
    t0 = squeeze(data{maxActivationSpectrumIndex}.measurementTime(1, 1));
    t1 = squeeze(data{maxActivationSpectrumIndex}.measurementTime(1, nRepeats));
    s0 = squeeze(data{maxActivationSpectrumIndex}.measuredSPD(:, 1));
    s1 = squeeze(data{maxActivationSpectrumIndex}.measuredSPD(:, nRepeats));
    % find the scaling factor based on points that are > 5% of the peak SPD
    indices = find(s1 > max(s1)*0.05);
    s = s0(indices) \ s1(indices);
    scalingFactor = @(t) 1./((1-(1-s)*((t-t0)./(t1-t0))));
    
    % Do the spectrum scaling correction
    for repeatIndex = 1:nRepeats
        for spectrumIndex = 1:nSpectraMeasured
            timeOfMeasurement = squeeze(data{spectrumIndex}.measurementTime(1, repeatIndex));
            data{spectrumIndex}.measuredSPD(:, repeatIndex) = data{spectrumIndex}.measuredSPD(:, repeatIndex) * scalingFactor(timeOfMeasurement);
            fprintf('Scaling spectrum %d (repat: %d) by %2.4f\n', spectrumIndex, repeatIndex, scalingFactor(timeOfMeasurement));
        end
    end
    
    plotScalingExample = false;
    if (plotScalingExample)
        t = sort(allTimes);
        correction = returnScaleFactor(t);
        figure(1);
        plot(t, correction, 'k-', 'LineWidth', 4.0);
        hold on;
        tt = t((t>=t0) & (t <=t1));
        plot(tt, returnScaleFactor(tt), 'rs');
        drawnow;


        figure(2); clf
        subplot(1,2,1);
        plot(1:numel(s0), s0, 'r-');
        hold on;
        plot(1:numel(s0), s1, 'b-');

        subplot(1,2,2);
        plot(1:numel(s0), s0*scalingFactor(t0), 'r-', 'LineWidth', 2.0);
        hold on;
        plot(1:numel(s0), s1*scalingFactor(t1), 'b:', 'LineWidth', 2.0);
        drawnow;
    end
    
end