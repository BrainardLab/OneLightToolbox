% OLDirectionNominalParamsDictionary
%
% Description:
%     Generate dictionary with params for the examined modulation directions
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
d = paramsValidateAndAppendToDictionary(d, params);

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
d = paramsValidateAndAppendToDictionary(d, params);

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
d = paramsValidateAndAppendToDictionary(d, params);

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
d = paramsValidateAndAppendToDictionary(d, params);

end

function d = paramsValidateAndAppendToDictionary(d, params)

% Update modulationDirection
params.modulationDirection = params.name;

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
    case 'pulse'
        assert((isfield(params, 'dictionaryType')             && ischar(params.dictionaryType)),            sprintf('params.dictionaryType does not exist or it does not contain a string value.'));
        assert((isfield(params, 'type')                       && ischar(params.type)),                      sprintf('params.type does not exist or it does not contain a string value.'));
        assert((isfield(params, 'name')                       && ischar(params.name)),                      sprintf('params.name does not exist or it does not contain a string value.'));
        assert((isfield(params, 'baseModulationContrast')     && isnumeric(params.baseModulationContrast)), sprintf('params.baseModulationContrast does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'primaryHeadRoom')            && isnumeric(params.primaryHeadRoom)),        sprintf('params.primaryHeadRoom does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'photoreceptorClasses')       && iscell(params.photoreceptorClasses)),      sprintf('params.photoreceptorClasses does not exist or it does not contain a cell value.'));
        assert((isfield(params, 'fieldSizeDegrees')           && isnumeric(params.fieldSizeDegrees)),       sprintf('params.ieldSizeDegrees does not exist or it does not contain a number.'));
        assert((isfield(params, 'pupilDiameterMm')            && isnumeric(params.pupilDiameterMm)),        sprintf('params.pupilDiameterMm does not exist or it does not contain a number.'));
        assert((isfield(params, 'maxPowerDiff')               && isnumeric(params.maxPowerDiff)),           sprintf('params.maxPowerDiff does not exist or it does not contain a number.'));
        assert((isfield(params, 'modulationDirection')        && ischar(params.modulationDirection)),       sprintf('params.modulationDirection does not exist or it does not contain a string value.'));
        assert((isfield(params, 'modulationDirection')        && ischar(params.modulationDirection)),       sprintf('params.modulationDirection does not exist or it does not contain a string value.'));
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
        assert((isfield(params, 'cacheFile')                  && ischar(params.cacheFile)),                 sprintf('params.cacheFile does not exist or it does not contain a string value.'));
    otherwise
        error('Unknown direction type specified: ''%s''.\n', params.type);
end

% All validations OK. Add entry to the dictionary.
d(params.name) = params;
end

function params = defaultParams(type)
params = struct();
params.type = type;
params.name = '';

switch (type)
    case 'pulse'
        params.dictionaryType = 'Direction';
        params.baseModulationContrast = 4/6;
        params.primaryHeadRoom = 0.005;
        params.photoreceptorClasses = {'LConeTabulatedAbsorbance', 'MConeTabulatedAbsorbance', 'SConeTabulatedAbsorbance', 'Melanopsin'};
        params.fieldSizeDegrees = 27.5;
        params.pupilDiameterMm = 8.0;
        params.maxPowerDiff = 0.1;
        params.modulationDirection = '';
        params.modulationContrast = [4/6];
        params.whichReceptorsToIsolate = {[4]};
        params.whichReceptorsToIgnore = {[]};
        params.whichReceptorsToMinimize = {[]};
        params.directionsYoked = [0];
        params.directionsYokedAbs = [0];
        params.receptorIsolateMode = 'Standard';
        params.useAmbient = true;
        params.doSelfScreening = true;
        params.backgroundType = 'optimized';
        params.backgroundName = '';
        params.backgroundObserverAge = 32;
        params.cacheFile = '';
    otherwise
        error('Unknown direction type specified: ''%s''.\n', type);
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
theName = OLMakeApproachBackgroundName('MelanopsinDirected',params);
end