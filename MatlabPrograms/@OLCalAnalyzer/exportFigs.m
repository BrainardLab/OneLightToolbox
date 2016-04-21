function exportFigs(obj, varargin)

    parser = inputParser;
    parser.addRequired('format', @ischar);
    
    % Execute the parser
    parser.parse(varargin{:});
    % Create a standard Matlab structure from the parser results.
    p = parser.Results;
    format = p.format;
    validatestring(format, {'png', 'pdf'});
    
    % Get all the figure names
    fnames = fieldnames(obj.figsList);
    
    % Go through each one and export the data
    for i = 1:length(fnames)
        if (~strncmp(fnames{i},'Compare',7))
            figName = [fnames{i} '_' obj.inputCalID];
        else
            figName = fnames{i};
        end
        figName = strrep(figName, ' ', '_');
        figName = strrep(figName, '-', '_');
        figName = strrep(figName, ':', '.');
        figHandle = obj.figsList.(fnames{i});
        imageFileName = fullfile(obj.figuresDir,figName);
        if (strcmp(format, 'png'))
            NicePlot.exportFigToPNG(imageFileName, figHandle, 300);
        else
            NicePlot.exportFigToPDF(imageFileName, figHandle, 300);
        end
        fprintf('[%02d] Exported file: %s.%s\n', i, imageFileName, format);
    end
end

