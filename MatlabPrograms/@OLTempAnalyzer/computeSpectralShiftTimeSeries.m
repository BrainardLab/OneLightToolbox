function [combPeakTimeSeries, initialPeaks, gainTimeSeries] = computeSpectralShiftTimeSeries(obj, stabilitySpectra, entryIndex)
    
    if (isempty(stabilitySpectra))
        combPeakTimeSeries = [];
        initialPeaks = [];
        gainTimeSeries = [];
        return;
    end
    
    stabilitySpectra
    numel(stabilitySpectra)
    entryIndex
    stabilitySpectra{entryIndex}
    
    combSPDNominalPeaks = obj.combSPDNominalPeaks;
    
    spectraShiftsData = stabilitySpectra{entryIndex}.spectraShiftsData.measSpd;
    h = waitbar(0.0, sprintf('computing spectral shifts for entry %d', entryIndex));
    wax = findobj(h, 'type','axes');
    tax = get(wax,'title');
    set(tax,'fontsize',14)
    for timePointIndex = 1:size(spectraShiftsData,2)
        waitbar(timePointIndex/size(spectraShiftsData,2),h);
        [combPeakTimeSeries(:, timePointIndex), gainTimeSeries(:, timePointIndex)] = findPeaks(squeeze(spectraShiftsData(:, timePointIndex)), stabilitySpectra{entryIndex}.wavelengthSupport, combSPDNominalPeaks);
    end
    close(h);
    initialPeaks = squeeze(combPeakTimeSeries(:,1));
    combPeakTimeSeries = bsxfun(@minus, combPeakTimeSeries, initialPeaks);
    initialGain = squeeze(gainTimeSeries(:,1));
    gainTimeSeries = bsxfun(@times, gainTimeSeries, 1./initialGain);
end


function [combPeakTimeSeries, gainTimeSeries] = findPeaks(spd, spectralAxis, combSPDNominalPeaks)

    for peakIndex = 1:numel(combSPDNominalPeaks)
        % nominal peak
        peak = combSPDNominalPeaks(peakIndex);

        % Find exact peak
        dataIndicesToFit = sort(find(abs(spectralAxis - peak) <= 15));
        [maxComb,idx] = max(spd(dataIndicesToFit));
        peak = spectralAxis(dataIndicesToFit(idx));
        refPeaks(peakIndex) = peak;

        % Select spectral region to fit
        dataIndicesToFit = sort(find(abs(spectralAxis - peak) <= 15));
        dataIndicesToFit = dataIndicesToFit(find(spd(dataIndicesToFit) > 0.1*maxComb));

        xData = spectralAxis(dataIndicesToFit);
        xDataHiRes = (xData(1):0.1:xData(end))';

        initialParams    = [0   5   peak     6.28   6.28  2.0];
        paramLowerBounds = [0   0   peak-30  1.00   1.00  1.5]; 
        paramUpperBounds = [0  100  peak+30 30.00  30.00  10.0];

        % Fit the reference SPD peak
        spdData = 1000*spd(dataIndicesToFit);  % in milliWatts
        fitParamsRef = fitGaussianToData(xData, spdData, initialParams, paramLowerBounds, paramUpperBounds);
        combPeakTimeSeries(peakIndex) = fitParamsRef(3);
        gainTimeSeries(peakIndex) = fitParamsRef(2); 
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
