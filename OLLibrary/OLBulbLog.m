function OLBulbLog(box, onoff, varargin)
% Writes entry to bulb log
%
% Syntax:
%   OLBulbLog(box, 'on')
%   OLBulbLog(box, 'off')
%   OLBulbLog(box, 'on'/'off', 'temperature', temp, 'notes', notes)
%   OLBulbLog(box, 'BulbSerial', serial, 'Date', date, 'TimeOn', time, 'TempOn', temp, 'NotesOn', notes, 'TempOff', temp, 'NotesOff', notes)
%
% Description:
%    To better track the behavior of our OneLight boxes, we keep logs of
%    how long they're on. This function writes an entry into one of these
%    logs.
% 
%    The log are stored in Comma-Separated-Value files, under the name
%    'BulbLog_Box[ABCD].csv'. These files are located in
%    getpref('OneLightToolbox','BulbLogsDir'), which should be set in the
%    local hook (see template). They contain the following columns:
%      - BulbSerial
%      - Date
%      - TimeOn
%      - TempOn
%      - NotesOn
%      - TempOff
%      - TempOff
%      - NotesOff
%
%    The most common form of using this function is simply:
%    - on startup:  OLBulbLog([A B C D], 'on')
%    - on shutdown: OLBulbLog([A B C D], 'off')
%    Room temperature can be noted as numeric value, by using key/value 
%    pair 'temperature'. Notes can be added as a string, by using key/value
%    pair 'notes'.
%
%    A more extended way of using this function, is that it can take any of
%    the column headers as a key/value pair, if you want to manually fill
%    an entry of the log. You're probably better off doing that in a
%    spreadsheet program, but who am I to judge.
%
% Inputs:
%    box         - Letter indicating which OneLight log this should go to. 
%                  Valid letters are 'A', 'B', 'C', or 'D'
%    onoff       - string 'on' or 'off', indicating whether box was turned
%                  on or off
%
% Outputs:
%    None.
%
% Optional key/value pairs:
%    temperature - numeric scalar indicating room(?) temperature. Default
%                  NaN.
%    notes       - single string, with any notes. Default "".
%
%    BulbSerial  - serial number of the bulb. Default 'Box[ABCD]'.
%    Date        - date of entry, in 'mm/dd/yyyy' format.. Default todays 
%                  date.
%    TimeOn      - time when bulb was ignited, in 'HH:mm' format (24:00).
%                  Default NaT.
%    TempOn      - room(?) temperature when bulb was ignited. Default NaN.
%    NotesOn     - single string of notes about turning on. Default "".
%    TempOff     - time when box was shutdown, in 'HH:mm' format (24:00).
%                  Default NaT.
%    TempOff     - room(?) temperature when box was shutdown. Default NaN.
%    NotesOff    - single string of notes about turning off. Default "".

% History:
%   04/19/18  jv  wrote it.

%% Input validation
parser = inputParser;
parser.addRequired('box',@(x) all(logical(validatestring(x,{'A','B','C','D'}))));
parser.addRequired('onoff',@(x) all(logical(validatestring(x,{'on','off','ON','OFF',''}))));
parser.addParameter('temperature',missing,@isnumeric);
parser.addParameter('notes',missing);

parser.addParameter('BulbSerial',missing);
parser.addParameter('Date',datetime('now','Format','MM/dd/yyyy'));
parser.addParameter('TimeOn',missing);
parser.addParameter('TempOn',missing);
parser.addParameter('NotesOn',missing);
parser.addParameter('TimeOff',missing);
parser.addParameter('TempOff',missing);
parser.addParameter('NotesOff',missing);

parser.parse(box, onoff, varargin{:});

box = ['Box' parser.Results.box];

%% Load relevant file
bulbLogsDir = getpref('OneLightToolbox','BulbLogsDir');
bulbLogFileName = fullfile(bulbLogsDir,sprintf('BulbLog_%s.csv',box));
bulbLogTable = readtable(bulbLogFileName);

%% Convert to proper datatypes
if ~isempty(bulbLogTable)
    bulbLogTable.BulbSerial = string(bulbLogTable.BulbSerial);
    bulbLogTable.NotesOn = string(bulbLogTable.NotesOn);
    bulbLogTable.NotesOff = string(bulbLogTable.NotesOff);
    bulbLogTable.TimeOn = datetime(bulbLogTable.TimeOn,'InputFormat','HH:mm','Format','HH:mm');
    bulbLogTable.TimeOff = datetime(bulbLogTable.TimeOff,'InputFormat','HH:mm','Format','HH:mm');
end

%% Compose entry
if ismissing(parser.Results.BulbSerial)
    entry.BulbSerial = string(box);
else
    entry.BulbSerial = parser.Results.BulbSerial;
end
entry.Date = datetime(parser.Results.Date,'Format','MM/dd/yyyy');
entry.TimeOn = datetime(parser.Results.TimeOn,'InputFormat','HH:mm','Format','HH:mm');
entry.TimeOff = datetime(parser.Results.TimeOff','InputFormat','HH:mm','Format','HH:mm');
entry.NotesOn = string(parser.Results.NotesOn);
entry.NotesOff = string(parser.Results.NotesOff);
entry.TempOn = parser.Results.TempOn;
entry.TempOff = parser.Results.TempOff;

%% Short-hand mode, overwrite fields:
switch parser.Results.onoff
    case 'on'
        % Overwrite values for turning bulb on
        entry.BulbSerial = string(box);
        entry.Date = datetime('now','Format','MM/dd/yyyy');
        entry.TimeOn = datetime('now','Format','hh:mm');
        entry.TempOn = parser.Results.temperature;
        entry.NotesOn = string(parser.Results.notes);
    case 'off'
        % Write entry for turning bulb off
        entry.TimeOff = datetime('now','Format','hh:mm');
        entry.TempOff = parser.Results.temperature;
        entry.NotesOff = string(parser.Results.notes);

        % See if we are filling in a row from today
        entryN = find(bulbLogTable.Date == datetime('today'),1,'last');
        if isempty(entryN)
            entryN = size(bulbLogTable,1)+1;
            entry.BulbSerial = string(box);
            entry.Date = datetime('now','Format','MM/dd/yyyy');
            warning('No corresponding entry for turning on bulb. Appending row, and indicating missing values');
        else
            entry.BulbSerial = string(bulbLogTable.BulbSerial(entryN));
            entry.Date       = bulbLogTable.Date(entryN);
            entry.TimeOn     = bulbLogTable.TimeOn(entryN);
            entry.TempOn     = bulbLogTable.TempOn(entryN);
            entry.NotesOn    = bulbLogTable.NotesOn(entryN);
            bulbLogTable(entryN,:) = [];
        end
end

%% Save out
% Convert to table row
entry = struct2table(entry);

% Append to table
if ~isempty(bulbLogTable)
    bulbLogTable = [bulbLogTable; entry];
else
    bulbLogTable = entry;
end

% Save
writetable(bulbLogTable,bulbLogFileName);