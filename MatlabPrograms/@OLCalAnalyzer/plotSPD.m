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
    validatestring(spdType, {'raw', 'computed'});
    spdName = p.spdName;
    
    % Get band indices to plot 
    bandIndicesToPlot = p.bandIndicesToPlot;
    
    % Validate that the queried field exists
    if strcmp(spdType, 'raw')
        if (~isfield(obj.inputCal.raw, spdName))
            fprintf(2, 'Did not find field ''obj.inputCal.raw.%s''. Nothing plotted for this query.', spdName);
            return;
        else
            % Extract the desired spd data
            spd = eval(sprintf('obj.inputCal.raw.%s', spdName));
        end
    elseif strcmp(spdType, 'computed')
        if (~isfield(obj.inputCal.computed, spdName))
            fprintf(2, 'Did not find field ''obj.inputCal.computed.%s''. Nothing plotted for this query.', spdName);
            return;
        else
            % Extract the desired spd data
            spd = eval(sprintf('obj.inputCal.computed.%s', spdName));
            size(spd)
            if (~isempty(bandIndicesToPlot))
                spd = spd(:, bandIndicesToPlot);
            end
            size(spd)
        end
    end
    
    
    % Set up figure
    hFig = figure; clf; 
    obj.figsList.(spdName) = hFig;
    set(hFig, 'Color', [1 1 1], 'Position', [10 1000 530 520]);
    subplot('Position', [0.08 0.08 0.91 0.91]);
    
    if strcmp(spdType, 'raw')
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

            otherwise
                fprintf('Unknown raw spd name: %s', spdName);
        end
    end
    
    % Plot
    if strcmp(spdType, 'raw')
        plot(obj.waveAxis, spd(:,1), 'r-', 'LineWidth', 2.0);
        hold on;
        plot(obj.waveAxis, spd(:,2), 'b-', 'LineWidth', 2.0);
    else
        colors = jet(size(spd,2));
        hold on;
        for bandIndex = 1:size(spd,2)
            plot(obj.waveAxis, spd(:,bandIndex), '-', 'Color', colors(bandIndex,:), 'LineWidth', 2.0);
        end
    end
    
    
    if strcmp(spdType, 'raw')
        % legend
        hL = legend(...
            sprintf('%s pre-calibration  (lum: %2.2f cd/m2)',spdName, preLum), ...
            sprintf('%s post-calibration (lum: %2.2f cd/m2)',spdName, postLum), ...
            'Location', 'NorthOutside');
    else
        if (~isempty(bandIndicesToPlot))
            hL = legend(sprintf('%d\n', bandIndicesToPlot), 'Location', 'NorthOutside');
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
