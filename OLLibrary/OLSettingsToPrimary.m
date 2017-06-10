function primary = OLSettingsToPrimary(cal, settings, verbose)
% SettingsToPrimary Convert OneLight settings (gamma corrected) values back to linear primary values.
%
% Syntax:
% primary = OLSettingsToPrimary(cal, settings)
% primary = OLSettingsToPrimary(cal, settings, verbose)
%
% Description:
% Converts settings back to primaries.
%
% Input:
% oneLightCal (struct)       - OneLight calibration file after it has been processed by OLInitCal.
% settings (NumPrimariesxNSpecta)  - The normalized, corrected power level for each
%                              effective primary (fraction of max power) in the range [0,1].
%                              NSpectra is the number of spectra to process.
% verbose (logical)          - Enables/disables verbose diagnostic information.
%                              Defaults to false.
%
% Output:
% settings (NumPrimariesxNSpecta) - The normalized, gamma corrected power level for each
%                              effective primary.  These are also in the range [0,1].
%                              NSpectra is the number of spectra to process.
%
% 1/17/14  dhb, ms   Improved comments.
% 1/20/14  dhb, ms   Optimistically think that we've fixed this for full gamma table.
% 2/16/14  dhb       Convert to take input and output for each primery, not for each mirror.

% Validate the number of inputs.
narginchk(2,3);

% Setup some defaults.
if ~exist('verbose', 'var') || isempty(verbose)
    verbose = false;
end

% Make sure that the calibration file has been processed by OLInitCal.
assert(isfield(cal, 'computed'), 'OLSpdToPrimary:InvalidCalFile', ...
    'The calibration file needs to be processed by OLInitCal.');

% Check on input.  Number of rows in primary should match number of primaries
% as defined in the calibration file.
if (size(settings,1) ~= cal.describe.numWavelengthBands)
    error('Passed number of primaries does not match calibration data');
end

if ~isfield(cal.describe, 'useAverageGamma') || (~cal.describe.useAverageGamma)
    % If we've dummied up what looks like a gamma function measurement for
    % every primary, then we can just use PTB's gamma correction directly.
    cal.computed.gammaMode = 0;
    primary = SettingsToPrimary(cal.computed,settings);
else
    % If we computed a single average gamma function, we have to use lower level
    % routines.
    primary = zeros(size(settings));
    NSpectra = size(settings, 2);
    for i = 1:NSpectra
        for m = 1:size(settings, 1)
            [primary(m,i)] = SearchGammaTable(settings(m,i),cal.computed.gammaTableAvg,cal.computed.gammaInput);
        end
    end
end
