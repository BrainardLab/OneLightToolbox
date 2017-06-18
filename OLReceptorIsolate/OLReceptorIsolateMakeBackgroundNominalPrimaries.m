function [cacheData, olCache, params] = OLReceptorIsolateMakeBackgroundNominalPrimaries(params, forceRecompute)
% OLReceptorIsolateMakeBackgroundNominalPrimaries - Computes the receptor-isolating settings.
%
% Syntax:
% OLReceptorIsolateFindIsolatingPrimaries(params, forceRecompute)
%
% Input:
% params (struct) - Parameters struct as returned by OLReceptorIsolatePrepareConfig.
% forceRecompute (logical) - If true, forces a recompute of the data found
%     in the config file.  Only do this if the target spectra were changed.
%     Default: false
%
% Output:
% cacheData (struct)
% olCache (class)
% params (struct)
% contrastVector (vector) - contains the contrasts of the modulation for
%       the reference observer specified in the params.
%
% See also:
%   OLReceptorIsolateSaveCache, OLReceptorIsolatePrepareConfig
%
% 4/19/13   dhb, ms     Update for new convention for desired contrasts in routine ReceptorIsolate.
% 2/25/14   ms          Modularized.

% Setup the directories we'll use.  We count on the
% standard relative directory structure that we always
% use in our (BrainardLab) experiments.
cacheDir = fullfile(getpref(params.experiment, 'ModulationNominalPrimariesDir'));
if ~isdir(cacheDir)
    mkdir(cacheDir);
end

%% Load the calibration file.
cal = LoadCalFile(OLCalibrationTypes.(params.calibrationType).CalFileName, [], getpref('OneLight', 'OneLightCalData'));
assert(~isempty(cal), 'OLFlickerComputeModulationSpectra:NoCalFile', 'Could not load calibration file: %s', ...
    OLCalibrationTypes.(params.calibrationType).CalFileName);
calID = OLGetCalID(cal);

%% Pull out S
S = cal.describe.S;

%% Create the cache object.
olCache = OLCache(cacheDir, cal);

% Create the cache file name.
[~, cacheFileName] = fileparts(params.cacheFile);

switch params.backgroundType
    case 'BackgroundHalfOn'
        backgroundPrimary = 0.5*ones(size(cal.computed.pr650M,2),1);
    case 'BackgroundEES'
        backgroundPrimary = InvSolveChrom(cal, [1/3 1/3]);
    case {'BackgroundOptim' 'BackgroundOptimRod' 'BackgroundOptimMel' 'BackgroundMaxMel' 'BackgroundMaxLMS' 'BackgroundMaxRod' 'BackgroundMaxMelRodSilent' 'BackgroundMaxMelRodControl'}
        
        %% Parse some of the parameter fields
        photoreceptorClasses = allwords(params.photoreceptorClasses, ',');
        
        
        %% Set up what will be common to all observer ages
        %% Pull out the 'M' matrix
        B_primary = cal.computed.pr650M;
        
        %% Set up some parameters for the optimization
        whichPrimariesToPin = [];       % Primaries we want to pin
        whichReceptorsToIgnore = params.whichReceptorsToIgnore;    % Receptors to ignore
        whichReceptorsToIsolate = params.whichReceptorsToIsolate;    % Receptors to stimulate
        whichReceptorsToMinimize = params.whichReceptorsToMinimize;
        
        % Peg desired contrasts
        if ~isempty(params.modulationContrast)
            desiredContrasts = params.modulationContrast;
        else
            desiredContrasts = [];
        end
        
        % Assign an empty 'ambientSpd' variable so that the ReceptorIsolate
        % code still works. As of Sep 2013 (i.e. SSMRI), we include the ambient measurements
        % in the optimization. This is defined in a flag in the stimulus .cfg
        % files.
        if params.useAmbient
            ambientSpd = cal.computed.pr650MeanDark;
        else
            ambientSpd = zeros(size(B_primary,1),1);
        end
        
        % If the 'ReceptorIsolate' mode does not exist, just use the standard one.
        % We will later make a call to the ReceptorIsolateWrapper function.
        receptorIsolateMode = 'Standard';
        
        observerAgeInYears = 32;
        backgroundPrimary = 0.5*ones(size(B_primary,2),1); % Initial primary
        
        %% Background spd.  Make sure is within primaries.
        % Need to make sure we start optimization at background.
        backgroundSpd = OLPrimaryToSpd(cal, backgroundPrimary);
        radianceWattsPerM2Sr = backgroundSpd;
        radianceWattsPerM2Sr(radianceWattsPerM2Sr < 0) = 0;
        radianceWattsPerCm2Sr = (10.^-4)*radianceWattsPerM2Sr;
        radianceQuantaPerCm2SrSec = EnergyToQuanta(S,radianceWattsPerCm2Sr);
        
        %% Get the fraction bleached for each cone type. See
        % OLGetBGConeIsomerizations for reference.
        
        %% Load CIE functions.
        load T_xyz1931
        T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);
        photopicLuminanceCdM2 = T_xyz(2,:)*radianceWattsPerM2Sr;
        chromaticityXY = T_xyz(1:2,:)*radianceWattsPerM2Sr/sum(T_xyz*radianceWattsPerM2Sr);
        
        %% Adjust background luminance by scaling.  Handles small shifts from
        % original calibration, just by scaling.  This is close enough for purposes
        % of computing fraction of pigment bleached.
        desiredPhotopicLuminanceCdM2 = photopicLuminanceCdM2; % here we set it to original one
        scaleFactor = desiredPhotopicLuminanceCdM2/photopicLuminanceCdM2;
        radianceWattsPerM2Sr = scaleFactor*radianceWattsPerM2Sr;
        radianceWattsPerCm2Sr = scaleFactor*radianceWattsPerCm2Sr;
        radianceQuantaPerCm2SrSec = scaleFactor*radianceQuantaPerCm2SrSec;
        photopicLuminanceCdM2 = scaleFactor*photopicLuminanceCdM2;
        
        %% Get cone spectral sensitivities to use to compute isomerization rates
        lambdaMaxShift = zeros(1, length(photoreceptorClasses));
        [T_cones, T_quantalIsom]  = GetHumanPhotoreceptorSS(S, {'LCone' 'MCone' 'SCone'}, params.fieldSizeDegrees, observerAgeInYears, params.pupilDiameterMm, [], []);
        [T_conesHemo, T_quantalIsomHemo]  = GetHumanPhotoreceptorSS(S, {'LConeTabulatedAbsorbancePenumbral' 'MConeTabulatedAbsorbancePenumbral' 'SConeTabulatedAbsorbancePenumbral'}, params.fieldSizeDegrees, observerAgeInYears, params.pupilDiameterMm, [], []);
        
        %% Compute irradiance, trolands, etc.
        pupilAreaMm2 = pi*((params.pupilDiameterMm/2)^2);
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
        
        %% Get fraction bleached
        fractionBleachedFromTrolands = ComputePhotopigmentBleaching(irradiancePhotTrolands,'cones','trolands','Boynton');
        fractionBleachedFromIsom = zeros(3,1);
        fractionBleachedFromIsomHemo = zeros(3,1);
        for i = 1:3
            fractionBleachedFromIsom(i) = ComputePhotopigmentBleaching(theLMSIsomerizations(i),'cones','isomerizations','Boynton');
            fractionBleachedFromIsomHemo(i) = ComputePhotopigmentBleaching(theLMSIsomerizationsHemo(i),'cones','isomerizations','Boynton');
        end
        GetLuminanceAndTrolandsFromSpd(S, radianceWattsPerM2Sr, params.pupilDiameterMm, true);

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
        
        % If the cache file name contains 'ScreeningUncorrected', assume no
        % bleaching
        %if strfind(cacheFileName, 'ScreeningUncorrected')
        fractionBleached(:) = 0; % Do not correct for screening
        %end
        
        % Construct the receptor matrix
        T_receptors = GetHumanPhotoreceptorSS(S, photoreceptorClasses, params.fieldSizeDegrees, observerAgeInYears, params.pupilDiameterMm, lambdaMaxShift, fractionBleached);
        
        % Calculate the receptor activations to the background
        backgroundReceptors = T_receptors*(B_primary*backgroundPrimary + ambientSpd);
        
        % If the config contains a field called Klein check, get the Klein
        % XYZ also
        if isfield(params, 'checkKlein') && params.checkKlein;
            T_klein = GetKleinK10AColorimeterXYZ(S);
            T_receptors = [T_receptors ; T_klein];
            photoreceptorClasses = [photoreceptorClasses kleinLabel];
        end
        
        
        %% Isolate the receptors by calling the wrapper
        initialPrimary = backgroundPrimary;
        [modulationPrimary] = ReceptorIsolateOptimBackgroundMulti(T_receptors, whichReceptorsToIsolate, ...
            whichReceptorsToIgnore,whichReceptorsToMinimize,B_primary,backgroundPrimary,...
            initialPrimary,whichPrimariesToPin,params.primaryHeadRoom,params.maxPowerDiff,...
            desiredContrasts,ambientSpd,params.directionsYoked,params.directionsYokedAbs,params.pegBackground);
        
        backgroundPrimary = modulationPrimary{1};
        backgroundSpd = OLPrimaryToSpd(cal, backgroundPrimary);
        photopicLuminanceCdM2 = T_xyz(2,:)*backgroundSpd
        chromaticityXY = T_xyz(1:2,:)*backgroundSpd/sum(T_xyz*backgroundSpd)
end

for observerAgeInYears = 20:60
    cacheData.data(observerAgeInYears).backgroundPrimary = backgroundPrimary;
end
cacheData.cal = cal;