function plotSPD(obj,varargin)

    defaultBandIndices = [];
    
    parser = inputParser;
    parser.addRequired('spdType', @ischar);
    parser.addRequired('spdName', @ischar);
    parser.addParameter('bandIndicesToPlot', defaultBandIndices, @isnumeric);
    
    % Execute the parser
    parser.parse(varargin{:});
    % Create a standard Matlab structure from the parser results.
    p = parser.Results;
    
    % Get spd type and name
    spdType = p.spdType;
    spdName = p.spdName;
    
    % Validate spdType
    validatestring(spdType, {'raw', 'computed'});
    
    % Get band indices to plot 
    bandIndicesToPlot = p.bandIndicesToPlot;
    
    % Validate that the queried field exists
    if strcmp(spdType, 'raw')
        if (~isfield(obj.cal.raw, spdName))
            error('\nDid not find field ''cal.raw.%s''. Nothing plotted for this query.\n', spdName);
        else
            % Extract the desired spd data
            spd = eval(sprintf('obj.cal.raw.%s', spdName));
        end
    elseif strcmp(spdType, 'computed')
        if (~isfield(obj.cal.computed, spdName))
            error('\nDid not find field ''cal.computed.%s''. Nothing plotted for this query.\n', spdName);
        else
            % Extract the desired spd data
            spd = eval(sprintf('obj.cal.computed.%s', spdName));
        end
    end
    
    % If bandIndicedToPlot is non-empty, plot only those indices
    if (~isempty(bandIndicesToPlot))
       spd = spd(:, bandIndicesToPlot);
    end
            
    % Set up figure
    hFig = figure; clf;
    if (isempty(bandIndicesToPlot))
        figurePrefix = sprintf('%s_%s', spdType, spdName);
    else
        figurePrefix = sprintf('%s_%s_select_bands', spdType, spdName);
    end
    obj.figsList.(figurePrefix) = hFig;
    set(hFig, 'Name', figurePrefix, 'Color', [1 1 1], 'Position', [10 1000 530 520]);
    subplot('Position', [0.08 0.08 0.91 0.91]);

    % Plot
    if ( (strcmp(spdName, 'darkMeas')) || (strcmp(spdName, 'halfOnMeas')) || (strcmp(spdName, 'fullOn')) )
        switch spdName 
            case 'darkMeas'  
                preLum = obj.summaryData.darkLumPre;
                postLum  = obj.summaryData.darkLumPost;
            case 'halfOnMeas'
                preLum = obj.summaryData.halfOnLumPre;
                postLum  = obj.summaryData.halfOnLumPost;
            case 'fullOn'
                preLum = obj.summaryData.fullOnLumPre;
                postLum  = obj.summaryData.fullOnLumPost;
        end
        
        plot(obj.waveAxis, spd(:,1), 'r-', 'LineWidth', 2.0);
        hold on;
        plot(obj.waveAxis, spd(:,2), 'b-', 'LineWidth', 2.0);
        
        % legend
        hL = legend(...
            sprintf('%s pre-calibration  (lum: %2.2f cd/m2)',spdName, preLum), ...
            sprintf('%s post-calibration (lum: %2.2f cd/m2)',spdName, postLum), ...
            'Location', 'NorthOutside');
    else
        colors = jet(size(spd,2));
        hold on;
        for bandIter = 1:size(spd,2)
            if (~isempty(bandIndicesToPlot))
                lineLegend = sprintf('band %02d (%s)',bandIndicesToPlot(bandIter), spdType);
            else
                lineLegend = '';
            end
            plot(obj.waveAxis, spd(:,bandIter), '-', 'Color', colors(bandIter,:), 'LineWidth', 2.0, 'DisplayName', lineLegend);
        end
        
        if (~isempty(bandIndicesToPlot))
            hL = legend('Location', 'NorthOutside');
        end
    end
    
    % Finish plot
    box off
    pbaspect([1 1 1])
    hL.FontSize = 12;
    hL.FontName = 'Menlo';       
    set(gca, 'XLim', [obj.waveAxis(1)-5 obj.waveAxis(end)+5], 'YLim', [0 max(spd(:))]);
    set(gca, 'FontSize', 12);
    xlabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('power', 'FontSize', 14, 'FontWeight', 'bold');
    drawnow;
end
