function plotGammaSPD(obj, varargin)
    
    parser = inputParser;
    parser.addRequired('gammaSPDType', @ischar);
    parser.addRequired('gammaSPDName', @ischar);

    % Execute the parser
    parser.parse(varargin{:});
    % Create a standard Matlab structure from the parser results.
    p = parser.Results;
    
    % Get spd type and name
    gammaSPDType = p.gammaSPDType;
    gammaSPDName = p.gammaSPDName;
    
    % Validate spdType
    validatestring(gammaSPDType, {'raw', 'computed'});
    
    % Validate that the queried field exists
    if strcmp(gammaSPDType, 'raw')
        if (~isfield(obj.cal.raw.gamma, gammaSPDName))
            error('\nDid not find field ''cal.raw.gamma.%s''. Nothing plotted for this query.\n', gammaSPDName);
        else
            % Set up figure
            hFig = figure; clf;
            figurePrefix = sprintf('%s_%s_GammaSPD', gammaSPDType, gammaSPDName);
            obj.figsList.(figurePrefix) = hFig;
            set(hFig, 'Position', [10 1000 1990 1060], 'Name', figurePrefix,  'Color', [1 1 1]);
            
            % Indices of bands for which we measured gamma data
            gammaBandIndices = obj.cal.describe.gamma.gammaBands;
            gammaLevels = obj.cal.describe.gamma.gammaLevels;
            meanDarkSPD = mean(obj.cal.raw.darkMeas,2);
            
            colors = jet(numel(gammaLevels));
            
            fprintf('Gammas were measured for these bands: %s\n', sprintf('%d ', gammaBandIndices));
            fprintf('Gammas were measured for these levels: %s\n', sprintf('%2.2f ', gammaLevels));
            
            subplotPosVectors = NicePlot.getSubPlotPosVectors(...
               'rowsNum', 4, ...
               'colsNum', round(0.5*numel(gammaBandIndices)), ...
               'heightMargin',   0.02, ...
               'widthMargin',    0.01, ...
               'leftMargin',     0.03, ...
               'rightMargin',    0.00, ...
               'bottomMargin',   0.01, ...
               'topMargin',      0.000);
            
            for bandIter = 1:numel(gammaBandIndices)
                
                %colsForGammaBand = find(squeeze(obj.cal.raw.gamma.cols(:, bandIter)) == 1);
                %fprintf('Mirror columns activated for gammaBand #%2d: %s\n', gammaBandIndices(bandIter), sprintf('%d ', colsForGammaBand));
               
                % Extract the desired spd data
                tmp = eval(sprintf('obj.cal.raw.gamma.%s(bandIter).meas', gammaSPDName));
                if (bandIter == 1)
                    gammaSPD = zeros(numel(gammaBandIndices), size(tmp,2), size(tmp,1));
                end
                gammaSPD(bandIter,:,:) = tmp';
                
                gain = 1000;
                % Unscaled data
                row = 1 + 2*floor((bandIter-1)/size(subplotPosVectors,2));
                col = 1 + mod((bandIter-1),size(subplotPosVectors,2));
                subplot('position',subplotPosVectors(row,col).v);
                hold on;
                for gammaIter = 1:numel(gammaLevels)
                    lineLegend = sprintf('gamma = %2.2f', gammaLevels(gammaIter));
                    if (obj.cal.describe.specifiedBackground)
                        gammaSPD(bandIter,gammaIter,:) = gammaSPD(bandIter,gammaIter,:) - reshape(obj.cal.raw.gamma.rad(bandIter).effectiveBgMeas, [1 1 numel(obj.cal.raw.gamma.rad(bandIter).effectiveBgMeas)]);
                    else
                        gammaSPD(bandIter,gammaIter,:) = gammaSPD(bandIter,gammaIter,:) - reshape(meanDarkSPD, [1 1 numel(meanDarkSPD)]);
                    end
                    plot(obj.waveAxis, gain*squeeze(gammaSPD(bandIter,gammaIter,:)), 'Color', colors(gammaIter,:), 'LineWidth', 1.0, 'DisplayName', lineLegend);
                end % gammaIter
                
                % Add legend
                % hL = legend('Location', 'WestOutside');  
                
                % Finish plot
                box off
                pbaspect([1 1 1])
                hL.FontSize = 12;
                hL.FontName = 'Menlo'; 
                yTicks = [0:10];
                set(gca, 'YTick', yTicks, 'YTickLabel', sprintf('%2.1f\n', yTicks));
                set(gca, 'XLim', [obj.waveAxis(1)-5 obj.waveAxis(end)+5], 'YLim', [0 10]);
                set(gca, 'FontSize', 12);
                %xlabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
                if (col == 1)
                    ylabel('power (mW/sr/m2/nm)', 'FontSize', 14, 'FontWeight', 'bold');
                else
                    set(gca, 'YTick', []);
                end
                title(sprintf('unscaled SPD (band: %d)', gammaBandIndices(bandIter)));
                
                
                % Scaled data
                row = 2 + 2*floor((bandIter-1)/size(subplotPosVectors,2));
                col = 1 + mod((bandIter-1),size(subplotPosVectors,2));
                subplot('position',subplotPosVectors(row,col).v);
                hold on;
                for gammaIter = 1:numel(gammaLevels)
                    lineLegend = sprintf('gamma = %2.2f', gammaLevels(gammaIter));
                    scaledSPD = squeeze(gammaSPD(bandIter, gammaIter,:)) / obj.cal.computed.gammaData1{bandIter}(gammaIter);
                    plot(obj.waveAxis, gain*scaledSPD, 'Color', colors(gammaIter,:), 'LineWidth', 1.0, 'DisplayName', lineLegend);
                end % gammaIter
                
                %hL = legend('Location', 'WestOutside');  
                % Finish plot
                box off
                pbaspect([1 1 1])
                hL.FontSize = 12;
                hL.FontName = 'Menlo';       
                set(gca, 'XLim', [obj.waveAxis(1)-5 obj.waveAxis(end)+5], 'YLim', [0 10]);
                set(gca, 'FontSize', 12);
                set(gca, 'YTick', yTicks, 'YTickLabel', sprintf('%2.1f\n', yTicks));
                if (col == 1)
                    ylabel('power (mW/sr/m2/nm)', 'FontSize', 14, 'FontWeight', 'bold');
                else
                    set(gca, 'YTick', []);
                end
                title(sprintf('scaled SPD (band: %d)', gammaBandIndices(bandIter)));
                
            end % bandIter
        end % isfield
    else
        error('Not implemented gammaSPDType: %s\n', gammaSPDType)
    end   
end

