function SPDs = ToPredictedSPD(direction, varargin)
% Predict positive and negative differential SPDs of bipolar direction
%
% Syntax:
%   SPDs = direction_bipolar.ToPredictedSPD
%   SPDs = ToPredictedSPD(direction_bipolar)
%   SPDs = ToPredictedSPD([direction1, direction2])
%
% Description:
%    Predicts the spectral power distribution corresponding to the positive
%    and negative components of an OLDirection_bipolar object. Since these
%    components are vectors of differential primary values, the returned
%    SPDs can be interpreted as the change in spectral power resultant from
%    this OLDirection_bipolar.
%
% Inputs:
%    direction  - (matrix of) OLDirection_bipolar object(s) specifying the
%                 direction(s) to predict SPDs for.
%
% Outputs:
%    SPDs       - nWlsx2N matrix of SPDs (power at each of nWls
%                 wavelengthbands), of the positive and negative
%                 differential component of direction (separate columns),
%                 for each of N directions
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
parser.addRequired('direction',@(x) isa(x,'OLDirection_bipolar'));
parser.parse(direction, varargin{:});

%% Calculate SPDs
if isscalar(direction)
    SPDs = OLPrimaryToSpd(direction.calibration,[direction.differentialPositive direction.differentialNegative],'differentialMode',true);
else
    SPDs = [];
    for i = 1:numel(direction)
        SPDs = cat(2,SPDs,direction(i).ToPredictedSPD);
    end
end
end