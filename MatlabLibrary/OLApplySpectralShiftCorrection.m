function spectralShiftCorrectedSPD = OLApplySpectralShiftCorrection(cal, theSpd, theTimeOfMeasurement)
    
    [~,closestStateMeasIndex] = min(abs(cal.computed.spectralShiftCorrection.times - theTimeOfMeasurement));    
    spectralShiftCorrection = cal.computed.spectralShiftCorrection.amplitudes(closestStateMeasIndex);

    xData = SToWls(cal.describe.S);
    
    % Upsample
    dX = 0.01;
    xDataHiRes = (xData(1):dX:xData(end));
    
    % Interpolate
    theHiResSpd = interp1(xData, squeeze(theSpd), xDataHiRes, 'spline');
    
    % Shift
    shiftBinsNum = sign(spectralShiftCorrection) * round(abs(spectralShiftCorrection)/dX);
    shiftedSpd = circshift(theHiResSpd, shiftBinsNum, 2);
    if (shiftBinsNum>=0)
        shiftedSpd(1:shiftBinsNum) = 0;
    else
        shiftedSpd(end:end+shiftBinsNum+1) = 0;
    end
    
    % back to original sampling
    spectralShiftCorrectedSPD = interp1(xDataHiRes, shiftedSpd, xData);
end
