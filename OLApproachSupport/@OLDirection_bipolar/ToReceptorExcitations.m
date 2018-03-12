function excitations = ToReceptorExcitations(direction, receptors)
% Predicts receptor excitations from OLDirection
%
% Syntax:
%   excitations = direction.ToReceptorExcitations(T_receptors);
%   excitations = direction.ToReceptorExcitations(SSTReceptor);
%   excitations = ToReceptorExcitations(direction, ...);
%   [excitations, SPDs] = ...
%
% Description:
%    Predicts the excitation on the specified receptors, by the positive
%    and negative component of an OLDirection. Since these components are
%    vectors of differential primary values, the returned excitations can
%    be interpreted as the change in receptor excitation resultant from
%    this OLDirection.
%
% Inputs:
%    direction  - OLDirection object specifying the direction to predict 
%                 excitations for.
%    receptors  - either:
%                 - RxnWls matrix (T_receptors) of R receptor sensitivities
%                   sampled at nWls wavelength bands
%                 - SSTReceptor-object, in which case the
%                   T.T_energyNormalized matrix will be used
% Outputs:
%    excitation - Rx2 matrix of excitations of the R receptors for both the
%                 positive and negative component of the direction
%    SPDs       - The SPDs of the positive and negative differential
%                 component of direction
%
% Optional key/value pairs:
%    None.
%
% Notes:
%    * TODO: implement nonscalar input support -- can currently only deal
%            with a single OLDirection input
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
SPDs = direction.ToSPDs;

%% to excitations
excitations = SPDToReceptorExcitation(SPDs, receptors);

end