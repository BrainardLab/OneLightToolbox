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
    case 'modulation'
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

%% Make direction information for each observer age
for observerAgeInYears = 20:60
    % Say hello
    fprintf('\nObserver age: %g\n',observerAgeInYears);
    
    % Grab the background from the cache file
    backgroundCacheFile = ['Background_' params.backgroundName '.mat'];
    [backgroundCacheData,isStale] = backgroundOlCache.load([backgroundCacheFile]);
    assert(~isStale,'Background cache file is stale, aborting.');
    backgroundPrimary = backgroundCacheData.backgroundPrimary;
    backgroundSpd = OLPrimaryToSpd(cal, backgroundPrimary);
    
    % If we are doing a pulse, then we need to adjust the background so
    % that it is at the low end of the direction modulation, so that we can
    % then pulse upwards around it.  We do that here.
    if (strcmp(params.type,'pulse'))
        % Note what we are doing
        fprintf('  - Adjusting background to allow positive pulse\n');
        
        % Get self screening parameters if doing so
        if (params.doSelfScreening)
            fractionBleached = OLEstimateConePhotopigmentFractionBleached(S,backgroundSpd,pupilDiameterMm,params.fieldSizeDegrees,photoreceptorClasses);
        else
            fractionBleached = zeros(1,length(photoreceptorClasses));
        end
        
        % Construct the receptor matrix based on the bleaching fraction to
        % this background.
        T_receptors = GetHumanPhotoreceptorSS(S, photoreceptorClasses, params.fieldSizeDegrees, observerAgeInYears, pupilDiameterMm, [], fractionBleached);
        
        % Calculate the receptor coordinates of the background
        backgroundReceptors = T_receptors*backgroundSpd;
        
        % Isolate the receptors by calling the wrapper
        modulationPrimary = ReceptorIsolate(T_receptors,...
            params.background.whichReceptorsToIsolate, params.background.whichReceptorsToIgnore, params.whichReceptorsToMinimize, ...
            B_primary, backgroundPrimary, initialPrimary, whichPrimariesToPin,...
            params.primaryHeadRoom, params.maxPowerDiff, params.background.modulationContrast, ambientSpd);
        modulationSpd = OLPrimaryToSpd(cal, modulationPrimary);
        modulationReceptors = T_receptors*modulationSpd;
        
        % Look at both negative and positive swing
        differencePrimary = modulationPrimary - backgroundPrimary;
        modulationPrimarySignedPositive = backgroundPrimary+differencePrimary;
        modulationPrimarySignedNegative = backgroundPrimary-differencePrimary;
        
        % Compute and report constrasts
        differenceSpdSignedPositive = B_primary*(modulationPrimarySignedPositive-backgroundPrimary);
        differenceReceptors = T_receptors*differenceSpdSignedPositive;
        isolateContrastsSignedPositive = differenceReceptors ./ backgroundReceptors;
        
        differenceSpdSignedNegative = B_primary*(modulationPrimarySignedNegative-backgroundPrimary);
        differenceReceptors = T_receptors*differenceSpdSignedNegative;
        isolateContrastsSignedNegative = differenceReceptors ./ backgroundReceptors;
        
        for j = 1:size(T_receptors,1)
            fprintf('  - %s: contrast around original background = \t%f / %f\n',photoreceptorClasses{j},isolateContrastsSignedPositive(j),isolateContrastsSignedNegative(j));
        end
        
        % Make the new background, which we take as the negative swing to
        % allow a positive pulse.
        backgroundPrimary = backgroundPrimary + params.background.whichPoleToUse*differencePrimary;
        backgroundSpd = OLPrimaryToSpd(cal, backgroundPrimary);
    end
    
    %% Get fraction bleached for background we're actually using
    if (params.doSelfScreening)
        fractionBleached = OLEstimateConePhotopigmentFractionBleached(S,backgroundSpd,pupilDiameterMm,params.fieldSizeDegrees,photoreceptorClasses);
    else
        fractionBleached = zeros(1,length(photoreceptorClasses));
    end
    
    %% Construct the receptor matrix based on the bleaching fraction to this background.
    T_receptors = GetHumanPhotoreceptorSS(S, photoreceptorClasses, params.fieldSizeDegrees, observerAgeInYears, pupilDiameterMm, [], fractionBleached);
    
    %% Calculate the receptor coordinates of the background
    backgroundReceptors = T_receptors*backgroundSpd;
    
    %% Isolate the receptors by calling the wrapper
    modulationPrimary = ReceptorIsolate(T_receptors, whichReceptorsToIsolate, ...
        whichReceptorsToIgnore,whichReceptorsToMinimize,B_primary,backgroundPrimary,...
        initialPrimary,whichPrimariesToPin,params.primaryHeadRoom,params.maxPowerDiff,...
        desiredContrasts,ambientSpd);
    modulationSpd = OLPrimaryToSpd(cal, modulationPrimary);
    modulationReceptors = T_receptors*modulationSpd;
    
    %% Look at both negative and positive swing
    differencePrimary = modulationPrimary - backgroundPrimary;
    modulationPrimarySignedPositive = backgroundPrimary+differencePrimary;
    modulationPrimarySignedNegative = backgroundPrimary-differencePrimary;
    
    %% Isn't this check going to fail for a pulse?
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
    
    %% Why not just use this to do the above?
    % Print out contrasts. This routine is in the Silent Substitution Toolbox.
    ComputeAndReportContrastsFromSpds(sprintf('\n> Observer age: %g',observerAgeInYears),photoreceptorClasses,T_receptors,backgroundSpd,modulationSpd,[],[]);
    
    %% Might want to save the values returned by this, and get photopic
    % trolands too.
    % Print ouf luminance info.  This routine is also in the Silent Substitution Toolbox
    GetLuminanceAndTrolandsFromSpd(S, radianceWattsPerM2Sr, pupilDiameterMm, true);
    
    % Assign all the cache fields
    
    %% Save out important information
    %
    %
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
    
    
end

%% Tuck in the calibration structure
cacheData.cal = cal;


end
