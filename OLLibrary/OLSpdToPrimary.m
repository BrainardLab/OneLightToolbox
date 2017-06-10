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
% This routine truncates values into the range [0,1] in normal mode, and into
% range [-1,1] in differential mode.
%
% Input:
% oneLightCal (struct) - OneLight calibration file after it has been
%                        processed by OLInitCal.
% targetSpd (nWlsx1) - The target spectrum, sampled at the wavelengths
%                      used in the calibration file (typically 380 to 780 nm in 2 nm steps).
%
% Output:
% effectivePrimary (nPrimariesx1) - The [0-1] primary value for each effective primary
%                                   of the OneLight. nPrimaries is the number of effective primaries.
%                                   Not gamma corrected.
%
% What we mean by effective primaries is the number of column groups
% that were set up at calibration time.  Often these consiste of 16
% physical columns of the DLP chip.
% 
% Optional Key-Value Pairs:
%  'verbose' - true/false (default false). Provide more diagnostic output.
%  'lambda' - value (default 0.1). Value of smoothing parameter.  Smaller
%             lead to less smoothing, with 0 doing no smoothing at all.
%  'differentialMode' - true/false (default false). Run in differential
%                       mode.  This means, don't subtract dark light.
%                       Useful when we want to find delta primaries that
%                       produce a predicted delta spd.
%
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

%% Parse the input
p = inputParser;
p.addParameter('verbose', false, @islogical);
p.addParameter('lambda', 0.1, @isscalar);
p.addParameter('differentialMode', false, @islogical);
p.parse(varargin{:});
params = p.Results;

%% Check wavelength sampling
nWls = size(targetSpd,1);
if (nWls ~= oneLightCal.describe.S(3))
    error('Wavelength sampling inconsistency between passed spectrum and calibration');
end

%% In differential mode, we ignore the dark light, otherwise we snag it from
% the calibration file.
if params.differentialMode
    darkSpd = zeros(size(oneLightCal.computed.pr650MeanDark));
else
    darkSpd = oneLightCal.computed.pr650MeanDark;
end

%% Make sure that the calibration file has been processed by OLInitCal.
assert(isfield(oneLightCal, 'computed'), 'OLSpdToPrimary:InvalidCalFile', ...
    'The calibration file needs to be processed by OLInitCal.');

%% Find primaries the linear way, without any constraints
%
% This would be the most straightforward way to find the primaries, but for many
% spectra the primary values really ring, which is why we use the search based
% method below and enforce a smoothing regularization constraint.
%
% We skip this step unless we are debuging.
DEBUG = 0;
if (DEBUG)
    pinvEffectivePrimary = pinv(oneLightCal.computed.pr650M) * (targetSpd - darkSpd);
    if params.verbose
        fprintf('Pinv settings: min = %g, max = %g\n', min(pinvEffectivePrimary(:)), max(pinvEffectivePrimary(:)));
    end
end

%% Use lsqlin to enforce constraints.
%
% This first constraint (C1,d1) minimizes the error between the predicted spectrum
% and the desired spectrum.
C1 = oneLightCal.computed.pr650M;
d1 = targetSpd - darkSpd;

% The second constraint computes the difference between between neighboring
% settings values and tries to make this small.  How much this is weighted 
% depends on the value of params.lambda.  The bigger params.lambda, the
% more this constraint kicks in.
nPrimaries = size(oneLightCal.computed.pr650M,2);
C2 = zeros(nPrimaries -1, nPrimaries );
for i = 1:nPrimaries -1
    C2(i,i) = params.lambda;
    C2(i,i+1) = -params.lambda;
end
d2 = zeros(nPrimaries-1,1);

% Paste together the target and smoothness constraints
C = [C1 ; C2];
d = [d1 ; d2];

% In differential mode, the bounds on primaries are [-1,1].
% Otherwise they are [0,1].
if params.differentialMode
    vlb = -ones(nPrimaries,1);
    vub = ones(nPrimaries,1);
else
    vlb = zeros(nPrimaries,1);
    vub = ones(nPrimaries,1);
end

% Call into lsqlin
options = optimset('lsqlin');
options = optimset(options,'Diagnostics','off','Display','off','LargeScale','off','Algorithm','active-set');
effectivePrimary = lsqlin(C,d,[],[],[],[],vlb,vub,[],options);
if params.verbose
    fprintf('Lsqlin effective primaries: min = %g, max = %g\n', min(effectivePrimary(:)), max(effectivePrimary(:)));
end

%% Make sure we enforce bounds, in case lsqlin has a bit of numerical slop
if params.differentialMode
    effectivePrimary(effectivePrimary < -1) = -1;
else
    effectivePrimary(effectivePrimary < 0) = 0;
end
effectivePrimary(effectivePrimary > 1) = 1;


