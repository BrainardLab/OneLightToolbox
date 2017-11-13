% OLDirectionNominalParamsDictionary
%
% Description:
%     Generate dictionary with params for the examined modulation directions.  The fields
%     are explained at the end of this routine, where default values are assigned.
%
%     This routine does its best to check that all and only needed fields are present in
%     the dictionary structures.
%
% Note:
%     When you add a new type, you need to add that type to the corresponding switch statment
%     in OLCheckCacheParamsAgainstCurrentParams.
%
% See also: OLCheckCacheParamsAgainstCurrentParams.

% 6/22/17  npc  Wrote it.
% 6/28/18  dhb  backgroundType -> backgroundName. Use names of routine that creates backgrounds.
%          dhb  Add name field.
%          dhb  Explicitly set contrasts in each case, rather than rely on defaults.
%          dhb  Bring in params.photoreceptorClasses.  These go with directions/backgrounds.
%          dhb  Bring in params.useAmbient.  This goes with directions/backgrounds.
% 7/5/17   dhb  Bringing up to speed.
% 7/19/17  npc  Added a type for each background. For now, there is only one type: 'pulse'. 
%               Defaults and checking are done according to type. params.photoreceptorClasses is now a cell array
% 7/22/17  dhb  No more modulationDirection field.
% 7/23/17  dhb  Comment field meanings.
% 7/27/17  dhb  Light flux entry
% 11/10/17 dhb, jv  Add field for receptor generator type.
% 11/10/17 jv   Abstracted-out generation of defaults and validation of params

function d = OLDirectionNominalParamsDictionary()

% Initialize dictionary
d = containers.Map();

%% MaxMel_275_80_667
%
% Direction for maximum contrast melanopsin pulse
%   Field size: 27.5 deg
%   Pupil diameter: 8 mm
%   Modulation contrast: 66.7%
%
% Modulation contrast is used to generate, but the result is a 400%
% contrast step up relative to the background.
baseName = 'MaxMel';
type = 'pulse';

params = OLDirectionNominalDictionaryDefaults(type);
params.primaryHeadRoom = 0.01;
params.baseModulationContrast = 4/6;
params.pupilDiameterMm = 8.0;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = [params.baseModulationContrast];
params.whichReceptorsToIsolate = [4];
params.whichReceptorsToIgnore = [];
params.whichReceptorsToMinimize = [];
params.backgroundType = 'optimized';
params.backgroundName = OLMakeApproachDirectionBackgroundName('MelanopsinDirected',params);
params.name = OLMakeApproachDirectionName(baseName,params);
params.cacheFile = ['Direction_' params.name '.mat'];
if OLDirectionNominalDictionaryValidate(params)
    % All validations OK. Add entry to the dictionary.
    d(params.name) = params;
end

%% MaxMel_600_80_667
%
% Direction for maximum contrast melanopsin pulse
%   Field size: 60.0 deg
%   Pupil diameter: 8 mm
%   Modulation contrast: 66.7%
%
% Modulation contrast is used to generate, but the result is a 400%
% contrast step up relative to the background.
baseName = 'MaxMel';
type = 'pulse';

params = OLDirectionNominalDictionaryDefaults(type);
params.primaryHeadRoom = 0.01;
params.baseModulationContrast = 4/6;
params.fieldSizeDegrees = 60.0;
params.pupilDiameterMm = 8.0;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = [params.baseModulationContrast];
params.whichReceptorsToIsolate = [4];
params.whichReceptorsToIgnore = [];
params.whichReceptorsToMinimize = [];
params.backgroundType = 'optimized';
params.backgroundName = OLMakeApproachDirectionBackgroundName('MelanopsinDirected',params);
params.name = OLMakeApproachDirectionName(baseName,params);
params.cacheFile = ['Direction_' params.name '.mat'];
if OLDirectionNominalDictionaryValidate(params)
    % All validations OK. Add entry to the dictionary.
    d(params.name) = params;
end

%% MaxLMS_275_80_667
%
% Direction for maximum contrast LMS pulse
%   Field size: 27.5 deg
%   Pupil diameter: 8 mm
%   Modulation contrast: 66.7%
%
% Modulation contrast is used to generate, but the result is a 400%
% contrast step up relative to the background.
baseName = 'MaxLMS';
type = 'pulse';

params = OLDirectionNominalDictionaryDefaults(type);
params.primaryHeadRoom = 0.01;
params.baseModulationContrast = 4/6;
params.pupilDiameterMm = 8.0;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = [params.baseModulationContrast params.baseModulationContrast params.baseModulationContrast];
params.whichReceptorsToIsolate = [1 2 3];
params.whichReceptorsToIgnore = [];
params.whichReceptorsToMinimize = [];
params.backgroundType = 'optimized';
params.backgroundName = OLMakeApproachDirectionBackgroundName('LMSDirected',params);
params.name = OLMakeApproachDirectionName(baseName,params);
params.cacheFile = ['Direction_' params.name '.mat'];
if OLDirectionNominalDictionaryValidate(params)
    % All validations OK. Add entry to the dictionary.
    d(params.name) = params;
end

%% MaxLMS_600_80_667
%
% Direction for maximum contrast LMS pulse
%   Field size: 60.0 deg
%   Pupil diameter: 8 mm
%   Modulation contrast: 66.7%
%
% Modulation contrast is used to generate, but the result is a 400%
% contrast step up relative to the background.
baseName = 'MaxLMS';
type = 'pulse';

params = OLDirectionNominalDictionaryDefaults(type);
params.primaryHeadRoom = 0.01;
params.baseModulationContrast = 4/6;
params.fieldSizeDegrees = 60.0;
params.pupilDiameterMm = 8.0;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = [params.baseModulationContrast params.baseModulationContrast params.baseModulationContrast];
params.whichReceptorsToIsolate = [1 2 3];
params.whichReceptorsToIgnore = [];
params.whichReceptorsToMinimize = [];
params.backgroundType = 'optimized';
params.backgroundName = OLMakeApproachDirectionBackgroundName('LMSDirected',params);
params.name = OLMakeApproachDirectionName(baseName,params);
params.cacheFile = ['Direction_' params.name '.mat'];
if OLDirectionNominalDictionaryValidate(params)
    % All validations OK. Add entry to the dictionary.
    d(params.name) = params;
end
%% MaxMel_275_60_667
%
% Direction for maximum contrast melanopsin pulse
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm
%   Modulation contrast: 66.7%
%
% Modulation contrast is used to generate, but the result is a 400%
% contrast step up relative to the background.
baseName = 'MaxMel';
type = 'pulse';

params = OLDirectionNominalDictionaryDefaults(type);
params.primaryHeadRoom = 0.005;
params.baseModulationContrast = 4/6;
params.pupilDiameterMm = 6.0;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = [params.baseModulationContrast];
params.whichReceptorsToIsolate = [4];
params.whichReceptorsToIgnore = [];
params.whichReceptorsToMinimize = [];
params.backgroundType = 'optimized';
params.backgroundName = OLMakeApproachDirectionBackgroundName('MelanopsinDirected',params);
params.name = OLMakeApproachDirectionName(baseName,params);
params.cacheFile = ['Direction_' params.name '.mat'];
if OLDirectionNominalDictionaryValidate(params)
    % All validations OK. Add entry to the dictionary.
    d(params.name) = params;
end

%% MaxLMS_275_60_667
%
% Direction for maximum contrast LMS pulse
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm
%   Modulation contrast: 66.7%
%
% Modulation contrast is used to generate, but the result is a 400%
% contrast step up relative to the background.
baseName = 'MaxLMS';
type = 'pulse';

params = OLDirectionNominalDictionaryDefaults(type);
params.primaryHeadRoom = 0.005;
params.baseModulationContrast = 4/6;
params.pupilDiameterMm = 6.0;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = [params.baseModulationContrast params.baseModulationContrast params.baseModulationContrast];
params.whichReceptorsToIsolate = [1 2 3];
params.whichReceptorsToIgnore = [];
params.whichReceptorsToMinimize = [];
params.backgroundType = 'optimized';
params.backgroundName = OLMakeApproachDirectionBackgroundName('LMSDirected',params);
params.name = OLMakeApproachDirectionName(baseName,params);
params.cacheFile = ['Direction_' params.name '.mat'];
if OLDirectionNominalDictionaryValidate(params)
    % All validations OK. Add entry to the dictionary.
    d(params.name) = params;
end

%% LightFlux_540_380_50
baseName = 'LightFlux';
type = 'lightfluxchrom';

params = OLDirectionNominalDictionaryDefaults(type);
params.lightFluxDesiredXY = [0.54,0.38];
params.lightFluxDownFactor = 5;
params.name = OLMakeApproachDirectionName(baseName,params);
params.backgroundType = 'lightfluxchrom';
params.backgroundName = OLMakeApproachDirectionBackgroundName('LightFlux',params);
params.cacheFile = ['Direction_' params.name '.mat'];
if OLDirectionNominalDictionaryValidate(params)
    % All validations OK. Add entry to the dictionary.
    d(params.name) = params;
end

%% LightFlux_330_330_20
baseName = 'LightFlux';
type = 'lightfluxchrom';

params = OLDirectionNominalDictionaryDefaults(type);
params.lightFluxDesiredXY = [0.33,0.33];
params.lightFluxDownFactor = 2;
params.name = OLMakeApproachDirectionName(baseName,params);
params.backgroundType = 'lightfluxchrom';
params.backgroundName = OLMakeApproachDirectionBackgroundName('LightFlux',params);
params.cacheFile = ['Direction_' params.name '.mat'];
if OLDirectionNominalDictionaryValidate(params)
    % All validations OK. Add entry to the dictionary.
    d(params.name) = params;
end
end



% OLMakeApproachDirectionBackgroundName
% 
% Description:
%     Local function so that we can make the background file name from the
%     backgroundType filed in the direction parameters structure.  A little ugly,
%     but probably sufficiently localized that it is OK.
function theName = OLMakeApproachDirectionBackgroundName(name,params)
params.type = params.backgroundType;
theName = OLMakeApproachBackgroundName(name,params);
end