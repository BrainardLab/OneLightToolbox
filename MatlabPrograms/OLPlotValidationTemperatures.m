function OLPlotValidationTemperatures

% Cal type to look for
theTargetCalType = 'BoxDRandomizedLongCableAEyePiece2_ND03';

% Where MELA_materials is located
rootDir = '/Users1/DropBoxLinks/DropboxAguirreBrainardLabs/MELA_materials';

% Query user to select a cache file
[theValidationCacheFile, pathName] = uigetfile('*.mat', 'Select a cache file to open', rootDir);
s = load(fullfile(pathName,theValidationCacheFile));

% Check wether that file contains theTargetCalType
availableCalTypes = fieldnames(s);
if (~ismember(theTargetCalType, availableCalTypes))
    fprintf(2,'T''%s'' cal type not found in ''%s''.\n', theTargetCalType, fullfile(pathName,theValidationCacheFile));
    fprintf(2,'Cal types found:\n');
    for k = 1:numel(availableCalTypes)
        fprintf(2,'%d: ''%s''\n', k, availableCalTypes{k});
    end
    return
end
s = s.(theTargetCalType);

% Attempt to extract temperature data
for measurementIndex = 1:numel(s)
    theMeasurementData = s{measurementIndex};
    if (isfield(theMeasurementData, 'temperatureData'))
        allTemperatureData(measurementIndex,:,:,:) = theMeasurementData.temperatureData.modulationAllMeas;
    else
        fprintf(2,'There were no temperature data in ''%s''.\n', fullfile(pathName,theValidationCacheFile));
        theMeasurementData
        return;
    end
end
clear 's'

% Compute temperature range
tempRange = [floor(min(allTemperatureData(:)))-1 ceil(max(allTemperatureData(:)))+1];

% Plot data
hFig = figure(1); clf;
set(hFig, 'Position', [10 10 1150 540]);
scriptName = 'OLCorrectCacheFileOOC';

for measurementIndex = 1:size(allTemperatureData,1)
    theTemperatureData = squeeze(allTemperatureData(measurementIndex,:,:,:));
    theOneLightTemp = [];
    theAmbientTemp = [];
    for iter = 1:size(theTemperatureData,1)
        for iPowerLevel = 1:size(theTemperatureData,2)
            theOneLightTemp(numel(theOneLightTemp)+1) = theTemperatureData(iter, iPowerLevel,1);
            theAmbientTemp(numel(theAmbientTemp)+1) = theTemperatureData(iter, iPowerLevel,2);
        end
    end
    
    subplot(1,size(allTemperatureData,1), measurementIndex)
    plot(1:numel(theOneLightTemp), theOneLightTemp(:), 'ro-', 'LineWidth', 1.5, 'MarkerSize', 10, 'MarkerFaceColor', [1 0.7 0.7]);
    hold on
    plot(1:numel(theOneLightTemp), theAmbientTemp(:), 'bo-', 'LineWidth', 1.5, 'MarkerSize', 10, 'MarkerFaceColor', [0.7 0.7 1.0]);
    
    hL = legend({'OneLight', 'Ambient'}, 'Location', 'SouthEast');
    % Finish plot
    box off
    grid on
    pbaspect([1 1 1])
    hL.FontSize = 12;
    hL.FontName = 'Menlo';       
    set(gca, 'XLim', [1 numel(theOneLightTemp)], 'YLim', tempRange, 'XTick', [1:2:numel(theOneLightTemp)], 'YTick', 0:1:100);
    set(gca, 'FontSize', 12);
    xlabel('measurement index', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('temperature (deg Celcius)', 'FontSize', 14, 'FontWeight', 'bold');
    drawnow;
    title(sprintf('%s\n%s', scriptName, theMeasurementData.date));
end

end
