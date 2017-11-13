%OLBackgroundNominalParamsDictionary
%
% Description:
%     Generate dictionary with params for backgrounds.   The fields
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

% 6/28/17  dhb  Created from direction version.
% 6/28/18  dhb  backgroundType -> backgroundName. Use names of routine that creates backgrounds.
%          dhb  Add name field.
%          dhb  Bring in params.photoreceptorClasses.  These go with directions/backgrounds.
%          dhb  Bring in params.useAmbient.  This goes with directions/backgrounds.
% 6/29/18  dhb  More extended names to reflect key parameters, so that protocols can check
% 7/19/17  npc  Added a type for each background. For now, there is only one type: 'basic'. 
%               Defaults and checking are done according to type. params.photoreceptorClasses is now a cell array.
% 7/22/17  dhb  No more modulationDirection field.

% NEED TO ADD THESE as type 'named'
%          'BackgroundHalfOn' - Primaries set to 0.5;
%          'BackgroundEES' - Background metameric to an equal energy spectrum, scaled in middle of gamut.

function d = OLBackgroundNominalParamsDictionary()
    % Initialize dictionary
    d = containers.Map();
    
    %% MelanopsinDirected_275_80_667
    %
    % Background to allow maximum melanopsin pulse contrast
    %   Field size: 27.5 deg
    %   Pupil diameter: 8 mm
    %   Modulation contrast: 66.7%
    % 
    % Note modulation contrast is typically 2/3 for 400% pulse contrast <=> 66.66% sinusoidal contrast
    baseName = 'MelanopsinDirected';
    type = 'optimized';
    
    params = OLBackgroundNominalDictionaryDefaults(type);
    params.baseModulationContrast = 4/6;
    params.primaryHeadRoom = 0.01;
    params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
    params.modulationContrast = [params.baseModulationContrast];
    params.whichReceptorsToIsolate = {[4]};
    params.whichReceptorsToIgnore = {[]};
    params.whichReceptorsToMinimize = {[]};
    params.directionsYoked = [0];
    params.directionsYokedAbs = [0];
    params.name = OLMakeApproachBackgroundName(baseName,params);
    params.cacheFile = ['Background_' params.name  '.mat'];
    if OLBackgroundNominalDictionaryValidate(params)
        % All validations OK. Add entry to the dictionary.
        d(params.name) = params;
    end
    
    %% MelanopsinDirected_600_80_667
    %
    % Background to allow maximum melanopsin pulse contrast
    %   Field size: 60.0 deg
    %   Pupil diameter: 8 mm
    %   Modulation contrast: 66.7%
    % 
    % Note modulation contrast is typically 2/3 for 400% pulse contrast <=> 66.66% sinusoidal contrast
    baseName = 'MelanopsinDirected';
    type = 'optimized';
    
    params = OLBackgroundNominalDictionaryDefaults(type);
    params.baseModulationContrast = 4/6;
    params.primaryHeadRoom = 0.01;
    params.fieldSizeDegrees = 60;
    params.pupilDiameterMm = 8;
    params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
    params.modulationContrast = [params.baseModulationContrast];
    params.whichReceptorsToIsolate = {[4]};
    params.whichReceptorsToIgnore = {[]};
    params.whichReceptorsToMinimize = {[]};
    params.directionsYoked = [0];
    params.directionsYokedAbs = [0];
    params.name = OLMakeApproachBackgroundName(baseName,params);
    params.cacheFile = ['Background_' params.name  '.mat'];
    if OLBackgroundNominalDictionaryValidate(params)
        % All validations OK. Add entry to the dictionary.
        d(params.name) = params;
    end
    
    %% LMSDirected_LMS_275_80_667
    % 
    % Background to allow maximum LMS pulse contrast
    %   Field size: 27,5 deg
    %   Pupil diameter: 8 mm
    %   Modulation contrast: 66.7%
    % 
    % Note modulation contrast is typically 2/3 for 400% pulse contrast <=> 66.66% sinusoidal contrast
    baseName = 'LMSDirected';
    type = 'optimized';
    
    params = OLBackgroundNominalDictionaryDefaults(type);
    params.baseModulationContrast = 4/6;
    params.primaryHeadRoom = 0.005;
    params.fieldSizeDegrees = 27.5; 
    params.pupilDiameterMm = 8;
    params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
    params.modulationContrast = {[params.baseModulationContrast params.baseModulationContrast params.baseModulationContrast]};
    params.whichReceptorsToIsolate = {[1 2 3]};
    params.whichReceptorsToIgnore = {[]};
    params.whichReceptorsToMinimize = {[]};
    params.directionsYoked = [1];
    params.directionsYokedAbs = [0];
    params.name = OLMakeApproachBackgroundName(baseName,params);
    params.cacheFile = ['Background_' params.name  '.mat'];
    if OLBackgroundNominalDictionaryValidate(params)
        % All validations OK. Add entry to the dictionary.
        d(params.name) = params;
    end
    
    %% LMSDirected_LMS_600_80_667
    % 
    % Background to allow maximum LMS pulse contrast
    %   Field size: 60 deg
    %   Pupil diameter: 8 mm
    %   Modulation contrast: 66.7%
    % 
    % Note modulation contrast is typically 2/3 for 400% pulse contrast <=> 66.66% sinusoidal contrast
    baseName = 'LMSDirected';
    type = 'optimized';
    
    params = OLBackgroundNominalDictionaryDefaults(type);
    params.baseModulationContrast = 4/6;
    params.primaryHeadRoom = 0.005;
    params.fieldSizeDegrees = 60; 
    params.pupilDiameterMm = 8;
    params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
    params.modulationContrast = {[params.baseModulationContrast params.baseModulationContrast params.baseModulationContrast]};
    params.whichReceptorsToIsolate = {[1 2 3]};
    params.whichReceptorsToIgnore = {[]};
    params.whichReceptorsToMinimize = {[]};
    params.directionsYoked = [1];
    params.directionsYokedAbs = [0];
    params.name = OLMakeApproachBackgroundName(baseName,params);
    params.cacheFile = ['Background_' params.name  '.mat'];
    if OLBackgroundNominalDictionaryValidate(params)
        % All validations OK. Add entry to the dictionary.
        d(params.name) = params;
    end
    
     %% MelanopsinDirected_275_60_667
    %
    % Background to allow maximum melanopsin pulse contrast
    %   Field size: 27.5 deg
    %   Pupil diameter: 6 mm
    %   Modulation contrast: 66.7%
    % 
    % Note modulation contrast is typically 2/3 for 400% pulse contrast <=> 66.66% sinusoidal contrast
    baseName = 'MelanopsinDirected';
    type = 'optimized';
    
    params = OLBackgroundNominalDictionaryDefaults(type);
    params.baseModulationContrast = 4/6;
    params.primaryHeadRoom = 0.01;
    params.pupilDiameterMm = 6;
    params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
    params.modulationContrast = [params.baseModulationContrast];
    params.whichReceptorsToIsolate = {[4]};
    params.whichReceptorsToIgnore = {[]};
    params.whichReceptorsToMinimize = {[]};
    params.directionsYoked = [0];
    params.directionsYokedAbs = [0];
    params.name = OLMakeApproachBackgroundName(baseName,params);
    params.cacheFile = ['Background_' params.name  '.mat'];
    if OLBackgroundNominalDictionaryValidate(params)
        % All validations OK. Add entry to the dictionary.
        d(params.name) = params;
    end
    
    %% LMSDirected_LMS_275_60_667
    % 
    % Background to allow maximum LMS pulse contrast
    %   Field size: 27.5 deg
    %   Pupil diameter: 6 mm
    %   Modulation contrast: 66.7%
    % 
    % Note modulation contrast is typically 2/3 for 400% pulse contrast <=> 66.66% sinusoidal contrast
    baseName = 'LMSDirected';
    type = 'optimized';
    
    params = OLBackgroundNominalDictionaryDefaults(type);
    params.baseModulationContrast = 4/6;
    params.primaryHeadRoom = 0.005;
    params.pupilDiameterMm = 6;
    params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
    params.modulationContrast = {[params.baseModulationContrast params.baseModulationContrast params.baseModulationContrast]};
    params.whichReceptorsToIsolate = {[1 2 3]};
    params.whichReceptorsToIgnore = {[]};
    params.whichReceptorsToMinimize = {[]};
    params.directionsYoked = [1];
    params.directionsYokedAbs = [0];
    params.name = OLMakeApproachBackgroundName(baseName,params);
    params.cacheFile = ['Background_' params.name  '.mat'];
    if OLBackgroundNominalDictionaryValidate(params)
        % All validations OK. Add entry to the dictionary.
        d(params.name) = params;
    end
    
    %% LightFlux_540_380_50
    %
    % Background at xy = [0.54,0.38] that allows light flux pulses to increase a factor of 5
    % within gamut
    baseName = 'LightFlux';
    type = 'lightfluxchrom';
    
    params = OLBackgroundNominalDictionaryDefaults(type);
    params.lightFluxDesiredXY = [0.54,0.38];
    params.lightFluxDownFactor = 5;
    params.name = OLMakeApproachBackgroundName(baseName,params); 
    params.cacheFile = ['Background_' params.name  '.mat'];
    if OLBackgroundNominalDictionaryValidate(params)
        % All validations OK. Add entry to the dictionary.
        d(params.name) = params;
    end
    
    %% LightFlux_330_330_20
    %
    % Background at xy = [0.33,0.33] that allows light flux pulses to increase a factor of  2
    % within gamut
    baseName = 'LightFlux';
    type = 'lightfluxchrom';
    
    params = OLBackgroundNominalDictionaryDefaults(type);
    params.lightFluxDesiredXY = [0.33,0.33];
    params.lightFluxDownFactor = 2;
    params.name = OLMakeApproachBackgroundName(baseName,params); 
    params.cacheFile = ['Background_' params.name  '.mat'];
    if OLBackgroundNominalDictionaryValidate(params)         
        % All validations OK. Add entry to the dictionary.
        d(params.name) = params;
    end
end