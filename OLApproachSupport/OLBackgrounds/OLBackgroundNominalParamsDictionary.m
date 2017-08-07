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
    
    params = defaultParams(type);
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
    d = paramsValidateAndAppendToDictionary(d, params);
    
    %% LMSDirected_LMS_275_80_667
    % 
    % Background to allow maximum LMS pulse contrast
    %   Field size: 27.5 deg
    %   Pupil diameter: 8 mm
    %   Modulation contrast: 66.7%
    % 
    % Note modulation contrast is typically 2/3 for 400% pulse contrast <=> 66.66% sinusoidal contrast
    baseName = 'LMSDirected';
    type = 'optimized';
    
    params = defaultParams(type);
    params.baseModulationContrast = 4/6;
    params.primaryHeadRoom = 0.005;
    params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
    params.modulationContrast = {[params.baseModulationContrast params.baseModulationContrast params.baseModulationContrast]};
    params.whichReceptorsToIsolate = {[1 2 3]};
    params.whichReceptorsToIgnore = {[]};
    params.whichReceptorsToMinimize = {[]};
    params.directionsYoked = [1];
    params.directionsYokedAbs = [0];
    params.name = OLMakeApproachBackgroundName(baseName,params);
    params.cacheFile = ['Background_' params.name  '.mat'];
    d = paramsValidateAndAppendToDictionary(d, params);
    
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
    
    params = defaultParams(type);
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
    d = paramsValidateAndAppendToDictionary(d, params);
    
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
    
    params = defaultParams(type);
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
    d = paramsValidateAndAppendToDictionary(d, params);
    
    %% LightFlux_54_38_5.0
    %
    % Background at xy = [0.54,0.38] that allows light flux pulses to increase a factor of 5
    % within gamut
    baseName = 'LightFlux';
    type = 'lightfluxchrom';
    
    params = defaultParams(type);
    params.lightFluxDesiredXY = [0.54,0.38];
    params.lightFluxDownFactor = 5;
    params.name = OLMakeApproachBackgroundName(baseName,params); 
    params.cacheFile = ['Background_' params.name  '.mat'];
    d = paramsValidateAndAppendToDictionary(d, params);
    
    %% LightFlux_33_33_2.0
    %
    % Background at xy = [0.54,0.38] that allows light flux pulses to increase a factor of 5
    % within gamut
    baseName = 'LightFlux';
    type = 'lightfluxchrom';
    
    params = defaultParams(type);
    params.lightFluxDesiredXY = [0.33,0.33];
    params.lightFluxDownFactor = 2;
    params.name = OLMakeApproachBackgroundName(baseName,params); 
    params.cacheFile = ['Background_' params.name  '.mat'];
    d = paramsValidateAndAppendToDictionary(d, params);
end

function d = paramsValidateAndAppendToDictionary(d, params)

% Get all the expected field names for this type
allFieldNames = fieldnames(defaultParams(params.type));

% Test that there are no extra params
if (~all(ismember(fieldnames(params), allFieldNames)))
    fprintf(2,'\nParams struct contain extra params\n');
    fNames = fieldnames(params);
    idx = ismember(fieldnames(params), allFieldNames);
    idx = find(idx == 0);
    for k = 1:numel(idx)
        fprintf(2,'- ''%s'' \n', fNames{idx(k)});
    end
    error('Remove extra params or update defaultParams\n');
end

% Test that all expected params exist and that they have the expected type
switch (params.type)
    case 'optimized'
        % Test that all expected params exist and that they have the expected type
        assert((isfield(params, 'dictionaryType')             && ischar(params.dictionaryType)),            sprintf('params.dictionaryType does not exist or it does not contain a string value.'));
        assert((isfield(params, 'type')                       && ischar(params.type)),                      sprintf('params.type does not exist or it does not contain a string value.'));
        assert((isfield(params, 'name')                       && ischar(params.name)),                      sprintf('params.name does not exist or it does not contain a string value.'));
        assert((isfield(params, 'baseModulationContrast')     && isnumeric(params.baseModulationContrast)), sprintf('params.baseModulationContrast does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'primaryHeadRoom')            && isnumeric(params.primaryHeadRoom)),        sprintf('params.primaryHeadRoom does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'pegBackground')              && islogical(params.pegBackground)),          sprintf('params.pegBackground does not exist or it does not contain a boolean value.'));
        assert((isfield(params, 'photoreceptorClasses')       && iscell(params.photoreceptorClasses)),      sprintf('params.photoreceptorClasses does not exist or it does not contain a cell value.'));
        assert((isfield(params, 'fieldSizeDegrees')           && isnumeric(params.fieldSizeDegrees)),       sprintf('params.ieldSizeDegrees does not exist or it does not contain a number.'));
        assert((isfield(params, 'pupilDiameterMm')            && isnumeric(params.pupilDiameterMm)),        sprintf('params.pupilDiameterMm does not exist or it does not contain a number.'));
        assert((isfield(params, 'backgroundObserverAge')      && isnumeric(params.pupilDiameterMm)),        sprintf('params.backgroundObserverAge does not exist or it does not contain a number.'));
        assert((isfield(params, 'maxPowerDiff')               && isnumeric(params.maxPowerDiff)),           sprintf('params.maxPowerDiff does not exist or it does not contain a number.'));
        assert((isfield(params, 'modulationContrast')         && (isnumeric(params.modulationContrast) || iscell(params.whichReceptorsToIsolate))),         sprintf('params.modulationContrast does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'whichReceptorsToIsolate')    && (isnumeric(params.whichReceptorsToIsolate) || iscell(params.whichReceptorsToIsolate))),    sprintf('params.whichReceptorsToIsolate does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'whichReceptorsToIgnore')     && (isnumeric(params.whichReceptorsToIgnore) || iscell(params.whichReceptorsToIgnore))),      sprintf('params.whichReceptorsToIgnore does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'whichReceptorsToMinimize')   && (isnumeric(params.whichReceptorsToMinimize) || iscell(params.whichReceptorsToMinimize))),  sprintf('params.whichReceptorsToMinimize does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'directionsYoked')            && isnumeric(params.directionsYoked)),        sprintf('params.directionsYoked does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'directionsYokedAbs')         && isnumeric(params.directionsYokedAbs)),     sprintf('params.directionsYokedAbs does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'useAmbient')                 && islogical(params.useAmbient)),             sprintf('params.useAmbient does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'cacheFile')                  && ischar(params.cacheFile)),                 sprintf('params.cacheFile does not exist or it does not contain a string value.'));
        
    case 'lightfluxchrom'
        assert((isfield(params, 'dictionaryType')             && ischar(params.dictionaryType)),            sprintf('params.dictionaryType does not exist or it does not contain a string value.'));
        assert((isfield(params, 'type')                       && ischar(params.type)),                      sprintf('params.type does not exist or it does not contain a string value.'));
        assert((isfield(params, 'name')                       && ischar(params.name)),                      sprintf('params.name does not exist or it does not contain a string value.'));
        assert((isfield(params, 'primaryHeadRoom')            && isnumeric(params.primaryHeadRoom)),        sprintf('params.primaryHeadRoom does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'lightFluxDesiredXY')         && isnumeric(params.lightFluxDesiredXY)),     sprintf('params.lightFluxDesiredXY does not exit or it does not contain numeric values.'));
        assert((isfield(params, 'lightFluxDownFactor')        && isnumeric(params.lightFluxDownFactor)),    sprintf('params.lightFluxDownFactor does not exit or it is not numeric.'));
        assert((isfield(params, 'useAmbient')                 && islogical(params.useAmbient)),             sprintf('params.useAmbient does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'cacheFile')                  && ischar(params.cacheFile)),                 sprintf('params.cacheFile does not exist or it does not contain a string value.'));
    otherwise
        error('Unknown background type: ''%s''.\n', type)
end % switch

% All validations OK. Add entry to the dictionary.
d(params.name) = params;
end

function params = defaultParams(type)
params = struct();
params.type = type;
params.name = '';

switch (type)
    % Background is optimized to allow a maximal modulation.
    case 'optimized'
        params.dictionaryType = 'Background';                                     % What type of dictionary is this?
        params.pegBackground = false;                                             % Passed to the routine that optimizes backgrounds.         
        params.baseModulationContrast = 4/6;                                      % How much symmetric modulation contrast do we want to enable?  Used to generate background name.
        params.primaryHeadRoom = 0.01;                                            % How close to edge of [0-1] primary gamut do we want to get?
        params.photoreceptorClasses = ...                                         % Names of photoreceptor classes being considered.
            {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
        params.fieldSizeDegrees = 27.5;                                           % Field size used in background seeking. Affects fundamentals.
        params.pupilDiameterMm = 8.0;                                             % Pupil diameter used in background seeking. Affects fundamentals.
        params.backgroundObserverAge = 32;                                        % Observer age used in background seeking. Affects fundamentals.
        params.maxPowerDiff = 0.1;                                                % Smoothing parameter for routine that finds backgrounds.
        params.modulationContrast = [params.baseModulationContrast];              % Vector of constrasts sought in isolation.
        params.whichReceptorsToIsolate = {[4]};                                   % Which receptor classes are not being silenced.
        params.whichReceptorsToIgnore = {[]};                                     % Receptor classes ignored in calculations.
        params.whichReceptorsToMinimize = {[]};                                   % These receptors are minimized in contrast, subject to other constraints.
        params.directionsYoked = [0];                                             % See ReceptorIsolate.
        params.directionsYokedAbs = [0];                                          % See ReceptorIsolate.
        params.useAmbient = true;                                                 % Use measured ambient in calculations if true. If false, set ambient to zero.
        params.cacheFile = '';                                                    % Place holder, modulation name and type-specific . Just declaring the field here.
        
    case 'lightfluxchrom'
        params.dictionaryType = 'Background';                                     % What type of dictionary is this?
        params.primaryHeadRoom = 0.01;                                            % How close to edge of [0-1] primary gamut do we want to get? (Check if actually used someday.) 
        params.lightFluxDesiredXY = [0.54 0.38];                                  % Background chromaticity.
        params.lightFluxDownFactor = 5;                                           % Factor to decrease background after initial values found.  Determines how big a pulse we can put on it.
        params.useAmbient = true;                                                 % Use measured ambient in calculations if true. If false, set ambient to zero.
        params.cacheFile = '';                                                    % Place holder, modulation name and type-specific . Just declaring the field here.

    otherwise
        error('Unknown background type specified: ''%s''.\n', type)
end % switch
end

