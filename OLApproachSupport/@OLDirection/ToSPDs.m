function SPDs = ToSPDs(direction, varargin)
% Predict SPDs of direction, either differential or including background
%
% Syntax:
%   SPDs = direction.ToSPDs;
%   SPDs = direction.ToSPDs(background);
%   SPDs = ToSPDs(direction);
%   SPDs = ToSPDs(direction, background);
%
% Description:
%    Predicts the spectral power distribution corresponding to the
%    positive and negative components of an OLDirection object. Since these
%    components are vectors of differential primary values, the returned
%    SPDs can be interpreted as the change in spectral power resultant from
%    this OLDirection.
%
%    When a background (another OLDirection object) is specified, the
%    differential primaries of the direction are added to the primaries of
%    the background, and the returned SPDs are the spectral power of
%    background +- the direction.
%
% Inputs:
%    direction  - an OLDirection object specifying the direction in primary
%                 space
%    background - [OPTIONAL] an OLDirection object specifying the
%                 background in primary space
%
% Outputs:
%    SPDs       - The SPDs of the positive and negative differential
%                 component of direction
%
% Notes:
%    * TODO: implement nonscalar input support -- can currently only deal
%            with a single OLDirection input
%
% See also:
%    OLDirection, OLPrimaryToSpd

% History:
%    03/08/18  jv  wrote it.

%% Input validation
parser = inputParser;
parser.addRequired('direction',@(x) isa(x,'OLDirection'));
parser.addOptional('background',OLDirection.NullDirection(direction.calibration),@(x) isempty(x) || isa(x,'OLDirection'));
parser.parse(direction, varargin{:});
background = parser.Results.background;

%% Calculate SPDs
totalDirection = direction + background;
SPDPos = OLPrimaryToSpd(direction.calibration,totalDirection.differentialPositive,'differentialMode',true);
SPDNeg = OLPrimaryToSpd(direction.calibration,totalDirection.differentialNegative,'differentialMode',true);
SPDs = [SPDPos SPDNeg];

end