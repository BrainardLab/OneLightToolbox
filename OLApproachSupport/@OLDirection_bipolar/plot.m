function F = plot(direction, varargin)
% Plots an OLDirection
%
% Syntax:
%   plot(OLDirection);
%
% Description:
%    Detailed explanation goes here
%
% Inputs:
%
% Outputs:
%
% Optional key/value pairs:
%
% See also:
%

% History:
%    03/08/18  jv  wrote it.

%% Input validation
parser = inputParser;
parser.addRequired('direction',@(x) isa(x,'OLDirection'));
parser.addOptional('background',OLDirection.NullDirection(direction.calibration),@(x) isa(x,'OLDirection'));
parser.parse(direction,varargin{:});
background = parser.Results.background;

%% Get figure
F = figure();

%% Plot differential primaries
plotDifferentials = subplot(1,5,1); hold on;
stem(direction.differentialPositive,'g');
stem(direction.differentialNegative,'r');
xlim([0 length(direction.differentialPositive)]);
ylim([-1 1]);
title('Differential primaries');
legend({'positive','negative'});
xlabel('Device primary');
ylabel('Primary value');

%% Plot combined primaries
plotPrimaries = subplot(1,5,2); hold on;
combined = direction + background;
stem(combined.differentialPositive,'g');
stem(combined.differentialNegative,'r');
stem(background.differentialPositive,'k');
xlim([0 length(direction.differentialPositive)]);
ylim([-1 1]);
title('Direction primaries');
legend({'positive','negative','background'});
xlabel('Device primary');
ylabel('Primary value');

%% Plot differential SPDs
plotDifferentialSPDs = subplot(1,5,3); hold on;
SPDs = direction.ToSPDs;
wls = MakeItWls(direction.calibration.describe.S);
plot(wls,SPDs(:,1),'g');
plot(wls,SPDs(:,2),'r');
xlim([min(wls),max(wls)]);
ylim([min(SPDs(:)),max(SPDs(:))]);
title('Differential SPDs');
legend({'positive','negative'});
xlabel('wavelength (nm)');
ylabel('spectral power');

%% Plot direction SPDs
plotDifferentialSPDs = subplot(1,5,4); hold on;
SPDbackground = OLPrimaryToSpd(background.calibration, background.differentialPositive);
SPDdirectionPos = OLPrimaryToSpd(direction.calibration, direction.differentialPositive+background.differentialPositive);
SPDdirectionNeg = OLPrimaryToSpd(direction.calibration, direction.differentialNegative+background.differentialPositive);
wls = MakeItWls(direction.calibration.describe.S);
plot(wls,SPDdirectionPos,'g');
plot(wls,SPDdirectionNeg,'r');
plot(wls,SPDbackground,'k');
xlim([min(wls),max(wls)]);
ylim([0,max([SPDdirectionPos; SPDdirectionNeg])]);
title('Direction SPDs');
legend({'positive','negative','background'});
xlabel('wavelength (nm)');
ylabel('spectral power');

%% Plot differential receptor excitations
plotExcitationsDifferential = subplot(1,5,5); hold on;


end
