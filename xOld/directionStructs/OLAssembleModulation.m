function modulation = OLAssembleModulation(directionStruct, directionWaveform, calibration, varargin)
% Assemble background and direction primaries, and waveform into modulation 
%
% Usage:
%   modulation = OLAssembleModulation(directionStruct, directionWaveform, calibration)
%
% Description:
%    A modulation is a temporal variation of the device primaries, from a
%    background in a certain direction. This function takes in
%    specification of a direction, in a directionStruct, and a temporal
%    waveform for this variation and creates the modulation.
%
% Input:
%    directionStruct   - a single struct array (for one observer age), with
%                        the following fields:
%                          * backgroundPrimary   : the primary values for
%                                                  the background.
%                          * differentialPositive: the difference in 
%                                                  primary values to be
%                                                  added to the background
%                                                  primary to create the
%                                                  positive direction
%                          * differentialNegative: the difference in 
%                                                  primary values to be
%                                                  added to the background
%                                                  primary to create the
%                                                  negative direction
%                          * describe            : Any additional
%                                                 (meta)-information that
%                                                 might be stored
%    directionWaveform - A 1xT vector of contrast (in range [-1,1]) on 
%                        direction at each timepoint t.
%    calibration       - OneLight calibration struct
% Output:
%    modulation        - Structure with all the information necessary to 
%                        run the modulation in these fields:
%                          * waveformMatrix : NxT matrix of temporal 
%                                             waveforms, where each row
%                                             corresponds to a different
%                                             the waveform for a different
%                                             vector of primary values.
%                                             First row is background (all
%                                             ones), other rows are paired:
%                                             positive differential
%                                             direction primary, followed
%                                             by negative differential.
%                          * primaryValues  : PxN matrix of primary values
%                                             for all the primary basis
%                                             vectors used. First column is
%                                             background, other columns are
%                                             paired similar to
%                                             waveformMatrix.
%                          * primaryWaveform: PxT matrix of device primary 
%                                             value power at each timepoint
%                          * nominalSPDs    : Nominal SPD at each timepoint
%                          * starts, stops  : starts and stops to put this
%                                             primaryWaveform on the device
%
% Optional key/value pairs.
%    None.
%
% See also: 
%    OLMakeModulationsStartsStops, 
%    OLReceptorIsolateMakeModulationStartsStops

% NOTES:
%    * [01/30/18  jv  TODO: Currently can only deal with one direction. 
%       Underlying architecture can deal with multiple, so that should be
%       implement here. Will require some clever thinking to deal with
%       gamut limitations.]
% 
% History:
%    07/21/17  dhb       Tried to improve comments.
%    08/09/17  dhb, mab  Compute pos/neg diff more flexibly.
%    01/29/18  dhb, jv   Moved waveform generation to OLWaveformFromParams.
%    01/30/18  jv        Updated to use the new OLPrimaryWaveform and
%                        OLPrimaryStartsStops machinery.
%                        Takes in a waveform vector, rather than params.

%% Input validation, initialization
parser = inputParser();
parser.addRequired('directionStruct',@isstruct);
parser.addRequired('directionWaveform',@isnumeric);
parser.addRequired('calibration',@isstruct);
parser.parse(directionStruct,directionWaveform,calibration,varargin{:});

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
waveformBackground = ones(1, length(directionWaveform));
waveformPos = (directionWaveform >= 0) .* directionWaveform;
waveformNeg = (directionWaveform < 0) .* -directionWaveform;
waveformMatrix = [waveformBackground; waveformPos; waveformNeg];

%% Assemble primary values matrix
if any(waveformNeg) % waveformNeg is non-empty
    assert(~isempty(directionStruct.differentialNegative),'directionStruct.differentialNegative cannot be empty if there is a negative component to the waveform');
else
    % if no negative component to the waveform, set the negative
    % differential primary to zeroes. 
    directionStruct.differentialNegative = zeros(size(directionStruct.differentialPositive)); 
end
primaryValues = [directionStruct.backgroundPrimary, directionStruct.differentialPositive, directionStruct.differentialNegative];

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