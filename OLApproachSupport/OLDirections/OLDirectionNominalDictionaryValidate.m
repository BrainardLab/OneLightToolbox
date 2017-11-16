function valid = OLDirectionNominalDictionaryValidate(entry)
%OLDIRECTIONNOMINALDICTIONARYVALIDATE Validate parameters of given nominal
%directions dictionary entry

valid = false;

% Get all the expected field names for this type
allFieldNames = fieldnames(OLDirectionNominalDictionaryDefaults(entry.type));

% Test that there are no extra params
if (~all(ismember(fieldnames(entry),allFieldNames)))
    fprintf(2,'\nParams struct contain extra params\n');
    fNames = fieldnames(entry);
    idx = ismember(fieldnames(entry),allFieldNames);
    idx = find(idx == 0);
    for k = 1:numel(idx)
        fprintf(2,'- ''%s'' \n', fNames{idx(k)});
    end
    error('Remove extra params or update defaultParams\n');
end

% Test that all expected params exist and that they have the expected type
switch (entry.type)
    case 'pulse'
        assert((isfield(entry, 'dictionaryType')             && ischar(entry.dictionaryType)),            sprintf('params.dictionaryType does not exist or it does not contain a string value.'));
        assert((isfield(entry, 'type')                       && ischar(entry.type)),                      sprintf('params.type does not exist or it does not contain a string value.'));
        assert((isfield(entry, 'name')                       && ischar(entry.name)),                      sprintf('params.name does not exist or it does not contain a string value.'));
        assert((isfield(entry, 'whichReceptorGenerator')     && ischar(entry.whichReceptorGenerator)),    sprintf('params.whichReceptorGenerator does not exist or it does not contain a string.'));
        assert((isfield(entry, 'baseModulationContrast')     && isnumeric(entry.baseModulationContrast)), sprintf('params.baseModulationContrast does not exist or it does not contain a numeric value.'));
        assert((isfield(entry, 'primaryHeadRoom')            && isnumeric(entry.primaryHeadRoom)),        sprintf('params.primaryHeadRoom does not exist or it does not contain a numeric value.'));
        assert((isfield(entry, 'whichReceptorGenerator')     && ischar(entry.whichReceptorGenerator)),     sprintf('params.whichReceptorGenerator does not exist or it does not contain a string value.'));
        assert((isfield(entry, 'photoreceptorClasses')       && iscell(entry.photoreceptorClasses)),      sprintf('params.photoreceptorClasses does not exist or it does not contain a cell value.'));
        assert((isfield(entry, 'fieldSizeDegrees')           && isnumeric(entry.fieldSizeDegrees)),       sprintf('params.ieldSizeDegrees does not exist or it does not contain a number.'));
        assert((isfield(entry, 'pupilDiameterMm')            && isnumeric(entry.pupilDiameterMm)),        sprintf('params.pupilDiameterMm does not exist or it does not contain a number.'));
        assert((isfield(entry, 'maxPowerDiff')               && isnumeric(entry.maxPowerDiff)),           sprintf('params.maxPowerDiff does not exist or it does not contain a number.'));
        assert((isfield(entry, 'modulationContrast')         && (isnumeric(entry.modulationContrast) || iscell(entry.whichReceptorsToIsolate))),         sprintf('params.modulationContrast does not exist or it does not contain a numeric value.'));
        assert((isfield(entry, 'whichReceptorsToIsolate')    && (isnumeric(entry.whichReceptorsToIsolate) || iscell(entry.whichReceptorsToIsolate))),    sprintf('params.whichReceptorsToIsolate does not exist or it does not contain a numeric value.'));
        assert((isfield(entry, 'whichReceptorsToIgnore')     && (isnumeric(entry.whichReceptorsToIgnore) || iscell(entry.whichReceptorsToIgnore))),      sprintf('params.whichReceptorsToIgnore does not exist or it does not contain a numeric value.'));
        assert((isfield(entry, 'whichReceptorsToMinimize')   && (isnumeric(entry.whichReceptorsToMinimize) || iscell(entry.whichReceptorsToMinimize))),  sprintf('params.whichReceptorsToMinimize does not exist or it does not contain a numeric value.'));
        assert((isfield(entry, 'directionsYoked')            && isnumeric(entry.directionsYoked)),        sprintf('params.directionsYoked does not exist or it does not contain a numeric value.'));
        assert((isfield(entry, 'directionsYokedAbs')         && isnumeric(entry.directionsYokedAbs)),     sprintf('params.directionsYokedAbs does not exist or it does not contain a numeric value.'));
        assert((isfield(entry, 'receptorIsolateMode')        && ischar(entry.receptorIsolateMode)),       sprintf('params.receptorIsolateMode does not exist or it does not contain a string value.'));
        assert((isfield(entry, 'useAmbient')                 && islogical(entry.useAmbient)),             sprintf('params.useAmbient does not exist or it does not contain a logical value.'));
        assert((isfield(entry, 'doSelfScreening')            && islogical(entry.doSelfScreening)),        sprintf('params.doSelfScreening does not exist or it does not contain a logical value.'));
        assert((isfield(entry, 'backgroundType')             && ischar(entry.backgroundType)),            sprintf('params.backgroundType does not exist or it does not contain a string value.'));
        assert((isfield(entry, 'backgroundName')             && ischar(entry.backgroundName)),            sprintf('params.backgroundName does not exist or it does not contain a string value.'));
        assert((isfield(entry, 'backgroundObserverAge')      && isnumeric(entry.backgroundObserverAge)),  sprintf('params.backgroundObserverAge does not exist or it does not contain a number.'));
        assert((isfield(entry, 'correctionPowerLevels')      && isnumeric(entry.correctionPowerLevels)),  sprintf('params.correctionPowerLevels does not exist or it does not contain a number.'));
        assert((isfield(entry, 'validationPowerLevels')      && isnumeric(entry.validationPowerLevels)),  sprintf('params.validationPowerLevels does not exist or it does not contain a number.'));
        assert((isfield(entry, 'cacheFile')                  && ischar(entry.cacheFile)),                 sprintf('params.cacheFile does not exist or it does not contain a string value.'));
        
    case 'lightfluxchrom'
        assert((isfield(entry, 'dictionaryType')             && ischar(entry.dictionaryType)),            sprintf('params.dictionaryType does not exist or it does not contain a string value.'));
        assert((isfield(entry, 'type')                       && ischar(entry.type)),                      sprintf('params.type does not exist or it does not contain a string value.'));
        assert((isfield(entry, 'name')                       && ischar(entry.name)),                      sprintf('params.name does not exist or it does not contain a string value.'));
        assert((isfield(entry, 'primaryHeadRoom')            && isnumeric(entry.primaryHeadRoom)),        sprintf('params.primaryHeadRoom does not exist or it does not contain a numeric value.'));
        assert((isfield(entry, 'lightFluxDesiredXY')         && isnumeric(entry.lightFluxDesiredXY)),     sprintf('params.lightFluxDesiredXY does not exit or it does not contain numeric values.'));
        assert((isfield(entry, 'lightFluxDownFactor')        && isnumeric(entry.lightFluxDownFactor)),    sprintf('params.lightFluxDownFactor does not exit or it is not numeric.'));
        assert((isfield(entry, 'useAmbient')                 && islogical(entry.useAmbient)),             sprintf('params.useAmbient does not exist or it does not contain a logical value.'));
        assert((isfield(entry, 'backgroundType')             && ischar(entry.backgroundType)),            sprintf('params.backgroundType does not exist or it does not contain a string value.'));
        assert((isfield(entry, 'backgroundName')             && ischar(entry.backgroundName)),            sprintf('params.backgroundName does not exist or it does not contain a string value.'));
        assert((isfield(entry, 'backgroundObserverAge')      && isnumeric(entry.backgroundObserverAge)),  sprintf('params.backgroundObserverAge does not exist or it does not contain a number.'));
        assert((isfield(entry, 'correctionPowerLevels')      && isnumeric(entry.correctionPowerLevels)),  sprintf('params.correctionPowerLevels does not exist or it does not contain a number.'));
        assert((isfield(entry, 'validationPowerLevels')      && isnumeric(entry.validationPowerLevels)),  sprintf('params.validationPowerLevels does not exist or it does not contain a number.'));
        assert((isfield(entry, 'cacheFile')                  && ischar(entry.cacheFile)),                 sprintf('params.cacheFile does not exist or it does not contain a string value.'));
        
    otherwise
        error('Unknown direction type specified: ''%s''.\n', entry.type);
end

valid = true;
end

