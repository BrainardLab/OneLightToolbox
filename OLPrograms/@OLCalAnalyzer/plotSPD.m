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
            if (strcmp(spdName, 'wigglyMeas'))
                spd = eval(sprintf('obj.cal.raw.%s.measSpd', spdName));
            else
                spd = eval(sprintf('obj.cal.raw.%s', spdName));
            end
            size(spd)
        end
    elseif strcmp(spdType, 'computed')
        if (~isfield(obj.cal.computed, spdName))
            error('\nDid not find field ''cal.computed.%s''. Nothing plotted for this query.\n', spdName);
        else
            % Extract the desired spd data
            if (strcmp(spdName, 'wigglyMeas'))
                spd = eval(sprintf('obj.cal.computed.%s.measSpd', spdName));
            else
                spd = eval(sprintf('obj.cal.computed.%s', spdName));
            end
            size(spd)
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
    set(hFig, 'Name', figurePrefix, 'Color', [1 1 1], 'Position', [10 1000 1000 520]);
    

    % Plot
    if ( (strcmp(spdName, 'darkMeas')) || (strcmp(spdName, 'wigglyMeas')) || (strcmp(spdName, 'halfOnMeas')) || (strcmp(spdName, 'fullOn')) )
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
            case 'wigglyMeas' 
                obj.summaryData
                preLum = obj.summaryData.wigglyLumPre;
                postLum  = obj.summaryData.wigglyLumPost;
        end
        
        
        % The ratios plot
        subplot('Position', [0.53 0.08 0.45 0.91]);
        plot(obj.waveAxis, spd(:,1) ./ spd(:,end), 'k-');
        title(sprintf('%s %s', spdType, spdName));
        box off
        pbaspect([1 1 1])      
        set(gca, 'XLim', [obj.waveAxis(1)-5 obj.waveAxis(end)+5], 'YLim', [0.3 3]);
        set(gca, 'FontSize', 12);
        xlabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
        ylabel('pre- : post-calibration spd ratio', 'FontSize', 14, 'FontWeight', 'bold');
    
        subplot('Position', [0.04 0.08 0.45 0.91]);
        plot(obj.waveAxis, spd(:,1), 'r-', 'LineWidth', 2.0);
        hold on;
        plot(obj.waveAxis, spd(:,end), 'b-', 'LineWidth', 2.0);
        % legend
        hL = legend(...
            sprintf('%s pre-calibration, %s  (lum: %2.2f cd/m2)',spdType, spdName, preLum), ...
            sprintf('%s post-calibration, %s (lum: %2.2f cd/m2)',spdType, spdName, postLum), ...
            'Location', 'NorthOutside');
        
    else
        subplot('Position', [0.04 0.08 0.45 0.91]);
        colors = jet(size(spd,2));
        hold on;
        for bandIter = 1:size(spd,2)
            if (~isempty(bandIndicesToPlot))
                lineLegend = sprintf('band %02d, %s',bandIndicesToPlot(bandIter), spdType);
            else
                lineLegend = '';
            end
            plot(obj.waveAxis, spd(:,bandIter), '-', 'Color', colors(bandIter,:), 'LineWidth', 1.0, 'DisplayName', lineLegend);
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
