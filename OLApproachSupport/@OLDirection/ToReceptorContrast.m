function [contrasts, excitation, excitationDiff] = ToReceptorContrast(directions, receptors)
% Calculates contrast on photoreceptors between OLDirections
%
% Syntax:
%   contrasts = direction.ToReceptorExcitations(T_receptors)
%   contrasts = direction.ToReceptorExcitations(SSTReceptors)
%   contrasts = ToReceptorExcitations(direction, ...)
%   contrasts = ToReceptorExcitations([direction1 direction2], ...)
%   [contrasts, excitation, excitationDiff] = ...
%
% Description:
%    Predicts the contrast on the specified receptors, by the OLDirections.
%
% Inputs:
%    direction      - OLDirection object(array) specifying the direction to
%                     predict excitations for.
%    receptors      - either:
%                     - RxnWls matrix (T_receptors) of R receptor
%                       sensitivities sampled at nWls wavelength bands
%                     - SSTReceptor-object, in which case the
%                       T.T_energyNormalized matrix will be used
%
% Outputs:
%    contrasts      - NxNxR matrix of contrasts (one NxN
%                     matrix per receptor type), where contrasts(i,j,R) =
%                     excitationDiff(i,j,R) / excitation(R,i)
%    excitation     - RxN matrix of excitations of each receptor type to
%                     each SPD
%    excitationDiff - NxNxR matrix of differences in excitations (one NxN
%                     matrix per receptor type), where
%                     excitationDiff(i,j,R) = excitation(R,j) -
%                     excitation(R,i).
%
% Optional key/value pairs:
%    None.
%
% Notes:
%    In the case that only 2 directions are passed (e.g., a background
%    and a direction), the outputs are simplified as follows:
%       excitationDiff - Rx2 matrix, where the first column is the
%                      excitation(R,j) - reponse(R,i), and the second column
%                      the inverse
%       contrasts    - Rx2 matrix, where the first column is the contrast
%                      relative to the first SPD, and the second column is
%                      the contrast relative to the second SPD.
%
%    In the case that only 1 direction is passed, excitation is returned as
%    normal, but excitationDiff and contrasts are returned as Rx1
%    columnvectors of NaNs.
%
% See also:
%    SPDToReceptorExcitation; ReceptorExcitationToReceptorContrast

% History:
%    03/14/18  jv  wrote it.

%% Input validation
parser = inputParser;
parser.addRequired('directions',@(x) isa(x,'OLDirection'));
parser.addRequired('receptors',@(x) isnumeric(x) || isa(x,'SSTReceptor'));
parser.parse(directions, receptors);

%% Get excitations
excitation = ToReceptorExcitation(directions,receptors);

%% Get contrasts
[contrasts, excitationDiff] = ReceptorExcitationToReceptorContrast(excitation);

end