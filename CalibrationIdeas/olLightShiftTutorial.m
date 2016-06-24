function olLightShiftTutorial
% olLightShiftTutorial
%
% Explore effects of a shift of light on the DMD on OL light output, as
% my intuitions aren't quite good enough.
%
% 6/3/16  dhb  Wrote it.

%% Clear and close
clear; close all;

%% The mirrors pick off a Gaussian funciton of wavelength.
%
% Define that Gaussian
wls = 500:1:600;
centerWl = 550;
wlWidth = 2;
mirrorFilter = normpdf(wls,centerWl,wlWidth);
mirrorFilter = mirrorFilter/max(mirrorFilter);

%% Filter if light shifts on the DMD chip
%
% If the bulb shifts on the DMD ship, that's
% like moving the center wavelength of the filter.
% Model that.
wlShift = 1;
mirrorFilterShift = normpdf(wls,centerWl+wlShift,wlWidth);
mirrorFilterShift = mirrorFilterShift/max(mirrorFilterShift);

%% Model the bulb spectrum
% 
% Over a small part of the spectrum, the bulb is a lot
% like a linear ramp, so we'll just model it as a line
% with a slope
bulbSpdMeanPower = 0.5;
bulbSpdSlope = 0.005;
bulbSpd = bulbSpdMeanPower + (wls-centerWl)*bulbSpdSlope;

%% Compute the measured spd
theSpd = bulbSpd.*mirrorFilter;
theSpdShift = bulbSpd.*mirrorFilterShift;
theSpdDiff = theSpdShift-theSpd;

%% Plot it all up
figure; clf;
set(gcf,'Position',[150 740 1400 600]);

% No shift
subplot(1,3,1); hold on
plot(wls,mirrorFilter,'k','LineWidth',2);
plot(wls,bulbSpd,'r','LineWidth',2);
plot(wls,theSpd,'b','LineWidth',2);
xlabel('Wavelength (nm)');
ylabel('Power/Attenuation');
title('Spectra Without Wavelenght Shift');
ylim([0 1]);
legend({'Mirror Filter', 'Bulb Spd', 'Output Spd'},'Location','NorthWest');

% With shift
subplot(1,3,2); hold on
plot(wls,mirrorFilterShift,'k','LineWidth',2);
plot(wls,bulbSpd,'r','LineWidth',2);
plot(wls,theSpdShift,'b','LineWidth',2);
xlabel('Wavelength (nm)');
ylabel('Power/Attenuation');
ylim([0 1]);
title('Spectra With Wavelenght Shift');
legend({'Mirror Filter Shifted', 'Bulb Spd', 'Output Spd Shifted'},'Location','NorthWest');

% Difference
subplot(1,3,3); hold on;
plot(wls,theSpdDiff,'b','LineWidth',2);
xlabel('Wavelength (nm)');
ylabel('Change in Power');
ylim([-0.5 0.5]);
title('Effect of Shift (Difference in Power)');
end
