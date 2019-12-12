function OLPlotValidationTimeSeries(varargin)
% Plots time series of validation measurements
%
% Example usage:
%{
OLPlotValidationTimeSeries(...
    'approachName', 'OLApproach_Squint', ...
    'protocolName', 'SquintToPulse', ...
    'objectType',   'DirectionObjects', ...
    'objectName',   'MaxMelDirection', ...
    'visualizedProperty' , 'SConeContrast', ...
    'visualizedStatistics', 'medians and data points', ...
    'plottingTheme', 'bright', ...
    'excludedSubjectNames', {'HERO_instantiationCheck', 'boxAModulationCheck', 'temperatureCheck'} ...
);
%}
%
% History:
%    07/01/18  npc  wrote it.
%
%

% Subject names not to be included in the generated plots
defaultExcludedSubjectNames = {...
    'boxAModulationCheck'...
    'HERO_instantiationCheck' ...
    'temperatureCheck' ...
    };

% Parse inputs
parser = inputParser;
parser.addParameter('approachName','OLApproach_Squint',@ischar);
parser.addParameter('protocolName','SquintToPulse',@ischar);
parser.addParameter('experimentName',[],@ischar);
parser.addParameter('objectType', 'DirectionObjects');
parser.addParameter('objectName', 'MaxMelDirection');
parser.addParameter('visualizedProperty' , 'SConeContrast');
parser.addParameter('visualizedStatistics','medians only',@(x)ismember(x, {'medians only', 'data points only', 'medians and data points'}));
parser.addParameter('plottingTheme','bright',@(x)ismember(x, {'dark', 'bright'}));
parser.addParameter('excludedSubjectNames', defaultExcludedSubjectNames, @iscell);
parser.addParameter('yLim', [], @isnumeric);
parser.addParameter('limits', [], @isnumeric);
parser.addParameter('calibrations',{},@iscell);
parser.addParameter('saveDir','.', @ischar);
parser.addParameter('firstDateToPlot', [], @ischar);
parser.addParameter('excludedSessions', [], @isstruct);



parser.parse(varargin{:});
approachName = parser.Results.approachName;
protocolParams.protocol = parser.Results.protocolName;
objectType = parser.Results.objectType;
excludedSubjectNames = parser.Results.excludedSubjectNames;
excludedSessions = parser.Results.excludedSessions;
objectName = parser.Results.objectName;
visualizedProperty = parser.Results.visualizedProperty;
visualizedStatistics = parser.Results.visualizedStatistics;
plottingTheme = parser.Results.plottingTheme;
firstDateToPlot = parser.Results.firstDateToPlot;


% Serialize folders based on their session date
objectsDataPath = ...
    RetrieveObjectsDataPath(approachName, protocolParams, objectType);
[serializedData, subjectNames] = ...
    SerializeObjectsInDataPathBasedOnDates(objectsDataPath, excludedSubjectNames, excludedSessions, parser.Results.experimentName);

% Extract relevant data for visualization
[sessionData, timeLabels] = ...
    extractDataToVisualize(serializedData, subjectNames, objectName, plottingTheme);




% Plot the data
PlotAllSessionsData(sessionData, timeLabels, approachName, ...
    protocolParams.protocol, objectType, objectName, visualizedProperty, ...
    'visualizedStatistics', visualizedStatistics, ...
    'plottingTheme', plottingTheme, 'yLim', parser.Results.yLim, 'limits', parser.Results.limits, ...
    'calibrations', parser.Results.calibrations, 'saveDir', parser.Results.saveDir, 'firstDateToPlot', firstDateToPlot);
end

% ----------------------- SUPPORTING FUNCTIONS ----------------------------
% Method to plot the visualized data from all the sessions
function PlotAllSessionsData(sessionData, timeLabels, approachName, protocolName, objectType, objectName, visualizedProperty, varargin)
% Parse inputs
parser = inputParser;
parser.addParameter('visualizedStatistics','medians only',@(x)ismember(x, {'medians only', 'data points only', 'medians and data points'}));
parser.addParameter('plottingTheme','bright',@(x)ismember(x, {'dark', 'bright'}));
parser.addParameter('yLim', [], @isnumeric);
parser.addParameter('limits', [], @isnumeric);
parser.addParameter('calibrations',{},@iscell);
parser.addParameter('saveDir','.', @ischar);
parser.addParameter('firstDateToPlot', [], @ischar);


parser.parse(varargin{:});
visualizedStatistics = parser.Results.visualizedStatistics;
firstDateToPlot = parser.Results.firstDateToPlot;

% dark theme
darkTheme = struct(...
    'dataPointFill'      ,[0.6 0.4 0.2], ...
    'dataPointOutline'   ,[1.0 0.8 0.6], ...
    'medianPointFill'    ,[0.8 0.6 0.3], ...
    'medianPointOutline' ,[1.0 0.9 0.6], ...
    'axes'               ,[0.8 0.8 0.8], ...
    'background'         ,[0.4 0.4 0.4], ...
    'figBackground'      ,[0.29 0.29 0.29]);

% bright theme
brightTheme = struct(...
    'dataPointFill'     ,[0.3 0.8 0.7], ...
    'dataPointOutline'  ,[0.2 0.4 0.3], ...
    'medianPointFill'   ,[0.2 1.0 0.8], ...
    'medianPointOutline',[0.1 0.7 0.6], ...
    'axes'              ,[0.3 0.3 0.3], ...
    'background'        ,[0.9 0.9 0.9], ...
    'figBackground'     ,[1.0 1.0 1.0]);

% Set plotting theme
eval(sprintf('plottingTheme = %sTheme;',parser.Results.plottingTheme));

% Init figure
hFig = figure(1); clf;
set(hFig, 'Position', [10 10 2100 1300], 'Color', plottingTheme.figBackground);

% Compute subplot positions
validationPrefices = {'postcorrection', 'postexperiment'};
subplotPosVectors = NicePlot.getSubPlotPosVectors(...
    'rowsNum', numel(validationPrefices), ...
    'colsNum', 1, ...
    'heightMargin',  0.10, ...
    'widthMargin',    0.05, ...
    'leftMargin',     0.06, ...
    'rightMargin',    0.0001, ...
    'bottomMargin',   0.08, ...
    'topMargin',      0.01);

% Plot
for validationPrefixIndex = 1:numel(validationPrefices)
    validationPrefix = validationPrefices{validationPrefixIndex};
    subplot('Position', subplotPosVectors(validationPrefixIndex,1).v);
    hold on;
    medians = nan(1,numel(sessionData));
    for sessionIndex = 1:numel(sessionData)
        theSessionData = sessionData{sessionIndex};
        if (~isempty(theSessionData.(validationPrefix)))
            theMeasuredPropertyValues = theSessionData.(validationPrefix).(visualizedProperty);
            medians(sessionIndex) = median(theMeasuredPropertyValues);
            switch (visualizedStatistics)
                case 'data points only'
                    plot(sessionIndex*ones(1,numel(theMeasuredPropertyValues)), ...
                        theMeasuredPropertyValues, 'o-', 'MarkerSize', 10, ...
                        'MarkerFaceColor', plottingTheme.dataPointFill, ...
                        'Color', plottingTheme.dataPointOutline, ...
                        'LineWidth', 1.5);
                case 'medians only'
                    % do nothing
                case 'medians and data points'
                    plot(sessionIndex*ones(1,numel(theMeasuredPropertyValues)), ...
                        theMeasuredPropertyValues, 'o-', 'MarkerSize', 8, ...
                        'MarkerFaceColor', plottingTheme.dataPointFill, ...
                        'Color', plottingTheme.dataPointOutline, ...
                        'LineWidth', 1.0);
                otherwise
                    error('Unknown visualized statistic: ''%s''. Choose bettween {''medians only'', ''data points only'', ''medians and data points''}');
            end % switch
        end
    end % sessionIndex
    
    % Add median data points
    switch (visualizedStatistics)
        case {'medians only', 'medians and data points'}
            plot(1:numel(sessionData), medians, 's-', ...
                'MarkerFaceColor', plottingTheme.medianPointFill, ...
                'Color', plottingTheme.medianPointOutline, ...
                'MarkerSize', 14, 'LineWidth', 1.5);
    end
    
    set(gca, 'XLim', [0.5 numel(sessionData)+0.5], ...
        'XTick', 1:numel(timeLabels), 'XTickLabels', timeLabels);
    set(gca, 'XColor', plottingTheme.axes, ...
        'YColor', plottingTheme.axes, 'Color', plottingTheme.background, 'FontSize', 14, 'LineWidth', 1.0);
    ylabel(gca, visualizedProperty, 'FontWeight', 'bold');
    
    if strcmp(validationPrefix, 'postcorrection')
        validationPrefixForTitle = 'preexperiment';
    else
        validationPrefixForTitle = validationPrefix;
    end
    if (strcmp(parser.Results.plottingTheme, 'dark'))
        
        titleName = sprintf('\\color{white}\\rm[%s - %s - %s - %s]  -> \\bf\\color{yellow} %s', ...
            strrep(approachName, '_', ''), ...
            strrep(protocolName, '_', ''), ...
            strrep(objectType, '_', ''), ...
            strrep(objectName, '_', ''), ...
            validationPrefixForTitle);
    else
        titleName = sprintf('\\color{black}\\rm[%s - %s - %s - %s]  -> \\bf\\color{red} %s', ...
            strrep(approachName, '_', ''), ...
            strrep(protocolName, '_', ''), ...
            strrep(objectType, '_', ''), ...
            strrep(objectName, '_', ''), ...
            validationPrefixForTitle);
    end
    title(gca, titleName);
    xtickangle(gca, 20);
    ytickformat('%+.2f');
    box on; grid on;
    if ~isempty(parser.Results.yLim)
        ylim([parser.Results.yLim])
    end
    
    
    axes = gca;
    if ~isempty(parser.Results.limits)
        
        line(axes.XLim, [parser.Results.limits(1) parser.Results.limits(1)], 'Color', 'r', 'LineStyle', '--');
        line(axes.XLim, [parser.Results.limits(2) parser.Results.limits(2)], 'Color', 'r', 'LineStyle', '--');
        
    end
    
    
    % if not plotting all sessions, figure out where to start plotting from
    
    dates = [];
    for ii = 1:length(timeLabels)
        date = strsplit(timeLabels{ii}, '}');
        date = strsplit(date{3}, '\');
        dates{ii} = date{1};
    end
    
    
    if isempty(firstDateToPlot)
        startingIndex = 1;
    else
        for dd = 1:length(dates)
            if datenum(dates(dd), 'yyyy-mm-dd') >= datenum(firstDateToPlot, 'yyyy-mm-dd')
                startingIndex = dd;
                break
            end
        end
        
        
    end
    xlim([startingIndex, axes.XLim(2)]);
    
    if ~isempty(parser.Results.calibrations)
        for cc = 1:length(parser.Results.calibrations)
            
            
                indices = find(strcmp(dates, parser.Results.calibrations{cc}));
                index = max(indices);
                if ~isempty(indices)
                    line([index index], axes.YLim, 'Color', 'k');
                else
                    for dd = 1:length(dates)
                        if datenum(dates(dd), 'yyyy-mm-dd') >= datenum(parser.Results.calibrations{cc}, 'yyyy-mm-dd')
                            index = dd-0.5;
                            break
                        end
                    end
                    line([index index], axes.YLim, 'Color', 'k');
                end
        end
    end
                    
        
    
end

figName = sprintf('%s_%s_%s_%s_%s', ...
    strrep(approachName, '_', ''), ...
    strrep(protocolName, '_', ''), ...
    strrep(objectType, '_', ''), ...
    strrep(objectName, '_', ''), ...
    visualizedProperty);
NicePlot.exportFigToPDF(fullfile(parser.Results.saveDir, sprintf('%s.pdf', figName)), hFig, 300);
end

function oldStuff()


%sessionName = 'MELA_0119/2018-06-01_session_3'
sessionName = 'temperatureCheck/2018-06-29_session_1';

sessionFullName = fullfile('SquintToPulse/DirectionObjects',sessionName);
directionName = 'LightFluxDirection.mat';
theValidationFataFile = fullfile(melaDataPath1, 'Experiments', approachName, sessionFullName, directionName);
fprintf('Loading %s\n', theValidationFataFile);
theDirectionObjectName = 'LightFluxDirection';
load(theValidationFataFile, theDirectionObjectName);
eval(sprintf('theDirectionObject = %s;', theDirectionObjectName));

theDirectionObject
validation = theDirectionObject.describe.validation;
validationsNum = numel(validation);

serializedTempData = [];
index = 0;

for vIndex = 1:validationsNum
    theValidationEntry = validation(vIndex);
    temperatures = theValidationEntry.temperatures;
    [primariesNum, repsNum] = size(temperatures);
    for primaryIndex = 1:primariesNum
        for repIndex = 1:repsNum
            index = index+1;
            t = temperatures{primaryIndex, repIndex};
            serializedTempData(index,:) = [t.time t.value(1) t.value(2)];
        end
    end
end

[~,idx] = sort(squeeze(serializedTempData(:,1)));
serializedTempData = serializedTempData(idx,:);

hFig = figure(100); clf;
plot(squeeze(serializedTempData(:,1)), squeeze(serializedTempData(:,2)),'rs-');
hold on
plot(squeeze(serializedTempData(:,1)), squeeze(serializedTempData(:,3)), 'bs-');

end


% Method to extract relevant data for visualization
function [sessionData, timeLabels] = extractDataToVisualize(serializedData, subjectNames, objectName, plottingTheme)
fprintf('Found data for the following subjects:\n');
for k = 1:numel(subjectNames)
    fprintf('\t%s\n', subjectNames{k});
end

timeLabels = cell(1,numel(serializedData));
sessionData = cell(1,numel(serializedData));
validationPrefices = {'precorrection', 'postcorrection', 'postexperiment'};

% Open progress bar
hWaitBar = waitbar(0, 'Extracing relevant data');
for sessionIndex = 1:numel(serializedData)
    % Get serialized data struct
    d = serializedData{sessionIndex};
    
    % Get filename
    theDataFilename = fullfile(d.sessionPathName,objectName);
    
    % Let the user name what we are doing by updating the progress bar
    waitbar(sessionIndex/numel(serializedData), hWaitBar, sprintf('Extracing relevant data for %s - %s - %d\n', strrep(d.subjectName, '_', ''), d.sessionDate, d.sessionIndex));...
        
% Load data
load(theDataFilename, objectName);
dirObject = eval(objectName);

% Extract validation data
val = cell(1, numel(validationPrefices));
for validationPrefixIndex = 1:numel(validationPrefices)
    val{validationPrefixIndex} = summarizeValidation(dirObject, ...
        'plot', 'off', ...
        'whichValidationPrefix', validationPrefices{validationPrefixIndex});
end

% Arrange to data to a struct
sessionData{sessionIndex} = struct(...
    validationPrefices{1}, val{1}, ...
    validationPrefices{2}, val{2}, ...
    validationPrefices{3}, val{3} ...
    );

% Generate time labels for all sessions
if (strcmp(plottingTheme, 'dark'))
    timeLabels{sessionIndex} = strrep(sprintf('\\color{cyan}\\bf%s\\rm - \\color{white}%s\\color{green}.%d', ...
        d.subjectName, d.sessionDate, d.sessionIndex), '_', '');
else
    timeLabels{sessionIndex} = strrep(sprintf('\\color{black}\\bf%s\\rm - \\color{blue}%s\\color{green}.%d', ...
        d.subjectName, d.sessionDate, d.sessionIndex), '_', '');
end
end
% Close progress bar
close(hWaitBar);
end

% Method to serialize objects based on the date/session in their filenames
function [serializedData, subjectNames] = SerializeObjectsInDataPathBasedOnDates(objectsDataPath, excludedSubjectNames, excludedSessions, experimentName)
% Get all the files under objectsDataPath
files = dir(objectsDataPath);

% Extract only those that are directories.
isDirectory = [files.isdir];
subFolders = files(isDirectory);

% Print names of subfolders with valid names
invalidFolderNames = {'.', '..'};

sessionNamesForSubject = {};
sessionPathsForAllSubjects = {};
subjectNamesForAllSessions = {};
subjectNames = {};
validSubjectIndex = 0;
for k = 1 : length(subFolders)
    theSubjectName = subFolders(k).name;
    if (~ismember(theSubjectName, invalidFolderNames)) && (~ismember(theSubjectName, excludedSubjectNames))
        validSubjectIndex = validSubjectIndex + 1;
        % Compute full subjectNamePath
        subjectNamePath = fullfile(objectsDataPath,theSubjectName, experimentName);
        subjectNames{numel(subjectNames)+1} = theSubjectName;
        % Get all the files under subjectName
        files2 = dir(subjectNamePath);
        % Extract only those that are directories.
        isDirectory = [files2.isdir];
        subFolders2 = files2(isDirectory);
        sessionNames = {};
        validSessionIndex = 0;
        for kk = 1 : length(subFolders2)
            theSessionName = subFolders2(kk).name;
            if ~strcmp(theSessionName(1), 'x')
                if (~ismember(theSessionName, invalidFolderNames))
                    validSessionIndex = validSessionIndex + 1;
                    % Compute full sessionPath
                    sessionPath = fullfile(subjectNamePath,theSessionName);
                    sessionNames{validSessionIndex} = theSessionName;
                    if isempty(excludedSessions)
                        sessionPathsForAllSubjects{numel(sessionPathsForAllSubjects)+1} = sessionPath;
                        subjectNamesForAllSessions{numel(subjectNamesForAllSessions)+1} = theSubjectName;
                    else
                        skipSubjectLogical = false;
                        for ii = 1:length(excludedSessions.names)
                            if strcmp(theSessionName, excludedSessions.dates{ii}) && strcmp(theSessionName, excludedSessions.dates{ii})
                                skipSubjectLogical = true;
                                break
                            end
                            
                            
                        end % if
                        if ~skipSubjectLogical
                            sessionPathsForAllSubjects{numel(sessionPathsForAllSubjects)+1} = sessionPath;
                            subjectNamesForAllSessions{numel(subjectNamesForAllSessions)+1} = theSubjectName;
                        end
                    end
                end
            end
        end % for kk
        sessionNamesForSubject{validSubjectIndex} = sessionNames;
    end % if
end % for k

dateNumbers = zeros(1, numel(sessionPathsForAllSubjects));
sessionDates = cell(1,numel(sessionPathsForAllSubjects));
sessionIndices = zeros(1, numel(sessionPathsForAllSubjects));

% Extract dates for all sessions for all subjects
for k = 1:numel(sessionPathsForAllSubjects)
    sessionPathName = sessionPathsForAllSubjects{k};
    subjectName = subjectNamesForAllSessions{k};
    [dateNumbers(k), sessionDates{k}, sessionIndices(k)] = extractDateNumberFromSessionPathName(sessionPathName, subjectName, experimentName);
end

% Sort directories according the session dates
[~, sortedIndices] = sort(dateNumbers);
serializedData = cell(1, numel(sessionPathsForAllSubjects));
for k = 1:numel(sessionPathsForAllSubjects)
    index = sortedIndices(k);
    sessionPathName = sessionPathsForAllSubjects{index};
    subjectName = subjectNamesForAllSessions{index};
    sessionIndex = sessionIndices(index);
    sessionDate = sessionDates{index};
    serializedData{k} = struct(...
        'sessionPathName', sessionPathName, ...
        'sessionDate', sessionDate, ...
        'sessionIndex', sessionIndex, ...
        'subjectName', subjectName...
        );
end
end


function [dateNumber, sessionDate, sessionIndex] = extractDateNumberFromSessionPathName(sessionPathName, subjectName, experimentName)
k1 = strfind(sessionPathName, 'session');
k2 = strfind(sessionPathName, subjectName);
sessionDate = sessionPathName(k2+length(subjectName)+1+length(experimentName)+1:k1-2);
sessionIndex = str2double(sessionPathName(k1+length('session')+1:end));
% Update the date by adding x minutes, where x is the sessionIndex
updatedSessionDate = datetime(sessionDate) + minutes(sessionIndex);
% Return a number for the update date
dateNumber = datenum(updatedSessionDate);
end


function  objectsDataPath = RetrieveObjectsDataPath(approachName, protocolParams, objectType)
p = getpref(approachName);
melaDataPath = p.DataPath;
objectsDataPath = fullfile(melaDataPath, 'Experiments', approachName, protocolParams.protocol, objectType);
end