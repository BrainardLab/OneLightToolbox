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
    % scale SPDs
    kScale = [validations(i).SPDbackground.desiredSPD; validations(i).SPDcombined.desiredSPD]' ...
        / [validations(i).SPDbackground.measuredSPD; validations(i).SPDcombined.measuredSPD]';
    
    % calculate contrast
    contrastDesired = [contrastDesired, validations(i).contrastDesired(:,1)];
    contrastActual = [contrastActual, validations(i).contrastActual(:,1)];
    
    % plot
    wls = MakeItWls(direction.calibration.describe.S);
    figure()
    plot(wls,validations(i).SPDbackground.desiredSPD,'k--'); hold on;
    plot(wls,kScale*validations(i).SPDbackground.measuredSPD,'k-');
    plot(wls,validations(i).SPDcombined.desiredSPD,'g--');
    plot(wls,kScale*validations(i).SPDcombined.measuredSPD,'g-');
    legend({'background desired','background measured',...
        'direction desired', 'direction measured'});
    title(sprintf('Validation %d',i));
    xlabel('Wavelength (nm)');
    ylabel('Spectral power');
end

figure();
for r = 1:size(contrastDesired,1)
    % subplot per receptor
    subplot(1,size(contrastDesired,1),r); hold on;
    bar(contrastActual(r,:),'k'); hold on;
    plot(contrastDesired(r,:),'g');
    ylim(max(abs(ylim)) * [-1.1 1.1]);
    title(sprintf('Contrast on receptor %d',r));
    ylabel('contrast');
    xlabel('validation');
end