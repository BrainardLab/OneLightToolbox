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
parser.addParameter('objectType', 'DirectionObjects');
parser.addParameter('objectName', 'MaxMelDirection');
parser.addParameter('visualizedProperty' , 'SConeContrast');
parser.addParameter('visualizedStatistics','medians only',@(x)ismember(x, {'medians only', 'datapoints only', 'medians and data points'}));
parser.addParameter('excludedSubjectNames', defaultExcludedSubjectNames, @iscell);
parser.parse(varargin{:});
approachName = parser.Results.approachName;
protocolParams.protocol = parser.Results.protocolName;
objectType = parser.Results.objectType;
excludedSubjectNames = parser.Results.excludedSubjectNames;
objectName = parser.Results.objectName;
visualizedProperty = parser.Results.visualizedProperty;
visualizedStatistics = parser.Results.visualizedStatistics;

% Serialize folders based on their session date
objectsDataPath = ...
    RetrieveObjectsDataPath(approachName, protocolParams, objectType);
[serializedData, subjectNames] = ...
    SerializeObjectsInDataPathBasedOnDates(objectsDataPath, excludedSubjectNames);

% Extract relevant data for visualization
[sessionData, timeLabels] = ...
    extractDataToVisualize(serializedData, subjectNames, objectName);

% Plot the data
PlotAllSessionsData(sessionData, timeLabels, approachName, ...
    protocolParams.protocol, objectType, objectName, visualizedProperty, ...
    'visualizedStatistics', visualizedStatistics);
end

% ----------------------- SUPPORTING FUNCTIONS ----------------------------
% Method to plot the visualized data from all the sessions
function PlotAllSessionsData(sessionData, timeLabels, approachName, protocolName, objectType, objectName, visualizedProperty, varargin)
    % Parse inputs
    parser = inputParser;
    parser.addParameter('visualizedStatistics','medians only',@(x)ismember(x, {'medians only', 'datapoints only', 'medians and data points'}));
    parser.parse(varargin{:});
    visualizedStatistics = parser.Results.visualizedStatistics;
    
    hFig = figure(1); clf;
    backgroundColor = [0.29 0.29 0.29];
    set(hFig, 'Position', [10 10 2100 1300], 'Color', backgroundColor);
    
    validationPrefices = {'precorrection', 'postcorrection', 'postexperiment'};
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
         'rowsNum', numel(validationPrefices), ...
         'colsNum', 1, ...
         'heightMargin',  0.10, ...
         'widthMargin',    0.05, ...
         'leftMargin',     0.06, ...
         'rightMargin',    0.0001, ...
         'bottomMargin',   0.08, ...
         'topMargin',      0.01);

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
                    case 'datapoints only'
                        plot(sessionIndex*ones(1,numel(theMeasuredPropertyValues)), theMeasuredPropertyValues, ...
                            'o-', 'MarkerFaceColor', [0.6 0.4 0.2], 'MarkerSize', 10, 'Color', [1.0 0.8 0.6], 'LineWidth', 1.5);
                    case 'medians only'
                        % do nothing
                    case 'medians and data points'
                        plot(sessionIndex*ones(1,numel(theMeasuredPropertyValues)), theMeasuredPropertyValues, ...
                            'o-', 'MarkerFaceColor', [0.6 0.4 0.2], 'MarkerSize', 8, 'Color', [1.0 0.8 0.6], 'LineWidth', 1.0);    
                    otherwise
                        error('Unknown visualized statistic: ''%s''. Choose bettween {''median'', ''datapoints'', ''both''}');
                end % switch
            end
        end % sessionIndex
        
        % Add median data points
        switch (visualizedStatistics)
            case 'medians only'
               plot(1:numel(sessionData), medians, 's-', 'MarkerFaceColor', [0.8 0.6 0.3], 'MarkerSize', 14, 'Color', [1.0 0.9 0.6], 'LineWidth', 1.5);
            case 'medians and data points'
               plot(1:numel(sessionData), medians, 's-', 'MarkerFaceColor', [0.8 0.6 0.3], 'MarkerSize', 14, 'Color', [1.0 0.9 0.6], 'LineWidth', 1.5);
        end
    
        set(gca, 'XLim', [0.5 numel(sessionData)+0.5], 'XTick', 1:numel(timeLabels), 'XTickLabels', timeLabels);
        set(gca, 'XColor', [0.8 0.8 0.8], 'YColor', [0.8 0.8 0.8], 'Color', backgroundColor+0.1, 'FontSize', 14, 'LineWidth', 1.0);
        ylabel(gca, visualizedProperty, 'FontWeight', 'bold');
        titleName = sprintf('\\color{white}\\rm[%s - %s - %s - %s]  -> \\bf\\color{yellow} %s', ...
            strrep(approachName, '_', ''), ...
            strrep(protocolName, '_', ''), ...
            strrep(objectType, '_', ''), ...
            strrep(objectName, '_', ''), ...
            validationPrefix);
        title(gca, titleName, 'Color', [1.0 0.9 0.6]);
        xtickangle(gca, 20);
        ytickformat('%+.2f');
        box on; grid on;
    end
    
    figName = sprintf('%s_%s_%s_%s_%s', ...
            strrep(approachName, '_', ''), ...
            strrep(protocolName, '_', ''), ...
            strrep(objectType, '_', ''), ...
            strrep(objectName, '_', ''));
    NicePlot.exportFigToPDF(sprintf('%s.pdf', figName), hFig, 300);
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
function [sessionData, timeLabels] = extractDataToVisualize(serializedData, subjectNames, objectName)
    fprintf('Plotting data for the following subjects:\n');
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
        timeLabels{sessionIndex} = strrep(sprintf('\\color{cyan}\\bf%s\\rm - \\color{white}%s\\color{green}.%d', d.subjectName, d.sessionDate, d.sessionIndex), '_', '');
    end
    % Close progress bar
    close(hWaitBar);
end

% Method to serialize objects based on the date/session in their filenames
function [serializedData, subjectNames] = SerializeObjectsInDataPathBasedOnDates(objectsDataPath, excludedSubjectNames)
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
            subjectNamePath = fullfile(objectsDataPath,theSubjectName);
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
                if (~ismember(theSessionName, invalidFolderNames))
                    validSessionIndex = validSessionIndex + 1;
                    % Compute full sessionPath
                    sessionPath = fullfile(subjectNamePath,theSessionName);
                    sessionNames{validSessionIndex} = theSessionName;
                    sessionPathsForAllSubjects{numel(sessionPathsForAllSubjects)+1} = sessionPath;
                    subjectNamesForAllSessions{numel(subjectNamesForAllSessions)+1} = theSubjectName;
                end % if
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
        [dateNumbers(k), sessionDates{k}, sessionIndices(k)] = extractDateNumberFromSessionPathName(sessionPathName, subjectName);
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

function [dateNumber, sessionDate, sessionIndex] = extractDateNumberFromSessionPathName(sessionPathName, subjectName)
    k1 = strfind(sessionPathName, 'session');
    k2 = strfind(sessionPathName, subjectName);
    sessionDate = sessionPathName(k2+length(subjectName)+1:k1-2);
    sessionIndex = str2double(sessionPathName(k1+length('session')+1:end));
    % Update the date by adding x minutes, where x is the sessionIndex
    updatedSessionDate = datetime(sessionDate) + minutes(sessionIndex);
    % Return a number for the update date
    dateNumber = datenum(updatedSessionDate);
end


function  objectsDataPath = RetrieveObjectsDataPath(approachName, protocolParams, objectType)
    p = getpref(approachName);
    melaDataPath = p.DataPath;
    computerInfo = GetComputerInfo();
    if (strcmp(computerInfo.userShortName, 'nicolas'))
        melaDataPath = strrep(melaDataPath, 'MELA_data', 'MELA_data (1)');
    end
    
    objectsDataPath = fullfile(melaDataPath, 'Experiments', approachName, protocolParams.protocol, objectType);
end