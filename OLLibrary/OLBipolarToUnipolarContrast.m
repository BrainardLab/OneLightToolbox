function unipolarContrast = OLBipolarToUnipolarContrast(bipolarContrast)
% Convert bipolar contrast to corresponding unipolar trough-to-peak  
%
% Syntax:
%   unipolarContrast = OLBipolarToUnipolarContrast(bipolarContrast);
%
% Description:
%    Because math is hard.
%
% Inputs:
%    bipolarContrast  - the bipolarContrast(s) to convert. Must be in range
%                       [0,1].

% Outputs:
%    unipolarContrast - the corresponding unipolar contrast from trough to
%                       peak.
%
% Optional key/value pairs:
%    None.
%

% History:
%    02/13/18  jv  wrote it.

%% Input validation
parser = inputParser();
parser.addRequired('bipolarContrast', @isnumeric);
parser.parse(bipolarContrast);

assert(~any(bipolarContrast(:) > 1),'Bipolar contrast cannot be greater than 100%');
assert(~any(bipolarContrast(:) < 0),'Bipolar contrast cannot be less than 0%');

%% Convert
% bipolarContrast = (peak - start)/start
% bipolarContrast * start = peak - start

% peak = bipolarContrast * start + start
% if start = 1, peak = bipolarContrast + 1;
peak = 1 + bipolarContrast;
trough = 1 - bipolarContrast;

% unipolarContrast = (peak - trough) / trough
unipolarContrast = (peak - trough) ./ trough;

end