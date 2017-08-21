% OOLCalibrationParamsDictionary
%
% Description:
%     Generate dictionary with box-specific calibration params. This is used by OLCalibrateOOC.
%     The fields are explained at the end of this routine, where default values are assigned.
%
%     This routine does its best to check that all and only needed fields are present in
%     the dictionary structures.
%
% See also: OLCalibrateOOC.
%
% 8/7/17   npc  Wrote it.
%

function d = OLCalibrationParamsDictionary()

% Initialize dictionary
d = containers.Map();

boxName = 'BoxA';
type = 'standardCalibration';
params = defaultParams(type);
params.boxName = boxName;

% Update box-specific calibration params
params.gammaFitType = 'betacdfpiecelin';
params.useAverageGamma = false;
params.nShortPrimariesSkip = 7;
params.nLongPrimariesSkip = 3;
params.nGammaBands = 16;        
d = paramsValidateAndAppendToDictionary(d, params);


boxName = 'BoxB';
type = 'standardCalibration';
params = defaultParams(type);
params.boxName = boxName;

% Update box-specific calibration params
params.gammaFitType = 'betacdfpiecelin';
params.useAverageGamma = true;
params.nShortPrimariesSkip = 5;
params.nLongPrimariesSkip = 3;
params.nGammaBands = 16;        
d = paramsValidateAndAppendToDictionary(d, params);


boxName = 'BoxC';
type = 'standardCalibration';
params = defaultParams(type);
params.boxName = boxName;

% Update box-specific calibration params
params.gammaFitType = 'betacdfpiecelin';
params.useAverageGamma = false;
params.nShortPrimariesSkip = 8;
params.nLongPrimariesSkip = 8;
params.nGammaBands = 16;        
d = paramsValidateAndAppendToDictionary(d, params);


boxName = 'BoxD';
type = 'standardCalibration';
params = defaultParams(type);
params.boxName = boxName;

% Update box-specific calibration params
params.gammaFitType = 'betacdfpiecelin';
params.useAverageGamma = true;
params.nShortPrimariesSkip = 8;
params.nLongPrimariesSkip = 2;
params.nGammaBands = 16;        
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
    case 'standardCalibration'
        assert((isfield(params, 'dictionaryType')             && ischar(params.dictionaryType)),            sprintf('params.dictionaryType does not exist or it does not contain a string value.'));
        assert((isfield(params, 'type')                       && ischar(params.type)),                      sprintf('params.type does not exist or it does not contain a string value.'));
        assert((isfield(params, 'boxName')                    && ischar(params.boxName)),                   sprintf('params.boxName does not exist or it does not contain a string value.'));
        assert((isfield(params, 'gammaFitType')               && ischar(params.gammaFitType)),              sprintf('params.gammaFitType does not exist or it does not contain a string value.'));
        assert((isfield(params, 'useAverageGamma')            && islogical(params.useAverageGamma)),        sprintf('params.useAverageGamma does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'nShortPrimariesSkip')        && isnumeric(params.nShortPrimariesSkip)),    sprintf('params.nShortPrimariesSkip does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'nLongPrimariesSkip')         && isnumeric(params.nLongPrimariesSkip)),     sprintf('params.nLongPrimariesSkip does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'nGammaBands')                && isnumeric(params.nGammaBands)),            sprintf('params.nGammaBands does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'nGammaFitLevels')            && isnumeric(params.nGammaFitLevels)),        sprintf('params.nGammaFitLevels does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'nGammaLevels')               && isnumeric(params.nGammaLevels)),           sprintf('params.nGammaLevels does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'randomizeGammaLevels')       && islogical(params.randomizeGammaLevels)),   sprintf('params.randomizeGammaLevels does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'randomizeGammaMeas')         && islogical(params.randomizeGammaMeas)),     sprintf('params.randomizeGammaMeas does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'randomizePrimaryMeas')       && islogical(params.randomizePrimaryMeas)),   sprintf('params.randomizePrimaryMeas does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'correctLinearDrift')         && islogical(params.correctLinearDrift)),     sprintf('params.correctLinearDrift does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'specifiedBackground')        && islogical(params.specifiedBackground)),    sprintf('params.specifiedBackground does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'zeroPrimariesAwayFromPeak')  && islogical(params.zeroPrimariesAwayFromPeak)), sprintf('params.zeroPrimariesAwayFromPeak does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'zeroItWLRangeMinus')         && isnumeric(params.zeroItWLRangeMinus)),     sprintf('params.zeroItWLRangeMinus does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'zeroItWLRangePlus')          && isnumeric(params.zeroItWLRangePlus)),      sprintf('params.zeroItWLRangePlus does not exist or it does not contain a numeric value.'));
        assert((isfield(params, 'doPrimaries')                && islogical(params.doPrimaries)),            sprintf('params.doPrimaries does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'doGamma')                    && islogical(params.doGamma)),                sprintf('params.doGamma does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'doIndependence')             && islogical(params.doIndependence)),         sprintf('params.doIndependence does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'extraSave')                  && islogical(params.extraSave)),              sprintf('params.extraSave does not exist or it does not contain a logical value.'));
        assert((isfield(params, 'useOmni')                    && islogical(params.useOmni)),                sprintf('params.useOmni does not exist or it does not contain a logical value.'));
    otherwise
            error('Unknown direction type specified: ''%s''.\n', params.type);
end % switch

% All validations OK. Add entry to the dictionary.
d(params.boxName) = params;
end

function params = defaultParams(type)
params = struct();
params.dictionaryType = 'Calibration';
params.type = type;

switch (type)
    case 'standardCalibration'
        % Box-specific calibration params.
        params.boxName = '';                            % Name of the OL box.
        params.gammaFitType = '';                       % Method to use for fitting the gamma function
        params.useAverageGamma = [];                    % Whether to use the average (across all primaries) gamma function
        params.nShortPrimariesSkip = [];                % Skip this many primaries at the short end of the spectrum
        params.nLongPrimariesSkip = [];                 % Skip this many primaries at the long end of the spectrum
        params.nGammaBands = [];                        % How many primaries to measure the gamma function on

        % Common calibration params
        params.nGammaFitLevels = 1024;                  % How many levels to etract by fitting the gamma function
        params.nGammaLevels = 24;                       % How many levels to measure the gamma function at
    
        params.randomizeGammaLevels = true;             % Whether to randomize the gamma level measurements. We do this to counter systematic device drift.
    	params.randomizeGammaMeas = true;               % Whether to randomize the gamma measurements. We do this to counter systematic device drift.
    	params.randomizePrimaryMeas = true;             % Whether to randomize the primary measurements. We do this to counter systematic device drift.
    
    	params.correctLinearDrift = true;               % Whether to correct (scale) for device linear drift according to the fluctuation in power at the time of measurement
        params.specifiedBackground = false;             % Whether to use non-zero background for gamma and related measurments
        
        params.zeroPrimariesAwayFromPeak = false;       % Whether to zero primaries away from their peak
        params.zeroItWLRangeMinus = 100;                % How far to go from the peak towards the short before zeroing.
        params.zeroItWlRangePlus = 100;                 % How far to go from the peak towards the long before zeroing.
    
        % Some code for debugging and quick checks.  These should generally all
        % be set to true.  If any are false, OLInitCal is not run.  You'll want
        % cal.describe.extraSave set to true when you have any of these set to false.
    	params.doPrimaries = true;                      % Measure the SPDs of the primaryies
        params.doGamma = true;                          % Measure the gamma functions of the primaries
        params.doIndependence = true;                   % Do spectral independence check measurements
    
        params.extraSave = false;                       % Whether to do an extra save of the cal data (in case of a crash) 
        params.useOmni = false;                         % Whether to use the omni spectrometer
    
    otherwise
        error('Unknown calibration type specified: ''%s''.\n', type);
end % switch

end
