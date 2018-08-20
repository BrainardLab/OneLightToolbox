function fig = OLPlotValidationDirectionUnipolar(validation)
% Plots a single validation of an OLDirection_Unipolar object
%
% Syntax:
% 
% Description:
%
% Inputs:
%
% Outputs:
%
% Optional keyword arguments:
%
% See also:
%

% History:
%    08/20/18  jv   wrote OLPlotValidationDirectionUnipolar

%
fig = figure();

% Plot SPDs (background, combined; desired, measured)
subplot(2,1,1); hold on;
plot(validation.SPDbackground.desiredSPD,'k:');
plot(validation.SPDbackground.measuredSPD,'r:');
plot(validation.SPDcombined.desiredSPD,'k-');
plot(validation.SPDcombined.measuredSPD,'r-');

% Plot contrasts (desired, measured)
subplot(2,1,2); hold on;
bar([validation.contrastDesired(:,1) validation.contrastActual(:,1)]);
legend({'Desired','Measured'},'Location','best');
xticks(1:size(validation.contrastDesired,1));
xticklabels({'L','M','S','Mel'});
end