function plotFrame(axesStruct, refActivation, interactingActivation, wavelengthAxis, theGamma, theOldGammas, refSettingsIndex, referenceSettingsValue, interactingSettingsValue, refSPD, refSPDmin, refSPDmax, interactingSPD, interactingSPDmin, interactingSPDmax, measuredComboAllSPDs, measuredComboSPD, predictedComboSPD, measuredComboSPDmin, measuredComboSPDmax, maxSPD, subplotPosVectors)
    
    % The gamma curves
    if (~isempty(theOldGammas)) && (refSettingsIndex == 1)
        % plot the previous gamma curves in black
        for k = 1:numel(theOldGammas)
            aGamma = theOldGammas{k};
            gammaOut(k,:) = [0 aGamma.gammaOut];
            gammaIn = [0 aGamma.gammaIn];
        end
        plot(axesStruct.gammaAxes, gammaIn,  gammaOut, '-', 'Color', [0.4 0.4 0.4 0.5], 'LineWidth', 1);
        hold(axesStruct.gammaAxes, 'on')
    end
    plot(axesStruct.gammaAxes, [0 theGamma.gammaIn(1:refSettingsIndex)],  [0 theGamma.gammaOut(1:refSettingsIndex)], 'rs-', 'Color', [1.0 0.0 0.0], 'MarkerSize', 8, 'MarkerFaceColor', [1 0.7 0.7], 'LineWidth', 1);
    if (refSettingsIndex == numel(theGamma.gammaIn))
        hold(axesStruct.gammaAxes, 'off')
    end

    set(axesStruct.gammaAxes, 'XLim', [0 1], 'YLim', [0 1.0], 'XTick', 0:0.2:1.0, 'YTick', 0:0.2:1.0, 'XTickLabel', sprintf('%0.1f\n', 0:0.2:1.0), 'YTickLabel', sprintf('%0.1f\n', 0:0.2:1.0), 'FontSize', 14);
    grid(axesStruct.gammaAxes, 'on');
    box(axesStruct.gammaAxes, 'off');
    xlabel(axesStruct.gammaAxes, 'settings value', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel(axesStruct.gammaAxes, 'gamma out', 'FontSize', 16, 'FontWeight', 'bold');
    
    % The activation pattern on top-left
    bar(axesStruct.activationAxes, 1:numel(refActivation), refActivation, 1.0, 'FaceColor', [1.0 0.75 0.75], 'EdgeColor', [1 0 0], 'EdgeAlpha', 0.5, 'LineWidth', 1.5);
    hold(axesStruct.activationAxes, 'on')
    bar(axesStruct.activationAxes, 1:numel(interactingActivation), interactingActivation, 1.0, 'FaceColor', [0.75 0.75 1.0], 'EdgeColor', [0 0 1], 'EdgeAlpha', 0.7, 'LineWidth', 1.5);
    hold(axesStruct.activationAxes, 'off')
    set(axesStruct.activationAxes, 'YLim', [0 1.0], 'XLim', [0 numel(refActivation)+1]);
    hL = legend(axesStruct.activationAxes, {'reference band', 'interacting band(s)'}, 'Location', 'NorthOutside', 'Orientation', 'Horizontal');
    legend boxoff;
    set(hL, 'FontSize', 14, 'FontName', 'Menlo');
    set(axesStruct.activationAxes, 'FontSize', 14, 'YLim', [0 1.0], 'XLim', [0 numel(interactingActivation)+1]);
    xlabel(axesStruct.activationAxes,'band no', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel(axesStruct.activationAxes,'settings value', 'FontSize', 16, 'FontWeight', 'bold');
    box(axesStruct.activationAxes, 'off');
    
    % The reference and interacting SPDs pattern on top-right
    plot(axesStruct.singletonSPDAxes, wavelengthAxis, refSPDmin, '-', 'Color', [0 0 0], 'LineWidth', 2.0);
    hold(axesStruct.singletonSPDAxes, 'on');
    plot(axesStruct.singletonSPDAxes, wavelengthAxis, refSPDmax, '-', 'Color', [0 0 0], 'LineWidth', 2.0);
    plot(axesStruct.singletonSPDAxes, wavelengthAxis, interactingSPDmin, '-', 'Color', [0 0 0], 'LineWidth', 2.0);
    plot(axesStruct.singletonSPDAxes, wavelengthAxis, interactingSPDmax, '-', 'Color', [0 0 0], 'LineWidth', 2.0);
    x = [wavelengthAxis(1) wavelengthAxis' wavelengthAxis(end)];
    baseline = min([0 min(refSPD)]);
    y = [baseline refSPD' baseline]; 
    patch(x,y, 'green', 'FaceColor', [1.0 0.8 0.8], 'EdgeColor', 'none',  'LineWidth', 2.0, 'parent', axesStruct.singletonSPDAxes);
    baseline = min([0 min(interactingSPD)]);
    y = [baseline interactingSPD' baseline]; 
    patch(x,y, 'green', 'FaceColor', [0.8 0.8 1.0], 'EdgeColor', 'none',  'FaceAlpha', 0.5, 'LineWidth', 2.0, 'parent', axesStruct.singletonSPDAxes);
    hold(axesStruct.singletonSPDAxes, 'off');
    hL = legend(axesStruct.singletonSPDAxes, {'reference band SPD(min)', 'reference band SPD(max)', 'interacting band(s) SPD (min)', 'interacting band(s) SPD (max)', 'reference band SPD', 'interacting band(s) SPD'}, 'Location', 'SouthWest');
    set(hL, 'FontSize', 14, 'FontName', 'Menlo');
    legend boxoff;
    set(axesStruct.singletonSPDAxes, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [0 maxSPD], 'XTick', [300:25:800], 'FontSize', 14);
    xlabel(axesStruct.singletonSPDAxes, 'wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel(axesStruct.singletonSPDAxes, 'power (mW)', 'FontSize', 16, 'FontWeight', 'bold');
    grid(axesStruct.singletonSPDAxes, 'on');
    box(axesStruct.singletonSPDAxes, 'off');
 
    % The measured and predicted combo SPDs on bottom-left
    repeatsColors = colormap(jet(2+size(measuredComboAllSPDs,2)));
   
    allLegends = {};
    for k = 1:size(measuredComboAllSPDs,2)
         allLegends{k} = sprintf('measured SPD (#%d)\n', k);
         plot(axesStruct.comboSPDAxes, wavelengthAxis,squeeze(measuredComboAllSPDs(:,k)), '-', 'Color', squeeze(repeatsColors(k+1,:)), 'LineWidth', 1.5);
         if (k == 1)
             hold(axesStruct.comboSPDAxes, 'on');
         end
     end
     plot(axesStruct.comboSPDAxes, wavelengthAxis,measuredComboSPD, '-', 'Color', [0.1 0.1 0.1],  'LineWidth', 3.0);
     plot(axesStruct.comboSPDAxes, wavelengthAxis,predictedComboSPD, '-', 'Color', [1.0 0.1 0.9], 'LineWidth', 3.0);
     hold(axesStruct.comboSPDAxes,'off');
%     
     allLegends{numel(allLegends)+1} = 'measured SPD (mean)';
     allLegends{numel(allLegends)+1} = 'predicted SPD (mean)';
%      
     hL = legend(axesStruct.comboSPDAxes, allLegends);
     set(hL, 'FontSize', 14, 'FontName', 'Menlo');
     legend boxoff;
     set(axesStruct.comboSPDAxes, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [0 maxSPD], 'XTick', [300:25:800]);
     set(axesStruct.comboSPDAxes, 'FontSize', 14, 'FontName', 'Menlo');
     xlabel(axesStruct.comboSPDAxes, 'wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold');
     ylabel(axesStruct.comboSPDAxes, 'power (mW)', 'FontSize', 16, 'FontWeight', 'bold');
     grid(axesStruct.comboSPDAxes, 'on');
     box(axesStruct.comboSPDAxes, 'off');
% 
    % The residual (measured - predicted combo SPDs) on bottom-right
    allLegends = {};
    for k = 1:size(measuredComboAllSPDs,2)
         allLegends{k} = sprintf('measured SPDmean - measuredSPD(#%d)\n', k);
         plot(axesStruct.residualSPDAxes, wavelengthAxis, measuredComboSPD-squeeze(measuredComboAllSPDs(:,k)), '-', 'Color', squeeze(repeatsColors(k+1,:)), 'LineWidth', 2.0);
         if (k == 1)
             hold(axesStruct.residualSPDAxes, 'on');
         end
    end
    y = [0 (measuredComboSPD-predictedComboSPD)' 0];
    patch(x,y, 'green', 'FaceColor', [0.6 0.6 0.6], 'EdgeColor', [0.3 0.3 0.3], 'FaceAlpha', 0.7, 'EdgeAlpha', 0.9, 'LineWidth', 2.0, 'parent', axesStruct.residualSPDAxes);
    hold(axesStruct.residualSPDAxes, 'off');
    allLegends{numel(allLegends)+1} = 'measured SPDmean - predicted SPD';
%     
    hL = legend(axesStruct.residualSPDAxes, allLegends, 'Location', 'SouthWest');
    set(hL, 'FontSize', 14, 'FontName', 'Menlo');
    legend boxoff;
    set(axesStruct.residualSPDAxes, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [-3 3], 'XTick', [300:25:800], 'FontSize', 14);
    xlabel(axesStruct.residualSPDAxes, 'wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel(axesStruct.residualSPDAxes, 'residual power (mW)', 'FontSize', 16, 'FontWeight', 'bold');
    grid on
    box off
%     
    text(385, 2.7, sprintf('reference   band  settings: %2.2f', referenceSettingsValue), 'Color', [1.0 0.3 0.3], 'FontName', 'Menlo', 'FontSize', 14, 'parent', axesStruct.residualSPDAxes);
    text(385, 2.2, sprintf('interacting band(s) settings: %2.2f', interactingSettingsValue), 'Color', [0.3 0.3 1.0],'FontName', 'Menlo', 'FontSize', 14, 'parent', axesStruct.residualSPDAxes);
    drawnow;
end
