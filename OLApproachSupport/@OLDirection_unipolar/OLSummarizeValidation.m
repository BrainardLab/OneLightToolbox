function OLSummarizeValidation(direction)
% Summarizes in figure and console output, validations stored in direction
%
% Syntax:
%
% Description:
%
% Inputs:
%
% Outputs:
%
% Optional key/value pairs:
%    None.
%
% See also:
%    OLDirection, OLValidateDirection

% History:
%    03/23/18  jv  wrote it.

%% Input validation
parser = inputParser();
parser.addRequired('direction',@(x) isa(x,'OLDirection'));
parser.parse(direction)

assert(~isscalar(direction),'OneLightToolbox:ApproachSupport:OLSummarizeValidation:NonscalarInput',...
        'OLSummarizeValidation can currently only summarize validations for one direction at a time');
    
%% Summarize single directions validation(s)
assert(isfield(direction.describe,'validation') && ~isempty(direction.describe.validation),...
    'OneLightToolbox:ApproachSupport:OLSummarizeValidation:UnvalidatedDirection',...
    'No validations found for direction');
validations = direction.describe.validation;



end