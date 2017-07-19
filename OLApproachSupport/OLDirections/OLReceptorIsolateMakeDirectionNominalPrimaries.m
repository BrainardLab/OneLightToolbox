function [cacheData, directionOlCache, wasRecomputed] = OLReceptorIsolateMakeDirectionNominalPrimaries(approach,params,forceRecompute)
% OLReceptorIsolateMakeDirectionNominalPrimaries  Computes nominal primaries for receptor-isolating directions.
%
% Usage:
%     [cacheData, olCache, wasRecomputed] = OLReceptorIsolateMakeDirectionNominalPrimaries(approach,params,forceRecompute)
%
% Description:
%     Use the calibration file and observer age to find the nominal
%     primaries that will produce various receptor isolating modulations.
%     The params
%     structure contains all of the important information, and is defined in
%     the OLDirectionNominalPrimaries dictionary.
%
%     This checks the cache file, and if things have already been computed
%     for the current calibration, it just returns what is there.  Cache
%     files are stored in the OLDirectionNominalPrimaries directory, specified
%     by the preferences for the current approach.
%
%     The parameters for the directions we know about are stored in the
%     direction dictionary, so that each direction's parameters are
%     associated with a direction name.
%
%     This routine knows about different types of directions:
%       modulation - symmetric modulation around a background.
%       pulse - incremental positive pulse relative to low end of swing around background.
%       lightflux - 
%
% Input:
%     approach (string)          Name of whatever approach is invoking this.
%
%     params (struct)            Parameters struct for the direction.  See
%                                OLDirectionNominalParamsDictionary.
%
%     forceRecompute (logical)   If true, forces a recompute of the data found in the config file.
%                                Default: false
%
% Output:
%     cacheData (struct)         Cache data structure.  Contains background
%                                primaries and cal structure.
%
%     olCache (class)            Cache object for storing this.
%
%     wasRecomptued (boolean)    Was the cacheData recomputed?
%
% Optional key/value pairs
%     None.

% 04/19/13   dhb, ms     Update for new convention for desired contrasts in routine ReceptorIsolate.
% 02/25/14   ms          Modularized.
% 06/15/17   dhb et al.  Handle isStale return from updated cache code.

%% Setup the directories we'll use. Directions go in their special place under the materials path approach directory.
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

%% Create the direction cache object and filename
directionOlCache = OLCache(cacheDir, cal);
[~, directionCacheFileName] = fileparts(params.cacheFile);

%% Create the background cache object
backgroundOlCache = OLCache(backgroundCacheDir, cal);

%% Need to check here whether we can just use the current cached data and do so if possible.
%
% If we don't need to recompute, we just return, cacheData in hand.  Otherwise we
% compute.
if (~forceRecompute)
    if (directionOlCache.exist(directionCacheFileName))
        [cacheData,isStale] = directionOlCache.load(directionCacheFileName);
        
        % Compare cacheData.describe.params against currently passed
        % parameters to determine if cache is stale.
        isStale = OLCheckCacheParamsAgainstCurrentParams(cacheData.describe.params, params, 'DirectionNominalPrimaries');
        
        if (~isStale)
            wasRecomputed = false;
            return;
        else
            clear cacheData;
        end
    end
end

%% OK, if we're here we need to compute.
%
% The switch handles different types of modulations we might encounter.
switch params.type
    case {'modulation', 'pulse'}
        %% Pupil diameter in mm.
        pupilDiameterMm = params.pupilDiameterMm;
        
        %% Photoreceptor classes: cell array of strings
        photoreceptorClasses = params.photoreceptorClasses;
        
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
        
        %% Make direction information for each observer age
        for observerAgeInYears = 20:60
            % Say hello
            fprintf('\nObserver age: %g\n',observerAgeInYears);
            
            % Grab the background from the cache file
            backgroundCacheFile = ['Background_' params.backgroundName '.mat'];
            [backgroundCacheData,isStale] = backgroundOlCache.load([backgroundCacheFile]);
            assert(~isStale,'Background cache file is stale, aborting.');
            backgroundPrimary = backgroundCacheData.data(params.backgroundObserverAge).backgroundPrimary;
            backgroundSpd = OLPrimaryToSpd(cal, backgroundPrimary);
            
            % Get fraction bleached for background we're actually using
            if (params.doSelfScreening)
                fractionBleached = OLEstimateConePhotopigmentFractionBleached(S,backgroundSpd,pupilDiameterMm,params.fieldSizeDegrees,observerAgeInYears,photoreceptorClasses);
            else
                fractionBleached = zeros(1,length(photoreceptorClasses));
            end
            
            % Get lambda max shift.  Currently not passed but could be.
            lambdaMaxShift = [];
            
            % Construct the receptor matrix based on the bleaching fraction to this background.
            T_receptors = GetHumanPhotoreceptorSS(S,photoreceptorClasses,params.fieldSizeDegrees,observerAgeInYears,pupilDiameterMm,lambdaMaxShift,fractionBleached);
            
            % Calculate the receptor coordinates of the background
            backgroundReceptors = T_receptors*backgroundSpd;
            
            % Isolate the receptors by calling the ReceptorIsolate
            initialPrimary = backgroundPrimary;
            modulationPrimary = ReceptorIsolate(T_receptors, whichReceptorsToIsolate, ...
                whichReceptorsToIgnore,whichReceptorsToMinimize,B_primary,backgroundPrimary,...
                initialPrimary,whichPrimariesToPin,params.primaryHeadRoom,params.maxPowerDiff,...
                desiredContrasts,ambientSpd);
            modulationSpd = OLPrimaryToSpd(cal, modulationPrimary);
            modulationReceptors = T_receptors*modulationSpd;
            
            % Look at both negative and positive swing and double check that we're within gamut
            differencePrimary = modulationPrimary - backgroundPrimary;
            modulationPrimarySignedPositive = backgroundPrimary+differencePrimary;
            modulationPrimarySignedNegative = backgroundPrimary-differencePrimary;
            if any(modulationPrimarySignedNegative > 1) | any(modulationPrimarySignedNegative < 0)  | any(modulationPrimarySignedPositive > 1)  | any(modulationPrimarySignedPositive < 0)
                error('Out of bounds.')
            end
            
            %% Compute and report constrasts
            differenceSpdSignedPositive = B_primary*differencePrimary;
            differenceReceptorsPositive = T_receptors*differenceSpdSignedPositive;
            isolateContrastsSignedPositive = differenceReceptorsPositive ./ backgroundReceptors;
            modulationSpdSignedPositive = backgroundSpd+differenceSpdSignedPositive;
            
            differenceSpdSignedNegative = B_primary*(-differencePrimary);
            differenceReceptorsNegative = T_receptors*differenceSpdSignedNegative;
            isolateContrastsSignedNegative = differenceReceptorsNegative ./ backgroundReceptors;
            modulationSpdSignedNegative = backgroundSpd+differenceSpdSignedNegative;
            
            % Print out contrasts. This routine is in the Silent Substitution Toolbox.
            ComputeAndReportContrastsFromSpds(sprintf('\n> Observer age: %g',observerAgeInYears),photoreceptorClasses,T_receptors,backgroundSpd,modulationSpd,[],[]);
            
            %% MIGHT WANT TO SAVE THE VALUES HERE AND PHOTOPIC LUMINANCE TOO.
            % Print out luminance info.  This routine is also in the Silent Substitution Toolbox
            GetLuminanceAndTrolandsFromSpd(S, backgroundSpd, pupilDiameterMm, true);
            
            % If it is a pulse rather than a modulation, we replace the background with the low end, and the difference
            % with the swing between low and high.
            if (strcmp(params.type,'pulse'))
                backgroundPrimary = modulationPrimarySignedNegative;
                backgroundSpd = modulationSpdSignedNegative;
                differencePrimary = modulationPrimarySignedPositive-modulationPrimarySignedNegative;
                modulationPrimarySignedNegative = [];
                modulationSpdSignedNegative = [];
            end
            
            %% Assign all the cache fields
            %
            % Description
            cacheData.data(observerAgeInYears).describe.params = params;
            cacheData.data(observerAgeInYears).describe.B_primary = B_primary;
            cacheData.data(observerAgeInYears).describe.ambientSpd = ambientSpd;
            cacheData.data(observerAgeInYears).describe.photoreceptors = photoreceptorClasses;
            cacheData.data(observerAgeInYears).describe.fractionBleached = fractionBleached;
            cacheData.data(observerAgeInYears).describe.S = S;
            cacheData.data(observerAgeInYears).describe.T_receptors = T_receptors;
            cacheData.data(observerAgeInYears).describe.S_receptors = S;
            cacheData.data(observerAgeInYears).describe.params.maxPowerDiff = params.maxPowerDiff;
            cacheData.data(observerAgeInYears).describe.params.primaryHeadRoom = params.primaryHeadRoom;
            
            cacheData.data(observerAgeInYears).describe.contrast = isolateContrastsSignedPositive;
            cacheData.data(observerAgeInYears).describe.contrastSignedPositive = isolateContrastsSignedPositive;
            cacheData.data(observerAgeInYears).describe.contrastSignedNegative = isolateContrastsSignedNegative;
            
            % Background
            cacheData.data(observerAgeInYears).backgroundPrimary = backgroundPrimary;
            cacheData.data(observerAgeInYears).backgroundSpd = backgroundSpd;
            
            % Modulation (unsigned)
            cacheData.data(observerAgeInYears).differencePrimary = differencePrimary;
            cacheData.data(observerAgeInYears).differenceSpd = B_primary*differencePrimary;
            
            % Modulation (signed)
            cacheData.data(observerAgeInYears).modulationPrimarySignedPositive = modulationPrimarySignedPositive;
            cacheData.data(observerAgeInYears).modulationPrimarySignedNegative = modulationPrimarySignedNegative;
            cacheData.data(observerAgeInYears).modulationSpdSignedPositive = modulationSpdSignedPositive;
            cacheData.data(observerAgeInYears).modulationSpdSignedNegative = modulationSpdSignedNegative;  
        end
        
    case 'lightflux'
        
        %     %% Melanopsin-directed
%     [paramsMelBackground, paramsMaxMel, cacheDataBackground, cacheDataMaxMel] = generateAndSavePrimaries(baseParams, paramsDictionary, 'MelanopsinDirected', 'MelanopsinDirectedSuperMaxMel');
% 
%     %% MaxLMS-directed
%     [paramsLMSBackground, paramsMaxLMS, cacheDataBackground, cacheDataMaxLMS] = generateAndSavePrimaries(baseParams, paramsDictionary, 'LMSDirected', 'LMSDirectedSuperMaxLMS');
% 
%     %% Light flux
%     %
%     % For the light flux, we'd like a background that is the average
%     % chromaticity between the two MaxMel and MaxLMS backgrounds. The
%     % appropriate chromaticities are (approx.):
%     %   x = 0.54, y = 0.38
% 
%     % Get the cal files
%     cal = LoadCalFile(OLCalibrationTypes.(baseParams.calibrationType).CalFileName, [], fullfile(getpref(baseParams.approach, 'MaterialsPath'), 'Experiments',baseParams.approach,'OneLightCalData'));
%     cacheDir = fullfile(getpref(baseParams.approach, 'MaterialsPath'),'Experiments',baseParams.approach,'DirectionNominalPrimaries');
%     
%     % Modulation 
%     desiredChromaticity = [0.54 0.38];
%     modPrimary = OLInvSolveChrom(cal, desiredChromaticity);
% 
%     % Background
%     %
%     % This 5 here is hard coding the fact that we want a 400% light flux
%     % modulation.
%     bgPrimary = modPrimary/5;
% 
%     % We copy over the information from the LMS cache file
%     cacheDataMaxPulseLightFlux = cacheDataMaxLMS;
%     paramsMaxPulseLightFlux = paramsMaxLMS;
% 
%     % Set up the cache structure
%     olCacheMaxPulseLightFlux = OLCache(cacheDir, cal);
% 
%     % Replace the values
%     for observerAgeInYrs = 20:60
%         cacheDataMaxPulseLightFlux.data(observerAgeInYrs).backgroundPrimary = bgPrimary;
%         cacheDataMaxPulseLightFlux.data(observerAgeInYrs).backgroundSpd = [];
%         cacheDataMaxPulseLightFlux.data(observerAgeInYrs).differencePrimary = modPrimary-bgPrimary;
%         cacheDataMaxPulseLightFlux.data(observerAgeInYrs).differenceSpd = [];
%         cacheDataMaxPulseLightFlux.data(observerAgeInYrs).modulationPrimarySignedPositive = [];
%         cacheDataMaxPulseLightFlux.data(observerAgeInYrs).modulationSpdSignedPositive = [];
%         cacheDataMaxPulseLightFlux.data(observerAgeInYrs).modulationPrimarySignedNegative = [];
%         cacheDataMaxPulseLightFlux.data(observerAgeInYrs).modulationSpdSignedNegative = [];
%     end
        
        % If the modulation we want is an isochromatic one, we simply scale
        % the background Spectrum. Otherwise, we call ReceptorIsolate. Due
        % to the ambient, we play a little game of adding a little bit to
        % scale the background just right.
        if strfind(directionCacheFileName, 'LightFlux')
            modulationPrimary = backgroundPrimary+backgroundPrimary*max(desiredContrasts);
        end
    otherwise
        error('Unknown direction type specified');
end

%% Tuck in the calibration structure for return
cacheData.cal = cal;
cacheData.directionParams = params;
wasRecomputed = true;


end
