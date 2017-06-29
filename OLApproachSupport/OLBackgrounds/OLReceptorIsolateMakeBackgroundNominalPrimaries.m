function [cacheData, olCache] = OLReceptorIsolateMakeBackgroundNominalPrimaries(approach,params, forceRecompute)
% OLReceptorIsolateMakeBackgroundNominalPrimaries - Finds backgrounds according to background parameters.
%
% Syntax:
%   OLReceptorIsolateMakeBackgroundNominalPrimaries(params, forceRecompute)
%
% Input:
%   approach (string)          Name of whatever approach is invoking this.
%
%   backgroundParams (struct)  Parameters struct for backgrounds.  See
%                              BackgroundNominalParamsDictionary.
%
%   forceRecompute (logical)   If true, forces a recompute of the data found in the config file. 
%                              Default: false
% Output:
%   cacheData (struct)         Cache data structure.  Contains background
%                              primaries and cal structure.
%
%   olCache (class)            Cache object for storing this.

% 4/19/13   dhb, ms     Update for new convention for desired contrasts in routine ReceptorIsolate.
% 2/25/14   ms          Modularized.
% 6/29/17   dhb         Cleaning up.

%% Setup the directories we'll use. Backgrounds go in their special place under the materials path approach directory.
cacheDir = fullfile(getpref(approach, 'MaterialsPath'), 'Experiments',approach,'BackgroundNominalPrimaries');
if ~isdir(cacheDir)
    mkdir(cacheDir);
end

%% Load the calibration file.
cal = LoadCalFile(OLCalibrationTypes.(params.calibrationType).CalFileName, [], fullfile(getpref(approach, 'MaterialsPath'), 'Experiments',approach,'OneLightCalData'));
assert(~isempty(cal), 'OLFlickerComputeModulationSpectra:NoCalFile', 'Could not load calibration file: %s', ...
    OLCalibrationTypes.(params.calibrationType).CalFileName);
calID = OLGetCalID(cal);

%% Pull out S
S = cal.describe.S;

%% Create the cache object.
olCache = OLCache(cacheDir, cal);

%% Create the cache file name.
[~, cacheFileName] = fileparts(params.cacheFile);

%% Need to check here whether we can just use the current cached data and do so if possible.

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
        
    case 'optimized'  
        % These backgrounds get optimized according to the parameters in
        % the structure.  Backgrounds are optimized with respect to a 32
        % year old observer, and no correction for photopigment bleaching
        % is applied.  We are just trying to get pretty good backgrounds,
        % so we don't need to fuss with small effects.
        
        %% Parse some of the parameter fields
        photoreceptorClasses = allwords(params.photoreceptorClasses, ',');
        
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
        
        % Assign an empty 'ambientSpd' variable so that the ReceptorIsolate
        % code still works. As of Sep 2013 (i.e. SSMRI), we include the ambient measurements
        % in the optimization. This is defined in a flag in the stimulus .cfg
        % files.
        if params.useAmbient
            ambientSpd = cal.computed.pr650MeanDark;
        else
            ambientSpd = zeros(size(B_primary,1),1);
        end
        
        % We get backgrounds for on nominal observer age, and hope for the
        % best for other observer ages.
        observerAgeInYears = 32;
        
        %% Initial background
        %
        % Start at mid point of primaries.
        backgroundPrimary = 0.5*ones(size(B_primary,2),1);
        
        %% Construct the receptor matrix
        fractionBleached = zeros(length(params.photoreceptorClasses));
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
% Fill in for all observer ages based on the nominal calculation.
for observerAgeInYears = 20:60
    cacheData.data(observerAgeInYears).backgroundPrimary = backgroundPrimary;
end
cacheData.cal = cal;

end