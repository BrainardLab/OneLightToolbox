function [excitation, SPD] = OLPrimaryToReceptorExcitation(primaryValues, calibration, receptors, varargin)
% Calculates receptor excitations from primary values
%
% Syntax:
%   excitation = OLPrimaryToReceptorExcitation(primaryValues, calibration, T_receptors);
%   excitation = OLPrimaryToReceptorExcitation(primaryValues, calibration, SSTReceptors);
%   [excitation, SPD] = OLPrimaryToReceptorExcitation(...);
%
% Description:
%    Takes in one or more vector of primary values, and a set of receptors
%    (sensitivities), and returns the excitation of each receptor type to
%    each vector of primary values.
%
% Inputs:
%    primaryValues - PxN matrix, where P is the number of device primaries,
%                    and N is the number of vectors of primary values. Each
%                    should be in range [0-1] for normal mode and [-1,1]
%                    for differential mode (see  below). Those values out
%                    of range are truncated to be in range.
%    calibration   - OneLight calibration file (must be valid, i.e., been
%                    processed by OLInitCal)
%    receptors     - either:
%                    - RxnWls matrix (T_receptors) of R receptor
%                      sensitivities sampled at nWls wavelength bands
%                    - SSTReceptor-object, in which case the
%                      T.T_energyNormalized matrix will be used
%
% Outputs:
%    excitation    - RxN matrix of excitations of the R receptors for each
%                    of the N vectors of primary values.
%    SPD           - Spectral power distribution for each of the N vectors
%                    of primary values
%
% Optional key/value pairs:
%    differentialMode - (true/false). Do not add in the dark light and
%                       allow primaries to be in range [-1,1] rather than
%                       [0,1]. Default false.
%
% See also:
%    OLPrimaryToSPD, SPDToReceptorExcitation

% History:
%    03/08/18  jv  wrote it, based on OLPrimaryToSPD and
%                  SPDToReceptorExcitation

%% Input validation
parser = inputParser;
parser.addRequired('primaryValues',@isnumeric);
parser.addRequired('calibration',@isstruct);
parser.addRequired('receptors',@(x) isnumeric(x) || isa(x,'SSTReceptor'));
parser.addParameter('differentialMode', false, @islogical);
parser.parse(primaryValues, calibration, receptors, varargin{:});

%% to SPD
SPD = OLPrimaryToSpd(calibration,primaryValues,'differentialMode', parser.Results.differentialMode);

%% to excitation
excitation = SPDToReceptorExcitation(SPD, receptors);

end