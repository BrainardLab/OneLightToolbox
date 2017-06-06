function availableCalTypes = OLGetAvailableCalibrationTypes(varargin)
%OLGetAvailableCalibrationTypes  Get the available calibration types
%
% Available types are those defined calibration types where there is in
% fact a calibration file available in the current calibration folder.
%
% Optional key/value pairs
%   'CalibrationFolder,'theFolderString' - Path to folder where calibration
%                                          files will be searched for.
%                                          Default is the empty string,
%                                          which causes the routine to look
%                                          in the result of
%                                          getpref('OneLight','OneLightCalData'). 
%
% See also OLCalibrationTypes, OLGetCalibrationStructure.

% 06/06/17  dhb  Wrote it.

%% Parse key/value pairs
p = inputParser;
p.addParameter('CalibrationFolder', '', @isstr);
p.parse(varargin{:});
params = p.Results;

%% Set the folder in which the calibration files live.
if (isempty(params.CalibrationFolder))
    calFolder = getpref('OneLight', 'OneLightCalData');
else
    calFolder = params.CalibrationFolder;
end
    
%% Get the list of possible calibration types.
calTypes = enumeration('OLCalibrationTypes');

%% Figure out the available calibration types
%
% That is, those where there is an actual calibration file in the calibration folder.
numAvailableCalTypes = 0;
for i = 1:length(calTypes)
    fName = [calFolder, filesep, calTypes(i).CalFileName, '.mat'];
    
    % If there is a calibration file associated with the calibration type,
    % store it as an available calibration type.
    if exist(fName, 'file')
        numAvailableCalTypes = numAvailableCalTypes + 1;
        availableCalTypes(numAvailableCalTypes) = calTypes(i); %#ok<AGROW>
    end
end

%% Throw an error if there are no calibration types.
%
% It is hard to imagine doing very much without any calibration available.
assert(numAvailableCalTypes >= 1, 'OLGetAvailableCalibrationTypes:NoAvailableCalTypes', ...
    'No available calibration types.');