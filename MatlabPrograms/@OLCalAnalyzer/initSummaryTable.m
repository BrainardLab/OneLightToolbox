function initSummaryTable(obj)

    obj.summaryTableFigure = figure(10000);
    set(obj.summaryTableFigure, 'MenuBar', 'none', 'Visible', 'off', 'Name', 'Summary', 'NumberTitle', 'off');
    % nan data
    d = [nan nan; nan nan; nan nan];

    % Create the column and row names in cell arrays 
    times = {'<html><font size="4"> Pre calibration </font></html>',...
             '<html><font size="4"> Post calibration </font></html>'};
         
    spdNames = {'<html><font size="4">dark measurements</font></html>',...
                '<html><font size="4">half ON measurements</font></html>', ...
                '<html><font size="4">full ON measurements</font></html>' ...
                };

    % Create the uitable
    obj.summaryTable = uitable(obj.summaryTableFigure, ...
        'Data',d,...
        'ColumnName', times,... 
        'RowName', spdNames);
    obj.summaryTable.FontName = 'Menlo';
    obj.summaryTable.FontSize = 16;
    
    % Set width and height
    obj.summaryTable.Position(3) = obj.summaryTable.Extent(3);
    obj.summaryTable.Position(4) = obj.summaryTable.Extent(4);
    
    set(obj.summaryTableFigure, 'Position',[440 500 obj.summaryTable.Position(3)*1.05 obj.summaryTable.Position(4)*1.5]);
    set(obj.summaryTableFigure, 'Visible', 'on');   
end

