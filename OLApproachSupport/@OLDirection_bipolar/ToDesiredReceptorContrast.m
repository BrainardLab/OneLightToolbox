function [contrasts, excitation, excitationDiff] = ToDesiredReceptorContrast(direction, background, receptors)
% Calculates photoreceptorcontrast of direction on background desired SPDs
%
% Syntax:
%   contrasts = ToDesiredReceptorContrast(direction, background, SSTReceptor)
%   contrasts = ToDesiredReceptorContrast(direction, background, T_receptors)
%   contrasts = direction.ToDesiredReceptorContrast(background, ...)
%   [contrasts, excitation, excitationDiff] = ...
%
% Description:
%    Predicts from desired differential SPDs of OLDirection, contrasts
%    compared to background. Takes dark level into account. If desired
%    differential SPD is not defined in object, predicts from primary
%    values.
%
% Inputs:
%    direction      - OLDirection_bipolar specifying the direction to
%                     predict contrast for
%    background     - OLDirection_unipolar specifying the background to 
%                     predict contrast on 
%    receptors      - either:
%                     - RxnWls matrix (T_receptors) of R receptor
%                       sensitivities sampled at nWls wavelength bands
%                     - SSTReceptor-object, in which case the
%                       T.T_energyNormalized matrix will be used
%
% Outputs:
%    contrasts      - R vector of mean (over pos and neg
%                     components) contrasts on R receptors. Use extra
%                     return outputs below and compute,if you want separate
%                     positive and negative contrast values.
%    excitation     - Rx3 matrix of excitations of each receptor type to
%                     background, direction positive component and
%                     direction negative component.
%    excitationDiff - Rx2 matrix of difference in excitation of each
%                     receptor type between background and direction
%                     positive component and direction negative component.
%
% Optional key/value pairs:
%    None.
%
% See also:
%    SPDToReceptorExcitation; ReceptorExcitationToReceptorContrast

% History:
%    03/14/18  jv  wrote it.

%% Input validation
parser = inputParser;
parser.addRequired('direction',@(x) isa(x,'OLDirection_bipolar'));
parser.addRequired('background',@(x) isa(x,'OLDirection_unipolar'));
parser.addRequired('receptors',@(x) isnumeric(x) || isa(x,'SSTReceptor'));
parser.parse(direction, background, receptors);
assert(matchingCalibration(direction,background),'OneLightToolbox:ApproachSupport:OLValidateDirection:MismatchedCalibration',...
       'Direction and background do not share a calibration.');

%% Get background SPD
if isempty(background.SPDdifferentialDesired)
    desiredBackgroundSPD = background.ToPredictedSPD;
else
    desiredBackgroundSPD = background.SPDdifferentialDesired;
end

%% Add dark light
desiredBackgroundSPD = desiredBackgroundSPD + background.calibration.computed.pr650MeanDark;

%% Get combined direction + background SPD
if isempty(direction.SPDdifferentialDesired)
    SPDdifferentialDesired = direction.ToPredictedSPD;
else
    SPDdifferentialDesired = direction.SPDdifferentialDesired;
end
desiredPositive = SPDdifferentialDesired(:,1) + desiredBackgroundSPD;
desiredNegative = SPDdifferentialDesired(:,2) + desiredBackgroundSPD;

%% Calculate contrast
[contrastsPos, excitationPos, excitationDiffPos] = SPDToReceptorContrast([desiredBackgroundSPD desiredPositive],receptors);
[contrastsNeg, excitationNeg, excitationDiffNeg] = SPDToReceptorContrast([desiredBackgroundSPD desiredNegative],receptors);

%% Combine outputs
contrasts = mean(abs([contrastsPos(:,1) contrastsNeg(:,1)]),2);
excitation = [excitationPos(:,1:2) excitationNeg(:,2)];
excitationDiff = [excitationDiffPos(:,1) excitationDiffNeg(:,1)];