function effectivePrimary = OLSpdToPrimary(oneLightCal, targetSpd, varargin)
% OLSpdToPrimary - Converts a spectrum into normalized primary OneLight mirror settings.
%
% Examples:
% effectivePrimary = OLSpdToPrimary(oneLightCal, targetSpd)
% effectivePrimary = OLSpdToPrimary(oneLightCal, targetSpd, 'lambda', 0.01)
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
% This routine will return values that are greater than 1, which can be
% useful if one wants to use it to scale input into gamut.
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
%  'lambda' - value (default 0.1). Value of smoothing parameter.  Smaller
%             lead to less smoothing, with 0 doing no smoothing at all.
%  'differentialMode' - true/false (default false). Run in differential
%                       mode.  This means, don't subtract dark light.
%                       Useful when we want to find delta primaries that
%                       produce a predicted delta spd.
% See also:
%   OLPrimaryToSpd, OLPrimaryToSettings, OLSettingsToStartsStops, OLSpdToPrimaryTest
%
% 3/29/13  dhb  Changed some variable names to make this cleaner (Settings -> Primary).
% 11/08/15 dhb  Specify explicitly that lsqlin algorithm should be 'active-set', ...
%               to satisfy warning in newer versions of Matlab
% 06/01/17 dhb  Remove primary return argument, because I don't think it
%               should be used.
% 06/04/17 dhb  Got rid of old code that dated from before we switched to
%               effective primaries concept.

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

% Find column input values for targetSpd without enforcing any constraints.  It's
% not completely clear why we do this, as the only way we use the answer is to
% determine the size of some vectors below, and for debugging.
targetEffectivePrimary = pinv(oneLightCal.computed.pr650M) * (targetSpd - darkSpd);
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
    A = [];
    b = [];
    vlb = zeros(size(targetEffectivePrimary));
end
options = optimset('lsqlin');
options = optimset(options,'Diagnostics','off','Display','off','LargeScale','off','Algorithm','active-set');
targetEffectivePrimary1 = lsqlin(C,d,A,b,[],[],vlb,[],[],options);
if params.verbose
    fprintf('Lsqlin effective primaries: min = %g, max = %g\n', min(targetEffectivePrimary1(:)), max(targetEffectivePrimary1(:)));
end
if ~params.differentialMode
    targetEffectivePrimary1(targetEffectivePrimary1 < 0) = 0;
end

% Set return values
effectivePrimary = targetEffectivePrimary1;

if params.verbose
    fprintf('Number of target settings less than 0: %d, number greater than 1: %d\n', length(find(effectivePrimary < 0)), length(find(effectivePrimary > 1)));
end
