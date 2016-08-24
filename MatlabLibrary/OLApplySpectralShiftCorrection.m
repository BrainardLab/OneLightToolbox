% OLApplySpectralShiftCorrection - Apply a single spectral shift correction to all SPDs in theSPDs.
%
% Syntax:
% spectralShiftCorrectedSPD = OLApplySpectralShiftCorrection(theSpds, spectralShiftCorrection, spectralAxis)
%
% 8/22/16   npc     Wrote it.
%

function spectralShiftCorrectedSPDs = OLApplySpectralShiftCorrection(theSpds, spectralShiftCorrection, spectralAxis)
    
    xData = spectralAxis;
    
    % Upsample
    dX = 0.01;
    xDataHiRes = (xData(1):dX:xData(end));
    
    spdNum = size(theSpds,2);
    spectralShiftCorrectedSPDs = 0*theSpds;
    
    for iSPD = 1:spdNum
        % Interpolate
        theHiResSpd = interp1(xData, squeeze(theSpds(:,iSPD)), xDataHiRes, 'spline');
    
        % Shift
        shiftBinsNum = sign(spectralShiftCorrection) * round(abs(spectralShiftCorrection)/dX);
        shiftedSpd = circshift(theHiResSpd, shiftBinsNum, 2);
        if (shiftBinsNum>=0)
            shiftedSpd(1:shiftBinsNum) = 0;
        else
            shiftedSpd(end:end+shiftBinsNum+1) = 0;
        end
    
        % back to original sampling
        spectralShiftCorrectedSPDs(:, iSPD) = interp1(xDataHiRes, shiftedSpd, xData);
    end
end
