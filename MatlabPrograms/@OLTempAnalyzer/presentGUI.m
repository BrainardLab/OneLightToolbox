function presentGUI(obj)

    guiWidth = 1800;
    guiHeight = 1150;
    
    obj.gui.figHandle = figure('units','pixels',...
              'position',[10 1000 guiWidth guiHeight],...
              'menubar','none',...
              'name','One light temperature & spectral shift visualizer',...
              'numbertitle','off',...
              'resize','off');
          
    temperatureAxesWidth = 900;
    temperatureAxesHeight = 450;
    temperatureAxesXoffset = 50;
    temperatureAxesCalYoffset = 620;
    temperatureAxesTestYoffset = 40;
    
    obj.gui.calTemperatureAxes = axes(...
        'units','pixels',...
        'position',[temperatureAxesXoffset temperatureAxesCalYoffset temperatureAxesWidth temperatureAxesHeight],...
        'fontsize',16,...
        'Color', [1 1 1], ...,...
        'nextplot','replacechildren');
    
    obj.gui.testTemperatureAxes = axes(...
        'units','pixels',...
        'position',[temperatureAxesXoffset temperatureAxesTestYoffset temperatureAxesWidth temperatureAxesHeight],...
        'fontsize',16, ...
        'Color', [1 1 1], ...
        'nextplot','replacechildren');
    
    % Load new cal file pushbutton
    obj.gui.calFileNameLoadNew = uicontrol(...
        'style','push',...
        'units','pix',...
        'position',[temperatureAxesXoffset+0 temperatureAxesCalYoffset+temperatureAxesHeight+30 200 25],...
        'backgroundcolor', [1 1 0.9], ...
        'fontsize',14, 'fontweight','bold', ...
        'string','Load new cal file');

    
    obj.gui.calFileNameEditBox = uicontrol(...
        'style','edit',...
        'enable', 'inactive', ...
        'units','pixels',...
        'backgroundcolor', [1.0 1.0 0.9], ...
        'position',[temperatureAxesXoffset+200 temperatureAxesCalYoffset+temperatureAxesHeight+30 1310 25],...
        'fontsize',14, 'fontweight','bold', ...
        'string','');
    
    
    % Load new test file pushbutton
    obj.gui.testFileNameLoadNew = uicontrol(...
        'style','push',...
        'units','pix',...
        'position',[temperatureAxesXoffset+0 temperatureAxesTestYoffset+temperatureAxesHeight+30 200 25],...
        'backgroundcolor', [1 1.0 0.9], ...
        'fontsize',14, 'fontweight','bold', ...
        'string','Load new test file');
    
    % Set the callback
    set(obj.gui.testFileNameLoadNew ,'callback', {@loadNewFile, obj.gui.testFileNameLoadNew, obj});
    
    obj.gui.testFileNameEditBox = uicontrol(...
        'style','edit',...
        'enable', 'inactive', ...
        'units','pixels',...
        'backgroundcolor', [1.0 1.0 0.9], ...
        'position',[temperatureAxesXoffset+200  temperatureAxesTestYoffset+temperatureAxesHeight+30 1310 25],...
        'fontsize',14, 'fontweight','bold', ...
        'string','');
    
    obj.gui.calSpectraAxes = axes(...
        'units','pixels',...
        'position',[temperatureAxesXoffset+temperatureAxesWidth+200 temperatureAxesCalYoffset temperatureAxesWidth-300 temperatureAxesHeight],...
        'fontsize',16,...
        'Color', [1 1 1], ...,...
        'nextplot','replacechildren');
    
    obj.gui.testSpectraAxes = axes(...
        'units','pixels',...
        'position',[temperatureAxesXoffset+temperatureAxesWidth+200 temperatureAxesTestYoffset temperatureAxesWidth-300 temperatureAxesHeight],...
        'fontsize',16, ...
        'Color', [1 1 1], ...
        'nextplot','replacechildren');
    
    
    % The popup menu for the available calibration measurements
    obj.gui.availableCalsMenu = uicontrol('style','pop',...
                  'units','pixels',...
                  'position',[1560 temperatureAxesCalYoffset+temperatureAxesHeight+30 200 25],...
                  'backgroundcolor', [1 0.9 0.9], ...
                  'fontsize',14, 'fontweight','bold', ...
                  'string', obj.calData.DateStrings ... % last first
                  );
    set(obj.gui.availableCalsMenu, 'Value', numel(obj.calData.DateStrings));          
    
             
    % The popup menu for the available test measurements
    obj.gui.availableTestsMenu = uicontrol('style','pop',...
                  'units','pixels',...
                  'position',[1560 temperatureAxesTestYoffset+temperatureAxesHeight+30 200 25],...
                  'backgroundcolor', [1 0.9 0.9], ...
                  'fontsize',14, 'fontweight','bold', ...
                  'string', obj.testData.DateStrings ...  % last first
                  );
    set(obj.gui.availableTestsMenu, 'Value', numel(obj.testData.DateStrings));
     
    
    % The radio group for selecting spectral shifts vs. gain shifts as the secondary plot (for the calTemperature)
    radioButtonGroupPosition = [temperatureAxesXoffset+587 temperatureAxesCalYoffset-35 315 30];
    obj.gui.calTemperatureSecondaryPlotGroup = uibuttongroup('units','pix',...
        'position',radioButtonGroupPosition ...
    );
    
    obj.gui.calTemperatureSecondaryPlotGroupRadioButton(1) = uicontrol(...
        obj.gui.calTemperatureSecondaryPlotGroup,...
        'style','rad',...
        'unit','pix',...
        'fontsize',14, 'fontweight','bold', ...
        'position', [10 2 130 25],...
        'string','spectral shifts');
    
    obj.gui.calTemperatureSecondaryPlotGroupRadioButton(2) = uicontrol(...
        obj.gui.calTemperatureSecondaryPlotGroup,...
        'style','rad',...
        'unit','pix',...
        'position', [160 2 160 25],...
        'fontsize',14, 'fontweight','bold', ...
        'string','gain fluctuations');
   
    
    % The radio group for selecting spectral shifts vs. gain shifts as the secondary plot (for the testTemperature)
    radioButtonGroupPosition = [temperatureAxesXoffset+587 temperatureAxesTestYoffset-35 315 30];
    obj.gui.testTemperatureSecondaryPlotGroup = uibuttongroup('units','pix',...
        'position',radioButtonGroupPosition ...
    );
    
    obj.gui.testTemperatureSecondaryPlotGroupRadioButton(1) = uicontrol(...
        obj.gui.testTemperatureSecondaryPlotGroup,...
        'style','rad',...
        'unit','pix',...
        'fontsize',14, 'fontweight','bold', ...
        'position', [10 2 130 25],...
        'string','spectral shifts');
    
    obj.gui.testTemperatureSecondaryPlotGroupRadioButton(2) = uicontrol(...
        obj.gui.testTemperatureSecondaryPlotGroup,...
        'style','rad',...
        'unit','pix',...
        'position', [160 2 160 25],...
        'fontsize',14, 'fontweight','bold', ...
        'string','gain fluctuations');
    
    
    
% CALLBACKS

    % Set the callback
    set(obj.gui.calTemperatureSecondaryPlotGroupRadioButton(1) ,'callback', {@secondaryPlotDataSelector, obj.gui.availableCalsMenu, obj.gui.calTemperatureAxes, obj.gui.calFileNameEditBox, obj, 'calibration', 1});
    
    % Set the callback
    set(obj.gui.calTemperatureSecondaryPlotGroupRadioButton(2) ,'callback', {@secondaryPlotDataSelector, obj.gui.availableCalsMenu, obj.gui.calTemperatureAxes, obj.gui.calFileNameEditBox, obj, 'calibration', 2});
    
    
    % Set the callback
    set(obj.gui.testTemperatureSecondaryPlotGroupRadioButton(1) ,'callback', {@secondaryPlotDataSelector, obj.gui.availableTestsMenu, obj.gui.testTemperatureAxes, obj.gui.testFileNameEditBox, obj, 'test', 1});
   
    
    % Set the callback
    set(obj.gui.testTemperatureSecondaryPlotGroupRadioButton(2) ,'callback', {@secondaryPlotDataSelector, obj.gui.availableTestsMenu, obj.gui.testTemperatureAxes, obj.gui.testFileNameEditBox, obj, 'test', 2});
    
    
    % Set the callback for the calibration data set
    set(obj.gui.availableCalsMenu,'callback',{@dateEntrySelected, obj.gui.availableCalsMenu, obj.gui.calTemperatureSecondaryPlotGroupRadioButton(1), obj, 'calibration', obj.gui.calTemperatureAxes, obj.gui.calSpectraAxes, obj.gui.calFileNameEditBox}); 

    % Set the callback for the test data set
    set(obj.gui.availableTestsMenu,'callback',{@dateEntrySelected, obj.gui.availableTestsMenu, obj.gui.calTemperatureSecondaryPlotGroupRadioButton(1), obj, 'test', obj.gui.testTemperatureAxes, obj.gui.testSpectraAxes, obj.gui.testFileNameEditBox}); 
    
    % Set the callback
    set(obj.gui.calFileNameLoadNew ,'callback', {@loadNewFile, obj.gui.calFileNameLoadNew, obj.gui.calTemperatureSecondaryPlotGroupRadioButton(1), obj});
    
    % Plot the last measurements
    plotTemperatureData(obj, 'calibration', numel(obj.calData.DateStrings), obj.gui.calTemperatureAxes, obj.gui.calFileNameEditBox, 'spectral shift time series');
    plotTemperatureData(obj, 'test', numel(obj.testData.DateStrings), obj.gui.testTemperatureAxes, obj.gui.testFileNameEditBox, 'spectral shift time series');
    
    plotSpectralStabilityData(obj, 'calibration', numel(obj.calData.DateStrings), obj.gui.calSpectraAxes);
    plotSpectralStabilityData(obj, 'test', numel(obj.testData.DateStrings), obj.gui.testSpectraAxes);
    
end


function [] = secondaryPlotDataSelector(varargin)

    popupMenuHandle = varargin{3};
    
    % Which temperature plot axes
    temperaturePlotAxes = varargin{4};
    
    dataSetNameEditBox = varargin{5};
    
    % obj handle
    obj = varargin{6};
    
    % Which data set to display
    dataSet = varargin{7};
    
    % which secondary plot data set
    secondaryPlotIndex = varargin{8};
    
    % Get the entry to display
    d = get(popupMenuHandle,{'string','val'});
    entryIndex = d{2};
    
    if (secondaryPlotIndex == 1)
        plotTemperatureData(obj, dataSet, entryIndex, temperaturePlotAxes, dataSetNameEditBox, 'spectral shift time series');
    else
        plotTemperatureData(obj, dataSet, entryIndex, temperaturePlotAxes, dataSetNameEditBox, 'gain shift time series');
    end
end


function [] = dateEntrySelected(varargin)
    popupMenuHandle = varargin{3};
    
    radioButton1Handle = varargin{4};
    
    % obj handle
    obj = varargin{5};
    
    % Which data set to display
    dataSet = varargin{6};
    
    % Where to plot the data
    temperaturePlotAxes = varargin{7};
    spectraPlotAxes = varargin{8};
    
    % Where to display the data set file name
    dataSetNameEditBox = varargin{9};
    
    % Get the entry to display
    d = get(popupMenuHandle,{'string','val'});
    entryIndex = d{2};
    
    if (get(radioButton1Handle, 'value')==1)
        shiftDataSetName = 'spectral shift time series';
    else
        shiftDataSetName = 'gain shift time series';
    end
    plotTemperatureData(obj, dataSet, entryIndex, temperaturePlotAxes, dataSetNameEditBox, shiftDataSetName);
    plotSpectralStabilityData(obj, dataSet, entryIndex, spectraPlotAxes);
    
end


function [] = loadNewFile(varargin)
    
    % Push button handle
    pushbuttonHandle = varargin{3};  % Get the structure.
    
    radioButton1Handle = varargin{4};
    
    % obj handle
    obj = varargin{5};
    
    if (get(radioButton1Handle, 'value')==1)
        shiftDataSetName = 'spectral shift time series';
    else
        shiftDataSetName = 'gain shift time series';
    end
    
    buttonText = get(pushbuttonHandle,'string'); 
    if (strcmp(buttonText, 'Load new cal file'))
        fprintf('Load new cal file\n');
        [filename, pathname] = uigetfile({'*.mat'}, 'Select a calibration file', obj.defaultRootDir);
        idx = strfind(pathname, 'MELA_materials');
        filename = fullfile(pathname(idx(end)+numel('MELA_materials')+1:end), filename);
        obj.calibrationFile = filename;
        
        % Retrieve the data
        [obj.calData.allTemperatureData, obj.calData.stabilitySpectra, obj.calData.DateStrings, obj.calData.fullFileName] = obj.retrieveData(obj.calibrationFile, 'cals');
        
        % Update GUI
        plotTemperatureData(obj, 'calibration', numel(obj.calData.DateStrings), obj.gui.calTemperatureAxes, obj.gui.calFileNameEditBox, shiftDataSetName);
        plotSpectralStabilityData(obj, 'calibration', numel(obj.calData.DateStrings), obj.gui.calSpectraAxes);
 
    else
        fprintf('Load new testfile\n');
        
        % Update GUI
        plotTemperatureData(obj, 'test', numel(obj.testData.DateStrings), obj.gui.testTemperatureAxes, obj.gui.testFileNameEditBox, shiftDataSetName);
        plotSpectralStabilityData(obj, 'test', numel(obj.testData.DateStrings), obj.gui.testSpectraAxes);
    end
   
end

