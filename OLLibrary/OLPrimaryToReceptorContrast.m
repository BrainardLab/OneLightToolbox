function [contrasts, excitationDiff, excitation, SPD] = OLPrimaryToReceptorContrast(primaryValues, calibration, receptors, varargin)
% Predicts receptor contrast from primary values
%
% Syntax:
%   contrasts = OLPrimaryToReceptorContrast(primaryValues, calibration, T_receptors);
%   contrasts = OLPrimaryToReceptorContrast(primaryValues, calibration, SSTReceptors);
%   [contrast, excitationDiff, excitation] = OLPrimaryToReceptorContrast(...);
%   [contrast, excitationDiff, excitation, SPD] = OLPrimaryToReceptorContrast(...);
%
% Description:
%    Takes in vectors of primary values, and a set of receptors
%    (sensitivities), and returns the predicted contrast on each receptor
%    type to between each pair of vector of primary values.
%
% Inputs:
%    primaryValues   - PxN matrix, where P is the number of device
%                      primaries, and N is the number of vectors of primary
%                      values. Those values out of range [0-1] are
%                      truncated to be in range.
%    calibration     - OneLight calibration struct
%    receptors       - either:
%                      - RxnWls matrix (T_receptors) of R receptor
%                        sensitivities sampled at nWls wavelength bands
%                      - SSTReceptor-object, in which case the
%                        T.T_energyNormalized matrix will be used
%
% Outputs:
%    contrasts       - NxNxR matrix of predicted contrasts (one NxN matrix
%                      per receptor type), where contrasts(i,j,R) =
%                      excitationDiff(i,j,R) / excitation(R,i)
%    excitationDiff  - NxNxR matrix of differences in predicted excitations
%                      (one NxN matrix per receptor type), where
%                      excitationDiff(i,j,R) = excitation(R,j) -
%                      excitation(R,i).
%    excitation      - RxN matrix of predicted excitations of the R
%                      receptors for each of the N vectors of primary
%                      values.
%    SPD             - Predicted spectral power distribution for each of the
%                      N vectors of primary values
%
% Optional key/value pairs:
%    None.
%
% Notes:
%    In the case that only 2 vectors of primary values are passed (e.g., a
%    background and a direction), the outputs are simplified as follows:
%       excitationDiff - Rx2 matrix, where the first column is the
%                        excitation(R,j) - excitation(R,i), and the second
%                        column the inverse
%       contrasts      - Rx2 matrix, where the first column is the contrast
%                        relative to the first vector of primary values,
%                        and the second column is the contrast relative to
%                        the second vector of primary values.a
%
%    In the case that only 1 vector of of primary values is passed,
%    excitationDiff and contrasts are returned as nWlsx1 columnvectors of
%    NaNs.
%    * TODO: implement differential vs. absolute primary values. 
%
% See also:
%    OLPrimaryToSPD, OLPrimaryToReceptorExcitation, SPDToReceptorExcitation
%    ReceptorExcitationToReceptorContrast

% History:
%    03/08/18  jv  wrote it, based on OLPrimaryToSPD and
%                  SPDToReceptorExcitation

%% Input validation
parser = inputParser;
parser.addRequired('primaryValues',@isnumeric);
parser.addRequired('calibration',@isstruct);
parser.addRequired('receptors',@(x) isnumeric(x) || isa(x,'SSTReceptor'));
parser.parse(primaryValues, calibration, receptors, varargin{:});

%% to SPD
SPD = OLPrimaryToSpd(calibration,primaryValues);

%% to excitation
excitation = SPDToReceptorExcitation(SPD, receptors);

%% to contrast
[contrasts, excitationDiff] = ReceptorExcitationToReceptorContrast(excitation);
end