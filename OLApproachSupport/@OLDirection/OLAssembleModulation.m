function modulation = OLAssembleModulation(direction, waveform, varargin)
% Assemble OLDirection, and temporal waveform, into modulation
%
% Syntax:
%   modulation = OLAssembleModulation(OLDirection, waveform, calibration)
%
% Description:
%    A modulation is a temporal variation of the device primaries, from a
%    background in a certain direction. This function takes in a
%    OLDirection object specifying directions in primary space, and a
%    temporal waveform for the direction, and combines them into a single
%    modulation.
%
% Inputs:
%    direction - OLDirection object specifying the direction to create
%                modulation of.
%    waveform  - A 1xT vector of contrast (in range [-1,1]) on 
%                        direction at each timepoint t.
%
% Outputs:
%    modulation - Structure with all the information necessary to run the
%                 modulation in the following fields:
%                 * waveformMatrix : NxT matrix of temporal waveforms,
%                                    where each row corresponds to a
%                                    different the waveform for a different
%                                    vector of primary values.
%                 * primaryValues  : PxN matrix of primary values for all
%                                    the primary basis vectors used. First
%                                    column is background, other columns
%                                    are paired similar to waveformMatrix.
%                 * primaryWaveform: PxT matrix of device primary value power at each timepoint
%                 * nominalSPDs    : Nominal SPD at each timepoint
%                 * starts, stops  : starts and stops to put this
%                                    primaryWaveform on the device
%
% Optional key/value pairs.
%    None.
%
% See also:
%    OLDirection,

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
parser.addRequired('direction',@(x) isa(x,'OLDirection'));
parser.addRequired('waveform',@isnumeric);
parser.parse(direction,waveform,varargin{:});
calibration = direction(1).calibration;

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
waveformPos = (waveform >= 0) .* waveform;
waveformNeg = (waveform < 0) .* -waveform;
waveformMatrix = [waveformPos; waveformNeg];

%% Assemble primary values matrix
primaryValues = [direction.differentialPositive, direction.differentialNegative];

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
modulation.predictedSPDs = nominalSPDs;
modulation.starts = starts;
modulation.stops = stops;

end