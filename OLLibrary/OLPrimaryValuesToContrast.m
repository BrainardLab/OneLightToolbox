function [contrast, excitation, excitationDiff] = OLPrimaryValuesToContrast(primaryValues, calibration, receptors)
% Calculates contrast on photoreceptors between OneLight primary vectors
%
% Syntax:
%   contrasts = SPDtoReceptorContrast(primaryValues, calibration, T_Receptors)
%   contrasts = SPDtoReceptorContrast(primaryValues, calibration, SSTReceptors)
%
% Description:
%    SPDToReceptorContrast takes in spectra, as a set of columnvectors of
%    power at wavelength for each spectrum, and takes in a set of
%    receptors, as a SSTReceptor object, and calculates the contrast on
%    each receptor between all pairs of spectra.
%
% Inputs:
%    primaryValues- PxN Matrix of spectral power distributions, where
%                   P is the number of device primaries, and N is the
%                   number of vectors to calculate contrasts across
%    receptors    - either:
%                   - RxnWls matrix (T_receptors) of R receptor
%                   sensitivities sampled at nWls wavelength bands
%                   - SSTReceptor-object, in which case the
%                     T.T_energyNormalized matrix will be used
%
% Outputs:
%    contrasts    - NxNxR matrix of contrasts in % (one NxN
%                   matrix per receptor type), where contrasts(i,j,R) =
%                   excitationDiff(i,j,R) / excitation(R,i) * 100%
%    excitation     - RxN matrix of excitations of each receptor type to each
%                   vector of primary values
%    excitationDiff - NxNxR matrix of differences in excitations (one NxN
%                   matrix per receptor type), where excitationDiff(i,j,R) =
%                   excitation(R,j) - excitation(R,i).
%
% Optional key/value pairs:
%    None.
%
% Notes:
%    In the case that only 2 vectors of primary values are passed (e.g., a background primary and a
%    direction primary), the outputs are simplified as follows:
%       excitationDiff - Rx2 matrix, where the first column is the
%                      excitation(R,j) - reponse(R,i), and the second column
%                      the inverse
%       contrasts    - Rx2 matrix, where the first column is the contrast
%                      relative to the first vector of primary values, and the second column is
%                      the contrast relative to the second vector of primary values.
%
%    In the case that only 1 vector of primary values is passed, excitation is returned as normal,
%    but excitationDiff and contrasts are returned as nWlsx1 columnvectors of
%    NaNs.

% History:
%    03/02/18  jv  created.

SPDs = OLPrimaryToSpd(calibration, primaryValues);
[contrast, excitation, excitationDiff] = SPDToReceptorContrast(SPDs, receptors);
end

