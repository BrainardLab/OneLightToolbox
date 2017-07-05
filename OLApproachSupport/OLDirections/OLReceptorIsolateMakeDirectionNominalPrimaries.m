function [cacheData, olCache, wasRecomputed] = OLReceptorIsolateMakeDirectionNominalPrimaries(approach,params,forceRecompute)
% OLReceptorIsolateMakeDirectionNominalPrimaries - Computes nominal primaries for receptor-isolating directions.
%
% Usage:
%   [cacheData, olCache, wasRecomputed] = OLReceptorIsolateMakeDirectionNominalPrimaries(approach,params,forceRecompute)
%
% Description:
%   Use the calibration file and observer age to find the nominal primaries
%   that will produce various receptor isolating modulations.  The params
%   structure contains all of the important information, and is defined in
%   the DirectionNominalPrimaries dictionary.
%
%   This checks the cache file, and if things have already been computed
%   for the current calibration, it just returns what is there.  Cache
%   files are stored in the DirectionNominalPrimaries directory, specified
%   by the preferences for the current approach.
%
%   The parameters for the directions we know about are stored in the
%   direction dictionary, so that each direction's parameters are
%   associated with a direction name.
%
% Input:
%   approach (string)          Name of whatever approach is invoking this.
%
%   params (struct)  Parameters struct for backgrounds.  See
%                              BackgroundNominalParamsDictionary.
%
%   forceRecompute (logical)   If true, forces a recompute of the data found in the config file.
%                              Default: false
% Output:
%   cacheData (struct)         Cache data structure.  Contains background
%                              primaries and cal structure.
%
%   olCache (class)            Cache object for storing this.
%
%   wasRecomptued (boolean)    Was the cacheData recomputed?
%
% Optional key/value pairs
%   None.

% 04/19/13   dhb, ms     Update for new convention for desired contrasts in routine ReceptorIsolate.
% 02/25/14   ms          Modularized.
% 06/15/17   dhb et al.  Handle isStale return from updated cache code.

%% Setup the directories we'll use. Directionss go in their special place under the materials path approach directory.
cacheDir = fullfile(getpref(params.approach, 'MaterialsPath'), 'Experiments',params.approach,'DirectionNominalPrimaries');
if ~isdir(cacheDir)
    mkdir(cacheDir);
end

% Background cache files, which we use here, have their own happy home.
backgroundCacheDir = fullfile(getpref(approach, 'MaterialsPath'), 'Experiments',approach,'BackgroundNominalPrimaries');

%% Load the calibration file
cal = LoadCalFile(OLCalibrationTypes.(params.calibrationType).CalFileName, [], fullfile(getpref(approach, 'MaterialsPath'), 'Experiments',approach,'OneLightCalData'));
assert(~isempty(cal), 'OLFlickerComputeModulationSpectra:NoCalFile', 'Could not load calibration file: %s', ...
    OLCalibrationTypes.(params.calibrationType).CalFileName);

%% Pull out S
S = cal.describe.S;

%% Create the cache object and filename
olCache = OLCache(cacheDir, cal);
[~, cacheFileName] = fileparts(params.cacheFile);

%% Create the background cache object
backgroundOlCache = OLCache(backgroundCacheDir, cal);

%% Need to check here whether we can just use the current cached data and do so if possible.
%
% If we don't need to recompute, we just return, cacheData in hand.  Otherwise we
% compute.
if (~forceRecompute)
    if (olCache.exist(cacheFileName))
        [cacheData,isStale] = olCache.load(cacheFileName);
        if (~isStale)
            wasRecomputed = false;
            return;
        else
            clear cacheData;
        end
    end
end

%% OK, need to compute.
switch params.type
    case 'pulse'
    case 'lightflux'
        
        % If the modulation we want is an isochromatic one, we simply scale
        % the background Spectrum. Otherwise, we call ReceptorIsolate. Due
        % to the ambient, we play a little game of adding a little bit to
        % scale the background just right.
        if strfind(cacheFileName, 'LightFlux')
            modulationPrimary = backgroundPrimary+backgroundPrimary*max(desiredContrasts);
        end
    otherwise
        error('Unknown direction type specified');
end

%% Pupil diameter in mm.
pupilDiameterMm = params.pupilDiameterMm;

%% Parse some of the parameter fields
photoreceptorClasses = allwords(params.photoreceptorClasses, ',');

%% Set up what will be common to all observer ages
% Pull out the 'M' matrix
B_primary = cal.computed.pr650M;

% Set up some parameters for the optimization
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

% Assign a zero 'ambientSpd' variable if we're not using the
% measured ambient.
if params.useAmbient
    ambientSpd = cal.computed.pr650MeanDark;
else
    ambientSpd = zeros(size(B_primary,1),1);
end

fprintf('\nGenerating stimuli which isolate receptor classes:');
for i = 1:length(whichReceptorsToIsolate)
    fprintf('\n  - %s', photoreceptorClasses{whichReceptorsToIsolate(i)});
end
fprintf('\nGenerating stimuli which ignore receptor classes:');
if ~(length(whichReceptorsToIgnore) == 0)
    for i = 1:length(whichReceptorsToIgnore)
        fprintf('\n  - %s', photoreceptorClasses{whichReceptorsToIgnore(i)});
    end
else
    fprintf('\n  - None');
end

% Make direction for each observer age
for observerAgeInYears = 20:60
    
    % Get the background from its cache file
    backgroundCacheFile = ['Background_' params.backgroundName '.mat'];
    [backgroundCacheData,isStale] = backgroundOlCache.load([backgroundCacheFile]);
    assert(~isStale,'Background cache file is stale, aborting.');
    backgroundPrimary = backgroundCacheData.backgroundPrimary;
    backgroundSpd = OLPrimaryToSpd(cal, backgroundPrimary);
    
    % Get self screening parameters if doing so
    if (params.doSelfScreening)
        
        %% Background spd.  Make sure is within primaries.
        % Need to make sure we start optimization at background.
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
        lambdaMaxShift = [];
        [T_cones, T_quantalIsom]  = GetHumanPhotoreceptorSS(S, {'LCone' 'MCone' 'SCone'}, params.fieldSizeDegrees, observerAgeInYears, pupilDiameterMm, [], []);
        [T_conesHemo, T_quantalIsomHemo]  = GetHumanPhotoreceptorSS(S, {'LConeHemo' 'MConeHemo' 'SConeHemo'}, params.fieldSizeDegrees, observerAgeInYears, pupilDiameterMm, [], []);
        
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
        
        %% Get fraction bleached
        fractionBleachedFromTrolands = ComputePhotopigmentBleaching(irradiancePhotTrolands,'cones','trolands','Boynton');
        fractionBleachedFromIsom = zeros(3,1);
        fractionBleachedFromIsomHemo = zeros(3,1);
        for i = 1:3
            fractionBleachedFromIsom(i) = ComputePhotopigmentBleaching(theLMSIsomerizations(i),'cones','isomerizations','Boynton');
            fractionBleachedFromIsomHemo(i) = ComputePhotopigmentBleaching(theLMSIsomerizationsHemo(i),'cones','isomerizations','Boynton');
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
        
    else
        fractionBleached = zeros(1,length(photoreceptorClasses));
        
    end
    
    % Construct the receptor matrix
    T_receptors = GetHumanPhotoreceptorSS(S, photoreceptorClasses, params.fieldSizeDegrees, observerAgeInYears, pupilDiameterMm, [], fractionBleached);
    
    % Calculate the receptor activations to the background
    backgroundReceptors = T_receptors*(B_primary*backgroundPrimary + ambientSpd);

    %% Isolate the receptors by calling the wrapper
    modulationPrimary = ReceptorIsolate(T_receptors,...
        params.background.whichReceptorsToIsolate, params.background.whichReceptorsToIgnore, params.whichReceptorsToMinimize, ...
        B_primary, backgroundPrimary, initialPrimary, whichPrimariesToPin,...
        params.primaryHeadRoom, params.maxPowerDiff, params.background.modulationContrast, ambientSpd);
    modulationSpd = B_primary*modulationPrimary + ambientSpd;
    modulationReceptors = T_receptors*modulationSpd;
    
    %% Look at both negative and positive swing
    differencePrimary = modulationPrimary - backgroundPrimary;
    modulationPrimarySignedPositive = backgroundPrimary+differencePrimary;
    modulationPrimarySignedNegative = backgroundPrimary-differencePrimary;
    
    %% Compute and report constrasts
    differenceSpdSignedPositive = B_primary*(modulationPrimarySignedPositive-backgroundPrimary);
    differenceReceptors = T_receptors*differenceSpdSignedPositive;
    isolateContrastsSignedPositive = differenceReceptors ./ backgroundReceptors;
    
    differenceSpdSignedNegative = B_primary*(modulationPrimarySignedNegative-backgroundPrimary);
    differenceReceptors = T_receptors*differenceSpdSignedNegative;
    isolateContrastsSignedNegative = differenceReceptors ./ backgroundReceptors;
    
    fprintf('\n> Observer age: %g\n',observerAgeInYears);
    for j = 1:size(T_receptors,1)
        fprintf('  - %s: contrast = \t%f / %f\n',photoreceptorClasses{j},isolateContrastsSignedPositive(j),isolateContrastsSignedNegative(j));
    end
    
    %% Make the modulation primaries, which isolate the photopigments, the new background. That way, we can have, e.g. a mel-high background.
    % If we use a positive or negative background (i.e. mel-high or
    % mel-low) depends on the number in
    % params.background.whichPoleToUse (can be +1 = positive or -1
    % = negative).
    backgroundPrimary = backgroundPrimary + params.background.whichPoleToUse*differencePrimary;
    
end

% %% Background spd.  Make sure is within primaries.
% % Need to make sure we start optimization at background.
% backgroundSpd = OLPrimaryToSpd(cal, backgroundPrimary);
% radianceWattsPerM2Sr = backgroundSpd;
% radianceWattsPerM2Sr(radianceWattsPerM2Sr < 0) = 0;
% radianceWattsPerCm2Sr = (10.^-4)*radianceWattsPerM2Sr;
% radianceQuantaPerCm2SrSec = EnergyToQuanta(S,radianceWattsPerCm2Sr);
% 
% %% Get the fraction bleached for each cone type. See
% % OLGetBGConeIsomerizations for reference.
% 
% %% Load CIE functions.
% load T_xyz1931
% T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);
% photopicLuminanceCdM2 = T_xyz(2,:)*radianceWattsPerM2Sr;
% chromaticityXY = T_xyz(1:2,:)*radianceWattsPerM2Sr/sum(T_xyz*radianceWattsPerM2Sr);
% 
% %% Adjust background luminance by scaling.  Handles small shifts from
% % original calibration, just by scaling.  This is close enough for purposes
% % of computing fraction of pigment bleached.
% desiredPhotopicLuminanceCdM2 = photopicLuminanceCdM2; % here we set it to original one
% scaleFactor = desiredPhotopicLuminanceCdM2/photopicLuminanceCdM2;
% radianceWattsPerM2Sr = scaleFactor*radianceWattsPerM2Sr;
% radianceWattsPerCm2Sr = scaleFactor*radianceWattsPerCm2Sr;
% radianceQuantaPerCm2SrSec = scaleFactor*radianceQuantaPerCm2SrSec;
% photopicLuminanceCdM2 = scaleFactor*photopicLuminanceCdM2;
% 
% %% Get cone spectral sensitivities to use to compute isomerization rates
% lambdaMaxShift = zeros(1, length(photoreceptorClasses));
% [T_cones, T_quantalIsom]  = GetHumanPhotoreceptorSS(S, {'LCone' 'MCone' 'SCone'}, params.fieldSizeDegrees, observerAgeInYears, pupilDiameterMm, [], []);
% [T_conesHemo, T_quantalIsomHemo]  = GetHumanPhotoreceptorSS(S, {'LConeTabulatedAbsorbancePenumbral' 'MConeTabulatedAbsorbancePenumbral' 'SConeTabulatedAbsorbancePenumbral'}, params.fieldSizeDegrees, observerAgeInYears, pupilDiameterMm, [], []);
% 
% %% Compute irradiance, trolands, etc.
% pupilAreaMm2 = pi*((pupilDiameterMm/2)^2);
% eyeLengthMm = 17;
% degPerMm = RetinalMMToDegrees(1,eyeLengthMm);
% irradianceWattsPerUm2 = RadianceToRetIrradiance(radianceWattsPerM2Sr,S,pupilAreaMm2,eyeLengthMm);
% irradianceScotTrolands = RetIrradianceToTrolands(irradianceWattsPerUm2, S, 'Scotopic', [], num2str(eyeLengthMm));
% irradiancePhotTrolands = RetIrradianceToTrolands(irradianceWattsPerUm2, S, 'Photopic', [], num2str(eyeLengthMm));
% irradianceQuantaPerUm2Sec = EnergyToQuanta(S,irradianceWattsPerUm2);
% irradianceWattsPerCm2 = (10.^8)*irradianceWattsPerUm2;
% irradianceQuantaPerCm2Sec = (10.^8)*irradianceQuantaPerUm2Sec;
% irradianceQuantaPerDeg2Sec = (degPerMm^2)*(10.^-2)*irradianceQuantaPerCm2Sec;
% 
% %% This is just to get cone inner segment diameter
% photoreceptors = DefaultPhotoreceptors('CIE10Deg');
% photoreceptors = FillInPhotoreceptors(photoreceptors);
% 
% %% Get isomerizations
% theLMSIsomerizations = PhotonAbsorptionRate(irradianceQuantaPerUm2Sec,S, ...
%     T_quantalIsom,S,photoreceptors.ISdiameter.value);
% theLMSIsomerizationsHemo = PhotonAbsorptionRate(irradianceQuantaPerUm2Sec,S, ...
%     T_quantalIsomHemo,S,photoreceptors.ISdiameter.value);
% 
% %% Get fraction bleached
% fractionBleachedFromTrolands = ComputePhotopigmentBleaching(irradiancePhotTrolands,'cones','trolands','Boynton');
% fractionBleachedFromIsom = zeros(3,1);
% fractionBleachedFromIsomHemo = zeros(3,1);
% for i = 1:3
%     fractionBleachedFromIsom(i) = ComputePhotopigmentBleaching(theLMSIsomerizations(i),'cones','isomerizations','Boynton');
%     fractionBleachedFromIsomHemo(i) = ComputePhotopigmentBleaching(theLMSIsomerizationsHemo(i),'cones','isomerizations','Boynton');
% end
% 
% 
% % We can now assign the fraction bleached for each photoreceptor
% % class.
% for p = 1:length(photoreceptorClasses)
%     switch photoreceptorClasses{p}
%         case 'LCone'
%             fractionBleached(p) = fractionBleachedFromIsom(1);
%         case 'MCone'
%             fractionBleached(p) = fractionBleachedFromIsom(2);
%         case 'SCone'
%             fractionBleached(p) = fractionBleachedFromIsom(3);
%         case 'LConeHemo'
%             fractionBleached(p) = fractionBleachedFromIsomHemo(1);
%         case 'MConeHemo'
%             fractionBleached(p) = fractionBleachedFromIsomHemo(2);
%         case 'SConeHemo'
%             fractionBleached(p) = fractionBleachedFromIsomHemo(3);
%         otherwise
%             fractionBleached(p) = 0;
%     end
% end
% 
% % If the cache file name contains 'ScreeningUncorrected', assume no
% % bleaching
% if strfind(cacheFileName, 'ScreeningUncorrected')
%     fractionBleached(:) = 0;
% end
% 
% % Construct the receptor matrix
% T_receptors = GetHumanPhotoreceptorSS(S, photoreceptorClasses, params.fieldSizeDegrees, observerAgeInYears, pupilDiameterMm, zeros(1, length(photoreceptorClasses)), fractionBleached);
% 
% % Calculate the receptor activations to the background
% backgroundReceptors = T_receptors*(B_primary*backgroundPrimary + ambientSpd);
% 
% % If the config contains a field called Klein check, get the Klein
% % XYZ also
% if isfield(params, 'checkKlein') && params.checkKlein;
%     T_klein = GetKleinK10AColorimeterXYZ(S);
%     T_receptors = [T_receptors ; T_klein];
%     photoreceptorClasses = [photoreceptorClasses kleinLabel];
% end
% 
% % If the modulation we want is an isochromatic one, we simply scale
% % the background Spectrum. Otherwise, we call ReceptorIsolate. Due
% % to the ambient, we play a little game of adding a little bit to
% % scale the background just right.
% if strfind(cacheFileName, 'LightFlux')
%     modulationPrimary = backgroundPrimary+backgroundPrimary*max(desiredContrasts);
% else
%     %% Isolate the receptors by calling the wrapper
%     modulationPrimary = ReceptorIsolate(T_receptors, whichReceptorsToIsolate, ...
%         whichReceptorsToIgnore,whichReceptorsToMinimize,B_primary,backgroundPrimary,...
%         initialPrimary,whichPrimariesToPin,params.primaryHeadRoom,params.maxPowerDiff,...
%         desiredContrasts,ambientSpd);
%     
% end
% modulationSpd = B_primary*modulationPrimary + ambientSpd;
% modulationReceptors = T_receptors*modulationSpd;

%% Look at both negative and positive swing
differencePrimary = modulationPrimary - backgroundPrimary;
modulationPrimarySignedPositive = backgroundPrimary+differencePrimary;
modulationPrimarySignedNegative = backgroundPrimary-differencePrimary;

if any(modulationPrimarySignedNegative > 1) | any(modulationPrimarySignedNegative < 0)  | any(modulationPrimarySignedPositive > 1)  | any(modulationPrimarySignedPositive < 0)
    error('Out of bounds.')
end

%% Compute and report constrasts
differenceSpdSignedPositive = B_primary*(modulationPrimarySignedPositive-backgroundPrimary);
differenceReceptors = T_receptors*differenceSpdSignedPositive;
isolateContrastsSignedPositive = differenceReceptors ./ backgroundReceptors;

differenceSpdSignedNegative = B_primary*(modulationPrimarySignedNegative-backgroundPrimary);
differenceReceptors = T_receptors*differenceSpdSignedNegative;
isolateContrastsSignedNegative = differenceReceptors ./ backgroundReceptors;

% Print out contrasts
ComputeAndReportContrastsFromSpds(sprintf('\n> Observer age: %g',observerAgeInYears),photoreceptorClasses,T_receptors,backgroundSpd,modulationSpd,[],[]);

% Print ouf luminance info.
GetLuminanceAndTrolandsFromSpd(S, radianceWattsPerM2Sr, pupilDiameterMm, true);

% Assign all the cache fields

%% Save out important information
cacheData.data(observerAgeInYears).describe.params = params;                     % Parameters
cacheData.data(observerAgeInYears).describe.B_primary = B_primary;
cacheData.data(observerAgeInYears).describe.photoreceptors = photoreceptorClasses;     % Photoreceptors
cacheData.data(observerAgeInYears).describe.fractionBleached = fractionBleached;
cacheData.data(observerAgeInYears).describe.S = S;     % Photoreceptors
cacheData.data(observerAgeInYears).describe.T_receptors = T_receptors;
cacheData.data(observerAgeInYears).describe.S_receptors = S;
cacheData.data(observerAgeInYears).describe.params.maxPowerDiff = params.maxPowerDiff;
cacheData.data(observerAgeInYears).describe.params.primaryHeadRoom = params.primaryHeadRoom;
cacheData.data(observerAgeInYears).describe.contrast = isolateContrastsSignedPositive;
cacheData.data(observerAgeInYears).describe.contrastSignedPositive = isolateContrastsSignedPositive;
cacheData.data(observerAgeInYears).describe.contrastSignedNegative = isolateContrastsSignedNegative;
cacheData.data(observerAgeInYears).describe.bgOperatingPoint = operatingPoint;
cacheData.cal = cal;

%% Stick in there the stuff we've calculated
% Background
cacheData.data(observerAgeInYears).backgroundPrimary = backgroundPrimary;
cacheData.data(observerAgeInYears).backgroundSpd = backgroundSpd;

% Modulation (unsigned)
cacheData.data(observerAgeInYears).differencePrimary = differencePrimary;
cacheData.data(observerAgeInYears).differenceSpd = B_primary*differencePrimary;

% Modulation (signed)
cacheData.data(observerAgeInYears).modulationPrimarySignedPositive = modulationPrimarySignedPositive;
cacheData.data(observerAgeInYears).modulationPrimarySignedNegative = modulationPrimarySignedNegative;
cacheData.data(observerAgeInYears).modulationSpdSignedPositive = (B_primary*modulationPrimarySignedPositive) + ambientSpd;
cacheData.data(observerAgeInYears).modulationSpdSignedNegative = (B_primary*modulationPrimarySignedNegative) + ambientSpd;

cacheData.data(observerAgeInYears).ambientSpd = ambientSpd;
cacheData.data(observerAgeInYears).operatingPoint = operatingPoint;

end

function contrast = ComputeContrastIso(T_receptors, B_primary, backgroundPrimary, ambientSpd, desiredContrast, c)
backgroundReceptors = T_receptors*(B_primary*backgroundPrimary + ambientSpd);
backgroundSpd = B_primary*backgroundPrimary + ambientSpd;
modulationPrimary = backgroundPrimary+backgroundPrimary*desiredContrast+c;


%% Look at both negative and positive swing
differencePrimary = modulationPrimary - backgroundPrimary;
modulationPrimarySignedPositive = backgroundPrimary+differencePrimary;
modulationPrimarySignedNegative = backgroundPrimary-differencePrimary;

%% Compute and report constrasts
differenceSpdSignedPositive = B_primary*(modulationPrimarySignedPositive-backgroundPrimary);

differenceReceptors = T_receptors*differenceSpdSignedPositive;
contrast = differenceReceptors ./ backgroundReceptors;

end

function error = FitIsoScalar(c, T_receptors, B_primary, backgroundPrimary, ambientSpd, desiredContrast);
contrast = mean(ComputeContrastIso(T_receptors, B_primary, backgroundPrimary, ambientSpd, desiredContrast, c));
error = sqrt(sum(contrast-desiredContrast).^2);
end

function f = FitChromaticity(x,B_primary,ambientSpd,T_xyz,targetX,targetY,targetLum)

% Compute background including ambient
backgroundSpd = B_primary*x + ambientSpd;

% Compute chromaticity of that
chromaticityXY = T_xyz(1:2,:)*backgroundSpd/sum(T_xyz*backgroundSpd);
photopicLuminanceCdM2 = T_xyz(2,:)*backgroundSpd;

f = sum((chromaticityXY(1)-targetX)^2 + (chromaticityXY(2)-targetY)^2 + (targetLum-photopicLuminanceCdM2)^2);
end