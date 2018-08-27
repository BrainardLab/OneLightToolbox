function fig = OLPlotValidationDirectionBipolar(validation)
% Plots a single validation of an OLDirection_Bipolar object
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
%    08/20/18  jv   wrote OLPlotValidationDirectionBipolar

%
fig = figure();

% Plot SPDs (background, combined; desired, measured)
subplot(2,1,1); hold on;
plot(validation.SPDbackground.desiredSPD,'g:');
plot(validation.SPDbackground.measuredSPD,'k:');
plot([validation.SPDcombined.desiredSPD],'g-');
plot([validation.SPDcombined.measuredSPD],'k-');
legend({'Desired background','Measured background','Desired SPD (+)','Desired SPD (-)','Measured SPD (+)','Measured SPD (-)'});

% Plot contrasts (desired, measured)
subplot(2,1,2); hold on;
bar([validation.contrastDesired(:,[1,3]) validation.contrastActual(:,[1,3])]);
legend({'Desired (+)','Desired (-)','Measured (+)','Measured (-)'},'Location','best');
xticks(1:size(validation.contrastDesired,1));
xticklabels({'L','M','S','Mel'});
end