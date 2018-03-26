function dictionary = OLBackgroundParamsDictionary()
% Defines a dictionary with parameters for named nominal backgrounds
%
% Syntax:
%   dictionary = OLBackgroundParamsDictionary()
%
% Description:
%    Define a dictionary of named backgrounds of modulation, with
%    corresponding nominal parameters. Types of backgrounds, and their
%    corresponding fields, are defined in OLBackgroundParamsDefaults
%    and validated by OLBackgroundParamsValidate.
%
% Inputs:
%    None.
%
% Outputs:
%    dictionary - dictionary with all parameters for all desired
%                 backgrounds
%
% Optional key/value pairs:
%    None.
%
% Notes:
%    * When you add a new type, you need to add that type to the 
%      corresponding switch statement in 
%      OLCheckCacheParamsAgainstCurrentParams.
%    * TODO:
%          i) add type 'BackgroundHalfOn' - Primaries set to 0.5;
%          ii) add type 'BackgroundEES' - Background metameric to an equal 
%              energy spectrum, scaled in middle of gamut.
%
% See also: 
%    OLBackgroundParams, OLBackgroundNomimalPrimaryFromParams,
%    OLBackgroundNominalPrimaryFromName,
%
%    OLDirectionParamsDictionary, OLMakeDirectionNominalPrimaries,

% History:
%    06/28/17  dhb  Created from direction version.
%    06/28/18  dhb  backgroundType -> backgroundName. Use names of routine 
%                   that creates backgrounds.
%              dhb  Add name field.
%              dhb  Bring in params.photoreceptorClasses.  These go with 
%                   directions/backgrounds.
%              dhb  Bring in params.useAmbient.  This goes with directions/
%                   backgrounds.
%    06/29/18  dhb  More extended names to reflect key parameters, so that 
%                   protocols can check
%    07/19/17  npc  Added a type for each background. For now, there is 
%                   only one type: 'basic'. 
%                   Defaults and checking are done according to type. 
%                   params.photoreceptorClasses is now a cell array.
%    07/22/17  dhb  No more modulationDirection field.
%    01/25/18  jv   Extract default params generation, validation.
%    02/07/18  jv   Updated to use OLBackgroundParams objects
%    03/26/18  jv, dhb Fix type in modulationContrast field of
%                   LMSDirected_LMS_275_60_667.

% Initialize dictionary
dictionary = containers.Map();

%% MelanopsinDirected_275_80_667
% Background to allow maximum unipolar contrast melanopsin modulation
%   Field size: 27.5 deg
%   Pupil diameter: 8 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, this background is also used
% for a 400% unipolar pulse
params = OLBackgroundParams_Optimized;
params.baseName = 'MelanopsinDirected';
params.primaryHeadRoom = 0.01;
params.baseModulationContrast = 4/6;
params.fieldSizeDegrees = 27.5;
params.pupilDiameterMm = 8;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = 4/6;
params.whichReceptorsToIsolate = {[4]};
params.whichReceptorsToIgnore = {[]};
params.whichReceptorsToMinimize = {[]};
params.directionsYoked = [0];
params.directionsYokedAbs = [0];
params.name = OLBackgroundNameFromParams(params);
if OLBackgroundParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MelanopsinDirected_600_80_667
% Background to allow maximum unipolar contrast melanopsin modulations
%   Field size: 60.0 deg
%   Pupil diameter: 8 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, this background is also used
% for a 400% unipolar pulse
params = OLBackgroundParams_Optimized;
params.baseName = 'MelanopsinDirected';
params.baseModulationContrast = 4/6;
params.primaryHeadRoom = 0.01;
params.fieldSizeDegrees = 60;
params.pupilDiameterMm = 8;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = [4/6];
params.whichReceptorsToIsolate = {[4]};
params.whichReceptorsToIgnore = {[]};
params.whichReceptorsToMinimize = {[]};
params.directionsYoked = [0];
params.directionsYokedAbs = [0];
params.name = OLBackgroundNameFromParams(params);
if OLBackgroundParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% LMSDirected_LMS_275_80_667
% Background to allow maximum unipolar contrast LMS modulations
%   Field size: 27.5 deg
%   Pupil diameter: 8 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, this background is also used
% for a 400% unipolar pulse
params = OLBackgroundParams_Optimized;
params.baseName = 'LMSDirected';
params.baseModulationContrast = 4/6;
params.primaryHeadRoom = 0.005;
params.fieldSizeDegrees = 27.5;
params.pupilDiameterMm = 8;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = {[4/6 4/6 4/6]};
params.whichReceptorsToIsolate = {[1 2 3]};
params.whichReceptorsToIgnore = {[]};
params.whichReceptorsToMinimize = {[]};
params.directionsYoked = [1];
params.directionsYokedAbs = [0];
params.name = OLBackgroundNameFromParams(params);
if OLBackgroundParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% LMSDirected_LMS_600_80_667
% Background to allow maximum unipolar contrast LMS modulations
%   Field size: 60.0 deg
%   Pupil diameter: 8 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, this background is also used
% for a 400% unipolar pulse
params = OLBackgroundParams_Optimized;
params.baseName = 'LMSDirected';
params.baseModulationContrast = 4/6;
params.primaryHeadRoom = 0.005;
params.fieldSizeDegrees = 60;
params.pupilDiameterMm = 8;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = {[4/6 4/6 4/6]};
params.whichReceptorsToIsolate = {[1 2 3]};
params.whichReceptorsToIgnore = {[]};
params.whichReceptorsToMinimize = {[]};
params.directionsYoked = [1];
params.directionsYokedAbs = [0];
params.name = OLBackgroundNameFromParams(params);
if OLBackgroundParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MelanopsinDirected_275_60_667
% Background to allow maximum unipolar contrast melanopsin modulations
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, this background is also used
% for a 400% unipolar pulse
params = OLBackgroundParams_Optimized;
params.baseName = 'MelanopsinDirected';
params.baseModulationContrast = 4/6;
params.primaryHeadRoom = 0.01;
params.pupilDiameterMm = 6;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = [4/6];
params.whichReceptorsToIsolate = {[4]};
params.whichReceptorsToIgnore = {[]};
params.whichReceptorsToMinimize = {[]};
params.directionsYoked = [0];
params.directionsYokedAbs = [0];
params.name = OLBackgroundNameFromParams(params);
if OLBackgroundParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% LMSDirected_LMS_275_60_667
% Background to allow maximum unipolar contrast LMS modulations
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, this background is also used
% for a 400% unipolar pulse
params = OLBackgroundParams_Optimized;
params.baseName = 'LMSDirected';
params.baseModulationContrast = 4/6;
params.primaryHeadRoom = 0.005;
params.pupilDiameterMm = 6;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = {[4/6 4/6 4/6]};
params.whichReceptorsToIsolate = {[1 2 3]};
params.whichReceptorsToIgnore = {[]};
params.whichReceptorsToMinimize = {[]};
params.directionsYoked = [1];
params.directionsYokedAbs = [0];
params.name = OLBackgroundNameFromParams(params);
if OLBackgroundParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% LightFlux_540_380_50
% Background at xy = [0.54,0.38] that allows light flux pulses to increase
% a factor of 5 within gamut
params = OLBackgroundParams_LightFluxChrom;
params.baseName = 'LightFlux';
params.lightFluxDesiredXY = [0.54,0.38];
params.lightFluxDownFactor = 5;
params.name = OLBackgroundNameFromParams(params);
if OLBackgroundParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% LightFlux_330_330_20
% Background at xy = [0.33,0.33] that allows light flux pulses to increase 
% a factor of  2 within gamut
params = OLBackgroundParams_LightFluxChrom;
params.baseName = 'LightFlux';
params.lightFluxDesiredXY = [0.33,0.33];
params.lightFluxDownFactor = 2;
params.name = OLBackgroundNameFromParams(params);
if OLBackgroundParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end
end