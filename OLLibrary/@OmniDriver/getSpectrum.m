function [specData,isSaturated] = getSpectrum(obj,ignoreSaturationError)
% getSpectrum - Acquire the next available spectrum.
%
% Syntax:
% specData = obj.getSpectrum([ignoreSaturationError]);
%
% Description:
% Acquire the next available spectrum from the spectrometer. Any requested
% processing steps will already be applied to the returned spectrum (ie. 
% boxcar averaging, electric dark correction, multi-scan averaging, etc.).
%
% If flag ignoreSaturationError is set to true, this will not throw an
% error for a saturated reading. [Default, false]
%
% Output:
% specData -- Spectral data
% isSaturated -- true if saturated.
%
% Throws:
% OmniDriver:getSpectrum:Saturated
% OmniDriver:getSpectrum:Invalid
% OmniDriver:getSpectrum:NotOpen

assert(obj.IsOpen, 'OmniDriver:getSpectrum:NotOpen', 'Not connected to the spectrometer.');

specData = obj.Wrapper.getSpectrum(obj.TargetSpectrometer)';

if (nargin < 2 || isempty(ignoreSaturationError))
    ignoreSaturationError = false;
end

isSaturated = obj.Wrapper.isSaturated(obj.TargetSpectrometer);

% Throw any errors.
if (~ignoreSaturationError && isSaturated)
	throw(MException('OmniDriver:getSpectrum:Saturated', 'Spectrum saturated at %d microseconds.', obj.IntegrationTime));
end
if ~obj.Wrapper.isSpectrumValid(obj.TargetSpectrometer)
	throw(MException('OmniDriver:getSpectrum:Invalid', 'Failed to retrieve a valid spectrum, probably an I/O error.'));
end
