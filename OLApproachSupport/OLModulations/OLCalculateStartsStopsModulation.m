function modulation = OLCalculateStartsStopsModulation(waveformParams, cal, backgroundPrimary, diffPrimaryPos, varargin)
%%OLCalculateStartsStopsModulation  Calculate various modulations given background and pos/neg primary differences.
%
% Usage:
%     modulation = OLCalculateStartsStopsModulation(waveformParams, cal, backgroundPrimary, diffPrimaryPos, diffPrimaryNeg)
%
% Description:
%     This programes takes the waveform parameters and turns them into
%     modulations.
%
%     This is called by OLReceptorIsolateMakeModulationStartsStops to make the starts/stops
%     that implement a particular modulation, for a specific choice of waveform parameters.
%
%     It looks like if diffPrimayNeg is empty, only the positive arm is used (i.e. to make a pulse).
%
% Input:
%
% Output:
%    modulation             Structure containing (among other things) the starts/stops matrices that produce the modulation.
%
% Optional key/value pairs.
%    None.
%
% See also: OLMakeModulationsStartsStops, OLReceptorIsolateMakeModulationStartsStops, OLWaveformParamsDictionary.

% 7/21/17  dhb        Tried to improve comments.
% 8/09/17  dhb, mab   Compute pos/neg diff more flexibly.
% 01/28/18  dhb, jv  Moved waveform generation to OLWaveformFromParams. 

%% Input validation, initialization
parser = inputParser();
parser.addRequired('waveformParams',@isstruct);
parser.addRequired('calibration',@isstruct);
parser.addRequired('backgroundPrimary',@isnumeric);
parser.addRequired('diffPrimaryPos',@isnumeric);
parser.addOptional('diffPrimaryNeg',[],@isnumeric);
parser.parse(waveformParams,cal,backgroundPrimary,diffPrimaryPos,varargin{:});
diffPrimaryNeg = parser.Results.diffPrimaryNeg;

%% Generate the direction waveform from parameters
[waveformDirection, waveformParams] = OLWaveformFromParams(waveformParams);

%% Assemble waveforms matrix
waveformBackground = ones(1, length(waveformDirection));
waveformPos = (waveformDirection >= 0) .* waveformDirection;
waveformNeg = (waveformDirection < 0) .* -waveformDirection;
waveformMatrix = [waveformBackground; waveformPos; waveformNeg];

%% Assemble primary values matrix
if any(waveformNeg) % waveformNeg is non-empty
    assert(~isempty(diffPrimaryNeg),'diffPrimaryNeg cannot be empty if there is a negative component to the waveform');
else
    % if no negative component to the waveform, set the negative
    % differential primary to zeroes. 
    diffPrimaryNeg = zeros(size(diffPrimaryPos)); 
end
primaryValues = [backgroundPrimary, diffPrimaryPos, diffPrimaryNeg];

%% Create primary waveform matrix, predict SPDs
% OLPrimaryWaveform will do the matrix multiplication for us.
primaryWaveform = OLPrimaryWaveform(primaryValues,waveformMatrix,'truncateGamut',false);
spd = OLPrimaryToSpd(cal,primaryWaveform);

%% Convert to starts/stops
[starts, stops] = OLPrimaryToStartsStops(primaryWaveform,cal);

%% Creature return struct
modulation = struct();
modulation.waveformParams = waveformParams;
modulation.waveform = waveformDirection;
modulation.starts = starts;
modulation.stops = stops;
modulation.primaryValues = primaryValues;
modulation.primaries = primaryWaveform;
modulation.background.primaries = backgroundPrimary;
[modulation.background.starts, modulation.background.stops] = OLPrimaryToStartsStops(backgroundPrimary,cal);