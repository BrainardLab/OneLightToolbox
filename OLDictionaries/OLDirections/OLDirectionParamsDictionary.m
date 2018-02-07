function dictionary = OLDirectionParamsDictionary()
% Defines a dictionary with parameters for named nominal directions
%
% Syntax:
%   dictionary = OLDirectionParamsDictionary()
%
% Description:
%    Define a dictionary of named directions of modulation, with
%    corresponding nominal parameters. Types of directions, and their
%    corresponding fields, are defined in OLDirectionParamsDefaults,
%    and validated by OLDirectionParamsValidate.
%
% Inputs:
%    None.
%
% Outputs:
%    dictionary - dictionary with all parameters for all desired directions
%
% Optional key/value pairs:
%    None.
%
% Notes:
%    * When you add a new type, you need to add that type to the
%      corresponding switch statement in OLDirectionParamsDefaults,
%      OLDirectionParamsValidate, and 
%      OLCheckCacheParamsAgainstCurrentParams.
%
% See also: 
%    OLDirectionParamsDefaults, OLDirectionParamsValidate,
%
%    OLMakeDirectionNominalPrimaries, 
%    OLBackgroundParamsDictionary, OLMakeBackgroundNominalPrimaries,
%
%    OLCheckCacheParamsAgainstCurrentParams

% History:
%    06/22/17  npc  Wrote it. 06/28/18  dhb  backgroundType ->
%                   backgroundName. Use names of routine that creates
%                   backgrounds.
%              dhb  Add name field. 
%              dhb  Explicitly set contrasts in each case, rather than rely
%                   on defaults. 
%              dhb  Bring in params.photoreceptorClasses.  These go with
%                   directions/backgrounds. 
%              dhb  Bring in params.useAmbient. This goes with directions/
%                   backgrounds.
%    07/05/17  dhb  Bringing up to speed. :
%    07/19/17  npc  Added a type for each background. For now, there is 
%                   only one type: 'pulse'. Defaults and checking are done 
%                   according to type. params.photoreceptorClasses is now a
%                   cell array
%    07/22/17  dhb  No more modulationDirection field. 
%    07/23/17  dhb  Comment field meanings. 
%    07/27/17  dhb  Light flux entry 
%    01/24/18  dhb,jv  Finished adding support for modulations
%              jv   Renamed direction types: pulse is now unipolar,
%                   modulation is now bipolar
%	 01/25/18  jv	Extract defaults generation, validation of params.

% Initialize dictionary
dictionary = containers.Map();

%% MaxMel_unipolar_275_80_667
% Direction for maximum unipolar contrast melanopsin step
%   Field size: 27.5 deg
%   Pupil diameter: 8 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% 
% unipolar contrast step up relative to the background.
baseName = 'MaxMel';
type = 'unipolar';

params = OLDirectionParamsDefaults(type);
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
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxMel_bipolar_275_80_667
% Direction for maximum bipolar contrast melanopsin modulation
%   Field size: 27.5 deg
%   Pupil diameter: 8 mm
%   Bipolar contrast: 66.7%
baseName = 'MaxMel';
type = 'bipolar';

params = OLDirectionParamsDefaults(type);
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
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxMel_unipolar_275_60_667
% Direction for maximum unipolar contrast melanopsin step
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm -- for use with 6 mm artificial pupil as part of
%   pupillometry
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
baseName = 'MaxMel';
type = 'unipolar';

params = OLDirectionParamsDefaults(type);
params.primaryHeadRoom = 0.01;
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
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxMel_unipolar_600_80_667
% Direction for maximum unipolar contrast melanopsin step
%   Field size: 60.0 deg
%   Pupil diameter: 8 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
baseName = 'MaxMel';
type = 'unipolar';

params = OLDirectionParamsDefaults(type);
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
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxLMS_unipolar_275_80_667
% Direction for maximum unipolar contrast LMS step
%   Field size: 27.5 deg
%   Pupil diameter: 8 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
baseName = 'MaxLMS';
type = 'unipolar';

params = OLDirectionParamsDefaults(type);
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
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxLMS_unipolar_275_60_667
% Direction for maximum unipolar contrast LMS step
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm -- for use with 6 mm artificial pupil with
%   pupillometry
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
baseName = 'MaxLMS';
type = 'unipolar';

params = OLDirectionParamsDefaults(type);
params.primaryHeadRoom = 0.01;
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
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxLMS_unipolar_600_80_667
% Direction for maximum unipolar contrast LMS step
%   Field size: 60.0 deg
%   Pupil diameter: 8 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
baseName = 'MaxLMS';
type = 'unipolar';

params = OLDirectionParamsDefaults(type);
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
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxMel_unipolar_275_60_667
% Direction for maximum unipolar contrast melanopsin step
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
baseName = 'MaxMel';
type = 'unipolar';

params = OLDirectionParamsDefaults(type);
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
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxLMS_unipolar_275_60_667
% Direction for maximum unipolar contrast LMS step
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
baseName = 'MaxLMS';
type = 'unipolar';

params = OLDirectionParamsDefaults(type);
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
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% LightFlux_540_380_50
% Direction for maximum light flux step
%   CIE x = .54, y = .38
%   Flux factor = 5

baseName = 'LightFlux';
type = 'lightfluxchrom';

params = OLDirectionParamsDefaults(type);
params.lightFluxDesiredXY = [0.54,0.38];
params.lightFluxDownFactor = 5;
params.name = OLMakeApproachDirectionName(baseName,params);
params.backgroundType = 'lightfluxchrom';
params.backgroundName = OLMakeApproachDirectionBackgroundName('LightFlux',params);
params.cacheFile = ['Direction_' params.name '.mat'];
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% LightFlux_330_330_20
% Direction for maximum light flux step
%   CIE x = .33, y = .33
%   Flux factor = 2

baseName = 'LightFlux';
type = 'lightfluxchrom';

params = OLDirectionParamsDefaults(type);
params.lightFluxDesiredXY = [0.33,0.33];
params.lightFluxDownFactor = 2;
params.name = OLMakeApproachDirectionName(baseName,params);
params.backgroundType = 'lightfluxchrom';
params.backgroundName = OLMakeApproachDirectionBackgroundName('LightFlux',params);
params.cacheFile = ['Direction_' params.name '.mat'];
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end
end

function backgroundName = OLMakeApproachDirectionBackgroundName(name,params)
% Figure out the name of the background to be used for a direction
%
% Syntax:
%   backgroundName = OLMakeApproachDirectionBackgroundName(name,params)
% 
% Description:
%   Local function so that we can make the background file name from the
%   backgroundType filed in the direction parameters structure.  A little
%   ugly, but probably sufficiently localized that it is OK.
%
% Inputs:
%    name           - Name of the direction
%    params         - Parameters of the direction, as tehy will be 
%                     specified in the dictionary.
%
% Outputs:
%    backgroundName - string with the name of the background to be used for
%                     the given direction
%
% Optional key/value pairs:
%    None.
%
% See also:
%    OLBackgroundParamsDictionary, 
params.type = params.backgroundType;
backgroundName = OLMakeApproachBackgroundName(name,params);
end