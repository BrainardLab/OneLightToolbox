function plotGamma(obj, varargin)
    
    parser = inputParser;
    parser.addRequired('gammaType', @ischar);
    parser.addParameter('plotRatios', false, @islogical);
    
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

%         % Set up progression gamma curves figure
%         hFig = figure; clf;
%         figurePrefix = sprintf('%s_GammaProgression', gammaType);
%         obj.figsList.(figurePrefix) = hFig;
%         set(hFig, 'Position', [10 1000 2520 1250], 'Name', figurePrefix,  'Color', [1 1 1]);
%         subplotPosVectors = NicePlot.getSubPlotPosVectors(...
%            'rowsNum', 4, ...
%            'colsNum', ceil(0.25*numel(gammaInRawValues)), ...
%            'heightMargin',   0.03, ...
%            'widthMargin',    0.02, ...
%            'leftMargin',     0.03, ...
%            'rightMargin',    0.01, ...
%            'bottomMargin',   0.03, ...
%            'topMargin',      0.02);
% 
%        for gammaPointIter = 1:numel(gammaInRawValues)
%             row = 1 + floor((gammaPointIter-1)/size(subplotPosVectors,2));
%             col = 1 + mod((gammaPointIter-1),size(subplotPosVectors,2));
%             subplot('position',subplotPosVectors(row,col).v);
% 
%             gammaOutProgressionMeasured = squeeze(obj.cal.computed.gammaTableMeasuredBands(gammaPointIter,:));
% 
%             % Find the corresponding point in the fitted gamma curve
%             [~, correspondingFittedGammaPointIter] = min(abs(gammaInRawValues(gammaPointIter) - obj.cal.computed.gammaInput));
%             gammaOutProgressionFitted = squeeze(obj.cal.computed.gammaTableMeasuredBandsFit(correspondingFittedGammaPointIter,:));
% 
%             % Find the corresponding point in the interpolated gamma table
%             gammaOutProgressionFittedAndInterpolatedAcrossBands = squeeze(obj.cal.computed.gammaTable(correspondingFittedGammaPointIter, :));
% 
%             hold on
%             plot(gammaBandIndices, 100*gammaOutProgressionMeasured, 'ko', ...
%                 'MarkerSize', 16, 'MarkerFaceColor', [0.8 0.8 0.8], 'MarkerEdgeColor', [0.3 0.3 0.3], ...
%                 'DisplayName', 'measured SPD scalars');
% 
%             plot(gammaBandIndices, 100*gammaOutProgressionFitted, 'ko', ...
%                 'MarkerSize', 12, 'MarkerFaceColor', [0.2 1.0 0.8], 'MarkerEdgeColor', [0.1 0.5 0.3], ...
%                 'DisplayName', 'fitted SPD scalars');
% 
%             plot(1:obj.cal.describe.numWavelengthBands, 100*gammaOutProgressionFittedAndInterpolatedAcrossBands, 'ko', ...
%                  'MarkerSize', 6, 'MarkerFaceColor', [0.4 0.7 1.0], 'MarkerEdgeColor', [0.1 0.4 1.0], ...
%                  'DisplayName', 'fitted & band-intep. SPD scalars');
%             hold off
% 
%             % Finish plot  
%             hL = legend('Location', 'North');
%             hL.FontSize = 12;
%             hL.FontName = 'Menlo';  
% 
%             box off
%             set(gca, 'XTick', gammaBandIndices, 'XTickLabel', gammaBandIndices, 'YTick', [0:1:100]);
%             set(gca, 'XLim', [0 obj.cal.describe.numWavelengthBands+1], 'YLim', round(mean(gammaOutProgressionMeasured)*100) + [-3 3]);
%             set(gca, 'FontSize', 12);
%             if (row == size(subplotPosVectors,1))
%                 xlabel('band index', 'FontSize', 14, 'FontWeight', 'bold');
%             else
%                 set(gca, 'XTickLabels', {});
%             end
% 
%             if (col == 1)
%                 ylabel('gamma out (%)', 'FontSize', 14, 'FontWeight', 'bold');
%             end
%             titleLegend = sprintf('gamma in: %2.3f',gammaInRawValues(gammaPointIter));
%             title(titleLegend, 'FontSize', 14);
%        end

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
            if (obj.cal.describe.useAverageGamma)
                plot(gammaInValues, obj.cal.computed.gammaTableAvg,'k-', 'LineWidth', 3.0, 'Color', [0.8 1.0 0.2],  'DisplayName', 'average gamma SPD scalars (used)');
                plot(gammaInValues, obj.cal.computed.gammaTableMeasuredBandsFit(:,bandIter), 'k:', 'LineWidth', 2.0, 'Color', [0.2 1.0 0.8],  'DisplayName', 'fitted SPD scalars (not used)');
            else
                plot(gammaInValues, obj.cal.computed.gammaTableMeasuredBandsFit(:,bandIter), 'k-', 'LineWidth', 3.0, 'Color', [0.2 1.0 0.8],  'DisplayName', 'fitted SPD scalars (used)');
                plot(gammaInValues, obj.cal.computed.gammaTableAvg,'k:', 'LineWidth', 2.0, 'Color', [0.8 1.0 0.2],  'DisplayName', 'average gamma SPD scalars (not used)');
            end
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
    
    if (p.plotRatios)
        % Plot ratios figures
        for gammaBandIter = 1: size(obj.cal.computed.gammaTableMeasuredBands,2)

            hFig = figure; clf;
            figurePrefix = sprintf('%s_GammaScalarsBandNo%d', gammaType, gammaBandIndices(gammaBandIter));
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

            for gammaInputIter = 1:numel(gammaInRawValues)

                row = 1 + floor((gammaInputIter-1)/size(subplotPosVectors,2));
                col = 1 + mod((gammaInputIter-1),size(subplotPosVectors,2));
                subplot('position',subplotPosVectors(row,col).v);

                plot([obj.waveAxis(1) obj.waveAxis(end)], obj.cal.computed.gammaTableMeasuredBands(gammaInputIter,gammaBandIter)*[1 1], 'r-', 'LineWidth', 2.0);
                hold on
                [~, correspondingFittedGammaPointIter] = min(abs(gammaInRawValues(gammaInputIter) - obj.cal.computed.gammaInput));
                plot([obj.waveAxis(1) obj.waveAxis(end)], obj.cal.computed.gammaTableMeasuredBandsFit(correspondingFittedGammaPointIter,gammaBandIter)*[1 1], 'b--', 'LineWidth', 2.0);
                plot(obj.cal.computed.gammaRatios(gammaBandIter,gammaInputIter).wavelengths, obj.cal.computed.gammaRatios(gammaBandIter,gammaInputIter).ratios, 'ks-', 'LineWidth', 1.5);
                plot(obj.waveAxis, obj.cal.computed.pr650M(:,gammaBandIndices(gammaBandIter))/max(squeeze(obj.cal.computed.pr650M(:,gammaBandIndices(gammaBandIter))))*0.2 + obj.cal.computed.gammaTableMeasuredBands(gammaInputIter,gammaBandIter)-0.1, 'b-', 'LineWidth', 1.5, 'Color', [0.3 0.3 0.3]);
                hold off

                set(gca, 'XLim', [obj.waveAxis(1) obj.waveAxis(end)], 'YLim', obj.cal.computed.gammaTableMeasuredBands(gammaInputIter,gammaBandIter)+[-0.1 0.1]);
                hL = legend({'uni-spectral ratio', 'uni-spectral ratio (fit)', 'wavelength-by-wavelength ratios'});
                title(sprintf('gamma in: %2.3f (band: %d)', gammaInRawValues(gammaInputIter), gammaBandIndices(gammaBandIter)));
            end
            drawnow
        end  % gammaBandIter
        
        genVideo = false;
        if (genVideo)
            % Generate ratios video

            % Open video stream
            videoFilename = sprintf('%s_Ratios.m4v', gammaType);
            writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
            writerObj.FrameRate = 15; 
            writerObj.Quality = 100;
            writerObj.open();

            hFig = figure; clf;
            figurePrefix = sprintf('%s_GammaScalarsVideoFig', gammaType);
            obj.figsList.(figurePrefix) = hFig;
            set(hFig, 'Position', [10 1000 1024 768], 'Name', figurePrefix,  'Color', [1 1 1]);


            for gammaBandIter = 1:size(obj.cal.computed.gammaTableMeasuredBands,1)

                gammaOutMax = squeeze(obj.cal.raw.gamma.rad(gammaBandIter).meas(:, end)) - obj.cal.computed.pr650MeanDark;
                gammaOutMax(gammaOutMax<0) = 0;

                if (max(gammaOutMax) > 0)
                   threshold = 1/100;
                   localUnispectralRatioWaveIndices = find(gammaOutMax/max(gammaOutMax)>threshold);
                else
                   localUnispectralRatioWaveIndices = [];
                end

                for gammaInputIter = 1:numel(gammaInRawValues)

                    gammaComputedScalar = obj.cal.computed.gammaTableMeasuredBands(gammaInputIter,gammaBandIter);
                    ratiosRange = gammaComputedScalar+[-0.2 0.2];

                    if (gammaInputIter == 1)
                        gammaOutAtThisLevel = obj.cal.computed.pr650MeanDark*0.0;
                    else
                        gammaOutAtThisLevel = squeeze(obj.cal.raw.gamma.rad(gammaBandIter).meas(:, gammaInputIter-1)) - obj.cal.computed.pr650MeanDark;
                        gammaOutAtThisLevel(gammaOutAtThisLevel<0) = 0;
                    end
                    ratiosAtIndividualWavelengths = gammaOutAtThisLevel * 0;
                    idx = find(gammaOutMax>0);
                    ratiosAtIndividualWavelengths(idx) = gammaOutAtThisLevel(idx) ./ gammaOutMax(idx);
                    ratiosAtIndividualWavelengths(ratiosAtIndividualWavelengths>ratiosRange(2)) = ratiosRange(2);
                    ratiosAtIndividualWavelengths(ratiosAtIndividualWavelengths<ratiosRange(1)) = ratiosRange(1);

                    x = [obj.waveAxis(1) obj.waveAxis' obj.waveAxis(end)];
                    y = [0 0.985*gammaOutMax'/max(gammaOutMax) 0];

                    clf;
                    subplot('Position', [0.06 0.06, 0.66 0.93]);

                    patch(x,y, 'green', 'FaceColor', [0.3 0.8 0.9], 'EdgeColor', [0.2 0.2 0.2], 'EdgeAlpha', 0.5, 'LineWidth', 2.0);
                    hold on;
                    plot([obj.waveAxis(1) obj.waveAxis(end)], gammaComputedScalar*[1 1], 'b-', 'Color', [0 0 1 0.5], 'LineWidth', 2.0);
                    if (~isempty(localUnispectralRatioWaveIndices))
                        plot(obj.waveAxis(localUnispectralRatioWaveIndices), ratiosAtIndividualWavelengths(localUnispectralRatioWaveIndices), 'rs', 'MarkerFaceColor', [1 0 0], 'MarkerSize', 6, 'LineWidth', 1.0);
                    end
                    %plot(obj.waveAxis, gammaOutMax/max(gammaOutMax), 'b-', 'LineWidth', 2.0);
                    hold off

                    set(gca, 'XTick', [300:50:900], 'YTick', [0:0.2:1.0]);
                    set(gca, 'XLim', [obj.waveAxis(1) obj.waveAxis(end)], 'YLim', [0 1]);
                    set(gca, 'FontSize', 14);
                    grid on
                    box on
                    xlabel('wavelength (nm)', 'FontSize', 18, 'FontWeight', 'bold');
                    ylabel('SPD  power ratio (gamma out)',  'FontSize', 18, 'FontWeight', 'bold');
                    if (gammaBandIndices(gammaBandIter) < 27)
                        legendLocation = 'SouthEast';
                    else
                        legendLocation = 'SouthWest';
                    end

                    hL = legend({sprintf('band %d spd (normalized)', gammaBandIndices(gammaBandIter)), sprintf('uni-spectral ratio (gamma in: %2.3f)', gammaInRawValues(gammaInputIter)), 'wavelength-by-wavelength ratios'}, 'Location', legendLocation);
                    hL.FontSize = 14;
                    hL.FontName = 'Menlo'; 

                    subplot('Position', [0.745 0.06, 0.25 0.93]);
                    plot(gammaInRawValues(1:gammaInputIter), obj.cal.computed.gammaTableMeasuredBands(1:gammaInputIter,gammaBandIter), 'bo-', 'LineWidth', 2.0, 'MarkerSize', 14, 'MarkerFaceColor', [0.5 0.5 1.0]);
                    hold on
                    if (~isempty(localUnispectralRatioWaveIndices))
                        plot(gammaInRawValues(gammaInputIter), ratiosAtIndividualWavelengths(localUnispectralRatioWaveIndices), 'rs', 'MarkerFaceColor', [1 0 0], 'MarkerSize', 6, 'LineWidth', 1.0);
                    end
                    hold off
                    set(gca, 'XLim', [0 1], 'YLim', [0 1]);
                    set(gca, 'FontSize', 14);
                    xlabel('gamma in', 'FontSize', 18, 'FontWeight', 'bold');
                    ylabel('',  'FontSize', 18, 'FontWeight', 'bold');
                    set(gca, 'XTick', [0:0.2:1.0], 'YTick', [0:0.2:1.0], 'YTickLabel', {});
                    grid on
                    box on
                    drawnow;
                    writerObj.writeVideo(getframe(hFig));
                end
            end
            % Close video stream
            writerObj.close();
        end % genVideo
    end  % plotRatios
end

    