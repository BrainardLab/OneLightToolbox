function [bipolarContrast, fraction] = OLUnipolarToBipolarContrast(unipolarContrast)
% Convert unipolar peak-to-trough to corresponding bipolar contrast
%
% Syntax:
%   unipolarContrast = OLBipolarToUnipolarContrast(bipolarContrast);
%
% Description:
%    Because math is hard.
%
% Inputs:
%    unipolarContrast - the bipolarContrast(s) to convert. Must be in range
%                       [0,1].

% Outputs:
%    bipolarContrast  - the corresponding unipolar contrast from trough to
%                       peak.
%    fraction         - string expressing rational fraction approximation
%                       (using rats(bipolarContrast) )
%
% Optional key/value pairs:
%    None.
%

% History:
%    02/13/18  jv  wrote it.

%% Input validation
parser = inputParser();
parser.addRequired('unipolarContrast', @isnumeric);
parser.parse(unipolarContrast);

assert(~any(unipolarContrast(:) < 0),'Trough-to-peak contrast cannot be negative');

%% Convert
% unipolarContrast = (peak - trough)/trough
% unipolarContrast * trough = peak - trough
% peak = unipolarContrast * trough + trough
% if trough = 1, peak = unipolarContrast + 1;
peak = 1 + unipolarContrast;
trough = 1;

% bipolarContrast = (peak - start) / start;
% start = ((peak - trough) / 2) + trough;
start = ((peak - trough) / 2) + trough;
bipolarContrast = (peak - start) / start;

fraction = rats(bipolarContrast);

end