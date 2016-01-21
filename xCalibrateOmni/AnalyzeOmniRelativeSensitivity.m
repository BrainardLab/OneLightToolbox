% AnalyzeOmniRelativeSensitivity
%
% Analyze output of the omni relative sensitivity
% calibration.
%
% The following codelet will compare the correction in two
% versions of the calibration from OmniDriverCal
%   calOneNumber = 4; calTwoNumber = 5;
%   cals = load('OmniDriverCal');
%   figure; clf; hold on;
%   plot(cals.cals{calOneNumber}.commonWls,cals.cals{calOneNumber}.omniCorrect/min(cals.cals{calOneNumber}.omniCorrect),'b')
%   plot(cals.cals{calTwoNumber}.commonWls,cals.cals{calTwoNumber}.omniCorrect/min(cals.cals{calTwoNumber}.omniCorrect),'r')
% We looked at this comparison for pre-post August 2012 LED calibration and things
% seemed quite stable.  There is an overall shift in the function because
% of changes in measurement geometry, but the shape was consistent over the
% common wavelengths of the two measurements, particulary given that we
% switched between PR-650 and PR-670.
%
% 7/22/12  dhb  Wrote it.

%% Clear
clear; close all

%% Read in file
cal = LoadCalFile('OmniDriverCal');

%% Tell us some stuff
fprintf('Omni calibration measurements from %s\n',cal.date);
fprintf('The %s fiber was used\n',cal.fiberType);
fprintf('Data were analyzed assuming %g nm wavelength shift (subtracted from nominal)\n',cal.wlShift);

%% Let's average and plot each set of measurements
figure; clf;
set(gcf,'Position',[1000 924 1132 414]);

% Plot PR-6xx spectra.
subplot(1,3,1); hold on
cal.avgPR6xx = zeros(size(cal.pr6xx(1).spd));
for i = 1:cal.nMeasAverage
    plot(SToWls(cal.S),cal.pr6xx(i).spd,'r');
    cal.avgPR6xx = cal.avgPR6xx + cal.pr6xx(i).spd;
end
cal.avgPR6xx = cal.avgPR6xx/cal.nMeasAverage;
plot(SToWls(cal.S),cal.avgPR6xx,'k');
title('PR-6xx Measurements');
xlabel('Wavelength (nm)')
ylabel('Calibrated Power');

% Plot Omni spectra.
subplot(1,3,2); hold on
cal.avgOmni = zeros(size(cal.omni(1).spectrum));
for i = 1:cal.nMeasAverage
    darkSubtractedSpectrum = cal.omni(i).spectrum - cal.omni(i).darkspectrum;
    plot(cal.omniwls,darkSubtractedSpectrum,'r');
    if (cal.measureDark)
        plot(cal.omniwls,cal.omni(i).darkspectrum,'k');
    end
    cal.avgOmni = cal.avgOmni + darkSubtractedSpectrum;
end
cal.avgOmni = cal.avgOmni/cal.nMeasAverage;
plot(cal.omniwls,cal.avgOmni,'k');
title('Omni Measurements');
xlabel('Wavelength (nm)')
ylabel('Uncalibrated Power');

%% PLot factors to bring omni into radiometric calibration
subplot(1,3,3)
plot(cal.commonWls,cal.omniCorrect,'k');
yl = ylim;
ylim([0 yl(2)]);
title('Correction Function');
xlabel('Wavelength (nm)')
ylabel('Correction');

%% Plot Omni spectra for full, half, and quarter integration times.
figure; clf;
set(gcf,'Position',[1000 924 900 414]);
subplot(1,2,1); hold on
cal.avgHalfOmni = zeros(size(cal.omni(1).halfSpectrum));
cal.avgQuarterOmni = zeros(size(cal.omni(1).quarterSpectrum));
for i = 1:cal.nMeasAverage
    darkSubtractedSpectrum = cal.omni(i).spectrum - cal.omni(i).darkspectrum;
    plot(cal.omniwls,darkSubtractedSpectrum,'k');
    
    darkSubtractedSpectrum = cal.omni(i).halfSpectrum - cal.omni(i).darkspectrum;
    plot(cal.omniwls,darkSubtractedSpectrum,'r');
    cal.avgHalfOmni = cal.avgHalfOmni + darkSubtractedSpectrum;

    darkSubtractedSpectrum = cal.omni(i).quarterSpectrum - cal.omni(i).darkspectrum;
    plot(cal.omniwls,darkSubtractedSpectrum,'g');
    cal.avgQuarterOmni = cal.avgQuarterOmni + darkSubtractedSpectrum;

    if (cal.measureDark)
        plot(cal.omniwls,cal.omni(i).darkspectrum,'k');
    end
end
cal.avgHalfOmni = cal.avgHalfOmni/cal.nMeasAverage;
cal.avgQuarterOmni = cal.avgQuarterOmni/cal.nMeasAverage;
title('Exposure Time Linearity');
xlabel('Wavelength (nm)')
ylabel('Uncalibrated Power');

subplot(1,2,2); hold on;
plot(cal.avgOmni,cal.avgHalfOmni,'ro','MarkerSize',2,'MarkerFaceColor','r');
plot(cal.avgOmni,cal.avgQuarterOmni,'go','MarkerSize',2,'MarkerFaceColor','g');
xl = xlim; yl = ylim; maxl = max([xl(2) yl(2)]);
xlim([0 maxl]); ylim([0 maxl]); axis('square');
plot([0 maxl],[0 maxl],'k');
title('Exposure Time Linearity');
xlabel('Full Exposure Duration');
ylabel('Shorter Exposure Duration');

%% Analyze data from OneLight cal file?
% 
% This file contains measurements from both the PR device and the omni.
% So we can check that they bear a consistent relationship.
%
% We do need to account for the additinoal fact that there is wavelength dependent spectral loss
% between where the OneLight pics off the light and where the OmniDriver picks off the light.  Thus the relation between the 
% two devices varies with each measurement and we can't tell all that much by the comparison.
% 
% Also, really needs the PR-670, to make the wavelength sampling fine enough to deal with the
% narrowband spectra coming out of the OneLight.
DO_ONELIGHT = 0;
if (DO_ONELIGHT)
    % Get the omni calibration file data
    whichFile = GetWithDefault('Enter desired OL file','OLEyeTrackerShortCable');
    ocal = LoadCalFile(whichFile);
    
    % Get the one light and PR-6xx measurements for whatever was measured in the
    % calibration
    prMeas = ocal.raw.lightMeas;
    prS = ocal.describe.S;
    omniMeas = ocal.raw.omniDriver.lightMeas;
    omniWls = ocal.describe.omniDriver.wavelengths;
    prMeasCommon = interp1(SToWls(prS),prMeas,cal.commonWls);
    omniMeasCommon = interp1(omniWls,omniMeas,cal.commonWls);
    omniMeasCommonCorrect = omniMeasCommon .* cal.omniCorrect(:,ones(1,size(omniMeasCommon,2)));
    
    % There is one more correction, though.  In these measurments, the omni isn't seeing the
    % same light as the PR-6xx.  So we use the half on measurements to deal with that.
    prHalfOnCommon = interp1(SToWls(prS),mean(ocal.raw.halfOnMeas,2),cal.commonWls);
    omniHalfOnCommon = interp1(omniWls,mean(ocal.raw.omniDriver.halfOnMeas,2),cal.commonWls);
    omniHalfOnCommonCorrect = omniHalfOnCommon .* cal.omniCorrect;
    configCorrect = prHalfOnCommon ./ omniHalfOnCommonCorrect;
    omniMeasCommonConfigCorrect = omniMeasCommonCorrect .* configCorrect(:,ones(1,size(omniMeasCommon,2)));

    figure; clf; hold on;
    omniFactor = 1; %omniMeasCommonCorrected(:)\prMeasCommon(:);
    set(gcf,'Position',[1000 924 900 414]);
    for i = 1:size(prMeas,2);
        if (rem(i,10) == 0)
            subplot(1,2,1); hold on
            plot(cal.commonWls,prMeasCommon(:,i),'r');
            plot(cal.commonWls,omniMeasCommonConfigCorrect(:,i)*omniFactor,'g');
            fprintf('Spectrum %d of %d\n',i,size(prMeas,2));
            subplot(1,2,2); hold on;
            plot(prMeasCommon(:,i),omniMeasCommonConfigCorrect(:,i),'ro','MarkerSize',2,'MarkerFaceColor','r');
            drawnow;
        end  
    end
    subplot(1,2,1); 
    xlabel('Wavelength (nm)');
    ylabel('Power');
    title('PR vs Omni from OneLight');
    subplot(1,2,2); hold on;
    xl = xlim; yl = ylim; maxl = max([xl(2) yl(2)]);
    xlim([0 xl(2)]); ylim([0 yl(2)]); axis('square');
    plot([0 xl(2)],[0 yl(2)],'k');
    title('PR vs Omni from OneLight');
    xlabel('PR');
    ylabel('Omni');
end



