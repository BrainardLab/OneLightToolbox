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
%    contrasts      - Rx1 vector of contrasts on R receptors of direction 
%                     on background
%    excitation     - Rx2 matrix of excitations of each receptor type to
%                     direction, and background
%    excitationDiff - Rx1 matrix of difference in excitation of each
%                     receptor type between direction and background
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

%% Convert to unipolar
unipolar = OLDirection_unipolar(direction.differentialPositive, direction.calibration);
[unipolarContrasts, excitation, excitationDiff] = ToDesiredReceptorContrast(unipolar, background, receptors);
contrasts = OLUnipolarToBipolarContrast(unipolarContrasts);