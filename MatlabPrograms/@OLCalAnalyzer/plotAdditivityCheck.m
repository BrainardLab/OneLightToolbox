% Method to plot additivity checks
function plotAdditivityCheck(obj)

    independenceMeasurementsNum = size(obj.cal.raw.independence.meas,2);
    predictedSPD = zeros(size(obj.cal.raw.independence.meas,1), 1);
    
    if (obj.cal.describe.specifiedBackground)
        baseSPD = obj.cal.computed.pr650MeanSpecifiedBackground;
    else
        baseSPD = obj.cal.computed.pr650MeanDark;
    end
    
    for iMeas = 1:independenceMeasurementsNum
        predictedSPD = predictedSPD + obj.cal.raw.independence.meas(:,iMeas)*obj.cal.computed.returnScaleFactor(obj.cal.raw.t.independence.meas(iMeas))-baseSPD;
    end
    measuredSPD = obj.cal.raw.independence.measAll*obj.cal.computed.returnScaleFactor(obj.cal.raw.t.independence.measAll)-baseSPD;
   
    hFig = figure; clf;
    figurePrefix = sprintf('AdditivityCheck');
    obj.figsList.(figurePrefix) = hFig;
    set(hFig, 'Position', [10 1000 1990 1060], 'Name', figurePrefix,  'Color', [1 1 1]);
            
    subplot('Position', [0.03 0.05 0.45 0.94]);
    plot(obj.waveAxis, 1000*predictedSPD, 'r-', 'LineWidth', 1.5); hold on
    plot(obj.waveAxis, 1000*measuredSPD, 'b--', 'LineWidth', 1.5);
    legend('predicted SPD', 'measured SPD'); legend boxoff;
    set(gca, 'XLim', [obj.waveAxis(1)-5 obj.waveAxis(end)+5]);
    xlabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('power (mW/sr/m2/nm)', 'FontSize', 14, 'FontWeight', 'bold');
    
    subplot('Position', [0.52 0.05 0.45 0.94]);
    plot(obj.waveAxis, 1000*(predictedSPD-measuredSPD), 'k-', 'LineWidth', 1.5); hold on
    legend('difference SPD'); legend boxoff;
    set(gca, 'XLim', [obj.waveAxis(1)-5 obj.waveAxis(end)+5], 'YLim', [-0.2 0.2]);
    xlabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
end

