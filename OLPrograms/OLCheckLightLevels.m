% OLCheckLightLevels
%
% Figure out how much light is coming out of the OL device in terms
% of retinal illuminance, so as to compare with light safety standards.

% 2/9/13   dhb  Started with the TsujimuraStimuli program and modified.
% 5/2/13   dhb  This is now tidied up.  
%               Compute MPE both with and without limiting cone angle flag 
%               set to true, and take the minimum.
% 6/28/13  dhb  Move plots to PsychCalLocalData subfolder.
%          dhb  Add a call through the ISO standard too.
% 2/6/13   ms   Set to calculate statistics on the last full-on measured.
% 08/9/17  dhb  Remove open of wiki at end.

%% Clear and close
clear; close all

%% Define the wavelength spacing that we will work with
S = [380 1 401];

%% Get OL calibration info
cal = OLGetCalibrationStructure;
calType = cal.describe.calType.CalFileName;
calDate = cal.describe.date;
calFolderInfo = what(getpref('OneLightToolbox', 'OneLightCalData'));
calFolder = calFolderInfo.path;
calFileName = cal.describe.calType.CalFileName;

% We'll store the plots under a folder with a unique timestamp.  We'll
% remap the ' ' and ':' characters to '-' and '.', respectively found
% in the date string.
s = strrep(cal.describe.date, ' ', '-');
s = strrep(s, ':', '.');
plotFolder = fullfile(calFolder, 'Plots', calFileName, s);
if ~exist(plotFolder, 'dir')
    [status, statMessage] = mkdir(plotFolder);
    assert(status, 'OLCheckLightLevels:mkdir', statMessage);
end

%% Find maximum spectrum that the OL can put out
Scal = cal.computed.pr650S;
nPrimaries = size(cal.computed.pr650M,2);
maxPrimary = ones(nPrimaries,1);
radianceWattsPerM2SrCal = cal.computed.pr650M*maxPrimary + cal.computed.pr650MeanDark;
radianceWattsPerM2Sr = SplineSpd(Scal,radianceWattsPerM2SrCal,S);
radianceWattsPerM2Sr(radianceWattsPerM2Sr < 0) = 0;
radianceWattsPerCm2Sr = (10.^-4)*radianceWattsPerM2Sr;
radianceQuantaPerCm2SrSec = EnergyToQuanta(S,radianceWattsPerCm2Sr);

%% Load CIE functions.   
load T_xyz1931
T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);
photopicLuminanceCdM2 = T_xyz(2,:)*radianceWattsPerM2Sr;
chromaticityXY = T_xyz(1:2,:)*radianceWattsPerM2Sr/sum(T_xyz*radianceWattsPerM2Sr);

%% Load cone spectral sensitivities
load T_cones_ss2
T_cones = SplineCmf(S_cones_ss2,T_cones_ss2,S);

%% Load in a directly measured sunlight through window
% and off piece of white paper towel on floor for comparison.
% Surely that is safe to look at.
load spd_phillybright
spd_phillybright = SplineSpd(S_phillybright,spd_phillybright,S);
photopicLuminancePhillyBrightCdM2 = T_xyz(2,:)*spd_phillybright;
OLSLratio = radianceWattsPerM2Sr./spd_phillybright;

%% Make a plot of one light and sunlight
% spectralFig = figure; clf;
% set(gcf,'Position',[127         198         767        1046]);
% subplot(2,1,1); hold on
% set(gca,'FontName','Helvetica','FontSIze',18);
% plot(SToWls(S),radianceWattsPerM2Sr,'r');
% plot(SToWls(S),spd_phillybright,'b');
% title('Stimulus (red) and Sunlight in DB''s office (blue)');
% xlabel('Wavelength (nm)'); ylabel('Watts/[m2-sr-wlband]');
% subplot(2,1,2); hold on
% set(gca,'FontName','Helvetica','FontSIze',18);
% plot(SToWls(S),OLSLratio,'k');
% title('Ratio of Daylight to Sunlight in DB''s office');
% xlabel('Wavelength (nm)'); ylabel('Ratio');

%% Compute irradiance, trolands, etc.
pupilDiamMm = 4.7;
pupilDiamMm = GetWithDefault('Enter observer pupil diameter in mm',pupilDiamMm);
pupilAreaMm2 = pi*((pupilDiamMm/2)^2);
eyeLengthMm = 17;
degPerMm = RetinalMMToDegrees(1,eyeLengthMm);
irradianceWattsPerUm2 = RadianceToRetIrradiance(radianceWattsPerM2Sr,S,pupilAreaMm2,eyeLengthMm);
irradianceScotTrolands = RetIrradianceToTrolands(irradianceWattsPerUm2, S, 'Scotopic', [], num2str(eyeLengthMm));
irradiancePhotTrolands = RetIrradianceToTrolands(irradianceWattsPerUm2, S, 'Photopic', [], num2str(eyeLengthMm));
irradianceQuantaPerUm2Sec = EnergyToQuanta(S,irradianceWattsPerUm2);
irradianceWattsPerCm2 = (10.^8)*irradianceWattsPerUm2;
irradianceQuantaPerCm2Sec = (10.^8)*irradianceQuantaPerUm2Sec;
irradianceQuantaPerDeg2Sec = (degPerMm^2)*(10.^-2)*irradianceQuantaPerCm2Sec;

%% Pupil adjustment factor for Ansi MPE 
mpePupilDiamMm = 3;
mpePupilDiamMm  = GetWithDefault('Enter ANSI 2007 MPE caclulations assumed pupil diameter in mm',mpePupilDiamMm );
pupilAdjustFactor = (pupilDiamMm/mpePupilDiamMm).^2;

%% Get trolands another way.  For scotopic trolands, this just uses scotopic vlambda (in PTB as T_rods)
% and the magic factor of 1700 scotopic lumens per Watt from Wyszecki & Stiles (2cd edition),
% p. 257.  (This is the analog of 683 photopic lumens per Watt.  Then apply formula from
% page 103 of same book.
%
% Same idea for photopic trolands, although we already have luminance in cd/m2 from above so
% we can short cut a little.
%
% The agreement is good to integer scotopic trolands and I'm will to write off the rest
% as round off error.
load T_rods
T_scotopicVlambda = SplineCmf(S_rods,T_rods,S);
irradianceScotTrolands_check = pupilAreaMm2*1700*(T_scotopicVlambda*radianceWattsPerM2Sr);
irradiancePhotTrolands_check = pupilAreaMm2*photopicLuminanceCdM2;

%% Get cone coordinates from radiance, and also adjust by pupil area.
% Useful for comparing to light levels produced by monochromatic lights
% in other papers
theLMS = T_cones*radianceWattsPerM2Sr;
theLMSTimesPupilArea = pupilAreaMm2*theLMS;

%% Compute irradiance arriving at cornea
%
% According to OSA Handbook of Optics, 2cd Edition, Chaper 24 (vol 2), pp. 24.13-24.15, the
% conversion is (assuming some approximations), irradiance = radiance*stimulusArea/distance^2.
% This is implemented in RadianceAndDistanceAreaToCornIrradiance
stimulusRadiusMm = 6;
stimulusDistanceMm = 25;
stimulusRadiusM = stimulusRadiusMm/1000;
stimulusAreaM2 = pi*(stimulusRadiusM^2);
stimulusDistanceM = stimulusDistanceMm/1000;
stimulusRadiusDeg = rad2deg(stimulusRadiusMm/stimulusDistanceMm);
stimulusAreaDegrees2 = pi*(stimulusRadiusDeg^2);
cornealIrradianceWattsPerM2 = RadianceAndDistanceAreaToCornIrradiance(radianceWattsPerM2Sr,stimulusDistanceM,stimulusAreaM2);
cornealIrradianceWattsPerCm2 = (10.^-4)*cornealIrradianceWattsPerM2;
cornealIrradianceQuantaPerCm2Sec = EnergyToQuanta(S,cornealIrradianceWattsPerCm2);

%% Report on stimulus
fprintf('\n');
fprintf('  * Analyzing OneLight calibration file %s from date %s\n',calType,calDate);
fprintf('  * Stimulus is maximum cal file says OneLight can produce\n');
fprintf('  * Stimulus diameter mm %0.1f, degrees %0.1f\n',2*stimulusRadiusMm,2*stimulusRadiusDeg);
fprintf('  * Stimulus radiance %0.1f log10 watts/[m2-sr], %0.1f log10 watts/[cm2-sr]\n',log10(sum(radianceWattsPerM2Sr)),log10(sum(radianceWattsPerCm2Sr)));
fprintf('  * Stimulus luminance %0.1f candelas/m2\n',photopicLuminanceCdM2);
fprintf('  * Stimulus chromaticity x=%0.4f, y=%0.4f\n',chromaticityXY(1), chromaticityXY(2));
fprintf('    * For comparison, sunlight in Philly: %0.1f cd/m2\n',photopicLuminancePhillyBrightCdM2);
fprintf('  * Stimulus %0.0f (check val %0.0f) scotopic trolands, %0.0f photopic trolands (check val %0.0f)\n',irradianceScotTrolands,irradianceScotTrolands_check,...
    irradiancePhotTrolands,irradiancePhotTrolands_check);
fprintf('  * Stimulus %0.1f log10 scotopic trolands, %0.1f log10 photopic trolands\n',log10(irradianceScotTrolands),log10(irradiancePhotTrolands));
fprintf('  * Stimulus retinal irradiance %0.1f log10 watts/cm2\n',log10(sum(irradianceWattsPerCm2)));
fprintf('  * Stimulus retinal irradiance %0.1f log10 quanta/[cm2-sec]\n',log10(sum(irradianceQuantaPerCm2Sec)));
fprintf('  * Stimulus retinal irradiance %0.1f log10 quanta/[deg2-sec]\n',log10(sum(irradianceQuantaPerDeg2Sec)));
fprintf('  * Stimulus corneal irradiance %0.1f log10 watts/cm2\n',log10(sum(cornealIrradianceWattsPerCm2)));
fprintf('  * Stimulus corneal irradiance %0.1f log10 quanta/[cm2-sec]\n',log10(sum(cornealIrradianceQuantaPerCm2Sec)));
fprintf('  * Pupil area times LMS: %0.2f, %0.2f, %0.2f\n',...
        theLMSTimesPupilArea(1),theLMSTimesPupilArea(2),theLMSTimesPupilArea(3));
    
%% Let's convert to melanopic units, as well as to equivalent stimulation at specific wavelengths
%
% We have retinal and corneal spectral irradiance
%  S
%  irradianceQuantaPerCm2Sec
%  cornealIrradianceWattsPerCm2
melanopsinAssumedFieldSizeDeg = 10;
melanopsonAssumeAgeYears = 32;
[~,T_melanopsinQuantal] = GetHumanPhotoreceptorSS(S, {'Melanopsin'},melanopsinAssumedFieldSizeDeg,melanopsonAssumeAgeYears,pupilDiamMm,[],[],[],[]);
T_melanopsinQuantal = T_melanopsinQuantal/max(T_melanopsinQuantal(1,:));
melIrradianceQuantaPerCm2Sec = T_melanopsinQuantal*irradianceQuantaPerCm2Sec;
melCornealIrradianceQuantaPerCm2Sec = T_melanopsinQuantal*cornealIrradianceQuantaPerCm2Sec;
fprintf('\n');
fprintf('  * Melanopic retinal irradiance %0.1f log10 melanopic quanta/[cm2-sec]\n',log10(melIrradianceQuantaPerCm2Sec));
fprintf('  * Melanopic corneal irradiance %0.1f log10 melanopic quanta/[cm2-sec]\n',log10(melCornealIrradianceQuantaPerCm2Sec));

% Convert Dacey reference retinal irradiances to melanopic units for
% comparison.  Dacey et al. 2005 gives 11-15 log quanta/[cm2-sec] as
% the range over which they measured sustained melanopsin responses.  It
% isn't clear that things were saturating at the high end, though.
index = find(SToWls(S) == 470);
if (isempty(index))
    error('Oops.  Need to find closest wavelength match as exact is not in sampled wls');
end
tempSpd = zeros(size(irradianceQuantaPerCm2Sec));
tempSpd(index) = 10^11;
fprintf('  * Dacey 2005 low, 11 log10 quanta/[cm2-sec] at 470 nm, is %0.1f is log10 melanopic quanta/[cm2-sec]\n',log10(T_melanopsinQuantal*tempSpd));
tempSpd = zeros(size(irradianceQuantaPerCm2Sec));
tempSpd(index) = 10^15;
fprintf('  * Dacey 2005 high, 15 log10 quanta/[cm2-sec] at 470 nm, is %0.1f is log10 melanopic quanta/[cm2-sec]\n',log10(T_melanopsinQuantal*tempSpd));

% Lucas (2012) says that a mouse retina has an area of 18 mm2 and that the
% mouse pupil varies between 9 to 0.1 mm2 in are.  For a fully
% dialated pupil and a full field stimulus, this givea a correction between
% corneal and retinal irradiance is that retinal is
% corneal*(pupilArea/retinalArea).  So for fully dialated pupil, retinal
% illuminance is about about half of corneal.
%
% As a check of this formula, we could ask whether our retinal and corneal
% irradiances are related in this way.  We have our pupil area, and we are
% assuming that the stimulus is 6 mm in radius at 25 mm from the eye.
% Given an eye length of 17 mm, which is about right, we can compute the
% retina radius of the stimulus as 6*17/25 as about 4 mm, and its area as
% about 50 mm2.  Given a pupil diameter of 4.7 mm, the pupil area is 17.34.
% So we should have retinal illuminance is 17.34/50*corneal illuminance, or
% 0.34 * corneal illuminance
%   sum(irradianceQuantaPerCm2Sec)
%   0.34*sum(cornealIrradianceQuantaPerCm2Sec)
% These numbers agree within 3 percent, which we're taking to be good
% enough for now.
%
% Lucas gives something like 11 log quanta/[cm2-sec] in mice as the low end of the
% melanopsin operating range for light between 480 and 500 nm.  We convert
% to retinal illuminance by multiplying by 0.5, and then to melanopic units
tempSpd = zeros(size(irradianceQuantaPerCm2Sec));
index = find(SToWls(S) == 480);
tempSpd(index) = (0.5*10^11)/3;
index = find(SToWls(S) == 490);
tempSpd(index) = (0.5*10^11)/3;
index = find(SToWls(S) == 500);
tempSpd(index) = (0.5*10^11)/3;
fprintf('  * Lucas low is %0.1f log10 melanopic quanta/[cm2-sec]\n',log10(T_melanopsinQuantal*tempSpd));

% At the high end, Lucas gives estimate of 10^15 quanta/[cm2-sec] in same
% wl range as melanopsin saturation, at the retina.
index = find(SToWls(S) == 480);
tempSpd(index) = (10^15)/3;
index = find(SToWls(S) == 490);
tempSpd(index) = (10^15)/3;
index = find(SToWls(S) == 500);
tempSpd(index) = (10^15)/3;
fprintf('  * Lucas high is %0.1f log10 melanopic quanta/[cm2-sec]\n',log10(T_melanopsinQuantal*tempSpd));

%% Get MPE from as a function of wavelength.  For each wavelength,
% take minimum radiance over specified sizes and durations.

% Specify what parameters to test
minLogSize = -1; maxLogSize = 2;
minLogDuration = -1; maxLogDuration = 4;
minLogYRad = -3; maxLogYRad = 2;
minLogYIrrad = -5; maxLogYIrrad = 0;
minLogYIntRad = 0; maxLogYIntRad = 3;
minLogYRadExp = -4; maxLogYRadExp = -1;
measuredWls = SToWls(S);
index = find(measuredWls >= 400);
stimulusWavelengthsNm = measuredWls(index);
stimulusSizesDeg = logspace(minLogSize,maxLogSize,5);
stimulusDurationsSec = logspace(minLogDuration,maxLogDuration,5);
%fprintf('Computing MPE over wavelengths from %0.1f to %0.1f deg\n',min(stimulusWavelengthsNm),max(stimulusWavelengthsNm));
clear MPELimitIntegratedRadiance_JoulesPerCm2Sr MPELimitRadiance_WattsPerCm2Sr MPELimitCornealIrradiance_WattsPerCm2 MPELimitCornealRadiantExposure_JoulesPerCm2
for w = 1:length(stimulusWavelengthsNm)
    stimulusWavelengthNm = stimulusWavelengthsNm(w);
    if (rem(w,10) == 0)  
        %fprintf('\tComputing minimum MPE for wavelength %d nm\n',stimulusWavelengthNm);
    end
    MPELimitIntegratedRadiance_JoulesPerCm2Sr(w) = Inf;
    MPELimitRadiance_WattsPerCm2Sr(w) = Inf;
    MPELimitCornealIrradiance_WattsPerCm2(w) = Inf;
    MPELimitCornealRadiantExposure_JoulesPerCm2(w) = Inf;
    for s = 1:length(stimulusSizesDeg)
        stimulusSizeDeg = stimulusSizesDeg(s);
        stimulusSizeMrad = DegToMrad(stimulusSizeDeg);
        for t = 1:length(stimulusDurationsSec)
            stimulusDurationSec = stimulusDurationsSec(t);
            
            % Compute MPE.  We don't understand how the cone limit computations fit in with
            % the standard, or not.  So, we run it both ways and take the lower limit returned.
            [temp1, temp2, temp3, temp4] = ...
                AnsiZ136MPEComputeExtendedSourceLimit(stimulusDurationSec,stimulusSizeDeg,stimulusWavelengthNm,0);
            [temp5, temp6, temp7, temp8] = ...
                AnsiZ136MPEComputeExtendedSourceLimit(stimulusDurationSec,stimulusSizeDeg,stimulusWavelengthNm,1);
            if (temp5 < temp1)
                temp1 = temp5;
            end
            if (temp6 < temp2)
                temp2 = temp6;
            end
            if (temp7 < temp3);
                temp3 = temp7;
            end
            if (temp8 < temp4)
                temp4 = temp8;
            end
            clear temp5 temp6 temp7 temp8
            
            % Store minimum at each wavelength.
            if (temp1 < MPELimitIntegratedRadiance_JoulesPerCm2Sr(w))
                MPELimitIntegratedRadiance_JoulesPerCm2Sr(w) = temp1;
            end
            if (temp2 < MPELimitRadiance_WattsPerCm2Sr(w))
                MPELimitRadiance_WattsPerCm2Sr(w) = temp2;
            end
            if (temp3 < MPELimitCornealIrradiance_WattsPerCm2(w))
                MPELimitCornealIrradiance_WattsPerCm2(w) = temp3;
            end
            if (temp4 < MPELimitCornealRadiantExposure_JoulesPerCm2(w))
                MPELimitCornealRadiantExposure_JoulesPerCm2(w) = temp4;
            end
        end
    end
end

%% Find how much total radiance we could tolerate if all our power was at the 
% wavelength with minimum MPE.
minMPERadiance = min(MPELimitRadiance_WattsPerCm2Sr(:));
fprintf('\n');
fprintf('  * Compute ANSI 2007 MPE as a function of wavelength.  For each wavelength, took minimum over size and duration\n');
fprintf('    * Size range: %0.1f to %0.1f degrees\n',min(stimulusSizesDeg),max(stimulusSizesDeg));
fprintf('    * Duration range: %0.1f to %0.1f seconds\n',min(stimulusDurationsSec),max(stimulusDurationsSec));
fprintf('  * Minimum ANSI MPE value over wavelengths: radiance %0.1f log W/[cm2-sr]\n',log10(minMPERadiance));
fprintf('    * Compare with total stimulus radiance %0.1f log  W/[cm2-sr]\n',log10(sum(radianceWattsPerCm2Sr)));
fprintf('    * Compare with total pupil adjusted radiance %0.1f log  W/[cm2-sr]\n',log10(sum(radianceWattsPerCm2Sr))+log10(pupilAdjustFactor));
fprintf('    * Pupil adjustment assumes observer pupil diameter of %0.1f mm, MPE standard diameter of %0.1f mm\n',pupilDiamMm,mpePupilDiamMm);

%% Sum over wavelength of power divided by MPE
% Could put this back in, but would have to think
% a bit harder about wavelength spacing adjustment.
%
% index = find(stimulusWavelengthsNm >= 400);
% deltaMeasuredWls = measuredWls(2)-measuredWls(1);
% deltaMPEWls = stimulusWavelengthsNm(2)-stimulusWavelengthsNm(1);
% MPERatioSum = 0;
% for i = 1:length(stimulusWavelengthsNm)
%     index = find(measuredWls == stimulusWavelengthsNm(i));
%     MPERatioSum = MPERatioSum + radianceWattsPerCm2Sr(index)/MPELimitRadiance_WattsPerCm2Sr(i);
% end
% fprintf('MPERatioSum = %0.4f\n',MPERatioSum*deltaMPEWls/deltaMeasuredWls);

%% Now compare to the ISO Standard
stimulusDurationForISOMPESecs = 60*60;
[IsOverLimit,ISO2007MPEStruct] = ISO2007MPECheckType1ContinuousRadiance(S,radianceWattsPerM2Sr,stimulusDurationForISOMPESecs,stimulusAreaDegrees2,eyeLengthMm);
fprintf('  * ISO MPE Analysis\n');
ISO2007MPEPrintAnalysis(IsOverLimit,ISO2007MPEStruct);
fprintf('  * Assumed duration seconds %0.1f, hours %0.1f\n',stimulusDurationForISOMPESecs,stimulusDurationForISOMPESecs/3600);

%% Root name for plots
plotRoot = sprintf(['MPEPlot_%d_%d_' cal.describe.date(1:11)],10*pupilDiamMm,10*mpePupilDiamMm);
plotRoot = strrep(plotRoot, ' ', '_');
plotRoot = strrep(plotRoot, '-', '_');
plotRoot = strrep(plotRoot, ':', '.');

%% Plot of stimulus radiance
%    Black solid, our spectrum
%    Black dashed, our spectrum bumped up by pupilAdjustFactor
%    Blue, sunlight measured off a piece of paper in my office in Philly
%    Red, ANSI MPE as a function of wavelength (power per band)
fig2 = figure; clf; hold on
set(gcf,'Position',[127         198         900 700]);
set(gca,'FontName','Helvetica','FontSIze',18);
log10radianceWattsPerCm2Sr = log10(radianceWattsPerCm2Sr);
log10radianceWattsPerCm2Sr(log10radianceWattsPerCm2Sr < -15) = NaN;
plot(SToWls(S),log10radianceWattsPerCm2Sr,'k','LineWidth',2);
plot(SToWls(S),log10radianceWattsPerCm2Sr+log10(pupilAdjustFactor),'k:','LineWidth',2);
plot(SToWls(S),log10(1e-4*spd_phillybright),'b:','LineWidth',2);
plot(stimulusWavelengthsNm,log10(MPELimitRadiance_WattsPerCm2Sr),'r','LineWidth',3);
xlabel('Wavelength');
ylabel('Radiance (W/[cm2-sr-wlband]');
theTitle{1} = sprintf('Luminance %0.1f cd/m2, total radiance %0.1f log10 watts/cm2-sr',photopicLuminanceCdM2,log10(sum(radianceWattsPerCm2Sr)));
theTitle{2} = sprintf('Pupil %0.1f mm, MPE Assumed Pupil %0.1f mm',pupilDiamMm,mpePupilDiamMm);
theTitle{3} = 'Black - OL max spectrum, Black dashed - pupil adjusted, Blue - Philly sunlight, Red - Ansi MPE';
title(theTitle,'FontSize',16);

curDir = pwd;
cd(plotFolder);
%savefigghost(plotRoot,fig2,'pdf');
FigureSave(plotRoot,fig2,'png');
cd(curDir);

% Full-on 1
radianceWattsPerM2SrCal = cal.raw.fullOn(:, 1);
radianceWattsPerM2Sr = SplineSpd(Scal,radianceWattsPerM2SrCal,S);
radianceWattsPerM2Sr(radianceWattsPerM2Sr < 0) = 0;
fullOn1PhotopicLuminanceCdM2 = T_xyz(2,:)*radianceWattsPerM2Sr;

radianceWattsPerM2SrCal = cal.raw.fullOn(:, 2);
radianceWattsPerM2Sr = SplineSpd(Scal,radianceWattsPerM2SrCal,S);
radianceWattsPerM2Sr(radianceWattsPerM2Sr < 0) = 0;
fullOn2PhotopicLuminanceCdM2 = T_xyz(2,:)*radianceWattsPerM2Sr;

beep; beep; beep;
fprintf('\n\n\n>>> You can copy the following line to the calibration log on the Wiki:\n\n');
fprintf('|''''%s''''|''''%s''''|''''%s''''|%g|%g|%.2f|%.2f|\n\n', cal.describe.calType.char, cal.describe.date, cal.describe.calID, cal.describe.bulbNumber, photopicLuminanceCdM2, fullOn1PhotopicLuminanceCdM2, fullOn2PhotopicLuminanceCdM2);
fprintf('>>> The Wiki URL is https://cfn.upenn.edu/aguirre/wiki/private:bluemechanism:experimental_apparatus:onelight:calibration:calibration_log\n');
%!open https://cfn.upenn.edu/aguirre/wiki/private:bluemechanism:experimental_apparatus:onelight:calibration:calibration_log