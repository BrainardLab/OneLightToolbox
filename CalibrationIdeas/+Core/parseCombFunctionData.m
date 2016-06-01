function parseCombFunctionData(warmUpData, wavelengthAxis)
    
    spdGain = 1000;
    
    for stimPattern = 1:numel(warmUpData)
        figure(stimPattern); clf;
        subplot(1,3,1);
        bar(warmUpData{stimPattern}.activation);
        
        meanSPD = mean(warmUpData{stimPattern}.measuredSPD,2);
        diffSPD = bsxfun(@minus, warmUpData{stimPattern}.measuredSPD, meanSPD);
        
        if (stimPattern == 1)
            fullOnData = spdGain * diffSPD;
        elseif (stimPattern == 2)
            combData = spdGain * diffSPD;
        else
            combComponentData(stimPattern-2,:,:) = spdGain * diffSPD;
        end
        
        subplot(1,3,2);
        plot(wavelengthAxis, spdGain * diffSPD, 'k-');
        
        
        subplot(1,3,3);
        plot(wavelengthAxis, spdGain * meanSPD, 'k-');
    end
    
end

