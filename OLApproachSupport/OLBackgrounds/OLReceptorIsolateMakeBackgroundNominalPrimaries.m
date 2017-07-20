function [cacheData, olCache, wasRecomputed] = OLReceptorIsolateMakeBackgroundNominalPrimaries(approach,params,forceRecompute)
% OLReceptorIsolateMakeBackgroundNominalPrimaries  Finds backgrounds according to background parameters.
%
% Usage:
%     [cacheData, olCache, wasRecomputed] = OLReceptorIsolateMakeBackgroundNominalPrimaries(approach,params,forceRecompute)
%
% Description:
%     Use calibration file information to make backgrounds with specified
%     properties.  Background properties are defined in the
%     BackgroundNominalPrimaries dictionary and passed as a parameter struct,
%     except for a few that are specifically named and that are calibration independent.
%
%     This checks the cache file, and if things have already been computed
%     for the current calibration, it just returns what is there.  Cache
%     files are stored in the BackgroundNominalPrimaries directory, specified
%     by the preferences for the current approach.
%
%     The parameters for the directions we know about are stored in the
%     background dictionary, so that each direction's parameters are
%     associated with a background name.
%
%     The background is just computed for a nominal (params.backgroundObserverAge) observer age,
%     because we don't need perfection for this, just something about right.
%
%     This routine knows about different types of backgrounds:
%       named - a specific named background
%       lightfluxchrom - background of a specified chromaticity, scaled to allow a light flux modulation.
%       optimized - a background optimized for some modulation.
%
% Input:
%     approach (string)          Name of whatever approach is invoking this.
%
%     params (struct)            Parameters struct for backgrounds.  See
%                                OLBackgroundNominalParamsDictionary.
%
%     forceRecompute (logical)   If true, forces a recompute of the data found in the config file.
%                                Default: false
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

% 06/29/17   dhb         Cleaning up.
% 07/05/17   dhb         Better comments.

%% Setup the directories we'll use. Backgrounds go in their special place under the materials path approach directory.
cacheDir = fullfile(getpref(approach, 'MaterialsPath'), 'Experiments',approach,'BackgroundNominalPrimaries');
if ~isdir(cacheDir)
    mkdir(cacheDir);
end

%% Load the calibration file
cal = LoadCalFile(OLCalibrationTypes.(params.calibrationType).CalFileName, [], fullfile(getpref(approach, 'MaterialsPath'), 'Experiments',approach,'OneLightCalData'));
assert(~isempty(cal), 'OLFlickerComputeModulationSpectra:NoCalFile', 'Could not load calibration file: %s', ...
    OLCalibrationTypes.(params.calibrationType).CalFileName);

%% Pull out S
S = cal.describe.S;

%% Create the cache object and filename
olCache = OLCache(cacheDir, cal);
[~, cacheFileName] = fileparts(params.cacheFile);

%% Need to check here whether we can just use the current cached data and do so if possible.
%
% If we don't need to recompute, we just return, cacheData in hand.  Otherwise we
% compute.
if (~forceRecompute)
    if (olCache.exist(cacheFileName))
        [cacheData,isStale] = olCache.load(cacheFileName);
        
        % Compare cacheData.describe.params against currently passed
        % parameters to determine if cache is stale.
        isStale = OLCheckCacheParamsAgainstCurrentParams(cacheData.describe.params, params, 'BackgroundNominalPrimaries');
 
        if (~isStale)
            wasRecomputed = false;
            return;
        else
            clear cacheData;
        end
    end
end

%% OK, need to recompute
switch params.type
    case 'named'
        % These are cases where we just do something very specific with the
        % name.
        switch params.name
            case 'BackgroundHalfOn'
                backgroundPrimary = 0.5*ones(size(cal.computed.pr650M,2),1);
            case 'BackgroundEES'
                backgroundPrimary = InvSolveChrom(cal, [1/3 1/3]);
            otherwise
                error('Unknown named background passed');
        end
        
    case 'lightfluxchrom'
        % Background at specified chromaticity that allows a large light
        % flux pulse modulation.
        maxBackgroundPrimary = OLBackgroundInvSolveChrom(cal, params.lightFluxDesiredXY);
        backgroundPrimary = maxBackgroundPrimary/params.lightFluxDownFactor;
        
    case 'optimized'
        % These backgrounds get optimized according to the parameters in
        % the structure.  Backgrounds are optimized with respect to a
        % params.backgroundObserverAge year old observer, and no correction
        % for photopigment bleaching is applied.  We are just trying to get
        % pretty good backgrounds, so we don't need to fuss with small
        % effects.
        
        %% Photoreceptor classes: cell array of strings
        photoreceptorClasses = params.photoreceptorClasses;
        
        %% Set up what will be common to all observer ages
        % Pull out the 'M' matrix
        B_primary = cal.computed.pr650M;
        
        %% Set up parameters for the optimization
        whichPrimariesToPin = [];
        whichReceptorsToIgnore = params.whichReceptorsToIgnore;
        whichReceptorsToIsolate = params.whichReceptorsToIsolate;
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
        
        % We get backgrounds for the nominal observer age, and hope for the
        % best for other observer ages.
        observerAgeInYears = params.backgroundObserverAge;
        
        %% Initial background
        %
        % Start at mid point of primaries.
        backgroundPrimary = 0.5*ones(size(B_primary,2),1);
        
        %% Construct the receptor matrix
        lambdaMaxShift = zeros(1, length(photoreceptorClasses));
        fractionBleached = zeros(1,length(photoreceptorClasses));
        T_receptors = GetHumanPhotoreceptorSS(S, photoreceptorClasses, params.fieldSizeDegrees, observerAgeInYears, params.pupilDiameterMm, lambdaMaxShift, fractionBleached);
        
        %% Isolate the receptors by calling the wrapper
        initialPrimary = backgroundPrimary;
        optimizedBackgroundPrimaries = ReceptorIsolateOptimBackgroundMulti(T_receptors, whichReceptorsToIsolate, ...
            whichReceptorsToIgnore,whichReceptorsToMinimize,B_primary,backgroundPrimary,...
            initialPrimary,whichPrimariesToPin,params.primaryHeadRoom,params.maxPowerDiff,...
            desiredContrasts,ambientSpd,params.directionsYoked,params.directionsYokedAbs,params.pegBackground);
        
        %% Pull out what we want
        backgroundPrimary = optimizedBackgroundPrimaries{1};   
        
    otherwise
        error('Unknown type for background passed');
end

 %% Fill in the cache data for return
 %
 %
 % Fill in for all observer ages based on the nominal calculation.
 for observerAgeInYears = 20:60     
     % The background
     cacheData.data(observerAgeInYears).backgroundPrimary = backgroundPrimary;
 end
 
% Calibration file, and note that we recomputed the cache data.
cacheData.params = params;
cacheData.cal = cal;
wasRecomputed = true;

end