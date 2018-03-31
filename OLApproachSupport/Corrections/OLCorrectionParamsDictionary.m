function d = OLCorrectionParamsDictionary(varargin)
% Defines a dictionary with parameters for spectral correction
%
% Description:
%     Generate dictionary with box-specific params for direction primary correction.  The fields
%     are explained at the end of this routine, where default values are assigned.
%
% Inputs:
%    None.
%
% Outputs:
%    dictionary         -  Dictionary with all parameters for all desired
%                          backgrounds
%
% Optional key/value pairs:
%    'alternateDictionaryFunc' - String with name of alternate dictionary
%                          function to call. This must be a function on the
%                          path. Default of empty results in using this
%                          function.
%
% Note:
%
% See also:
%

% 07/24/17  npc  Wrote it.
% 09/25/17  dhb  Remove useAverageGamma and zeroPrimariesAwayFromPeak fields.
%                Now, these should only be set in the calibration dictionary.
%           dhb  Also remove postreceptorCombinations field, at a cost in generality
%                but a gain in simplicity.
%    03/31/18  dhb  Add alternateDictionaryFunc key/value pair.

% Parse input
p = inputParser;
p.KeepUnmatched = true;
p.addParameter('alternateDictionaryFunc','',@ischar);
p.parse(varargin{:});

% Check for alternate dictionary, call if so and then return.
% Otherwise this is the dictionary function and we execute it.
% The alternate function must be on the path.
if (~isempty(p.Results.alternateDictionaryFunc))
    dictionaryFunction = str2func(sprintf('@%s',p.Results.alternateDictionaryFunc));
    dictionary = dictionaryFunction();
    return;
end

% Initialize dictionary
d = containers.Map();

boxName = 'BoxA';
type = 'standardCorrection';
params = defaultParams(type);
params.boxName = boxName;
d = paramsValidateAndAppendToDictionary(d, params);

boxName = 'BoxD';
type = 'standardCorrection';
params = defaultParams(type);
params.boxName = boxName;
d = paramsValidateAndAppendToDictionary(d, params);

boxName = 'BoxB';
type = 'standardCorrection';
params = defaultParams(type);
params.boxName = boxName;
params.learningRate = 0.5;
params.learningRateDecrease = true;
params.smoothness = 0.001;
params.iterativeSearch = true;
d = paramsValidateAndAppendToDictionary(d, params);

boxName = 'BoxC';
type = 'standardCorrection';
params = defaultParams(type);
params.boxName = boxName;
params.learningRate = 0.5;
params.learningRateDecrease = true;
params.smoothness = 0.001;
params.iterativeSearch = true;
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
        assert((isfield(params, 'calStateMeas')               && islogical(params.calStateMeas)),           sprintf('params.calStateMeas does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'iterativeSearch')            && islogical(params.iterativeSearch)),        sprintf('params.iterativeSearch does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'learningRate')               && isnumeric(params.learningRate)),           sprintf('params.learningRate does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'learningRateDecrease')       && islogical(params.learningRateDecrease)),   sprintf('params.learningRateDecrease does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'asympLearningRateFactor')    && isnumeric(params.asympLearningRateFactor)),sprintf('params.asympLearningRateFactor does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'smoothness')                 && isnumeric(params.smoothness)),             sprintf('params.smoothness does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'nIterations')                && isnumeric(params.nIterations)),            sprintf('params.nIterations does not exist or it does not contain a numeric value.'));

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
        params.calStateMeas = false;                                                        % Whether to take a state measurements
        params.iterativeSearch = true;                                                      % Do iterative search with fmincon on each measurement iteration?
        params.learningRate = 0.8;                                                          % How much adjustment is done on each seeking iteration.
        params.learningRateDecrease = false;                                                % When true, learning rate is decreased over iterations.
        params.asympLearningRateFactor = 0.5;                                               % If learningRateDecrease is true, this affects how fast it decreases.
        params.smoothness = 0.1;                                                            % Smoothness parameter for OLSpdToPrimary
        params.nIterations = 10;                                                            % Number of iterations to do before declaring victory.
        
    otherwise
        error('Unknown correction type specified: ''%s''.\n', type);
end
end
