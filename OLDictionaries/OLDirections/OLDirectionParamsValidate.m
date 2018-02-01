function valid = OLDirectionParamsValidate(params)
% Validate passed direction parameters
%
% Syntax:
%   valid = OLDirectionParamsValidate(entry)
%
% Description:
%    This function checks whether a given entry has all the appropriate 
%    fields, and no additional fields. The exact fields required, are those
%    returned by OLDirectionParamsDefaults, for the direction type 
%    specified in params. Throws an error if additional fields are present,
%    or if a field is missing or contains an unexpected value.
%
% Inputs:
%    params - the params to be validated and added to the dictionary
%
% Outputs:
%    valid  - logical boolean. True if entry contains all those fields, and 
%             only those fields, returned by
%             OLDirectionParamsDefaults for the given type. False
%             if missing or additional fields.
%
% Optional key/value pairs:
%    None.
%
% See also:
%    OLDirectionParamsDefaults, OLDirectionParamsDictionary

% History:
%    01/25/18  jv  Extracted from OLDirectionNominalParamsDictionary

valid = false;

% Get all the expected field names for this type
allFieldNames = fieldnames(OLDirectionParamsDefaults(params.type));

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
    case {'unipolar','bipolar'}
        assert((isfield(params, 'dictionaryType')             && ischar(params.dictionaryType)),            sprintf('params.dictionaryType does not exist or it does not contain a string value.'));
        assert((isfield(params, 'type')                       && ischar(params.type)),                      sprintf('params.type does not exist or it does not contain a string value.'));
        assert((isfield(params, 'name')                       && ischar(params.name)),                      sprintf('params.name does not exist or it does not contain a string value.'));
        assert((isfield(params, 'baseModulationContrast')     && isnumeric(params.baseModulationContrast)), sprintf('params.baseModulationContrast does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'primaryHeadRoom')            && isnumeric(params.primaryHeadRoom)),        sprintf('params.primaryHeadRoom does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'whichReceptorGenerator')     && ischar(params.whichReceptorGenerator)),     sprintf('params.whichReceptorGenerator does not exist or it does not contain a string value.'));
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

valid = true;
end

