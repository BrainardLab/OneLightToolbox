function plotPredictions(obj, varargin)

    parser = inputParser;
    parser.addRequired('spdType', @ischar);
    parser.addRequired('spdName', @ischar);
 
    % Execute the parser
    parser.parse(varargin{:});
    % Create a standard Matlab structure from the parser results.
    p = parser.Results;
    
    % Get spd type and name
    spdType = p.spdType;
    spdName = p.spdName;
    
    % Validate spdType
    validatestring(spdType, {'raw', 'computed'});
    
    
    % Extract the desired spd data
    if (strcmp(spdName, 'wigglyMeas'))
        measuredSPD = eval(sprintf('obj.cal.%s.%s.measSpd', spdType,spdName));
        settingsUsedPreCalibration = obj.cal.raw.wigglyMeas.settings(:,1);
        settingsUsedPostCalibration = obj.cal.raw.wigglyMeas.settings(:,2);
    else
        measuredSPD = eval(sprintf('obj.cal.%s.%s', spdType,spdName));
        if (strcmp(spdName, 'fullOn'))
            settingsUsedPreCalibration = ones(obj.cal.describe.numWavelengthBands,1);
            settingsUsedPostCalibration = settingsUsedPreCalibration;
        elseif (strcmp(spdName, 'halfOnMeas'))
            settingsUsedPreCalibration  = 0.5*ones(obj.cal.describe.numWavelengthBands,1);
            settingsUsedPostCalibration = settingsUsedPreCalibration;
        elseif (strcmp(spdName, 'darkMeas'))
            settingsUsedPreCalibration  = 0.0*ones(obj.cal.describe.numWavelengthBands,1);
            settingsUsedPostCalibration = settingsUsedPreCalibration;
        else
           error('Unknown settings for spd named: ''%s''\n.', spdName)
        end
    end

    
    % Retrieve measured data
    measuredSPDpreCalibration  = measuredSPD(:, 1);
    measuredSPDpostCalibration = measuredSPD(:, 2);
    
    % Compute predicted SPD
    primaries    = OLSettingsToPrimary(obj.cal, settingsUsedPreCalibration);
    predictedSPD = OLPrimaryToSpd(obj.cal, primaries);

    
    % Estimate settings from the measured SPD by solving
    % [obj.cal.computed.pr650M] * [effectivePrimaryActivations] = measuredSPD;
    designMatrix = obj.cal.computed.pr650M;
    %designMatrix = bsxfun(@minus,designMatrix, mean(designMatrix,1));

    %measuredDarkSPDpreCalibration  = obj.cal.raw.darkMeas(:,1);
    %measuredDarkSPDpostCalibration = obj.cal.raw.darkMeas(:,2);
    
    reconstructedPrimaryActivationsPreCalibration  = pinv(designMatrix) * (measuredSPDpreCalibration  - obj.cal.computed.pr650MeanDark);
    reconstructedPrimaryActivationsPostCalibration = pinv(designMatrix) * (measuredSPDpostCalibration - obj.cal.computed.pr650MeanDark);
    reconstructedSettingsPreCalibration  = OLPrimaryToSettings(obj.cal, reconstructedPrimaryActivationsPreCalibration);
    reconstructedSettingsPostCalibration = OLPrimaryToSettings(obj.cal, reconstructedPrimaryActivationsPostCalibration);
        
    % The settings/reconstructed settings plot
    hFig = figure; clf;
    figurePrefix = sprintf('%s_%s_Settings_VS_SPDreconstructedSettings', spdType, spdName);
    obj.figsList.(figurePrefix) = hFig;
    set(hFig, 'Name', figurePrefix, 'Color', [1 1 1], 'Position', [10 1000 700 1290]);
        
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', 2, ...
               'colsNum', 1, ...
               'heightMargin',   0.08, ...
               'widthMargin',    0.05, ...
               'leftMargin',     0.1, ...
               'rightMargin',    0.01, ...
               'bottomMargin',   0.03, ...
               'topMargin',      0.02);
           
    subplot('position', subplotPosVectors(1,1).v);
    makeSettingsSubFigure(obj, settingsUsedPreCalibration, reconstructedSettingsPreCalibration, 'pre-calibration', spdName)
        
    subplot('position', subplotPosVectors(2,1).v);
    makeSettingsSubFigure(obj, settingsUsedPostCalibration, reconstructedSettingsPostCalibration, 'post-calibration', spdName)

      
    % The measured vs. predicted SPD plot
    hFig = figure; clf;
    figurePrefix = sprintf('%s_%s_Measured_VS_Prediction_SPD', spdType, spdName);
    obj.figsList.(figurePrefix) = hFig;
    set(hFig, 'Name', figurePrefix, 'Color', [1 1 1], 'Position', [10 1000 1780 950]);
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', 1, ...
               'colsNum', 2, ...
               'heightMargin',   0.02, ...
               'widthMargin',    0.05, ...
               'leftMargin',     0.08, ...
               'rightMargin',    0.01, ...
               'bottomMargin',   0.1, ...
               'topMargin',      0.05);

    subplot('position', subplotPosVectors(1,1).v);
    
    hold on;
    plot(obj.waveAxis, 1000*measuredSPDpreCalibration, 'r-', 'LineWidth', 4.0, 'Color', [1.0 0.4 0.4 1.0], 'DisplayName', 'preCalibration');
    plot(obj.waveAxis, 1000*measuredSPDpostCalibration, 'b-', 'LineWidth', 4.0, 'Color', [0.4 0.4 1.0 1.0], 'DisplayName', 'postCalibration');
    plot(obj.waveAxis, 1000*predictedSPD, 'k-', 'LineWidth', 1.0, 'DisplayName', 'predicted');
    
    % Finish plot  
    hL = legend('Location', 'NorthWest');
    hL.FontSize = 16;
    hL.FontName = 'Menlo';  
                
    pbaspect([1 1 1]); 
    box off
    grid on
    set(gca, 'FontSize', 16);
    xlabel('wavelength (nm)', 'FontSize', 20, 'FontWeight', 'bold'); 
    ylabel('power (mW/sr/m2/nm)', 'FontSize', 20, 'FontWeight', 'bold');
    title(sprintf('SPD: ''%s''', spdName));
    
    
    subplot('position', subplotPosVectors(1,2).v);
    plot(obj.waveAxis, 1000*(predictedSPD-measuredSPDpreCalibration), 'r-', 'LineWidth', 4.0, 'Color', [1.0 0.4 0.4 1], 'DisplayName', 'predicted-measured(preCalibration)');
    hold on;
    plot(obj.waveAxis, 1000*(predictedSPD-measuredSPDpostCalibration), 'b-', 'LineWidth', 4.0, 'Color', [0.4 0.4 1.0 1], 'DisplayName', 'predicted-measured(postCalibration)');
    hold off;
    set(gca, 'YLim', 1e-1*[-25 25]);
    
    % Finish plot  
    hL = legend('Location', 'North', 'Orientation', 'horizontal');
    hL.FontSize = 16;
    hL.FontName = 'Menlo';  
    
    pbaspect([1 1 1]); 
    box off
    grid on
    set(gca, 'FontSize', 16);
    xlabel('wavelength (nm)', 'FontSize', 20, 'FontWeight', 'bold'); 
    ylabel('diff power (mW/sr/m2/nm)', 'FontSize', 20, 'FontWeight', 'bold');
    title(sprintf('SPD: ''%s, %s''', spdName, spdType));
    drawnow;
    
end


function makeSettingsSubFigure(obj, settingsUsed, reconstructedSettings, subplotTitle, spdName)

    bandIndices = 1:obj.cal.describe.numWavelengthBands;
    gammaBandIndices = obj.cal.describe.gamma.gammaBands;
    nonGammaBandIndices = setdiff(bandIndices, gammaBandIndices);
    
    settingsError = reconstructedSettings(:)-settingsUsed(:);
    yVals = 0*settingsError;
    yVals(gammaBandIndices) = settingsError(gammaBandIndices);
    bh = bar(bandIndices, yVals, 1.0);
    bh(1).EdgeColor = [0.5 0.0 1.0];
    bh(1).FaceColor = [0.9 0.5 1.0];
    hold on;
    yVals = 0*settingsError;
    yVals(nonGammaBandIndices) = settingsError(nonGammaBandIndices);
    bh = bar(bandIndices, yVals, 1.0);
    bh(1).EdgeColor = [0.1 0.1 0.1];
    bh(1).FaceColor = [0.8 0.8 0.8];
    box on
    yTicks = -0.25:0.05:0.25;
    set(gca, 'XLim', [0 numel(bandIndices)+1], 'XTick', gammaBandIndices, 'XTickLabel', gammaBandIndices, 'YLim', [-0.25 0.25], 'YTick', yTicks, 'YTickLabel', sprintf('%-2.2f\n', yTicks));
    set(gca, 'FontSize', 14);
    grid on
    xlabel('band no', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('settings diff (reconstructed - employed)', 'FontSize', 16, 'FontWeight', 'bold');
    legend({'measured band gamma   ', 'interpolated band gamma'}, 'FontSize', 16, 'FontName','Menlo', 'Location', 'NorthWest'); 
    title(sprintf('%s (SPD: ''%s'')', subplotTitle, spdName), 'FontSize', 18);
    drawnow;
end


function makeSettingsSubFigure2(obj, settingsUsed, reconstructedSettings, subplotTitle)

    bandIndices = 1:obj.cal.describe.numWavelengthBands;
    gammaBandIndices = obj.cal.describe.gamma.gammaBands;
    nonGammaBandIndices = setdiff(bandIndices, gammaBandIndices);
    
        
    bh = bar(bandIndices, [settingsUsed(:) reconstructedSettings(:)], 1);
    bh(1).EdgeColor = [0.2 0.2 0.2];
    bh(1).FaceColor = [0.9 0.9 0.9];
    bh(2).EdgeColor = [0.1 0.1 0.1];
    bh(2).FaceColor = [0.7 0.7 0.7];
    box off
    set(gca, 'XLim', [-0.25 numel(bandIndices)+0.25], 'XTick', gammaBandIndices, 'XTickLabel', gammaBandIndices, 'YLim', [0 1.0], 'YTick', 0:0.1:1.0);
    set(gca, 'FontSize', 14);
    xlabel('band no', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('settings value', 'FontSize', 16, 'FontWeight', 'bold');
    
    ax1 = gca;
    ax1_pos = ax1.Position; % position of first axes
    ax2 = axes('Position',ax1_pos,...
            'XAxisLocation','top',...
            'YAxisLocation','right',...
            'Color','none');
    linkaxes([ax1 ax2],'x');
    hold on
    settingsError = reconstructedSettings(:)-settingsUsed(:);
    plot(bandIndices, settingsError, 'ks-', 'LineWidth', 2.0, 'MarkerSize', 12, 'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [0.8 0.8 0.8],'parent', ax2);
    plot(gammaBandIndices, settingsError(gammaBandIndices),'rs', 'MarkerSize', 14, 'MarkerFaceColor', [1.0 0.7 0.7],'parent', ax2);
    
    hold off
    set(ax2, 'XLim', [-0.25 numel(bandIndices)+0.25], 'XTick', gammaBandIndices, 'XTickLabel', gammaBandIndices, 'YLim', [-0.5 0.5], 'YTick', -0.5:0.1:0.5, 'XColor', 'none', 'YColor', 'r');
    ylabel(ax2, 'reconstructed settings - settings', 'FontSize', 16); 
    set(ax2, 'FontSize', 14);
    legend(ax1, {'settings ', 'SPD-reconstructed settings '}, 'FontSize', 16, 'FontName','Menlo', 'Orientation', 'Horizontal', 'Location', 'NorthWest'); 
    legend(ax2, {'interpolated', 'measured'}, 'FontSize', 16, 'FontName','Menlo', 'Orientation', 'Horizontal', 'Location', 'NorthEast'); 
    title(subplotTitle, 'FontSize', 18);
    drawnow;
end

