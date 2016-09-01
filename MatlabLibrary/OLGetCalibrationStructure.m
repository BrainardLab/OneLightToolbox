function cal = OLGetCalibrationStructure
% cal = OLGetCalibrationStructure
%
% Interact with user to get the desired one light
% calibration structure.
%
% 4/4/13  dhb, ms  Pulled out of a calling program as separate function.

% First, set the paths in which the calibration files live.
calFolderInfo = what(getpref('OneLight', 'OneLightCalData'));
calFolder = calFolderInfo.path;

% Get a list of possible calibration types.
calTypes = enumeration('OLCalibrationTypes');

% Figure out the available calibration types.
numAvailCalTypes = 0;
for i = 1:length(calTypes)
    fName = [calFolder, filesep, calTypes(i).CalFileName, '.mat'];
    
    % If the calibration file associated with the calibration type,
    % store it as an available calibration type.
    if exist(fName, 'file')
        numAvailCalTypes = numAvailCalTypes + 1;
        availableCalTypes(numAvailCalTypes) = calTypes(i); %#ok<AGROW>
    end
end

% Throw an error if there are no calibration types
assert(numAvailCalTypes >= 1, 'OLAnalyzeCal:NoAvailableCalTypes', ...
    'No available calibration types.');

% Now have the user select an available calibration type to analyze.
keepPrompting = true;
while keepPrompting
    % Show the available calibration types.
    fprintf('\n*** Available Calibration Types ***\n\n');
    for i = 1:length(availableCalTypes)
        fprintf('%d - %s\n', i, availableCalTypes(i).char);
    end
    fprintf('\n');
    
    calIndex = GetInput('Select a Calibration Type', 'number', 1);
    
    % Check the selection.
    if calIndex >= 1 && calIndex <= numAvailCalTypes
        keepPrompting = false;
    else
        fprintf('\n* Invalid selection\n');
    end
end

% Extract the calibration file name.
cal = availableCalTypes(calIndex).CalFileName;

% If we only have the name of the calibration file, prompt for the version
% of the calibration data we want.
if ischar(cal)
    % Get all the calibration data.
    [~, cals] = LoadCalFile(cal);
    
    % Have the user select a calibration if there is more than 1.
    if length(cals) > 1
        % Now have the user select an available calibration type to
        % analyze.
        keepPrompting = true;
        while keepPrompting
            % Show the available calibration types.
            fprintf('\n*** Available Calibrations ***\n\n');
            for i = 1:length(cals)
                fprintf('%d - %s\n', i, cals{i}.describe.date);
            end
            fprintf('\n');
            
            calIndex = GetWithDefault('Select a Calibration', length(cals));
            
            % Check the selection.
            if calIndex >= 1 && calIndex <= length(cals)
                keepPrompting = false;
            else
                fprintf('\n* Invalid selection\n');
            end
        end
    else
        calIndex = 1;
    end
    
    % Extract the desired calibration.
    cal = cals{calIndex};
end


