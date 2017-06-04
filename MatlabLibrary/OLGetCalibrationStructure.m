function cal = OLGetCalibrationStructure(varargin)
%OLGetCalibrationStructure - Get calibration structure
%
% With no arguments, this prompts user to specify calibration type and date.
% The type and date can also be specified with optional key/value pairs.
%
% Optional key/value pairs
%   'CalibrationType','theCalibrationType' - Use the passed calibration type.
%   'CalibrationDate','theDateString' - Use the passed calibration date string.
%                                     - You can pass 'latest' to get the
%                                       most recent calibration.
%
% Examples:
%   cal = OLGetCalibrationStructure
%   cal = OLGetCalibrationStructure('CalibrationType','BoxDRandomizedLongCableAStubby1_ND02');
%   cal = OLGetCalibrationStructure('CalibrationType','BoxDRandomizedLongCableAStubby1_ND02','CalibrationDate','latest');
%   cal = OLGetCalibrationStructure('CalibrationType','BoxDRandomizedLongCableAStubby1_ND02','CalibrationDate','08-May-2017 12:30:33');
%
% 4/4/13  dhb, ms  Pulled out of a calling program as separate function.
% 6/4/17  dhb      Add key/value pair options.

% Parse key/value pairs
p = inputParser;
p.addParameter('CalibrationType', '', @isstr);
p.addParameter('CalibrationDate', '', @isstr)
p.parse(varargin{:});
params = p.Results;

% First, set the paths in which the calibration files live.
calFolderInfo = what(getpref('OneLight', 'OneLightCalData'));
calFolder = calFolderInfo.path;

% Get a list of possible calibration types.
calTypes = enumeration('OLCalibrationTypes');

% Figure out the available calibration types.
numAvailCalTypes = 0;
for i = 1:length(calTypes)
    fName = [calFolder, filesep, calTypes(i).CalFileName, '.mat'];
    
    % If there is a calibration file associated with the calibration type,
    % store it as an available calibration type.
    if exist(fName, 'file')
        numAvailCalTypes = numAvailCalTypes + 1;
        availableCalTypes(numAvailCalTypes) = calTypes(i); %#ok<AGROW>
    end
end

% Throw an error if there are no calibration types
assert(numAvailCalTypes >= 1, 'OLAnalyzeCal:NoAvailableCalTypes', ...
    'No available calibration types.');

% Get calibration type, either from user selection or because it was passed
% as a key/value pair.
calIndex = 0;
if (isempty(params.CalibrationType))
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
else
    for i = 1:length(availableCalTypes)
        if (strcmp(params.CalibrationType,availableCalTypes(i).char))
            calIndex = i;
            break;
        end
    end
    if calIndex >= 1 && calIndex <= numAvailCalTypes
    else
        error('Passed calibration type is not available');
    end
    
    % Extract the calibration file name.
    cal = availableCalTypes(calIndex).CalFileName;
end

% If we only have the name of the calibration file, prompt for the version
% of the calibration data we want.
calIndex = 0;
if ischar(cal)
    % Get all the calibration data.
    [~, cals] = LoadCalFile(cal, [], getpref('OneLight', 'OneLightCalData'));
    
    % Have the user select a calibration if there is more than 1 and we
    % didn't pass which one we wanted.
    if (length(cals) > 1)
        
        switch (params.CalibrationDate)
            case ''
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
            case 'latest'
                calIndex = length(cals);
            otherwise
                for i = 1:length(cals)
                    if (strcmp(cals{i}.describe.date,params.CalibrationDate))
                        calIndex = i;
                        break;
                    end
                end
                if calIndex >= 1 && calIndex <= length(cals)
                else
                    error('Invalid calibration date specified');
                end
        end
    else
        calIndex = 1;
    end
    
    % Extract the desired calibration.
    cal = cals{calIndex};
end


