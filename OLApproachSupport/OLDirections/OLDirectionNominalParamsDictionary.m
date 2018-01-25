function dictionary = OLDirectionNominalParamsDictionary()
% Populates dictionary with parameters for nominal direction primary values
%
% Syntax:
%   dictionary = OLDirectionNominalParamsDictionary()
%
% Description:
%    Generate dictionary with parameters for the desired modulation
%    directions.  The fields are explained at the end of this routine,
%    where default values are assigned.
%
%    This routine does its best to check that all and only needed fields
%    are present in the dictionary structures.
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
%      corresponding switch statement in
%      OLCheckCacheParamsAgainstCurrentParams.
%
% See also: 
%    OLMakeDirectionNominalPrimaries, OLBackgroundNominalParamsDictionary, 
%    OLMakeBackgroundNominalPrimaries, 
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

% Initialize dictionary
dictionary = containers.Map();

%% MaxMel_275_80_667
% Direction for maximum unipolar contrast melanopsin pulse
%   Field size: 27.5 deg
%   Pupil diameter: 8 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% 
% unipolar contrast step up relative to the background.
baseName = 'MaxMel';
type = 'unipolar';

params = defaultParams(type);
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
dictionary = paramsValidateAndAppendToDictionary(dictionary, params);

%% MaxMel_275_80_667_modulation
% Direction for maximum contrast melanopsin pulse
%   Field size: 27.5 deg
%   Pupil diameter: 8 mm
%   Bipolar contrast: 66.7%
baseName = 'MaxMel';
type = 'bipolar';

params = defaultParams(type);
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
dictionary = paramsValidateAndAppendToDictionary(dictionary, params);

%% MaxMel_275_60_667
% Direction for maximum contrast melanopsin pulse
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm -- for use with 6 mm artificial pupil as part of
%   pupillometry
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
baseName = 'MaxMel';
type = 'unipolar';

params = defaultParams(type);
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
dictionary = paramsValidateAndAppendToDictionary(dictionary, params);

%% MaxMel_600_80_667
% Direction for maximum contrast melanopsin pulse
%   Field size: 60.0 deg
%   Pupil diameter: 8 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
baseName = 'MaxMel';
type = 'unipolar';

params = defaultParams(type);
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
dictionary = paramsValidateAndAppendToDictionary(dictionary, params);

%% MaxLMS_275_80_667
% Direction for maximum contrast LMS pulse
%   Field size: 27.5 deg
%   Pupil diameter: 8 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
baseName = 'MaxLMS';
type = 'unipolar';

params = defaultParams(type);
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
dictionary = paramsValidateAndAppendToDictionary(dictionary, params);

%% MaxLMS_275_60_667
% Direction for maximum contrast LMS pulse
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm -- for use with 6 mm artificial pupil with
%   pupillometry
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
baseName = 'MaxLMS';
type = 'unipolar';

params = defaultParams(type);
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
dictionary = paramsValidateAndAppendToDictionary(dictionary, params);

%% MaxLMS_600_80_667
% Direction for maximum contrast LMS pulse
%   Field size: 60.0 deg
%   Pupil diameter: 8 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
baseName = 'MaxLMS';
type = 'unipolar';

params = defaultParams(type);
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
dictionary = paramsValidateAndAppendToDictionary(dictionary, params);

%% MaxMel_275_60_667
% Direction for maximum contrast melanopsin pulse
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
baseName = 'MaxMel';
type = 'unipolar';

params = defaultParams(type);
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
dictionary = paramsValidateAndAppendToDictionary(dictionary, params);

%% MaxLMS_275_60_667
% Direction for maximum contrast LMS pulse
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
baseName = 'MaxLMS';
type = 'unipolar';

params = defaultParams(type);
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
dictionary = paramsValidateAndAppendToDictionary(dictionary, params);

%% LightFlux_540_380_50
% Direction for maximum light flux pulse
%   CIE x = .54, y = .38
%   Flux factor = 5

baseName = 'LightFlux';
type = 'lightfluxchrom';

params = defaultParams(type);
params.lightFluxDesiredXY = [0.54,0.38];
params.lightFluxDownFactor = 5;
params.name = OLMakeApproachDirectionName(baseName,params);
params.backgroundType = 'lightfluxchrom';
params.backgroundName = OLMakeApproachDirectionBackgroundName('LightFlux',params);
params.cacheFile = ['Direction_' params.name '.mat'];
dictionary = paramsValidateAndAppendToDictionary(dictionary, params);

%% LightFlux_330_330_20
% Direction for maximum light flux pulse
%   CIE x = .33, y = .33
%   Flux factor = 2

baseName = 'LightFlux';
type = 'lightfluxchrom';

params = defaultParams(type);
params.lightFluxDesiredXY = [0.33,0.33];
params.lightFluxDownFactor = 2;
params.name = OLMakeApproachDirectionName(baseName,params);
params.backgroundType = 'lightfluxchrom';
params.backgroundName = OLMakeApproachDirectionBackgroundName('LightFlux',params);
params.cacheFile = ['Direction_' params.name '.mat'];
dictionary = paramsValidateAndAppendToDictionary(dictionary, params);
end

function dictionary = paramsValidateAndAppendToDictionary(dictionary, params)
% Validate passed parameters, and if valid, add to dictionary
%
% Syntax:
%   dictionary = paramsValidateAndAppendToDictionary(dictionary, params)
%
% Description:
%    Before adding a new entry to the dictionary, this function checks
%    whether it has all the appropriate fields, and no additional fields.
%    If not valid, will throw an error.
%    If valid, the params struct will be added to the dictionary, where the
%    params.name field will be the key, and the params struct the value.
%
%    The exact fields required, are those specified by the defaultParams
%    function, for the direction type specified in params.
%
% Inputs:
%    dictionary - a containers.Map() object in which to store the 
%                 dictionary entries
%    params     - the params to be validated and added to the dictionary
%
% Outputs:
%    dictionary - the updated containers.Map() object with the valid params
%                 added, under the key specified in params.name.
%
% Optional key/value pairs:
%    None.
%
% See also:
%    defaultParams

% Get all the expected field names for this type
allFieldNames = fieldnames(defaultParams(params.type));

% Test that there are no extra params
if (~all(ismember(fieldnames(params),allFieldNames)))
    fprintf(2,'\nParams struct contain extra params\n');
    fNames = fieldnames(params);
    idx = ismember(fieldnames(params),allFieldNames);
    idx = find(idx == 0);
    for k = 1:numel(idx)
        fprintf(2,'- ''%s'' \n', fNames{idx(k)});
    end
    error('Remove extra params or update defaultParams\n');
end

% Test that all expected params exist and that they have the expected type
switch (params.type)
    case {'unipolar', 'bipolar'}
        assert((isfield(params, 'dictionaryType')             && ischar(params.dictionaryType)),            sprintf('params.dictionaryType does not exist or it does not contain a string value.'));
        assert((isfield(params, 'type')                       && ischar(params.type)),                      sprintf('params.type does not exist or it does not contain a string value.'));
        assert((isfield(params, 'name')                       && ischar(params.name)),                      sprintf('params.name does not exist or it does not contain a string value.'));
        assert((isfield(params, 'baseModulationContrast')     && isnumeric(params.baseModulationContrast)), sprintf('params.baseModulationContrast does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'primaryHeadRoom')            && isnumeric(params.primaryHeadRoom)),        sprintf('params.primaryHeadRoom does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'photoreceptorClasses')       && iscell(params.photoreceptorClasses)),      sprintf('params.photoreceptorClasses does not exist or it does not contain a cell value.'));
        assert((isfield(params, 'fieldSizeDegrees')           && isnumeric(params.fieldSizeDegrees)),       sprintf('params.ieldSizeDegrees does not exist or it does not contain a number.'));
        assert((isfield(params, 'pupilDiameterMm')            && isnumeric(params.pupilDiameterMm)),        sprintf('params.pupilDiameterMm does not exist or it does not contain a number.'));
        assert((isfield(params, 'maxPowerDiff')               && isnumeric(params.maxPowerDiff)),           sprintf('params.maxPowerDiff does not exist or it does not contain a number.'));
        assert((isfield(params, 'modulationContrast')         && (isnumeric(params.modulationContrast) || iscell(params.whichReceptorsToIsolate))),         sprintf('params.modulationContrast does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'whichReceptorsToIsolate')    && (isnumeric(params.whichReceptorsToIsolate) || iscell(params.whichReceptorsToIsolate))),    sprintf('params.whichReceptorsToIsolate does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'whichReceptorsToIgnore')     && (isnumeric(params.whichReceptorsToIgnore) || iscell(params.whichReceptorsToIgnore))),      sprintf('params.whichReceptorsToIgnore does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'whichReceptorsToMinimize')   && (isnumeric(params.whichReceptorsToMinimize) || iscell(params.whichReceptorsToMinimize))),  sprintf('params.whichReceptorsToMinimize does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'directionsYoked')            && isnumeric(params.directionsYoked)),        sprintf('params.directionsYoked does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'directionsYokedAbs')         && isnumeric(params.directionsYokedAbs)),     sprintf('params.directionsYokedAbs does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'receptorIsolateMode')        && ischar(params.receptorIsolateMode)),       sprintf('params.receptorIsolateMode does not exist or it does not contain a string value.'));
        assert((isfield(params, 'useAmbient')                 && islogical(params.useAmbient)),             sprintf('params.useAmbient does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'doSelfScreening')            && islogical(params.doSelfScreening)),        sprintf('params.doSelfScreening does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'backgroundType')             && ischar(params.backgroundType)),            sprintf('params.backgroundType does not exist or it does not contain a string value.'));
        assert((isfield(params, 'backgroundName')             && ischar(params.backgroundName)),            sprintf('params.backgroundName does not exist or it does not contain a string value.'));
        assert((isfield(params, 'backgroundObserverAge')      && isnumeric(params.backgroundObserverAge)),  sprintf('params.backgroundObserverAge does not exist or it does not contain a number.'));
        assert((isfield(params, 'correctionPowerLevels')      && isnumeric(params.correctionPowerLevels)),  sprintf('params.correctionPowerLevels does not exist or it does not contain a number.'));
        assert((isfield(params, 'validationPowerLevels')      && isnumeric(params.validationPowerLevels)),  sprintf('params.validationPowerLevels does not exist or it does not contain a number.'));
        assert((isfield(params, 'cacheFile')                  && ischar(params.cacheFile)),                 sprintf('params.cacheFile does not exist or it does not contain a string value.'));
        
    case 'lightfluxchrom'
        assert((isfield(params, 'dictionaryType')             && ischar(params.dictionaryType)),            sprintf('params.dictionaryType does not exist or it does not contain a string value.'));
        assert((isfield(params, 'type')                       && ischar(params.type)),                      sprintf('params.type does not exist or it does not contain a string value.'));
        assert((isfield(params, 'name')                       && ischar(params.name)),                      sprintf('params.name does not exist or it does not contain a string value.'));
        assert((isfield(params, 'primaryHeadRoom')            && isnumeric(params.primaryHeadRoom)),        sprintf('params.primaryHeadRoom does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'lightFluxDesiredXY')         && isnumeric(params.lightFluxDesiredXY)),     sprintf('params.lightFluxDesiredXY does not exit or it does not contain numeric values.'));
        assert((isfield(params, 'lightFluxDownFactor')        && isnumeric(params.lightFluxDownFactor)),    sprintf('params.lightFluxDownFactor does not exit or it is not numeric.'));
        assert((isfield(params, 'useAmbient')                 && islogical(params.useAmbient)),             sprintf('params.useAmbient does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'backgroundType')             && ischar(params.backgroundType)),            sprintf('params.backgroundType does not exist or it does not contain a string value.'));
        assert((isfield(params, 'backgroundName')             && ischar(params.backgroundName)),            sprintf('params.backgroundName does not exist or it does not contain a string value.'));
        assert((isfield(params, 'backgroundObserverAge')      && isnumeric(params.backgroundObserverAge)),  sprintf('params.backgroundObserverAge does not exist or it does not contain a number.'));
        assert((isfield(params, 'correctionPowerLevels')      && isnumeric(params.correctionPowerLevels)),  sprintf('params.correctionPowerLevels does not exist or it does not contain a number.'));
        assert((isfield(params, 'validationPowerLevels')      && isnumeric(params.validationPowerLevels)),  sprintf('params.validationPowerLevels does not exist or it does not contain a number.'));
        assert((isfield(params, 'cacheFile')                  && ischar(params.cacheFile)),                 sprintf('params.cacheFile does not exist or it does not contain a string value.'));
        
    otherwise
        error('Unknown direction type specified: ''%s''.\n', params.type);
end

% All validations OK. Add entry to the dictionary.
dictionary(params.name) = params;
end

function params = defaultParams(type)
% Return the default parameters for a direction type
%
% Syntax:
%   params = defaultParams(type)
%
% Description:
%    Since a lot of the dictionary entries are small variations, this
%    function generates a set of default parameters; the parameters of
%    interest can then be overridden in the before adding an entry to the
%    dictionary.
%
% Inputs:
%    type   - string name of the type of direction. Currently available:
%               'bipolar':        bipolar contrast on some receptors
%               'unipolar':       unipolar contrast on some receptors
%               'lightfluxchrom': a light flux step at given chromaticity
%
% Outputs:
%    params - a struct with the default parameters for the given type of
%             direction
%
% Optional key/value pairs:
%    None.
%
% See also:
%    paramsValidateAndAppendToDictionary
params = struct();
params.type = type;
params.name = '';

switch (type)
    case {'bipolar', 'unipolar'}
        params.dictionaryType = 'Direction';                                     % What type of dictionary is this?
        params.baseModulationContrast = 4/6;                                     % How much symmetric bipolar contrast do we want to enable?  Used to generate background name.    
        params.primaryHeadRoom = 0.005;                                          % How close to edge of [0-1] primary gamut do we want to get?
        params.photoreceptorClasses = ...                                        % Names of photoreceptor classes being considered.
            {'LConeTabulatedAbsorbance', 'MConeTabulatedAbsorbance', 'SConeTabulatedAbsorbance', 'Melanopsin'};
        params.fieldSizeDegrees = 27.5;                                          % Field size. Affects fundamentals.
        params.pupilDiameterMm = 8.0;                                            % Pupil diameter used in background seeking. Affects fundamentals.
        params.maxPowerDiff = 0.1;                                               % Smoothing parameter for routine that finds backgrounds.
        params.modulationContrast = [params.baseModulationContrast];             % Vector of constrasts sought in isolation.
        params.whichReceptorsToIsolate = {[4]};                                  % Which receptor classes are not being silenced.
        params.whichReceptorsToIgnore = {[]};                                    % Receptor classes ignored in calculations.
        params.whichReceptorsToMinimize = {[]};                                  % These receptors are minimized in contrast, subject to other constraints.
        params.directionsYoked = [0];                                            % See ReceptorIsolate.
        params.directionsYokedAbs = [0];                                         % See ReceptorIsolate.
        params.receptorIsolateMode = 'Standard';                                 % See ReceptorIsolate.
        params.useAmbient = true;                                                % Use measured ambient in calculations if true. If false, set ambient to zero.
        params.doSelfScreening = false;                                          % Adjust photoreceptors for self-screening?
        params.backgroundType = 'optimized';                                     % Type of background
        params.backgroundName = '';                                              % Name of background 
        params.backgroundObserverAge = 32;                                       % Observer age expected in background 
        params.correctionPowerLevels = [0 1];                                    % Power levels to measure at during correction
        params.validationPowerLevels = [0 1];                                    % Power levels to measure at during validation
        params.cacheFile = '';                                                   % Cache filename goes here

    case 'lightfluxchrom'
        params.dictionaryType = 'Direction';                                     % What type of dictionary is this?
        params.primaryHeadRoom = 0.01;                                           % How close to edge of [0-1] primary gamut do we want to get? (Check if actually used someday.) 
        params.lightFluxDesiredXY = [0.54 0.38];                                 % Background chromaticity.
        params.lightFluxDownFactor = 5;                                          % Factor to decrease background after initial values found.  Determines how big a pulse we can put on it.
        params.useAmbient = true;                                                % Use measured ambient in calculations if true. If false, set ambient to zero.
        params.backgroundType = 'lightfluxchrom';                                % Type of background
        params.backgroundName = '';                                              % Name of background 
        params.backgroundObserverAge = 32;                                       % Observer age expected in background
        params.correctionPowerLevels = [0 1];                                    % Power levels to measure at during correction
        params.validationPowerLevels = [0 1];                                    % Power levels to measure at during validation
        params.cacheFile = '';                                                   % Cache filename goes here
        
    otherwise
        error('Unknown direction type specified: ''%s''.\n', type);
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
%    defaultParams, paramsValidateAndAppendToDictionary
params.type = params.backgroundType;
backgroundName = OLMakeApproachBackgroundName(name,params);
end