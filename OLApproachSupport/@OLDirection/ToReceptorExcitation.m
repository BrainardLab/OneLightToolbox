function [excitations, SPDs] = ToReceptorExcitations(direction, receptors)
% Predicts receptor excitations from OLDirection
%
% Syntax:
%   excitations = direction.ToReceptorExcitations(T_receptors)
%   excitations = direction.ToReceptorExcitations(SSTReceptor)
%   excitations = ToReceptorExcitations(direction, ...)
%   excitations = ToReceptorExcitations([direction1 direction2], ...)
%   [excitations, SPDs] = ...
%
% Description:
%    Predicts the excitation on the specified receptors, by the (positive
%    and negative) primary values of an OLDirection. Since these are
%    differential primary values, the returned excitations can be
%    interpreted as the change in receptor excitation resultant from this
%    OLDirection.
%
% Inputs:
%    direction  - OLDirection object(array) specifying the direction to
%                 predict excitations for.
%    receptors  - either:
%                 - RxnWls matrix (T_receptors) of R receptor sensitivities
%                   sampled at nWls wavelength bands
%                 - SSTReceptor-object, in which case the
%                   T.T_energyNormalized matrix will be used
% Outputs:
%    excitation - Rx(2)N matrix for of excitations of the N directions. For
%                 each unipolar direction, a single column of excitations
%                 is added, for each bipolar direction the excitations
%                 of the positive and negative component are added
%                 separately.
%    SPDs       - The predicted SPD of the direction
%
% Optional key/value pairs:
%    None.
%
% See also:
%    OLDirection, OLDirection.ToSPDs, SPDToReceptorExcitation

% History:
%    03/08/18  jv  wrote it.

%% Input validation
parser = inputParser;
parser.addRequired('direction',@(x) isa(x,'OLDirection'));
parser.addRequired('receptors',@(x) isnumeric(x) || isa(x,'SSTReceptor'));
parser.parse(direction, receptors);

%% to SPDs
if isscalar(direction)
    SPDs = direction.ToPredictedSPD;
else
    SPDs = [];
    for i = 1:numel(direction)
        SPDs = cat(2,SPDs,ToPredictedSPD(direction(i)));
    end
end

%% to excitations
excitations = SPDToReceptorExcitation(SPDs, receptors);

end