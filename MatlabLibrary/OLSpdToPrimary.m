function [effectivePrimary, primary, predictedSpd, outOfRange] = OLSpdToPrimary(oneLightCal, targetSpd, lambda, verbose)
% OLSpdToPrimary - Converts a spectrum into normalized primary OneLight mirror settings.
%
% Syntax:
% [effectivePrimary, primary, predictedSpd, outOfRange] = OLSpdToPrimary(oneLightCal, targetSpd)
% [effectivePrimary, primary, predictedSpd, outOfRange] = OLSpdToPrimary(oneLightCal, targetSpd, lambda)
% [effectivePrimary, primary, predictedSpd, outOfRange] = OLSpdToPrimary(oneLightCal, targetSpd, lambda, verbose)
%
% Description:
% Convert a spectral power distribution to the linear 0-1 fraction of light
% that we need from each column of mirrors.  No gamma correction is applied
% to the primary settings.
%
% Input:
% oneLightCal (struct) - OneLight calibration file after it has been
%     processed by OLInitCal.
% targetSpd (Mx1) - Target spectrum.  Should be on the same wavelength
%     spacing and power units as the PR-650 field of the calibration
%     structure.
% lambda (scalar) - Determines how much smoothing we apply to the settings.
%     Needed because there are more columns than wavelengths on the PR-650.
%     Defaults to 0.1.
% verbose (logical) - Enables/disables verbose diagnostic information.
%     Defaults to false.
%
% Output:
% effectivePrimary (Nx1) - The normalized power level for effective primary
%     of the OneLight. Not gamma corrected.
% primary (Nx1) - The normalized power level for each column of the
%     OneLight.  These values are not gamma corrected.  N is the number
%     of columns specified by the OneLight object, and corresponds to
%     the number of columns on its DLP chip.
% predictedSpd (struct) - What we think we'll produce with the returned
%     primary settings, for both PR-650 and OmniDriver radiometers. This
%     can deviate from the target because, for example, the OneLight device
%     has a finite spectral bandwidth.
% outOfRange (struct) - Contains 4 fields: low, high, numLow, and numHigh.
%     Low is true if the passed targetSpd has less power at any wavelength
%     than the dark measurement.  High is true if the computed primaries
%     exceed 1 for any column.  'numLow' and 'numHight' report the number
%     of out of range values.
%
% 3/29/13  dhb  Changed some variable names to make this cleaner (Settings -> Primary).
% 11/08/15 dhb  Specify explicitly that lsqlin algorithm should be 'active-set', to satisfy warning in newer versions of Matlab

% Validate the number of inputs.
error(nargchk(2, 4, nargin));

% Setup some defaults.
if ~exist('lambda', 'var') || isempty(lambda)
    lambda = 0.1;
end
if ~exist('verbose', 'var') || isempty(verbose)
    verbose = false;
end

% Make sure that the calibration file has been processed by OLInitCal.
assert(isfield(oneLightCal, 'computed'), 'OLSpdToPrimary:InvalidCalFile', ...
    'The calibration file needs to be processed by OLInitCal.');

% Look to see if any of the targetSpd wavelengths are less than the dark
% measurement.
if any((targetSpd - oneLightCal.computed.pr650MeanDark) < 0)
    outOfRange.low = true;
else
    outOfRange.low = false;
end

% Find column input values for targetSpd without enforcing any constraints.  It's
% not completely clear why we do this, as the only way we use the answer is to
% determine the size of some vectors below, and for debugging.
targeteffectivePrimary = pinv(oneLightCal.computed.pr650M) * (targetSpd - oneLightCal.computed.pr650MeanDark);
targetPrimary = oneLightCal.computed.D * targeteffectivePrimary;
if verbose
    fprintf('Pinv settings: min = %g, max = %g\n', min(targetPrimary(:)), max(targetPrimary(:)));
end

% Use lsqlin to enforce constraints.
% We will assume that the D matrix has non-overlapping sets of 1's in each of its
% columns, which is how we currently do our calibration.  When this is true, we can
% enforce positivity in the effective settings domain and be guaranteed that it will
% also hold in the returned (column by column) domain.  This simplifies our life
% a little, because it means that the predicted spectrum is actually the predicted
% spectrum.
%
% We do check and throw an error if this assumption turns out not to be valid, which
% could happen if at some point in the future we change the conditions we use to
% calibrate.
C1 = oneLightCal.computed.pr650M;
d1 = targetSpd - oneLightCal.computed.pr650MeanDark;
C2 = zeros(length(targeteffectivePrimary)-1, length(targeteffectivePrimary));
for i = 1:length(targeteffectivePrimary)-1
    C2(i,i) = lambda;
    C2(i,i+1) = -lambda;
end
d2 = zeros(length(targeteffectivePrimary)-1, 1);
C = [C1 ; C2];
d = [d1 ; d2];
A = -oneLightCal.computed.D;
b = zeros(size(targetPrimary))-eps;
vlb = zeros(size(targeteffectivePrimary));
options = optimset('lsqlin');
options = optimset(options,'Diagnostics','off','Display','off','LargeScale','off','Algorithm','active-set');
targeteffectivePrimary1 = lsqlin(C,d,A,b,[],[],vlb,[],[],options);
if verbose
    fprintf('Lsqlin effective settings: min = %g, max = %g\n', min(targeteffectivePrimary1(:)), max(targeteffectivePrimary1(:)));
end
targeteffectivePrimary1(targeteffectivePrimary1 < 0) = 0;
primary = oneLightCal.computed.D * targeteffectivePrimary1;
effectivePrimary = targeteffectivePrimary1;
if (any(primary < 0))
    error('D matrix used in calibration does not have assummed properties.  Read comments in source.');
end
index1 = find(primary < 0);
index2 = find(primary > 1);

% Store the number of out of range values.
outOfRange.numLow = length(index1);
outOfRange.numHigh = length(index2);

if verbose
    fprintf('Number of target settings less than 0: %d, number greater than 1: %d\n', outOfRange.numLow, outOfRange.numHigh);
end

% Look to see if any of the computed primary settings exceed 1.
if any(primary > 1)
    outOfRange.high = true;
else
    outOfRange.high = false;
end

predictedSpd.pr650 = oneLightCal.computed.pr650M * targeteffectivePrimary1 + oneLightCal.computed.pr650MeanDark;
if (oneLightCal.describe.useOmni)
    predictedSpd.omni = oneLightCal.computed.omniM * targeteffectivePrimary1 + oneLightCal.computed.omniMeanDark;
end