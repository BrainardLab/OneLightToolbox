function modulation = OLAssembleModulation(directions, waveforms, varargin)
% Assemble OLDirections, and temporal waveforms, into modulation
%
% Syntax:
%   modulation = OLAssembleModulation(OLDirections, waveforms, calibration)
%
% Description:
%    A modulation is a temporal variation of the device primaries, from a
%    background in a certain direction. This function takes in
%    OLDirection objects specifying directions in primary space, and
%    temporal waveforms for each direction, and combines them into a single
%    modulation.
%
% Inputs:
%    direction  - OLDirection objects specifying the directions to create
%                 modulation of.
%    waveform   - NxT matrix of differential scalars (in range [-1,1]) on 
%                 each of the N directions, at each timepoint T.
%
% Outputs:
%    modulation - Structure with all the information necessary to run the
%                 modulation in the following fields:
%                 * primaryWaveform: PxT matrix of device primary value
%                                    power at each timepoint
%                 * preidctedSPDs  : Predicted SPD at each timepoint
%                 * starts, stops  : starts and stops to put this
%                                    primaryWaveform on the device
%                 * directions     : the directions from which the
%                                    modulation was assembled (input)
%                 * waveforms      : the temporal waveforms from which the
%                                    modulation was assembled (input)
%
% Optional key/value pairs.
%    None.
%
% See also:
%    OLAssembleModulation, OLDirection, OLPrimaryWaveform

% History:
%    07/21/17  dhb       Tried to improve comments.
%    08/09/17  dhb, mab  Compute pos/neg diff more flexibly.
%    01/29/18  dhb, jv   Moved waveform generation to OLWaveformFromParams.
%    01/30/18  jv        Updated to use the new OLPrimaryWaveform and
%                        OLPrimaryStartsStops machinery.
%                        Takes in a waveform vector, rather than params.
%    03/09/18  jv        Work with OLDirection objects

%% Input validation, initialization
parser = inputParser();
parser.addRequired('directions',@(x) isa(x,'OLDirection'));
parser.addRequired('waveforms',@isnumeric);
parser.parse(directions,waveforms,varargin{:});
assert(size(waveforms,1) == numel(directions),'OneLightToolbox:OLApproachSupport:OLPrimaryWaveform:MismatchedSizes',...
    'Number of directions does not match number of waveforms');

%% Create primary waveform matrix, predict SPDs
% OLPrimaryWaveform will do the matrix multiplication for us.
primaryWaveform = OLPrimaryWaveform(directions,waveforms);
predictedSPDs = OLPrimaryToSpd(directions(1).calibration,primaryWaveform);

%% Convert to starts/stops
[starts, stops] = OLPrimaryToStartsStops(primaryWaveform,directions(1).calibration);

%% Creature return struct
modulation = struct();
modulation.primaryWaveform = primaryWaveform;
modulation.predictedSPDs = predictedSPDs;
modulation.starts = starts;
modulation.stops = stops;
modulation.directions = directions;
modulation.waveforms = waveforms;

end