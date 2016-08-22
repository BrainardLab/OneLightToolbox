% OLApplySpectralShiftCorrection - Apply spectral shift correction to theSPD based on its time of measurement for the particular cal.
%
% Syntax:
% spectralShiftCorrectedSPD = OLApplySpectralShiftCorrection(cal, theSpd, theTimeOfMeasurement)
%
% 8/22/16   npc     Wrote it.
%

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
