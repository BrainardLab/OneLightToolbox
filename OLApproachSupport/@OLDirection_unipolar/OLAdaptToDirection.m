function OLAdaptToDirection(direction, oneLight, adaptationDuration, varargin)
% Show OLDirection as adaptation stimulus
%
% Syntax:
%   OLAdaptToDirection(direction, OneLight, adaptationDuration)
%
% Description:
%    Puts the given Direction on the OneLight, for the specified duration.
%    Default gives a verbal countdown feedback every 30 seconds. 
%
%    Note: this routine stays busy executing for the entire duration, i.e.,
%    does not return control to caller until duration has elapsed.
%
% Inputs:
%    direction - OLDirection object 
%    OneLight  - OneLight object controlling a (simulated) OneLight device.
%    duration  - duration, adaptation duration, e.g.: seconds(60),
%                minutes(5)
%
% Outputs:
%    None.
%
% Optional key/value pairs:
%    'countdownInterval' - duration, interval between verbal countdowns.
%                          Last verbal countdown is [countdownInterval]
%                          away from 0s remaining, and every multiple from
%                          there. Default seconds(30). If set to
%                          seconds(0), will not give any verbal feedback.
%
% Notes:
%    * With the overhead processing, especially the first verbal
%      'Adaptation Starting', timing is imprecise on the order of 1-5
%      seconds. For adaptation, that should be fine.
%
% Examples in source code
%
% See also:
%    OLShowDirection, duration

% History:
%    05/08/18  jv  wrote it.

%{
    oneLight = OneLight('simulate',true);
    calibration = OLGetCalibrationStructure('CalibrationFolder',fileparts(which('OLDemoCal.mat')),'CalibrationType','DemoCal');
    P = calibration.describe.numWavelengthBands;  % number of effective device primaries
    primary = .5 * ones(P,1); % all primaries half-on    
    direction = OLDirection_unipolar(primary,calibration);
    
    %% Adapt 1.5 minutes, with countdown every 30s
    OLAdaptToDirection(direction,oneLight,minutes(1.5));
%}
%{
    oneLight = OneLight('simulate',true);
    calibration = OLGetCalibrationStructure('CalibrationFolder',fileparts(which('OLDemoCal.mat')),'CalibrationType','DemoCal');
    P = calibration.describe.numWavelengthBands;  % number of effective device primaries
    primary = .5 * ones(P,1); % all primaries half-on    
    direction = OLDirection_unipolar(primary,calibration);
    
    %% Adapt 45 seconds, with countdown at 40s and 20s.
    OLAdaptToDirection(direction,oneLight,seconds(45),'countdownInterval',seconds(20));
%}
%{
    oneLight = OneLight('simulate',true);
    calibration = OLGetCalibrationStructure('CalibrationFolder',fileparts(which('OLDemoCal.mat')),'CalibrationType','DemoCal');
    P = calibration.describe.numWavelengthBands;  % number of effective device primaries
    primary = .5 * ones(P,1); % all primaries half-on    
    direction = OLDirection_unipolar(primary,calibration);
    
    %% Adapt 45 seconds, no countdown.
    OLAdaptToDirection(direction,oneLight,seconds(45),'countdownInterval',seconds(0));
%}

%% Input validation
parser = inputParser;
parser.addRequired('direction',@(x) isa(x,'OLDirection'));
parser.addRequired('oneLight',@(x) isa(x,'OneLight'));
parser.addRequired('adaptationDuration',@(x) validateattributes(x,{'duration'},{'scalar'}));
parser.addParameter('countdownInterval',seconds(30),@(x) validateattributes(x,{'duration'},{'scalar'}));
parser.parse(direction, oneLight, adaptationDuration, varargin{:});

%% Set up countdown
if parser.Results.countdownInterval > 0
    countdownTimes = parser.Results.countdownInterval:parser.Results.countdownInterval:adaptationDuration;
    countdownTimes = fliplr(countdownTimes);
    if countdownTimes(1) == adaptationDuration
        countdownTimes = countdownTimes(2:end);
    end
else
    countdownTimes = [];
end

%% Show adaptation
OLShowDirection(direction, oneLight);
Speak(sprintf('Adaptation started, for %s',durationToStr(adaptationDuration)),[],230);
endTime = mglGetSecs + seconds(adaptationDuration);
eta = seconds(endTime-mglGetSecs);
while eta > 0
   if ~isempty(countdownTimes) && eta < countdownTimes(1)
       Speak(sprintf('%s of adaptation remaining',durationToStr(countdownTimes(1))),[],230);
       countdownTimes = countdownTimes(2:end);
   end
   eta = seconds(endTime-mglGetSecs);
end
Speak('Adaptation complete.',[],230);

end