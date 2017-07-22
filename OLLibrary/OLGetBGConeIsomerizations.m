% OLGetBGConeIsomerizations
%
% Figure out how much light is coming out of the OL device at specified
% backgorund level, in terms of retinal illuminance, and compute nominal
% cone isomerization rates.  This may then be used to compute the amount
% of cone pigment bleaching.
%
% 5/24/14  dhb  Wrote from OLCheckLightLevels.  It is possible that this
%               should just be part of OLCheckLightLevels, but instead
%               I pulled a bunch of stuff not relevant here out.

%% Clear and close
clear; close all

%% Define the wavelength spacing that we will work with
S = [380 1 401];

%% Get OL calibration info
cal = OLGetCalibrationStructure;
calType = cal.describe.calType.CalFileName;
calDate = cal.describe.date;
calFolderInfo = what(fullfile(CalDataFolder, 'OneLight'));
calFolder = calFolderInfo.path;
calFileName = cal.describe.calType.CalFileName;

%% Get other things
pupilDiameterMm = GetWithDefault('Enter observer pupil diameter in mm',4.7);
fieldSizeDegs = 27.5;
ageInYears = 32;

%% Find background spectrum from the OneLight
Scal = cal.computed.pr650S;
nPrimaries = size(cal.computed.pr650M,2);
bgPrimary = 0.5*ones(nPrimaries,1);
radianceWattsPerM2SrCal = OLPrimaryToSpd(cal,bgPrimary);
radianceWattsPerM2Sr = SplineSpd(Scal,radianceWattsPerM2SrCal,S);
radianceWattsPerM2Sr(radianceWattsPerM2Sr < 0) = 0;
radianceWattsPerCm2Sr = (10.^-4)*radianceWattsPerM2Sr;
radianceQuantaPerCm2SrSec = EnergyToQuanta(S,radianceWattsPerCm2Sr);

%% Load CIE functions.   
load T_xyz1931
T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);
photopicLuminanceCdM2 = T_xyz(2,:)*radianceWattsPerM2Sr;
chromaticityXY = T_xyz(1:2,:)*radianceWattsPerM2Sr/sum(T_xyz*radianceWattsPerM2Sr);

%% Adjust background luminance by scaling.  Handles small shifts from
% original calibration, just by scaling.  This is close enough for purposes
% of computing fraction of pigment bleached.
desiredPhotopicLuminanceCdM2 = GetWithDefault('Enter background luminance to compute for',photopicLuminanceCdM2);
scaleFactor = desiredPhotopicLuminanceCdM2/photopicLuminanceCdM2;
radianceWattsPerM2SrCal = scaleFactor*radianceWattsPerM2SrCal;
radianceWattsPerM2Sr = scaleFactor*radianceWattsPerM2Sr;
radianceWattsPerCm2Sr = scaleFactor*radianceWattsPerCm2Sr;
radianceQuantaPerCm2SrSec = scaleFactor*radianceQuantaPerCm2SrSec;
photopicLuminanceCdM2 = scaleFactor*photopicLuminanceCdM2;

%% Get cone spectral sensitivities to use to compute isomerization rates
lambdaMaxShift = [];
[T_cones, T_quantalIsom]  = GetHumanPhotopigmentSS(S, {'LCone' 'MCone' 'SCone'}, fieldSizeDegs, ageInYears, pupilDiameterMm, lambdaMaxShift,[]);
[T_conesHemo, T_quantalIsomHemo]  = GetHumanPhotopigmentSS(S, {'LConePenumbral' 'MConePenumbral' 'SConePenumbral'}, fieldSizeDegs, ageInYears, pupilDiameterMm, lambdaMaxShift,[]);

%% Compute irradiance, trolands, etc.
pupilAreaMm2 = pi*((pupilDiameterMm/2)^2);
eyeLengthMm = 17;
degPerMm = RetinalMMToDegrees(1,eyeLengthMm);
irradianceWattsPerUm2 = RadianceToRetIrradiance(radianceWattsPerM2Sr,S,pupilAreaMm2,eyeLengthMm);
irradianceScotTrolands = RetIrradianceToTrolands(irradianceWattsPerUm2, S, 'Scotopic', [], num2str(eyeLengthMm));
irradiancePhotTrolands = RetIrradianceToTrolands(irradianceWattsPerUm2, S, 'Photopic', [], num2str(eyeLengthMm));
irradianceQuantaPerUm2Sec = EnergyToQuanta(S,irradianceWattsPerUm2);
irradianceWattsPerCm2 = (10.^8)*irradianceWattsPerUm2;
irradianceQuantaPerCm2Sec = (10.^8)*irradianceQuantaPerUm2Sec;
irradianceQuantaPerDeg2Sec = (degPerMm^2)*(10.^-2)*irradianceQuantaPerCm2Sec;

%% This is just to get cone inner segment diameter
photoreceptors = DefaultPhotoreceptors('CIE10Deg');
photoreceptors = FillInPhotoreceptors(photoreceptors);

%% Get isomerizations
theLMSIsomerizations = PhotonAbsorptionRate(irradianceQuantaPerUm2Sec,S, ...
	T_quantalIsom,S,photoreceptors.ISdiameter.value);
theLMSIsomerizationsHemo = PhotonAbsorptionRate(irradianceQuantaPerUm2Sec,S, ...
	T_quantalIsomHemo,S,photoreceptors.ISdiameter.value);

%% Report on stimulus
fprintf('\n');
fprintf('  * Analyzing OneLight calibration file %s from date %s\n',calType,calDate);
fprintf('  * Stimulus is half max OneLight from calibration file\n');
fprintf('  * Stimulus radiance %0.1f log10 watts/[m2-sr], %0.1f log10 watts/[cm2-sr]\n',log10(sum(radianceWattsPerM2Sr)),log10(sum(radianceWattsPerCm2Sr)));
fprintf('  * Stimulus luminance %0.1f candelas/m2\n',photopicLuminanceCdM2);
fprintf('  * Stimulus chromaticity x=%0.4f, y=%0.4f\n',chromaticityXY(1), chromaticityXY(2));
fprintf('  * Stimulus %0.0f scotopic trolands, %0.0f photopic trolands\n',irradianceScotTrolands,irradiancePhotTrolands);
fprintf('  * Stimulus %0.1f log10 scotopic trolands, %0.1f log10 photopic trolands\n',log10(irradianceScotTrolands),log10(irradiancePhotTrolands));
fprintf('  * Stimulus retinal irradiance %0.1f log10 watts/cm2\n',log10(sum(irradianceWattsPerCm2)));
fprintf('  * Stimulus retinal irradiance %0.1f log10 quanta/[cm2-sec]\n',log10(sum(irradianceQuantaPerCm2Sec)));
fprintf('  * Stimulus retinal irradiance %0.1f log10 quanta/[deg2-sec]\n',log10(sum(irradianceQuantaPerDeg2Sec)));
fprintf('  * LMS isomerizations/cone-sec: %0.4g, %0.4g, %0.4g\n',...
        theLMSIsomerizations(1),theLMSIsomerizations(2),theLMSIsomerizations(3));
fprintf('  * LMSHemo isomerizations/cone-sec: %0.4g, %0.4g, %0.4g\n',...
        theLMSIsomerizationsHemo(1),theLMSIsomerizationsHemo(2),theLMSIsomerizationsHemo(3));
    
%% Simple check
% Calculating for a 10-deg field, IsomerizationsInEyeDemo says that the average (2 L per 1 M) isomerizations/cone-sec
% for a 1 troland 560 nm light is 128.  So we can take the retinal illuminance in trolands, multiply
% by 128 and compare to the average L and M isomerizations/cone-sec we get here.  They should be about
% the same.
fprintf('  * Check: Photopic trolands times 128: %0.4g, 2:1 average L and M: %0.4g\n',irradiancePhotTrolands*128,(2*theLMSIsomerizations(1)+theLMSIsomerizations(2))/3);

%% Get fraction bleached
fractionBleachedFromTrolands = ComputePhotopigmentBleaching(irradiancePhotTrolands,'cones','trolands','Boynton');
fractionBleachedFromIsom = zeros(3,1);
fractionBleachedFromIsomHemo = zeros(3,1);
for i = 1:3
    fractionBleachedFromIsom(i) = ComputePhotopigmentBleaching(theLMSIsomerizations(i),'cones','isomerizations','Boynton');
    fractionBleachedFromIsomHemo(i) = ComputePhotopigmentBleaching(theLMSIsomerizationsHemo(i),'cones','isomerizations','Boynton');
end
fprintf('  * Fraction bleached computed from trolands (applies to L and M cones): %0.2f\n',fractionBleachedFromTrolands);
fprintf('  * Fraction bleached from isomerization rates: L, %0.2f; M, %0.2f; S, %0.2f\n', ...
    fractionBleachedFromIsom(1),fractionBleachedFromIsom(2),fractionBleachedFromIsom(3));
fprintf('  * Fraction bleached from isomerization rates: LHemo, %0.2f; MHemo, %0.2f; SHemo, %0.2f\n', ...
    fractionBleachedFromIsomHemo(1),fractionBleachedFromIsomHemo(2),fractionBleachedFromIsomHemo(3));
        
%% Compute bleached cone sensitivities and isomerizations
[T_conesBleached,T_quantalIsomBleached] = GetHumanPhotopigmentSS(S, {'LCone' 'MCone' 'SCone'}, fieldSizeDegs, ageInYears, pupilDiameterMm, lambdaMaxShift, fractionBleachedFromIsom);
[T_conesHemoBleached] = GetHumanPhotopigmentSS(S, {'LConePenumbral' 'MConePenumbral' 'SConePenumbral'}, fieldSizeDegs, ageInYears, pupilDiameterMm, lambdaMaxShift, fractionBleachedFromIsom);
theLMSIsomerizationsBleached = PhotonAbsorptionRate(irradianceQuantaPerUm2Sec,S, ...
	T_quantalIsomBleached,S,photoreceptors.ISdiameter.value);
fprintf('  * LMS bleached isomerizations/cone-sec: %0.4g, %0.4g, %0.4g\n',...
        theLMSIsomerizationsBleached(1),theLMSIsomerizationsBleached(2),theLMSIsomerizationsBleached(3));
    
%% Plots
%
% Regular cones versus bleached cones
theFig1 = figure; clf; hold on
set(gca,'FontName','Helvetica','FontSize',18);
plot(SToWls(S),T_cones(1,:)','r','LineWidth',4);
plot(SToWls(S),T_cones(2,:)','g','LineWidth',4);
plot(SToWls(S),T_cones(3,:)','b','LineWidth',4);
plot(SToWls(S),T_conesBleached','k','LineWidth',2);
xlabel('Wavelegnth','FontSize',20);
ylabel('Sensitivity','FontSize',20);
xlim([380 750]); ylim([0 1]);
title(sprintf('Effect of pigment bleaching, %0.0f cd/m2',photopicLuminanceCdM2));

% Regular cones versus hemo cones
theFig2 = figure; clf; hold on
set(gca,'FontName','Helvetica','FontSize',18);
plot(SToWls(S),T_cones(1,:)','r','LineWidth',4);
plot(SToWls(S),T_cones(2,:)','g','LineWidth',4);
plot(SToWls(S),T_cones(3,:)','b','LineWidth',4);
plot(SToWls(S),T_conesHemo','k','LineWidth',2);
xlabel('Wavelegnth','FontSize',20);
ylabel('Sensitivity','FontSize',20);
xlim([380 750]); ylim([0 1]);
title(sprintf('Effect of hemoglobin'));

% Hemo cones, effect of bleaching
theFig3 = figure; clf; hold on
set(gca,'FontName','Helvetica','FontSize',18);
plot(SToWls(S),T_conesHemo(1,:)','r','LineWidth',4);
plot(SToWls(S),T_conesHemo(2,:)','g','LineWidth',4);
plot(SToWls(S),T_conesHemo(3,:)','b','LineWidth',4);
plot(SToWls(S),T_conesHemoBleached','k','LineWidth',2);
xlabel('Wavelegnth','FontSize',20);
ylabel('Sensitivity','FontSize',20);
xlim([380 750]); ylim([0 1]);
title(sprintf('Effect of pigment bleaching, hemo cones, %0.0f cd/m2',photopicLuminanceCdM2));

%% Save plots
%
% Root dir for plot
s = strrep(cal.describe.date, ' ', '-');
s = strrep(s, ':', '.');
plotFolder = fullfile(calFolder, 'Plots', calFileName, s);
if ~exist(plotFolder, 'dir')
    [status, statMessage] = mkdir(plotFolder);
    assert(status, 'OLCheckLightLevels:mkdir', statMessage);
end

% Save basic cone bleaching plot
plotRoot = sprintf(['ConeBleachingPlot_%d_%d_' cal.describe.date(1:11)],10*pupilDiameterMm,round(photopicLuminanceCdM2));
plotRoot = strrep(plotRoot, ' ', '_');
plotRoot = strrep(plotRoot, '-', '_');
plotRoot = strrep(plotRoot, ':', '.');
curDir = pwd;
cd(plotFolder);
FigureSave(plotRoot,theFig1,'png');
cd(curDir);

plotRoot = sprintf(['HemoConePlot_%d_%d_' cal.describe.date(1:11)],10*pupilDiameterMm,round(photopicLuminanceCdM2));
plotRoot = strrep(plotRoot, ' ', '_');
plotRoot = strrep(plotRoot, '-', '_');
plotRoot = strrep(plotRoot, ':', '.');
curDir = pwd;
cd(plotFolder);
FigureSave(plotRoot,theFig1,'png');
cd(curDir);

plotRoot = sprintf(['HemoConeBleachingPlot_%d_%d_' cal.describe.date(1:11)],10*pupilDiameterMm,round(photopicLuminanceCdM2));
plotRoot = strrep(plotRoot, ' ', '_');
plotRoot = strrep(plotRoot, '-', '_');
plotRoot = strrep(plotRoot, ':', '.');
curDir = pwd;
cd(plotFolder);
FigureSave(plotRoot,theFig3,'png');
cd(curDir);
