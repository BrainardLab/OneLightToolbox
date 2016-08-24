% OLComputeSpectralShiftBetweenCombSPDs - Returns the spectral shift that needs to be applied to the referenceSPD in order to align it with the currentSPD
%
% Syntax:
% [spectralShifts, refPeaks] = OLComputeSpectralShiftBetweenCombSPDs(theCurrentSPD, theReferenceSPD, combPeaks, spectralAxis)
%
% 8/22/16   npc     Wrote it.
%
function [spectralShifts, refPeaks] = OLComputeSpectralShiftBetweenCombSPDs(theCurrentSPD, theReferenceSPD, combPeaks, spectralAxis)
    
    paramNames = {...
        'offset (mWatts)', ...
        'gain (mWatts)', ...
        'peak (nm)', ...
        'left side sigma (nm)', ...
        'right side sigma (nm)', ...
        'exponent'};
    
    % Fit each of the combPeaks separately
    for peakIndex = 1:numel(combPeaks)
        % nominal peak
        peak = combPeaks(peakIndex);
        
        % Find exact peak
        dataIndicesToFit = sort(find(abs(spectralAxis - peak) <= 15));
        [maxComb,idx] = max(theReferenceSPD(dataIndicesToFit));
        peak = spectralAxis(dataIndicesToFit(idx));
        refPeaks(peakIndex) = peak;
        
        % Select spectral region to fit
        dataIndicesToFit = sort(find(abs(spectralAxis - peak) <= 15));
        dataIndicesToFit = dataIndicesToFit(find(theReferenceSPD(dataIndicesToFit) > 0.1*maxComb));
        
        xData = spectralAxis(dataIndicesToFit);
        xDataHiRes = (xData(1):0.1:xData(end))';
        
        initialParams    = [0   5  peak     6.28   6.28  2.0];
        paramLowerBounds = [0   0  peak-20  1.00   1.00  1.5]; 
        paramUpperBounds = [0  10  peak+20 10.00  10.00  4.0];
        
        % Fit the reference SPD peak
        spdData = 1000*theReferenceSPD(dataIndicesToFit);  % in milliWatts
        fitParams = fitGaussianToData(xData, spdData, initialParams, paramLowerBounds, paramUpperBounds);
        refPeak(peakIndex) = fitParams(3);
        
        % Fit the current SPD peak
        spdData = 1000*theCurrentSPD(dataIndicesToFit);  % in milliWatts
        fitParams = fitGaussianToData(xData, spdData, initialParams, paramLowerBounds, paramUpperBounds);
        currentPeak(peakIndex) = fitParams(3);
        
        spectralShifts(peakIndex) = currentPeak(peakIndex) - refPeak(peakIndex);
    end % peakIndex

end

function solution = fitGaussianToData(xData, yData, initialParams, paramLowerBounds, paramUpperBounds)
    Aeq = [];
    beq = [];
    A = [];
    b = [];
    nonlcon = [];
    options = optimoptions('fmincon');
    options = optimset('Display', 'off');
    solution = fmincon(@functionToMinimize, initialParams,A, b,Aeq,beq, paramLowerBounds, paramUpperBounds, nonlcon, options);
    
    function rmsResidual = functionToMinimize(params)
        yfit = twoSidedExponential(xData, params);
        rmsResidual  = sum((yfit - yData) .^2);
    end
end

function g = twoSidedExponential(wavelength, params)
    offset = params(1);
    gain = params(2);
    peakWavelength = params(3);
    leftSigmaWavelength = params(4);
    rightSigmaWavelength = params(5);
    exponent = params(6);
    leftIndices = find(wavelength < peakWavelength);
    rightIndices = find(wavelength >= peakWavelength);
    g1 = offset + gain*exp(-0.5*(abs((wavelength(leftIndices)-peakWavelength)/leftSigmaWavelength)).^exponent);    
    g2 = offset + gain*exp(-0.5*(abs((wavelength(rightIndices)-peakWavelength)/rightSigmaWavelength)).^exponent);
    g = cat(1, g1, g2);
end