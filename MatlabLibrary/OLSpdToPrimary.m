function [effectivePrimary primary] = OLSpdToPrimary(oneLightCal, targetSpd, varargin)
function effectivePrimary = OLSpdToPrimary(oneLightCal, targetSpd, varargin)
% OLSpdToPrimary - Converts a spectrum into normalized primary OneLight mirror settings.
%
% Examples:
% effectivePrimary = OLSpdToPrimary(oneLightCal, targetSpd)
% effectivePrimary = OLSpdToPrimary(oneLightCal, targetSpd, 'lambda', 0.2)
% effectivePrimary = OLSpdToPrimary(oneLightCal, targetSpd, 'verbose, true)
%
% Description:
% Convert a spectral power distribution to the linear 0-1 fraction of light
% that we need from each column of mirrors.  No gamma correction is applied
% to the primary settings.
%
% This routine also allows for a 'differentialMode' which is false unless
% the 'differentialMode' key value pair is passed.
%
% Input:
% oneLightCal (struct) - OneLight calibration file after it has been
%     processed by OLInitCal.
% targetSpd (nWlsx1) - The target spectrum, sampled at the wavelengths
%     used in the calibration file (typically 380 to 780 nm in 2 nm steps.)
%
% Output:
% effectivePrimary (Nx1) - The [0-1] primary value for each effective primary
%     of the OneLight. N is the number of effective primaries. Not gamma corrected.
%     What we mean by effective primaries is the number of column groups
%     that were set up at calibration time.  Often these consiste of 16
%     physical columns of the DLP chip.
%
% Optional Key-Value Pairs:
%  'verbose' - true/false (default false). Provide more diagnostic output.
%  'lambda' - value (default 0.1). Value of smoothing parameter.
%  'differentialMode' - true/false (default false). Run in differential
%                       mode.  This means, don't subtract dark light.
%                       Useful when we want to find delta primaries that
%                       produce a predicted delta spd.%
%
% NOTE: This routine contains vestigal code which is computing values thar
% are never used or returned.  Could use some cleaning.
%
% 3/29/13  dhb  Changed some variable names to make this cleaner (Settings -> Primary).
% 11/08/15 dhb  Specify explicitly that lsqlin algorithm should be 'active-set', ...
%               to satisfy warning in newer versions of Matlab
% 06/01/17 dhb  Remove primary return argument, because I don't think it
%               should be used.
%

% Parse the input
p = inputParser;
p.addOptional('verbose', false, @islogical);
p.addOptional('lambda', 0.1, @isscalar);
p.addOptional('differentialMode', false, @islogical);
p.parse(varargin{:});
params = p.Results;

if params.differentialMode
    darkSpd = zeros(size(oneLightCal.computed.pr650MeanDark));
else
    darkSpd = oneLightCal.computed.pr650MeanDark;
end

% Make sure that the calibration file has been processed by OLInitCal.
assert(isfield(oneLightCal, 'computed'), 'OLSpdToPrimary:InvalidCalFile', ...
    'The calibration file needs to be processed by OLInitCal.');

% Look to see if any of the targetSpd wavelengths are less than the dark
% measurement.
if any((targetSpd - darkSpd) < 0)
    outOfRange.low = true;
else
    outOfRange.low = false;
end

% Find column input values for targetSpd without enforcing any constraints.  It's
% not completely clear why we do this, as the only way we use the answer is to
% determine the size of some vectors below, and for debugging.
targetEffectivePrimary = pinv(oneLightCal.computed.pr650M) * (targetSpd - darkSpd);
%targetPrimary = oneLightCal.computed.D * targeteffectivePrimary;
if params.verbose
    fprintf('Pinv settings: min = %g, max = %g\n', min(targetEffectivePrimary(:)), max(targetEffectivePrimary(:)));
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
d1 = targetSpd - darkSpd;
C2 = zeros(length(targetEffectivePrimary)-1, length(targetEffectivePrimary));
for i = 1:length(targetEffectivePrimary)-1
    C2(i,i) = params.lambda;
    C2(i,i+1) = -params.lambda;
end
d2 = zeros(length(targetEffectivePrimary)-1, 1);
C = [C1 ; C2];
d = [d1 ; d2];

if params.differentialMode
    A = [];
    b = [];
    vlb = []; % Allow primaries to <0 if we are in differential mode
else
    A = -oneLightCal.computed.D;
    b = zeros(size(targetPrimary))-eps;
    vlb = zeros(size(targetEffectivePrimary));
end
options = optimset('lsqlin');
options = optimset(options,'Diagnostics','off','Display','off','LargeScale','off','Algorithm','active-set');
targeteffectivePrimary1 = lsqlin(C,d,A,b,[],[],vlb,[],[],options);

if params.verbose
    fprintf('Lsqlin effective settings: min = %g, max = %g\n', min(targeteffectivePrimary1(:)), max(targeteffectivePrimary1(:)));
end
if ~params.differentialMode
    targeteffectivePrimary1(targeteffectivePrimary1 < 0) = 0; % Bound to 0
end
primary = oneLightCal.computed.D * targeteffectivePrimary1;
effectivePrimary = targeteffectivePrimary1;
if ~params.differentialMode
    if (any(primary < 0))
        error('D matrix used in calibration does not have assumed properties.  Read comments in source.');
    end
end
index1 = find(primary < 0);
index2 = find(primary > 1);

% Store the number of out of range values.
outOfRange.numLow = length(index1);
outOfRange.numHigh = length(index2);

if params.verbose
    fprintf('Number of target settings less than 0: %d, number greater than 1: %d\n', outOfRange.numLow, outOfRange.numHigh);
end

% Look to see if any of the computed primary settings exceed 1.
if any(primary > 1)
    outOfRange.high = true;
else
    outOfRange.high = false;
end

predictedSpd.pr650 = oneLightCal.computed.pr650M * targeteffectivePrimary1 + darkSpd;