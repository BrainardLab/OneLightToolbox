%DirectionNominalParamsDictionary
%
% Description:
%   Generate dictionary with params for the examined modulation directions
%
% 6/22/17  npc  Wrote it.

function d = DirectionNominalParamsDictionary()
    % Initialize dictionary
    d = containers.Map();
    
    %% MaxMel
    %
    % Note modulation contrast is typically 2/3 for 400% contrast or 66.66%
    % sinusoidal contrast, modulation contrast has been set to 20% for testing purposes
    directionName = 'MelanopsinDirected';
    params = defaultParams();
    params.primaryHeadRoom = 0.01;
    params.backgroundType = 'BackgroundMaxMel';
    params.cacheFile = ['Direction_' params.backgroundType  '.mat'];
    d = paramsValidateAndAppendToDictionary(d, directionName, params);
    
    %% MelanopsinDirectedSuperMaxMel
    directionName = 'MelanopsinDirectedSuperMaxMel';
    params = defaultParams();
    params.primaryHeadRoom = 0.01;
    params.whichReceptorsToIsolate = [4];
    params.whichReceptorsToIgnore = [];
    params.whichReceptorsToMinimize = [];
    params.backgroundType = 'BackgroundMaxMel';
    params.cacheFile = ['Direction_' params.modulationDirection '.mat'];
    d = paramsValidateAndAppendToDictionary(d, directionName, params);
    
    %% LMSdirected
    directionName = 'LMSDirected';
    params = defaultParams();
    params.modulationContrast = {[4/6 4/6 4/6]};
    params.whichReceptorsToIsolate = {[1 2 3]};
    params.whichReceptorsToIgnore = {[]};
    params.whichReceptorsToMinimize = {[]};
    params.directionsYoked = [1];
    params.directionsYokedAbs = [0];
    params.backgroundType = 'BackgroundMaxLMS';
    params.cacheFile = ['Direction_' params.backgroundType  '.mat'];
    d = paramsValidateAndAppendToDictionary(d, directionName, params);
    
    %% LMSdirectedSuperMaxMex
    directionName = 'LMSDirectedSuperMaxLMS';
    params = defaultParams();
    params.primaryHeadRoom = 0.01;              % Original value 0.005
    params.backgroundType = 'BackgroundMaxLMS';
    params.modulationContrast = [4/6 4/6 4/6];
    params.whichReceptorsToIsolate = [1 2 3];
    params.whichReceptorsToIgnore = [];
    params.whichReceptorsToMinimize = [];
    params.cacheFile = ['Direction_' params.modulationDirection '.mat'];
    d = paramsValidateAndAppendToDictionary(d, directionName, params);
end

function d = paramsValidateAndAppendToDictionary(d, directionName, params)
    % Update modulationDirection
    params.modulationDirection = directionName;
    
    % Test that there are no extra params
    if (~all(ismember(fieldnames(params),fieldnames(defaultParams()))))
        fprintf(2,'\nParams struct contain extra params\n');
        fNames = fieldnames(params);
        idx = ismember(fieldnames(params),fieldnames(defaultParams()));
        idx = find(idx == 0);
        for k = 1:numel(idx)
            fprintf(2,'- ''%s'' \n', fNames{idx(k)});
        end
        error('Remove extra params or update defaultParams\n');
    end
        
    % Test that all expected params exist and that they have the expected type
    assert((isfield(params, 'type')                       && ischar(params.type)),                      sprintf('params.type does not exist or it does not contain a string value.'));
    assert((isfield(params, 'primaryHeadRoom')            && isnumeric(params.primaryHeadRoom)),        sprintf('params.primaryHeadRoom does not exist or it does not contain a numeric value.'));
    assert((isfield(params, 'pegBackground')              && islogical(params.pegBackground)),          sprintf('params.pegBackground does not exist or it does not contain a boolean value.'));
    assert((isfield(params, 'modulationDirection')        && ischar(params.modulationDirection)),       sprintf('params.modulationDirection does not exist or it does not contain a string value.'));
    assert((isfield(params, 'modulationContrast')         && (isnumeric(params.modulationContrast) || iscell(params.whichReceptorsToIsolate))),         sprintf('params.modulationContrast does not exist or it does not contain a numeric value.'));
    assert((isfield(params, 'whichReceptorsToIsolate')    && (isnumeric(params.whichReceptorsToIsolate) || iscell(params.whichReceptorsToIsolate))),    sprintf('params.whichReceptorsToIsolate does not exist or it does not contain a numeric value.'));
    assert((isfield(params, 'whichReceptorsToIgnore')     && (isnumeric(params.whichReceptorsToIgnore) || iscell(params.whichReceptorsToIgnore))),      sprintf('params.whichReceptorsToIgnore does not exist or it does not contain a numeric value.'));
    assert((isfield(params, 'whichReceptorsToMinimize')   && (isnumeric(params.whichReceptorsToMinimize) || iscell(params.whichReceptorsToMinimize))),  sprintf('params.whichReceptorsToMinimize does not exist or it does not contain a numeric value.'));
    assert((isfield(params, 'directionsYoked')            && isnumeric(params.directionsYoked)),        sprintf('params.directionsYoked does not exist or it does not contain a numeric value.'));
    assert((isfield(params, 'directionsYokedAbs')         && isnumeric(params.directionsYokedAbs)),     sprintf('params.directionsYokedAbs does not exist or it does not contain a numeric value.'));
    assert((isfield(params, 'receptorIsolateMode')        && ischar(params.receptorIsolateMode)),       sprintf('params.receptorIsolateMode does not exist or it does not contain a string value.'));
    assert((isfield(params, 'backgroundType')             && ischar(params.backgroundType)),            sprintf('params.backgroundType does not exist or it does not contain a string value.'));
    assert((isfield(params, 'cacheFile')                  && ischar(params.cacheFile)),                 sprintf('params.cacheFile does not exist or it does not contain a string value.'));
    
    % All validations OK. Add entry to the dictionary.
    d(directionName) = params;
end

function params = defaultParams()
    params = struct();
    params.type = 'pulse';
    params.pegBackground = false;           % not sure about default value of this param - Nicolas
    params.primaryHeadRoom = 0.005;         % original value
    params.modulationDirection = '';
    params.modulationContrast = [4/6];
    params.whichReceptorsToIsolate = {[4]};
    params.whichReceptorsToIgnore = {[]};
    params.whichReceptorsToMinimize = {[]};
    params.directionsYoked = [0];
    params.directionsYokedAbs = [0];
    params.receptorIsolateMode = 'Standard';
    params.backgroundType = '';
    params.cacheFile = '';
end

