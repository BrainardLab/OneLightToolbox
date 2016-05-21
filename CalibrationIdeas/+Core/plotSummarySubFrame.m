function plotSummarySubFrame(refActivation, interactingActivation, wavelengthAxis, referenceSettingsValue, interactingSettingsValue, refSPD, refSPDmin, refSPDmax, interactingSPD, interactingSPDmin, interactingSPDmax, measuredComboSPD, predictedComboSPD, measuredComboSPDmin, measuredComboSPDmax, maxSPD, maxResidualSPD, meanResidualSPD ,subplotPosVectors)
% The activation pattern on top-left
    subplot('Position', subplotPosVectors(1,1).v);
    bar(1:numel(refActivation), refActivation, 1.0, 'FaceColor', [1.0 0.75 0.75], 'EdgeColor', [1 0 0], 'EdgeAlpha', 0.5, 'LineWidth', 1.5);
    hold on
    bar(1:numel(interactingActivation), interactingActivation, 1.0, 'FaceColor', [0.75 0.75 1.0], 'EdgeColor', [0 0 1], 'EdgeAlpha', 0.7, 'LineWidth', 1.5);
    hold off;
    set(gca, 'YLim', [0 1.0], 'XLim', [0 numel(refActivation)+1]);
    xlabel('band no', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('settings value', 'FontSize', 14, 'FontWeight', 'bold');
    box off;
    
    % The reference and interacting SPDs pattern on top-right
    subplot('Position', subplotPosVectors(2,1).v);
    x = [wavelengthAxis(1) wavelengthAxis' wavelengthAxis(end)];
    baseline = min([0 min(refSPD)]);
    y = [baseline refSPD' baseline]; 
    patch(x,y, 'green', 'FaceColor', [1.0 0.8 0.8], 'EdgeColor', [1.0 0. 0.], 'EdgeAlpha', 0.5, 'LineWidth', 2.0);
    hold on
    plot(wavelengthAxis, refSPDmin, '-', 'Color', [0 0 0]);
    plot(wavelengthAxis, refSPDmax, '-', 'Color', [0 0 0]);
    baseline = min([0 min(interactingSPD)]);
    y = [baseline interactingSPD' baseline]; 
    patch(x,y, 'green', 'FaceColor', [0.8 0.8 1.0], 'EdgeColor', [0.0 0. 1], 'EdgeAlpha', 0.5, 'FaceAlpha', 0.5, 'LineWidth', 2.0);
    plot(wavelengthAxis, interactingSPDmin, '-', 'Color', [0 0 0]);
    plot(wavelengthAxis, interactingSPDmax, '-', 'Color', [0 0 0]);
    hold off;
    set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [0 maxSPD], 'XTick', [300:25:800]);
    set(gca, 'FontSize', 12);
    xlabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('power (mW)', 'FontSize', 14, 'FontWeight', 'bold');
    grid on
    box off

    % The measured and predicted combo SPDs on bottom-left
    subplot('Position', subplotPosVectors(3,1).v);
    plot(wavelengthAxis,predictedComboSPD, '-', 'Color', [1.0 0.1 0.9], 'LineWidth', 2.0);
    hold on;
    plot(wavelengthAxis,measuredComboSPD, '-', 'Color', [0.1 0.8 0.5],  'LineWidth', 2.0);
    plot(wavelengthAxis, measuredComboSPDmin, '-', 'Color', [0 0 0]);
    plot(wavelengthAxis, measuredComboSPDmax, '-', 'Color', [0 0 0]);
    hold off;
    hL = legend('predicted SPD', 'measured SPD', 'measured SPD (min)', 'measured SPD (max)', 'Location', 'SouthWest');
    set(hL, 'FontSize', 12, 'FontName', 'Menlo');
    legend boxoff;
    set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [0 maxSPD], 'XTick', [300:25:800]);
    set(gca, 'FontSize', 12, 'FontName', 'Menlo');
    xlabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('power (mW)', 'FontSize', 14, 'FontWeight', 'bold');
    grid on
    box off

    % The residual (measured - predicted combo SPDs) on bottom-right
    subplot('Position', subplotPosVectors(4,1).v);
    y = [0 (measuredComboSPD-predictedComboSPD)' 0];
    patch(x,y, 'green', 'FaceColor', [0.3 0.8 1.0], 'EdgeColor', [0.2 0.6 0.6], 'FaceAlpha', 0.7, 'EdgeAlpha', 0.9, 'LineWidth', 2.0);
    hold on;
    plot(wavelengthAxis, measuredComboSPD-measuredComboSPDmin, 'k--', 'LineWidth', 2.0);
    plot(wavelengthAxis, measuredComboSPD-measuredComboSPDmax, 'k:',  'LineWidth', 2.0);
    set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [-5 5], 'XTick', [300:25:800]);
    set(gca, 'FontSize', 12);
    xlabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('residual power (mW)', 'FontSize', 14, 'FontWeight', 'bold');
    grid on
    box off
    
    text(385, 4.7, sprintf('reference   band  settings: %2.2f', referenceSettingsValue), 'Color', [1.0 0.3 0.3], 'FontName', 'Menlo', 'FontSize', 12);
    text(385, 4.2, sprintf('interacting band(s) settings: %2.2f', interactingSettingsValue), 'Color', [0.3 0.3 1.0],'FontName', 'Menlo', 'FontSize', 12);
    drawnow;
    
end

