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

            gammaInRawValues = obj.cal.computed.gammaInputRaw;
            gammaInValues = obj.cal.computed.gammaInput;
            gammaBandIndices = obj.cal.describe.gamma.gammaBands;
            
            % Set up progression gamma curves figure
            hFig = figure; clf;
            figurePrefix = sprintf('%s_GammaProgression', gammaType);
            obj.figsList.(figurePrefix) = hFig;
            set(hFig, 'Position', [10 1000 2520 1250], 'Name', figurePrefix,  'Color', [1 1 1]);
            subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', 4, ...
               'colsNum', ceil(0.25*numel(gammaInRawValues)), ...
               'heightMargin',   0.03, ...
               'widthMargin',    0.02, ...
               'leftMargin',     0.03, ...
               'rightMargin',    0.01, ...
               'bottomMargin',   0.03, ...
               'topMargin',      0.02);
           
           for gammaPointIter = 1:numel(gammaInRawValues)
                row = 1 + floor((gammaPointIter-1)/size(subplotPosVectors,2));
                col = 1 + mod((gammaPointIter-1),size(subplotPosVectors,2));
                subplot('position',subplotPosVectors(row,col).v);
                
                gammaOutProgressionMeasured = squeeze(obj.cal.computed.gammaTableMeasuredBands(gammaPointIter,:));
                
                % Find the corresponding point in the fitted gamma curve
                [~, correspondingFittedGammaPointIter] = min(abs(gammaInRawValues(gammaPointIter) - obj.cal.computed.gammaInput));
                gammaOutProgressionFitted = squeeze(obj.cal.computed.gammaTableMeasuredBandsFit(correspondingFittedGammaPointIter,:));
                
                % Find the corresponding point in the interpolated gamma table
                gammaOutProgressionFittedAndInterpolatedAcrossBands = squeeze(obj.cal.computed.gammaTable(correspondingFittedGammaPointIter, :));
                
                hold on
                plot(gammaBandIndices, 100*gammaOutProgressionMeasured, 'ko', ...
                    'MarkerSize', 16, 'MarkerFaceColor', [0.8 0.8 0.8], 'MarkerEdgeColor', [0.3 0.3 0.3], ...
                    'DisplayName', 'measured SPD scalars');
                
                plot(gammaBandIndices, 100*gammaOutProgressionFitted, 'ko', ...
                    'MarkerSize', 12, 'MarkerFaceColor', [0.2 1.0 0.8], 'MarkerEdgeColor', [0.1 0.5 0.3], ...
                    'DisplayName', 'fitted SPD scalars');
                
                plot(1:obj.cal.describe.numWavelengthBands, 100*gammaOutProgressionFittedAndInterpolatedAcrossBands, 'ko', ...
                     'MarkerSize', 6, 'MarkerFaceColor', [0.4 0.7 1.0], 'MarkerEdgeColor', [0.1 0.4 1.0], ...
                     'DisplayName', 'fitted & band-intep. SPD scalars');
                hold off
                
                % Finish plot  
                hL = legend('Location', 'North');
                hL.FontSize = 12;
                hL.FontName = 'Menlo';  
                
                box off
                set(gca, 'XTick', gammaBandIndices, 'XTickLabel', gammaBandIndices, 'YTick', [0:1:100]);
                set(gca, 'XLim', [0 obj.cal.describe.numWavelengthBands+1], 'YLim', round(mean(gammaOutProgressionMeasured)*100) + [-3 3]);
                set(gca, 'FontSize', 12);
                if (row == size(subplotPosVectors,1))
                    xlabel('band index', 'FontSize', 14, 'FontWeight', 'bold');
                else
                    set(gca, 'XTickLabels', {});
                end
                
                if (col == 1)
                    ylabel('gamma out (%)', 'FontSize', 14, 'FontWeight', 'bold');
                end
                titleLegend = sprintf('gamma in: %2.3f',gammaInRawValues(gammaPointIter));
                title(titleLegend, 'FontSize', 14);
           end
           

            % Set up individual gamma curves figure
            hFig = figure; clf;
            figurePrefix = sprintf('%s_GammaIndividual', gammaType);
            obj.figsList.(figurePrefix) = hFig;
            set(hFig, 'Position', [10 1000 1875 1280], 'Name', figurePrefix,  'Color', [1 1 1]);

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
                
                titleLegend = sprintf('band %02d',gammaBandIndices(bandIter));
                hold on;
                plot(gammaInRawValues, obj.cal.computed.gammaTableMeasuredBands(:,bandIter), 'ko', 'MarkerSize', 14, 'MarkerFaceColor', [0.8 0.8 0.8], 'MarkerEdgeColor', [0.3 0.3 0.3], 'DisplayName', 'measured SPD scalars');           
                plot(gammaInValues, obj.cal.computed.gammaTableMeasuredBandsFit(:,bandIter), 'k-', 'LineWidth', 3.0, 'Color', [0.2 1.0 0.8],  'DisplayName', 'fitted SPD scalars');
                hold off;
                
                % Finish plot  
                hL = legend('Location', 'NorthWest');
                hL.FontSize = 12;
                hL.FontName = 'Menlo';  
                
                box off
                set(gca, 'XLim', [-0.02 1.02], 'YLim', [0 1]);
                set(gca, 'FontSize', 12);
                tickValues = gammaInRawValues(2:2:end-1);
                tickLabels = sprintf('%2.2f\n', tickValues);
                set(gca, 'XTick', tickValues, 'XTickLabel', tickLabels);
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

    