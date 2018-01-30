function [cacheData, directionOlCache, wasRecomputed] = OLReceptorIsolateMakeDirectionNominalPrimaries(approach,directionParams,forceRecompute,varargin)
% OLReceptorIsolateMakeDirectionNominalPrimaries  Computes nominal primaries for receptor-isolating directions.
%
% Usage:
%     [cacheData, olCache, wasRecomputed] = OLReceptorIsolateMakeDirectionNominalPrimaries(approach,directionParams,forceRecompute)
%
% Description:
%     Use the calibration file and observer age to find the nominal
%     primaries that will produce various receptor isolating modulations.
%     The directionParams structure contains all of the important
%     information, and is defined in the OLDirectionNominalPrimaries
%     dictionary.
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
%       bipolar - symmetric bipolar around a background.
%       unipolar - incremental positive unipolar relative to low end of swing around background.
%       lightfluxchrom - light flux pulse around a background of specified chromaticiity.
%
% Input:
%     approach (string)          Name of whatever approach is invoking this.
%
%     directionParams (struct)   Parameters struct for the direction.  See
%                                OLDirectionNominalParamsDictionary.
%
%     forceRecompute (logical)   If true, forces a recompute of the data found in the config file.z
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
%     'verbose'                  Be chatty? (default, false).

% 04/19/13   dhb, ms     Update for new convention for desired contrasts in routine ReceptorIsolate.
% 02/25/14   ms          Modularized.
% 06/15/17   dhb et al.  Handle isStale return from updated cache code.
% 07/22/17   dhb         Enforce verbose
% 08/09/17   dhb, mab    Comment out code that stores difference, just return background and max modulations.
% 08/10/17   dhb         Return only postiive swing.  Because this is a nominal calculation, the negative swing is redundant.


%% Parse input
p = inputParser;
p.addRequired('approach',@ischar);
p.addRequired('directionParams',@isstruct);
p.addRequired('forceRecompute',@islogical);
p.addParameter('verbose',false,@islogical);
p.parse(approach,directionParams,forceRecompute,varargin{:});

%% Setup the directories we'll use. Directions go in their special place under the materials path approach directory.
cacheDir = fullfile(getpref(directionParams.approach, 'DirectionNominalPrimariesPath'));
if ~isdir(cacheDir)
    mkdir(cacheDir);
end

% Background cache files, which we use here, have their own happy home.
backgroundCacheDir = fullfile(getpref(approach, 'BackgroundNominalPrimariesPath'));

%% Load the calibration file
cal = LoadCalFile(OLCalibrationTypes.(directionParams.calibrationType).CalFileName, [], fullfile(getpref(approach, 'OneLightCalDataPath')));
assert(~isempty(cal), 'OLFlickerComputeModulationSpectra:NoCalFile', 'Could not load calibration file: %s', ...
    OLCalibrationTypes.(directionParams.calibrationType).CalFileName);

%% Pull out S
S = cal.describe.S;

%% Create the direction cache object and filename
directionOlCache = OLCache(cacheDir, cal);
[~, directionCacheFileName] = fileparts(directionParams.cacheFile);

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
        % parameters to determine if everything is hunky-dory.  This throws
        % an error if not.  Could recompute, but we want the user to
        % think about this case and make sure it wasn't just an error.
        OLCheckCacheParamsAgainstCurrentParams(cacheData, directionParams);
        
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
switch directionParams.type
    case {'bipolar', 'unipolar'}
        % Pupil diameter in mm.
        pupilDiameterMm = directionParams.pupilDiameterMm;
        
        % Photoreceptor classes: cell array of strings
        photoreceptorClasses = directionParams.photoreceptorClasses;
        
        % Set up what will be common to all observer ages
        % Pull out the 'M' matrix
        B_primary = cal.computed.pr650M;
        
        % Set up some parameters for the optimization
        whichPrimariesToPin = [];       % Primaries we want to pin
        whichReceptorsToIgnore = directionParams.whichReceptorsToIgnore;    % Receptors to ignore
        whichReceptorsToIsolate = directionParams.whichReceptorsToIsolate;    % Receptors to stimulate
        whichReceptorsToMinimize = directionParams.whichReceptorsToMinimize;
        
        % Peg desired contrasts
        if ~isempty(directionParams.modulationContrast)
            desiredContrasts = directionParams.modulationContrast;
        else
            desiredContrasts = [];
        end
        
        % Assign a zero 'ambientSpd' variable if we're not using the
        % measured ambient.
        if directionParams.useAmbient
            ambientSpd = cal.computed.pr650MeanDark;
        else
            ambientSpd = zeros(size(B_primary,1),1);
        end
        
        if (p.Results.verbose), fprintf('\nGenerating stimuli which isolate receptor classes:'); end;
        for i = 1:length(whichReceptorsToIsolate)
            if (p.Results.verbose), fprintf('\n  - %s', photoreceptorClasses{whichReceptorsToIsolate(i)}); end;
        end
        if (p.Results.verbose), fprintf('\nGenerating stimuli which ignore receptor classes:'); end;
        if ~(length(whichReceptorsToIgnore) == 0)
            for i = 1:length(whichReceptorsToIgnore)
                if (p.Results.verbose), fprintf('\n  - %s', photoreceptorClasses{whichReceptorsToIgnore(i)}); end;
            end
        else
            if (p.Results.verbose), fprintf('\n  - None'); end;
        end
        
        % Make direction information for each observer age
        for observerAgeInYears = 20:60
            % Say hello
            if (p.Results.verbose), fprintf('\nObserver age: %g\n',observerAgeInYears); end;
            
            % Grab the background from the cache file
            backgroundCacheFile = ['Background_' directionParams.backgroundName '.mat'];
            [backgroundCacheData,isStale] = backgroundOlCache.load(backgroundCacheFile);
            assert(~isStale,'Background cache file is stale, aborting.');
            backgroundPrimary = backgroundCacheData.data(directionParams.backgroundObserverAge).backgroundPrimary;
            backgroundSpd = OLPrimaryToSpd(cal, backgroundPrimary);
            
            % Get fraction bleached for background we're actually using
            if (directionParams.doSelfScreening)
                fractionBleached = OLEstimateConePhotopigmentFractionBleached(S,backgroundSpd,pupilDiameterMm,directionParams.fieldSizeDegrees,observerAgeInYears,photoreceptorClasses);
            else
                fractionBleached = zeros(1,length(photoreceptorClasses));
            end
            
            % Get lambda max shift.  Currently not passed but could be.
            lambdaMaxShift = [];
            
            % Construct the receptor matrix based on the bleaching fraction to this background.
            T_receptors = GetHumanPhotoreceptorSS(S,photoreceptorClasses,directionParams.fieldSizeDegrees,observerAgeInYears,pupilDiameterMm,lambdaMaxShift,fractionBleached);
            
            % Calculate the receptor coordinates of the background
            backgroundReceptors = T_receptors*backgroundSpd;
            
            % Isolate the receptors by calling the ReceptorIsolate
            initialPrimary = backgroundPrimary;
            modulationPrimarySignedPositive = ReceptorIsolate(T_receptors, whichReceptorsToIsolate, ...
                whichReceptorsToIgnore,whichReceptorsToMinimize,B_primary,backgroundPrimary,...
                initialPrimary,whichPrimariesToPin,directionParams.primaryHeadRoom,directionParams.maxPowerDiff,...
                desiredContrasts,ambientSpd);
            
            % Look at both negative and positive swing and double check that we're within gamut
            differencePrimary = modulationPrimarySignedPositive - backgroundPrimary;
            modulationPrimarySignedPositive = backgroundPrimary+differencePrimary;
            modulationPrimarySignedNegative = backgroundPrimary-differencePrimary;
            if any(modulationPrimarySignedNegative > 1) | any(modulationPrimarySignedNegative < 0)  | any(modulationPrimarySignedPositive > 1)  | any(modulationPrimarySignedPositive < 0)
                error('Out of bounds.')
            end
            
            % Compute spds, constrasts
            differenceSpdSignedPositive = B_primary*differencePrimary;
            differenceReceptorsPositive = T_receptors*differenceSpdSignedPositive;
            isolateContrastsSignedPositive = differenceReceptorsPositive ./ backgroundReceptors;
            modulationSpdSignedPositive = backgroundSpd+differenceSpdSignedPositive;
            
            differenceSpdSignedNegative = B_primary*(-differencePrimary);
            modulationSpdSignedNegative = backgroundSpd+differenceSpdSignedNegative;
            
            % Print out contrasts. This routine is in the Silent Substitution Toolbox.
            if (p.Results.verbose), ComputeAndReportContrastsFromSpds(sprintf('\n> Observer age: %g',observerAgeInYears),photoreceptorClasses,T_receptors,backgroundSpd,modulationSpdSignedPositive,[],[]); end;
            
            %% [DHB NOTE: MIGHT WANT TO SAVE THE VALUES HERE AND PHOTOPIC LUMINANCE TOO.]
            % Print out luminance info.  This routine is also in the Silent Substitution Toolbox
            if (p.Results.verbose), GetLuminanceAndTrolandsFromSpd(S, backgroundSpd, pupilDiameterMm, true); end
            
            if (strcmp(directionParams.type,'unipolar'))
                backgroundPrimary = modulationPrimarySignedNegative;
                backgroundSpd = modulationSpdSignedNegative;
            end
            clear modulationPrimarySignedNegative modulationSpdSignedNegative
            
            %% Assign all the cache fields
            %
            % Description
            cacheData.data(observerAgeInYears).describe.params = directionParams;
            cacheData.data(observerAgeInYears).describe.B_primary = B_primary;
            cacheData.data(observerAgeInYears).describe.ambientSpd = ambientSpd;
            cacheData.data(observerAgeInYears).describe.photoreceptors = photoreceptorClasses;
            cacheData.data(observerAgeInYears).describe.lambdaMaxShift = lambdaMaxShift;
            cacheData.data(observerAgeInYears).describe.fractionBleached = fractionBleached;
            cacheData.data(observerAgeInYears).describe.S = S;
            cacheData.data(observerAgeInYears).describe.T_receptors = T_receptors;
            cacheData.data(observerAgeInYears).describe.S_receptors = S;
            cacheData.data(observerAgeInYears).describe.contrast = isolateContrastsSignedPositive;
            cacheData.data(observerAgeInYears).describe.contrastSignedPositive = isolateContrastsSignedPositive;
            
            % Background
            cacheData.data(observerAgeInYears).backgroundPrimary = backgroundPrimary;
            cacheData.data(observerAgeInYears).backgroundSpd = backgroundSpd;
            
            % Modulation (positive)
            cacheData.data(observerAgeInYears).modulationPrimarySignedPositive = modulationPrimarySignedPositive;
            cacheData.data(observerAgeInYears).modulationSpdSignedPositive = modulationSpdSignedPositive;
        end
        
    case 'lightfluxchrom'
        % A light flux pulse or modulation, computed given background.
        % 
        % Note: This has access to useAmbient and primaryHeadRoom parameters but does
        % not currently use them. That is because this counts on the background having
        % been set up to accommodate the desired modulation.
        
        % Grab the background from the cache file
        backgroundCacheFile = ['Background_' directionParams.backgroundName '.mat'];
        [backgroundCacheData,isStale] = backgroundOlCache.load(backgroundCacheFile);
        assert(~isStale,'Background cache file is stale, aborting.');
        backgroundPrimary = backgroundCacheData.data(directionParams.backgroundObserverAge).backgroundPrimary;
        backgroundSpd = OLPrimaryToSpd(cal, backgroundPrimary);
        
        % Check that the universe is consistent
        if (~strcmp(backgroundCacheData.params.type,'lightfluxchrom'))
            error('Background type is not lightfluxchrom');
        end
        if (~all(backgroundCacheData.params.lightFluxDesiredXY == directionParams.lightFluxDesiredXY))
            error('Background and direction chromaticities not the same');
        end
        if (backgroundCacheData.params.lightFluxDownFactor ~= directionParams.lightFluxDownFactor)
            error('Background and direction lightFluxDownFactors not the same');
        end

        % Modulation.  This is the background scaled up by the factor that the background
        % was originally scaled down by.
        modulationPrimarySignedPositive = backgroundPrimary*directionParams.lightFluxDownFactor;
        modulationSpdSignedPositive = OLPrimaryToSpd(cal, modulationPrimarySignedPositive);
        
        % Check gamut
        if (any(modulationPrimarySignedPositive > 1) | any(modulationPrimarySignedPositive < 0))
            error('Out of gamut error for the modulation');
        end
        
        % Replace the values
        for observerAgeInYrs = 20:60
            cacheData.data(observerAgeInYrs).backgroundPrimary = backgroundPrimary;
            cacheData.data(observerAgeInYrs).backgroundSpd = backgroundSpd;
            cacheData.data(observerAgeInYrs).modulationPrimarySignedPositive = modulationPrimarySignedPositive;
            cacheData.data(observerAgeInYrs).modulationSpdSignedPositive = modulationSpdSignedPositive;
            cacheData.data(observerAgeInYrs).describe.params = directionParams;
        end

    otherwise
        error('Unknown direction type specified');
end

%% Tuck in the calibration structure for return
cacheData.cal = cal;
cacheData.directionParams = directionParams;
wasRecomputed = true;


end
