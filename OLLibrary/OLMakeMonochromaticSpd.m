function spd = OLMakeMonochromaticSpd(oneLightCal, centerWl, fullWidthHalfMax)
% OLMakeMonochromaticSpd - Creates a monochromatic spectrum for the OneLight.
%
% Syntax:
% spd = OLMakeMonochromaticSpd(oneLightCal, centerWl, fullWidthHalfMax)
%
% Description:
% Creates a monochromatic spectrum for use with the OneLight experiments
% and toolbox.  Note that this only produces a target spectrum, not mirror
% primaries or settings.
%
% Input:
% oneLightCal (struct) - The OneLight calibration.
% centerWl (scalar) - The center wavelength in nanometers.
% fullWidthHalfMax (scalar) - The width in nanometers of the spectrum at
%     half its maximum value.
%
% 4/12/12  dhb  Call through function to get standard deviation.
%               Function pulled out and stuck in BrainardLabToolbox/OneLiners.

% Figure out the standard deviation.
standardDeviation = FWHMToStd(fullWidthHalfMax);

% Make the spectrum.
spd = normpdf(oneLightCal.computed.pr650Wls, centerWl, standardDeviation);
