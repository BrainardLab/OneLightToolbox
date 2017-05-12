% Method to plot the spectral stability data set
function plotSpectralStabilityData(obj, dataSetName, theEntryIndex, plotAxes)

    switch dataSetName
        case 'calibration'
            data = obj.calData;
        case 'test'
            data = obj.testData;
        otherwise
            error('plotSpectralStabilityData(dataSetName): dataSetName must be either ''calibration'' or ''test''.');
    end

    stabilitySpectra = data.stabilitySpectra;
    if (numel(stabilitySpectra) == 0)
        return;
    end
    
    powerFluctuationSpectrumMax = 0;
    for entryIndex = 1:numel(stabilitySpectra)
        s = stabilitySpectra{entryIndex};
        if (~isfield(s,'powerFluctuationsData'))
            continue;
        end
        powerFluctuationsData = s.powerFluctuationsData;
        spectraShiftsData = s.spectraShiftsData;
        powerFluctuationSpectrumMin = min(powerFluctuationsData.measSpd(:));
        powerFluctuationSpectrumMax = max(powerFluctuationsData.measSpd(:));
        spectralShiftSpectrumMin = min(spectraShiftsData.measSpd(:));
        spectralShiftSpectrumMax = max(spectraShiftsData.measSpd(:));
    end
    
    if (powerFluctuationSpectrumMax == 0)
        return;
    end
    
    powerFluctuationSpectraRange = [0 powerFluctuationSpectrumMax];
    spectralShiftSpectraRange = [0 spectralShiftSpectrumMax];
    YLims = [0 1000*max([0*powerFluctuationSpectraRange(2) spectralShiftSpectraRange(2)])];
    
    wavelengthSupport = stabilitySpectra{theEntryIndex}.wavelengthSupport;
    powerFluctuationsData = stabilitySpectra{theEntryIndex}.powerFluctuationsData;
    spectraShiftsData = stabilitySpectra{theEntryIndex}.spectraShiftsData;
    referenceCombPeaks = obj.combSPDActualPeaks{entryIndex};
    
    plot(plotAxes, wavelengthSupport, 1000*powerFluctuationsData.measSpd, '-', 'Color', [0.4 0.4 0.4]);
    hold(plotAxes, 'on');
    plot(plotAxes, wavelengthSupport, 1000*spectraShiftsData.measSpd, '-', 'Color', [0.6 0.6 0.6]);
    plot(plotAxes, referenceCombPeaks(1)*[1 1], YLims, 'k--', 'LineWidth', 1.0, 'Color', squeeze(obj.combSPDPlotColors(1,:)));
    plot(plotAxes, referenceCombPeaks(2)*[1 1], YLims, 'k--', 'LineWidth', 1.0, 'Color', squeeze(obj.combSPDPlotColors(2,:)));
    plot(plotAxes, referenceCombPeaks(3)*[1 1], YLims, 'k--', 'LineWidth', 1.0, 'Color', squeeze(obj.combSPDPlotColors(3,:)));
    plot(plotAxes, referenceCombPeaks(4)*[1 1], YLims, 'k--', 'LineWidth', 1.0, 'Color', squeeze(obj.combSPDPlotColors(4,:)));
    hold(plotAxes, 'off');
    % Finish plot
    box(plotAxes, 'on');
    grid(plotAxes, 'on');
    xlabel(plotAxes,'wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel(plotAxes, 'energy (mWatts/sr/m2/nm)', 'FontSize', 14, 'FontWeight', 'bold');
    set(plotAxes, 'FontSize', 14, 'XLim', [wavelengthSupport(1) wavelengthSupport(end)], 'YLim', YLims);
end

