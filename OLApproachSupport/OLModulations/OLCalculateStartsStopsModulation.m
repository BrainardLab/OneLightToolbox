function modulation = OLCalculateStartsStopsModulation(waveformParams, calibration, backgroundPrimary, diffPrimaryPos, varargin)
% Calculate various modulations given background and pos/neg primary differences.
%
% Usage:
%   modulation = OLCalculateStartsStopsModulation(waveformParams, calibration, backgroundPrimary, diffPrimaryPos, diffPrimaryNeg)
%   modulation = OLCalculateStartsStopsModulation(waveformParams, calibration, backgroundPrimary, diffPrimaryPos)
%
% Description:
%    This function takes waveform parameters and turns them into
%    modulations.
%
% Input:
%    waveformParams    - Parameter struct to generate waveform from
%    calibration       - OneLight calibration struct
%    backgroundPrimary - primary values for the background
%    diffPrimaryPos    - Primary values for the positive differential of
%                        the direction
%    diffPrimaryNeg    - Primary values for the negative differential of 
%                        the direction. Can be passed empty if there will 
%                        be no negative component to the waveform, e.g. for
%                        a pulse.
%
% Output:
%    modulation        - Structure containing (among other things) the 
%                        starts/stops matrices that produce the modulation.
%
% Optional key/value pairs.
%    None.
%
% See also: 
%    OLMakeModulationsStartsStops, 
%    OLReceptorIsolateMakeModulationStartsStops, 
%    OLModulationParamsDefaults, OLModulationParamsValidate,
%    OLModulationParamsDictioanry

% History:
%    07/21/17  dhb       Tried to improve comments.
%    08/09/17  dhb, mab  Compute pos/neg diff more flexibly.
%    01/29/18  dhb, jv   Moved waveform generation to OLWaveformFromParams.
%    01/30/18  jv        Updated to use the new OLPrimaryWaveform and
%                        OLPrimaryStartsStops machinery.

%% Input validation, initialization
parser = inputParser();
parser.addRequired('waveformParams',@isstruct);
parser.addRequired('calibration',@isstruct);
parser.addRequired('backgroundPrimary',@isnumeric);
parser.addRequired('diffPrimaryPos',@isnumeric);
parser.addOptional('diffPrimaryNeg',[],@isnumeric);
parser.parse(waveformParams,calibration,backgroundPrimary,diffPrimaryPos,varargin{:});
diffPrimaryNeg = parser.Results.diffPrimaryNeg;

%% Generate the direction waveform from parameters
[waveformDirection, timestep, waveformDuration] = OLWaveformFromParams(waveformParams);

%% Assemble waveforms matrix
% To generate the primary waveform, we need to combine the background, and
% direction, and their corresponding waveforms. Since the background should
% be added to the primary waveform at all timepoints, the background
% waveform is a vector of ones. The direction primary consists of a
% positive and negative differential primary (away the background), and
% these can asymmetric, especially after spectrum correction. To allow for
% this, we add them to the background separately, and we also have to put
% in the corresponding parts of the waveform separately. Thus, we break the
% direction waveform into a positive and negative component.
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
nominalSPDs = OLPrimaryToSpd(calibration,primaryWaveform);

%% Convert to starts/stops
[starts, stops] = OLPrimaryToStartsStops(primaryWaveform,calibration);

%% Creature return struct
modulation = struct();
modulation.waveformMatrix = waveformMatrix;
modulation.primaryValues = primaryValues;
modulation.primaryWaveform = primaryWaveform;
modulation.nominalSPDs = nominalSPDs;
modulation.starts = starts;
modulation.stops = stops;
modulation.background.primaries = backgroundPrimary;
[modulation.background.starts, modulation.background.stops] = OLPrimaryToStartsStops(backgroundPrimary,calibration);