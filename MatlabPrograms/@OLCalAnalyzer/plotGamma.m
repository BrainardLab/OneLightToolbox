function plotGamma(obj, varargin)
    
    parser = inputParser;
    parser.addRequired('gammaType', @ischar);
    
    % Execute the parser
    parser.parse(varargin{:});
    % Create a standard Matlab structure from the parser results.
    p = parser.Results;
    
    % Get spd type and name
    gammaType = p.gammaType;
    
    % Validate spdType
    validatestring(gammaType, {'raw', 'computed'});
    
    % Validate that the queried field exists
    if strcmp(gammaType, 'computed')

            gammaInValues = obj.cal.computed.gammaInputRaw;
            gammaBandIndices = obj.cal.describe.gamma.gammaBands;
            
            % Set up progression gamma curves figure
            hFig = figure; clf;
            figurePrefix = sprintf('%s_GammaProgression', gammaType);
            obj.figsList.(figurePrefix) = hFig;
            set(hFig, 'Position', [10 1000 2520 1250], 'Name', figurePrefix);
            subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', 4, ...
               'colsNum', ceil(0.25*numel(gammaInValues)), ...
               'heightMargin',   0.03, ...
               'widthMargin',    0.02, ...
               'leftMargin',     0.03, ...
               'rightMargin',    0.01, ...
               'bottomMargin',   0.03, ...
               'topMargin',      0.02);
           
           for gammaPointIter = 1:numel(gammaInValues)
                row = 1 + floor((gammaPointIter-1)/size(subplotPosVectors,2));
                col = 1 + mod((gammaPointIter-1),size(subplotPosVectors,2));
                subplot('position',subplotPosVectors(row,col).v);
                
                gammaOutProgressionMeasured = squeeze(obj.cal.computed.gammaTableMeasuredBands(gammaPointIter,:));
                
                % Find the corresponding point in the fitted gamma curve
                [~, correspondingFittedGammaPointIter] = min(abs(gammaInValues(gammaPointIter) - obj.cal.computed.gammaInput));
                gammaOutProgressionFitted = squeeze(obj.cal.computed.gammaTableMeasuredBandsFit(correspondingFittedGammaPointIter,:));
                
                % Find the corresponding point in the interpolated gamma table
                gammaOutProgressionFittedAndInterpolatedAcrossBands = squeeze(obj.cal.computed.gammaTable(correspondingFittedGammaPointIter, :));
                
                hold on

                
                plot(gammaBandIndices, gammaOutProgressionMeasured, 'ko', ...
                    'MarkerSize', 16, 'MarkerFaceColor', [0.8 0.8 0.8], 'MarkerEdgeColor', [0.3 0.3 0.3], ...
                    'DisplayName', 'measured SPD scalars');
                
                
                plot(gammaBandIndices, gammaOutProgressionFitted, 'ko', ...
                    'MarkerSize', 12, 'MarkerFaceColor', [0.2 1.0 0.8], 'MarkerEdgeColor', [0.1 0.5 0.3], ...
                    'DisplayName', sprintf('fitted SPD scalars (%2.3f)', obj.cal.computed.gammaInput(correspondingFittedGammaPointIter)));
                
                plot(1:obj.cal.describe.numWavelengthBands, gammaOutProgressionFittedAndInterpolatedAcrossBands, 'ko', ...
                     'MarkerSize', 6, 'MarkerFaceColor', [0.4 0.7 1.0], 'MarkerEdgeColor', [0.1 0.4 1.0], ...
                    'DisplayName', sprintf('fitted&intep. SPD scalars (%2.3f)', obj.cal.computed.gammaInput(correspondingFittedGammaPointIter)));
                
                hold off
                
                % Finish plot  
                hL = legend('Location', 'North');
                hL.FontSize = 12;
                hL.FontName = 'Menlo';  
                
                box off
                set(gca, 'XTick', gammaBandIndices, 'XTickLabel', gammaBandIndices);
                set(gca, 'XLim', [0 obj.cal.describe.numWavelengthBands+1], 'YLim', mean(gammaOutProgressionMeasured) + [-0.05 0.05]);
                set(gca, 'FontSize', 12);
                if (row == size(subplotPosVectors,1))
                    xlabel('band index', 'FontSize', 14, 'FontWeight', 'bold');
                else
                    set(gca, 'XTickLabels', {});
                end
                
                if (col == 1)
                    ylabel('gamma out', 'FontSize', 14, 'FontWeight', 'bold');
                end
                titleLegend = sprintf('gamma in: %2.3f',gammaInValues(gammaPointIter));
                title(titleLegend, 'FontSize', 14);
           end
           

            % Set up individual gamma curves figure
            hFig = figure; clf;
            figurePrefix = sprintf('%s_GammaIndividual', gammaType);
            obj.figsList.(figurePrefix) = hFig;
            set(hFig, 'Position', [10 1000 1650 1280], 'Name', figurePrefix);

            subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', 4, ...
               'colsNum', round(0.25*numel(gammaBandIndices)), ...
               'heightMargin',   0.03, ...
               'widthMargin',    0.02, ...
               'leftMargin',     0.03, ...
               'rightMargin',    0.01, ...
               'bottomMargin',   0.03, ...
               'topMargin',      0.02);
           
            for bandIter = 1:numel(gammaBandIndices)
                row = 1 + floor((bandIter-1)/size(subplotPosVectors,2));
                col = 1 + mod((bandIter-1),size(subplotPosVectors,2));
                subplot('position',subplotPosVectors(row,col).v);
                
                titleLegend = sprintf('band %02d (computed SPD scaling factors)',gammaBandIndices(bandIter));
                hold on;
                plot(gammaInValues, obj.cal.computed.gammaTableMeasuredBands, 'k-', 'LineWidth', 2.0);
                gammaOutValues = obj.cal.computed.gammaTableMeasuredBands(:,bandIter);
                plot(gammaInValues, gammaOutValues, '-', 'Color', [1 0 0],  'LineWidth', 2.0);
                hold off;
                
                % Finish plot
                box off
                set(gca, 'XLim', [-0.02 1.02], 'YLim', [0 1]);
                set(gca, 'FontSize', 12);
                if (row == size(subplotPosVectors,1))
                    xlabel('gamma in', 'FontSize', 14, 'FontWeight', 'bold');
                end
                
                if (col == 1)
                    ylabel('gamma out', 'FontSize', 14, 'FontWeight', 'bold');
                else
                    set(gca, 'YTickLabels', {});
                end
                title(titleLegend, 'FontSize', 14);
            end % bandIter 
        
    elseif strcmp(gammaType, 'raw')
        error('Raw not yet implemented\n');
    end
    

    drawnow;
end

    