% OLCorrectionParamsDictionary
%
% Description:
%     Generate dictionary with box-specific params for direction primary correction.  The fields
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

% 7/24/17  npc  Wrote it.

function d = OLCorrectionParamsDictionary()

% Initialize dictionary
d = containers.Map();

boxName = 'BoxA';
type = 'standardCorrection';
params = defaultParams(type, protocolParams);
params.boxName = boxName;
d = paramsValidateAndAppendToDictionary(d, params);

boxName = 'BoxD';
type = 'standardCorrection';
params = defaultParams(type, protocolParams);
params.boxName = boxName;
d = paramsValidateAndAppendToDictionary(d, params);

boxName = 'BoxB';
type = 'standardCorrection';
params = defaultParams(type, protocolParams);
params.boxName = boxName;
params.learningRate = 0.5;
params.learningRateDecrease = true;
params.smoothness = 0.001;
params.iterativeSearch = true;
params.useAverageGamma = true;
params.zeroPrimariesAwayFromPeak = true;
d = paramsValidateAndAppendToDictionary(d, params);

boxName = 'BoxC';
type = 'standardCorrection';
params = defaultParams(type, protocolParams);
params.boxName = boxName;
params.learningRate = 0.5;
params.learningRateDecrease = true;
params.smoothness = 0.001;
params.iterativeSearch = true;
params.useAverageGamma = true;
params.zeroPrimariesAwayFromPeak = true;
d = paramsValidateAndAppendToDictionary(d, params);

end

function d = paramsValidateAndAppendToDictionary(d, params)

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
    case 'standardCorrection'
        assert((isfield(params, 'dictionaryType')             && ischar(params.dictionaryType)),            sprintf('params.dictionaryType does not exist or it does not contain a string value.'));
        assert((isfield(params, 'type')                       && ischar(params.type)),                      sprintf('params.type does not exist or it does not contain a string value.'));
        assert((isfield(params, 'boxName')                    && ischar(params.boxName)),                   sprintf('params.boxName does not exist or it does not contain a string value.'));
        assert((isfield(params, 'fullOnMeas')                 && islogical(params.fullOnMeas)),             sprintf('params.fullOnMeas does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'calStateMeas')               && islogical(params.calStateMeas)),           sprintf('params.calStateMeas does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'darkMeas')                   && islogical(params.darkMeas)),               sprintf('params.darkMeas does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'reducedPowerLevels')         && islogical(params.reducedPowerLevels)),     sprintf('params.reducedPowerLevels does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'calculateSplatter')          && islogical(params.calculateSplatter)),      sprintf('params.calculateSplatter does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'learningRate')               && isnumeric(params.learningRate)),           sprintf('params.learningRate does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'learningRateDecrease')       && islogical(params.learningRateDecrease)),   sprintf('params.learningRateDecrease does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'asympLearningRateFactor')    && isnumeric(params.asympLearningRateFactor)),sprintf('params.asympLearningRateFactor does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'smoothness')                 && isnumeric(params.smoothness)),             sprintf('params.smoothness does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'iterativeSearch')            && islogical(params.iterativeSearch)),        sprintf('params.iterativeSearch does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'iterationsNum')              && isnumeric(params.iterationsNum)),          sprintf('params.iterationsNum does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'powerLevels')                && isnumeric(params.powerLevels)),            sprintf('params.powerLevels does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'postreceptoralCombinations') && isnumeric(params.postreceptoralCombinations)), sprintf('params.postreceptoralCombinations does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'useAverageGamma')            && islogical(params.useAverageGamma)),        sprintf('params.useAverageGamma does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'zeroPrimariesAwayFromPeak')  && islogical(params.zeroPrimariesAwayFromPeak)),  sprintf('params.zeroPrimariesAwayFromPeak does not exist or it does not contain a logical value.'));

    otherwise
        error('Unknown direction type specified: ''%s''.\n', params.type);
end

% All validations OK. Add entry to the dictionary.
d(params.boxName) = params;
end


function params = defaultParams(type)
params = struct();
params.dictionaryType = 'Correction';
params.type = type;
params.boxName = '';

switch (type)
    case 'standardCorrection'
        params.fullOnMeas = false;                                                          % Whether to take FULL-ON measurements
        params.calStateMeas = false;                                                        % Whether to take a state measurements
        params.darkMeas = false;                                                            % Whether to take dark measurements
        params.reducedPowerLevels = false;                                                  % ??
        params.calculateSplatter = false;                                                   % Whether to calculte splatter
        params.learningRate = 0.8;                                                          % ??
        params.learningRateDecrease = false;                                                % ??
        params.asympLearningRateFactor = 0.5;                                               % ??
        params.smoothness = 0.1;                                                            % ??
        params.iterativeSearch = false;                                                     % ??
        params.iterationsNum = 1;                                                           % ??
        params.powerLevels = [0 1.0000];                                                    % ??
        params.postreceptoralCombinations = [1 1 1 0 ; 1 -1 0 0 ; 0 0 1 0 ; 0 0 0 1];       % ??
        params.useAverageGamma = false;                                                     % whether to use the average (across channels) gamma
        params.zeroPrimariesAwayFromPeak = false;                                           % ??
    otherwise
        error('Unknown correction type specified: ''%s''.\n', type);
end
end
