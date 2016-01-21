function [omniSpectrum] = OmniRelativeToAbsolute(omniCal,omniRelativeSpectrum)
% [omniSpectrum] = OmniRelativeToAbsolute(omniCal,omniRelativeSpectrum)
%
% Apply the scale factor in the OmniCalFile to bring the relative spectrum
% into absolute units.  The exact units depend on how the factor was defined
% and apply to the measurement geometry used in that definition.
% Our typical application is with the LED stimulus device, and the factor is
% determined using LEDToolbox/AnalyzeOmniToDiode.
%
% See also CalibrateOmniRelativeSensitivity, AnalyzeOmniRelativeSensitivity,
%   OmniRawToRelative.
%
% 8/5/12  dhb  Wrote it.

omniSpectrum = omniRelativeSpectrum*omniCal.omniFactor.factor;