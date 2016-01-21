function [settings, primaries, predictedSpds] = OLSpdToSettings(oneLightCal, targetSpds, lambda, verbose)
% OLSpdToSettings - Converts spectra into OneLight calibrated mirror settings.
%
% Syntax:
% [settings, primaries] = OLSpdToSettings(oneLightCal, targetSpds, lambda)
% [settings, primaries] = OLSpdToSettings(oneLightCal, targetSpds, lambda, verbose)
%
% Description:
% Essentially a convience wrapper around OLSpdToPrimary and
% OLPrimaryToSettings.  Returns both the settings and the primaries.
%
% Input:
% oneLightCal (struct) - OneLight calibration file after it has been
%     processed by OLInitCal.
% targetSpds (MxN) - Target spectra.  Should be on the same wavelength
%     spacing and power units as the PR-650 field of the calibration
%     structure.
% lambda (scalar) - Determines how much smoothing we apply to the settings.
%     Needed because there are more columns than wavelengths on the PR-650.
%     Defaults to 0.1.
% verbose (logical) - Enables/disables verbose diagnostic information.
%     Defaults to false.
%
% Output:
% settings (CxN) - The normalized [0,1], gamma corrected power level for each
%     column of the OneLight.  Each column is a single set of mirror
%     settings.
% primaries (C*N) - The normalized power level for each column of the
%     OneLight.
% predictedSpds (1xN) - The predicted target spectra for the PR-650 and
%     OmniDriver spectrometers.

% Validate the number of inputs.
error(nargchk(3, 4, nargin));

if nargin == 3
	verbose = true;
end

numSpectra = size(targetSpds, 2);

% Convert the spectra into primaries.
primaries = zeros(oneLightCal.describe.numColMirrors, numSpectra);
for i = 1:numSpectra
	% Convert to primaries.
	[primaries(:,i), predictedSpds(i), outOfRange] = OLSpdToPrimary(oneLightCal, targetSpds(:,i), lambda, verbose); %#ok<AGROW>
	
	if verbose
		% Look to see if we had any out of range values.
		if outOfRange.low
			fprintf('\n*** WARNING *** Some values of the targetSpd were less than the dark measurement.\n\n');
		end
		if outOfRange.high
			fprintf('\n*** WARNING *** Some values of the computed primary exceed 1.\n\n');
		end
	end
end

% Convert from primaries to settings.
settings = OLPrimaryToSettings(oneLightCal, primaries);
