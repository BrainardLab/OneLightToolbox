function SPDs = ToPredictedSPD(direction, varargin)
% Predict differential SPD of unipolar direction
%
% Syntax:
%   SPDs = direction_unipolar.ToPredictedSPD;
%   SPDs = ToPredictedSPD(direction_unipolar);
%   SPDs = ToPredictedSPD([direction_unipolar1 direction_unipolar2]);
%
% Description:
%    Predicts the spectral power distribution corresponding to the primary
%    values of a OLDirection_unipolar object. Since these are differential
%    primary values, the returned SPDs can be interpreted as the change in
%    spectral power resultant from this OLDirection_unipolar.
%
% Inputs:
%    direction  - (matrix of) OLDirection_unipolar object(s) specifying the
%                 direction(s) to predict SPDs for.
%
% Outputs:
%    SPDs       - nWlsxN matrix of SPDs (power at each of nWls
%                 wavelengthbands), of differential primary values of
%                 direction (columns), for N directions
%
% See also:
%    OLDirection, OLPrimaryToSpd

% History:
%    03/08/18  jv  wrote it.
%    03/14/18  jv  removed 'background' argument. Instead, ToPredictedSPDs
%                  should be called on an OLDirection that forms the
%                  combination to predicted.
%                  Added support for multiple directions.

%% Input validation
parser = inputParser;
parser.addRequired('direction',@(x) isa(x,'OLDirection_unipolar'));
parser.parse(direction, varargin{:});

%% Calculate SPDs
if isscalar(direction)
    SPDs = OLPrimaryToSpd(direction.calibration,direction.differentialPrimaryValues,'differentialMode',true);
else
    SPDs = [];
    for i = 1:numel(direction)
        SPDs = cat(2,SPDs,direction(i).ToPredictedSPD);
    end
end
end