function [settings, primaries, predictedSpds] = OLSpdToSettings(oneLightCal, targetSpds, varargin)
%OLSpdToSettings - Converts spectra into OneLight calibrated mirror settings.
%
% Syntax:
% [settings, primaries] = OLSpdToSettings(oneLightCal, targetSpds)
% [settings, primaries] = OLSpdToSettings(oneLightCal, targetSpds, 'lambda', '001')
%
% Description:
% Essentially a convience wrapper around OLSpdToPrimary and
% OLPrimaryToSettings.  Returns settings, primaries and predicted
% spectra.
%
% Input:
% oneLightCal (struct) - OneLight calibration file after it has been
%   processed by OLInitCal.
% targetSpds (nWls x nSpectra) - Target spectra.  Should be on the same wavelength
%   spacing and power units as the PR-650 field of the calibration structure.
%
% Output:
% settings (nPrimaries x nSpectra) - The [0,1], gamma corrected power level for each
%   effective primary of the OneLight.  Each column is a single set of
%   primary values.
% primaries (nPrimaries x nSpectra) - The normalized power level for each column of the
%   OneLight.
% predictedSpds (nWls x nSpectra) - The predicted spectra 
%
% Optional key/value pairs:
%   'lambda' - scalar (default 0.1) - Determines how much smoothing we apply to the settings.
%    verbose' - true/false (default false) - Enables/disables verbose diagnostic information.


% 6/5/17  dhb  This could not have been working as it was sitting.  I
%              updated so it now conforms to our current conventions.

%% Parse the input
p = inputParser;
p.addOptional('verbose', false, @islogical);
p.addOptional('lambda', 0.1, @isscalar);
p.parse(varargin{:});
params = p.Results;

%% Check wavelength sampling
nWls = size(targetSpds,1);
if (nWls ~= oneLightCal.describe.S(3))
    error('Wavelength sampling inconsistency between passed spectrum and calibration');
end

% Convert the spectra into primaries.
nPrimaries = size(oneLightCal.computed.pr650M,2);
numSpectra = size(targetSpds, 2);
primaries = zeros(nPrimaries, numSpectra);
for i = 1:numSpectra
	% Convert to primaries.
	primaries(:,i) = OLSpdToPrimary(oneLightCal, targetSpds(:,i), 'lambda',params.lambda, 'verbose', params.verbose);
    
    % Convert to spectra
    predictedSpds(:,i) = OLPrimaryToSpd(oneLightCal,primaries(:,i));
end

% Convert from primaries to settings.
settings = OLPrimaryToSettings(oneLightCal, primaries);
