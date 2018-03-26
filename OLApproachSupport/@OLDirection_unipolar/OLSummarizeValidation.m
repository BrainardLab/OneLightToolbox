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

assert(isscalar(direction),'OneLightToolbox:ApproachSupport:OLSummarizeValidation:NonscalarInput',...
        'OLSummarizeValidation can currently only summarize validations for one direction at a time');
    
%% Summarize single directions validation(s)
assert(isfield(direction.describe,'validation') && ~isempty(direction.describe.validation),...
    'OneLightToolbox:ApproachSupport:OLSummarizeValidation:UnvalidatedDirection',...
    'No validations found for direction');
validations = direction.describe.validation;

contrastDesired = [];
contrastActual = [];
for i = 1:numel(validations)
    contrastDesired = [contrastDesired, validations(i).contrastDesired(:,1)];
    contrastActual = [contrastActual, validations(i).contrastActual(:,1)];
    figure(i)
    plot(validations(i).SPDbackground.desiredSPD,'k--'); hold on;
    plot(validations(i).SPDbackground.measuredSPD,'k-');
    plot(validations(i).SPDcombined.desiredSPD,'g--');
    plot(validations(i).SPDcombined.measuredSPD,'g-');
    legend({'background desired','background measured',...
        'direction desired', 'direction measured'});
end

figure();
for r = 1:size(contrastDesired,1)
    % subplot per receptor
    subplot(1,size(contrastDesired,1),r); hold on;
    bar(contrastActual(r,:),'k'); hold on;
    plot(contrastDesired(r,:),'g');
    ylim([-5,5]);
end