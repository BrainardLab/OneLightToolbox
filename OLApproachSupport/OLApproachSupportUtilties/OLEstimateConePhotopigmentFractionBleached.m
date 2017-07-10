function fractionBleached = OLEstimateConePhotopigmentFractionBleached(S,theSpd,pupilDiameterMm,fieldSizeDegrees,observerAgeInYears,photoreceptorClasses)
% OLEstimateConePhotopigmentFractionBleached  Estimate cone photopigment fraction bleached
%
% Usage:
%     fractionBleached = OLEstimateConePhotopigmentFractionBleached(S,spd,pupilDiameterMm,fieldSizeDegrees,observerAgeInYears,photoreceptorClasses)
%
% Description:
%     Compute isomerization rates of cones to a passed spectral radiance
%     and use this informaiton to estimate fraction of pigment bleached.
%
%     Inner segment diameter is taken to be that provided in the structure
%     obtaine via the following, independent of the passed field size. This
%     is OK because we're looking at log unit effects with this
%     calculation.
%        photoreceptors = DefaultPhotoreceptors('CIE10Deg');
%        photoreceptors = FillInPhotoreceptors(photoreceptors);
%
% Input:
%     S                          Wavelength sampling as row vector: [startWl deltaWl nWls],
%                                wavelengths in nm.
%
%     theSpd                     Spectral radiance in WattsPerM2Sr per wavelength band (not
%                                per nm)
%
%     pupilDiameterMm            Pupil diameter in mm to use when computing
%                                retinal irradiance.  Eye length is assumed to be 17 mm.
%
%     fieldSizeDegrees           Field size in degrees for cone spectral sensitivity computations.
%
%     observerAgeInYears         Observer age in years for cone spectral sensitivity computations.
%
%     photoreceptorClasses       Cell array of strings describing photoreceptor classes of interest.
%                                Options are 'LCone', 'MCone', 'SCone','LConeHemo', 'MConeHemo', 'SConeHemo.
%                                See GetHumanPhotoreceptorSS for description of exactly what these denote.
%
% Output:
%     fractionBleached           Vector of fraction photopigment bleached
%                                for specified classes.  For any other classes passed, fraction
%                                bleached is returned as zero.

% 07/05/17  dhb  Pulled this out as its own function.

%% Some basic radiometric calcs on the Spd.
% Need to make sure we start optimization at background.
radianceWattsPerM2Sr = theSpd;
radianceWattsPerM2Sr(radianceWattsPerM2Sr < 0) = 0;
radianceWattsPerCm2Sr = (10.^-4)*radianceWattsPerM2Sr;
radianceQuantaPerCm2SrSec = EnergyToQuanta(S,radianceWattsPerCm2Sr);

%% Load CIE functions so we can compute luminance
load T_xyz1931
T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);
photopicLuminanceCdM2 = T_xyz(2,:)*radianceWattsPerM2Sr;
chromaticityXY = T_xyz(1:2,:)*radianceWattsPerM2Sr/sum(T_xyz*radianceWattsPerM2Sr);

%% Get cone spectral sensitivities to use to compute isomerization rates
[T_cones, T_quantalIsom] = GetHumanPhotoreceptorSS(S, {'LCone' 'MCone' 'SCone'}, fieldSizeDegrees, observerAgeInYears, pupilDiameterMm, [], []);
%[T_conesHemo, T_quantalIsomHemo]  = GetHumanPhotoreceptorSS(S, {'LConeHemo' 'MConeHemo' 'SConeHemo'}, fieldSizeDegrees, observerAgeInYears, pupilDiameterMm, [], []);

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
ISDiameter = photoreceptors.ISdiameter.value;

%% Get isomerizations
theLMSIsomerizations = PhotonAbsorptionRate(irradianceQuantaPerUm2Sec,S, ...
    T_quantalIsom,S,ISDiameter);
% theLMSIsomerizationsHemo = PhotonAbsorptionRate(irradianceQuantaPerUm2Sec,S, ...
%     T_quantalIsomHemo,S,ISDiameter);

%% Get fraction bleached
fractionBleachedFromIsom = zeros(3,1);
fractionBleachedFromIsomHemo = zeros(3,1);
for i = 1:3
    fractionBleachedFromIsom(i) = ComputePhotopigmentBleaching(theLMSIsomerizations(i),'cones','isomerizations','Boynton');
%    fractionBleachedFromIsomHemo(i) = ComputePhotopigmentBleaching(theLMSIsomerizationsHemo(i),'cones','isomerizations','Boynton');
end

% We can now assign the fraction bleached for each photoreceptor
% class.
for p = 1:length(photoreceptorClasses)
    switch photoreceptorClasses{p}
        case 'LCone'
            fractionBleached(p) = fractionBleachedFromIsom(1);
        case 'MCone'
            fractionBleached(p) = fractionBleachedFromIsom(2);
        case 'SCone'
            fractionBleached(p) = fractionBleachedFromIsom(3);
        case 'LConeHemo'
            fractionBleached(p) = fractionBleachedFromIsomHemo(1);
        case 'MConeHemo'
            fractionBleached(p) = fractionBleachedFromIsomHemo(2);
        case 'SConeHemo'
            fractionBleached(p) = fractionBleachedFromIsomHemo(3);
        otherwise
            fractionBleached(p) = 0;
    end
end