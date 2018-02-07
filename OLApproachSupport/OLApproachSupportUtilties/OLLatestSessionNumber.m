function [latestSessionNumber, directories, perDirectory] = OLLatestSessionNumber(protocol,observerID,varargin)
% Finds protocols latest session number based on directory organization
%
% Syntax:
%   latestSessionNumber = OLLatestSessionNumber(protocolParams);
%   [latestSessionNumber, directories] = OLLatestSessionNumber(protocolParams);
%   [latestSessionNumber, directories, perDirectory] = OLLatestSessionNumber(protocolParams);
%
% Description:
%    Finds all directories specified in the preferences for this protocol,
%    and in all those directories, finds the 'session_x' subdirectory with
%    the highest session number (x). Returns the highest session number
%    found.
%
% Inputs:
%    protocol            - string specifying the protocol
%    observerID          - string specifying the observerID
%    date                - datestring specifying the date. Optional, 
%                          default '0000-01-00'.
%
% Outputs:
%    latestSessionNumber - highest session number that could be found
%                          in any of the directories
%    directories         - paths of the directories that were searched
%    perDirectory        - highest session number found in each directory
%
% Key/value pairs:
%    None.
%
% See also:
%    OLSessionLog

% History:
%    02/02/18  jv  wrote it.

%% Input validation
parser = inputParser();
parser.addRequired('protocol',@ischar);
parser.addRequired('observerID',@ischar);
parser.addOptional('date','0000-01-00',@ischar);
parser.parse(protocol,observerID,varargin{:});

%% Find directories
prefs = getpref(protocol);
prefsFields = fieldnames(prefs);
directoriesPrefs = prefsFields(contains(prefsFields,'Path'));
directories = getpref(protocol,directoriesPrefs);

%% Find latest session number
perDirectory = cellfun(@(x) latestSessionInDirectory(fullfile(x,observerID,date)),directories);
latestSessionNumber = max([perDirectory, 0]);

end

function latestSessionNumber = latestSessionInDirectory(directory)
% Finds the latest session in a directory
%
% Syntax:
%   latestSessionNumber = OLLatestSessionInDirectory(directory);
%
% Description:
%    Finds the 'session_x' subdirectory with the highest session number
%    (x), and return that highest session number. If the specified
%    directory does not exist, returns 0.
%
% Inputs:
%    diectory            - directory to find the highest session number in.
%                          If directory does not exist, returns 0.
%
% Outputs:
%    latestSessionNumber - highest session number that could be found. If
%                          directory did not exist, latestSessionNumber = 0
%
% Key/value pairs:
%    None.
%
% See also:
%    OLLatestSessionNumber

% History:
%    02/02/18  jv  wrote it, as local subfunction in OLLatestSessionNumber

if exist(directory,'dir')
    dirStatus = dir(directory);
    dirStatus=dirStatus(startsWith({dirStatus.name},'session_'));
    if ~isempty(dirStatus) 
        % other 'session_' subdirectories already in the directory, 
        % need to figure out session number
        priorSessionNumbers = str2double(extractAfter({dirStatus.name},'session_'));
        latestSessionNumber = max(priorSessionNumbers);
    else
        latestSessionNumber = 0;
    end
else
    latestSessionNumber = 0;
end

end