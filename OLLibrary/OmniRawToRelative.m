function [omniRelSpectrum,wls] = OmniRawToRelative(omniCal,omniRawSpectrum)
% [omniRelSpectrum,omniWls] = OmniRawToRelative(omniCal,omniRawSpectrum)
%
% Convert a raw spectrum measured with the omni to a calibrated relative 
% spectrum.  Uses the calibration structure.  Retruned spectrum is splined
% onto evenly spaced wavelengths with the span of omniCal.commonWls and
% the same number of samples as omniCal.commonWls.
%
% See also CalibrateOmniRelativeSensitivity, AnalyzeOmniRelativeSensitivity
%
% 8/5/12  dhb  Wrote it.

omniRawSpectrumCommon = interp1(omniCal.omniwls,omniRawSpectrum,omniCal.commonWls);
omniWls = omniCal.commonWls;
omniRelSpectrum = omniRawSpectrumCommon.*omniCal.omniCorrect;
wls = linspace(omniCal.commonWls(1),omniCal.commonWls(end),length(omniCal.commonWls))';
omniRelSpectrum = interp1(omniCal.commonWls,omniRelSpectrum,wls);