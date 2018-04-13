function [primary,predictedSpd,errorFraction] = OLSpdToPrimary(oneLightCal, targetSpd, varargin)
% Converts a spectrum into normalized primary OneLight mirror values.
%
% Syntax:
%     primary = OLSpdToPrimary(oneLightCal, targetSpd)
%     primary = OLSpdToPrimary(oneLightCal, targetSpd, 'lambda', 0.01)
%     primary = OLSpdToPrimary(oneLightCal, targetSpd, 'verbose, true)
%
% Description:
%    Convert a spectral power distribution to the linear 0-1 fraction of
%    light that we need from each effective primary.
%    No gamma correction is applied to the primary values.
%
%    What we mean by effective primaries is the number of column groups
%    that were set up at calibration time.  Often these consiste of 16
%    physical columns of the DLP chip.
%
%    This routine also allows for a 'differentialMode' which is false unless
%    the 'differentialMode' key value pair is passed.
%
%    This routine keeps values in the range [0,1] in normal mode, and in
%    range [-1,1] in differential mode.
%
%    The routine works by using lsqlin to minimize the SSE between target and
%    desired spectra.  The value of the 'lambda' key is smoothing parameter.
%    This weights an additional error term that tries to minimize the SSE
%    of the difference between neighboring primary values. This can reduce
%    ringing in the obtained primaries, at the cost of increasing the SSE
%    to which the target spd is reproduced.
%
%    Set value of 'checkSpd' to true to force a check on how well the
%    target is acheived.
%
% Inpust:
%    oneLightCal       - Struct. OneLight calibration file after it has been
%                        processed by OLInitCal.
%    targetSpd         - Column vector providing the target spectrum, sampled at the wavelengths
%                        used in the calibration file (typically 380 to 780 nm in 2 nm steps).
%
% Outputs:
%    primary           - Column vector containing the primary values for each effective primary
%                        of the OneLight. nPrimaries is the number of
%                        effective primaries. Not gamma corrected.
%    predictedSpd      - The spd predicted for the returned primaries.
%    errorFraction     - How close the predictedSpd came to the target, in
%                        fractional terms.
%
% 
% Optional Key-Value Pairs:
%  'verbose'           - Boolean (default false). Provide more diagnostic output.
%  'lambda'            - Scalar (default 0.005). Value of primary smoothing
%                        parameter.  Smaller values lead to less smoothing,
%                        with 0 doing no smoothing at all.
%   'primaryHeadroom'  - Scalar.  Headroom to leave on primaries.  Default
%                        0. How much headroom to protect in definition of
%                        in gamut.  Range used for check and truncation is
%                        [primaryHeadroom 1-primaryHeadroom]. Do not change
%                        this default.  Sometimes assumed to be true by a
%                        caller.
%   'primaryTolerance  - Scalar. Truncate to range [0,1] if primaries are
%                        within this tolerance of [0,1]. Default 1e-6, and
%                        'checkPrimaryOutOfRange' value is true.
%   'checkPrimaryOutOfRange' - Boolean. Perform primary tolerance check. Default true.
%   'differentialMode' - Boolean (default false). Run in differential
%                       mode.  This means, don't subtract dark light.
%                       Useful when we want to find delta primaries that
%                       produce a predicted delta spd.
%   'checkSpd'        - Boolean (default false). Because of smoothing and
%                       gamut limitations, this is not guaranteed to
%                       produce primaries that lead to the predictedSpd
%                       matching the targetSpd.  Set this to true to check
%                       force an error if difference exceeds tolerance.
%                       Otherwise, the toleranceFraction actually obtained
%                       is retruned. Tolerance is given by spdTolerance.
%   'spdToleranceFraction' - Scalar (default 0.01). If checkSpd is true, the
%                       tolerance to avoid an error message is this
%                       fraction times the maximum of targetSpd.
%
% See also:
%   OLPrimaryToSpd, OLPrimaryToSettings, OLSettingsToStartsStops, OLSpdToPrimaryTest
%

% History:
%   03/29/13  dhb  Changed some variable names to make this cleaner (Settings -> Primary).
%   11/08/15  dhb  Specify explicitly that lsqlin algorithm should be 'active-set', ...
%                  to satisfy warning in newer versions of Matlab
%   06/01/17  dhb  Remove primary return argument, because I don't think it
%                  should be used.
%   06/04/17  dhb  Got rid of old code that dated from before we switched to
%                  effective primaries concept.
%   04/04/18  dhb  Change lambda default to 0.005.

%% Parse the input
p = inputParser;
p.addParameter('verbose', false, @islogical);
p.addParameter('lambda', 0.005, @isscalar);
p.addParameter('primaryHeadroom', 0, @isscalar);
p.addParameter('primaryTolerance', 1e-6, @isscalar);
p.addParameter('checkPrimaryOutOfRange', true, @islogical);
p.addParameter('differentialMode', false, @islogical);
p.addParameter('checkSpd', false, @islogical);
p.addParameter('spdToleranceFraction', 0.01, @isscalar);
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
    pinvprimary = pinv(oneLightCal.computed.pr650M) * (targetSpd - darkSpd);
    if params.verbose
        fprintf('Pinv values: min = %g, max = %g\n', min(pinvprimary(:)), max(pinvprimary(:)));
    end
end

%% Use lsqlin to enforce constraints.
%
% This first constraint (C1,d1) minimizes the error between the predicted spectrum
% and the desired spectrum.
C1 = oneLightCal.computed.pr650M;
d1 = targetSpd - darkSpd;

% The second constraint computes the difference between between neighboring
% values and tries to make this small.  How much this is weighted 
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
options = optimset(options,'Diagnostics','off','Display','off');
primary = lsqlin(C,d,[],[],[],[],vlb,vub,[],options);
if params.verbose
    fprintf('Lsqlin effective primaries: min = %g, max = %g\n', min(primary(:)), max(primary(:)));
end

%% Make sure we enforce bounds, in case lsqlin has a bit of numerical slop
primary = OLCheckPrimaryGamut(primary, ...
    'primaryHeadroom',p.Results.primaryHeadroom, ...
    'primaryTolerance',p.Results.primaryTolerance, ...
    'checkPrimaryOutOfRange',p.Results.checkPrimaryOutOfRange, ...
    'differentialMode',p.Results.differentialMode);

%% Predict spd, and check if specified
predictedSpd = OLPrimaryToSpd(oneLightCal,primary, ...
    'primaryHeadroom',p.Results.primaryHeadroom, ...
    'primaryTolerance',p.Results.primaryTolerance, ...
    'checkPrimaryOutOfRange',p.Results.checkPrimaryOutOfRange, ...
    'differentialMode',params.differentialMode);

[~,errorFraction] = OLCheckSpdTolerance(targetSpd,predictedSpd, ...
    'checkSpd',p.Results.checkSpd,'spdToleranceFraction',p.Results.spdToleranceFraction);
end


