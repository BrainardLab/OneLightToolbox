function [cacheData olCache openSpectroRadiometerOBJ] = OLCorrectCacheFileOOC(cacheFileName, emailRecipient, ...
    meterType, spectroRadiometerOBJ, spectroRadiometerOBJWillShutdownAfterMeasurement, varargin)
% results = OLCorrectCacheFileOOC(cacheFileName, emailRecipient, ...
% meterType, spectroRadiometerOBJ, spectroRadiometerOBJWillShutdownAfterMeasurement, varargin)
% OLCorrectCacheFileOOC - Validates a OneLight cache file.
%
% Syntax:
% OLValidateCacheFile(cacheFileName)
%
% Description:
% Validates a OneLight cache file and measures the data it contains in
% order to see how our computed and predicted spectra compare with the
% actual spectra as seen by the PR-650 and OmniDriver spectrometers.
%
% Input:
% cacheFileName (string)    - The name of the cache file to validate.  The
%                             file name must be an absolute path.  This is
%                             because relative path can match anything on the
%                             Matlab path, which could lead to unintended
%                             results.
% emailRecipient (string)   - Email address to receive notifications
% meterType (string)        - Meter type to use.
% spectroRadiometerOBJ      - A previously open PR650 or PR670 object
% spectroRadiometerOBJWillShutdownAfterMeasurement - Boolean, indicating
%                             whether to shutdown the radiometer object
% varargin (keyword-value)  - A few keywords which determine the behavior
%                             of the routine.
%                             Keyword               Default   Behavior
%                             'ReferenceMode'       true      Adds suffix
%                                                             to file name
%                             'FullOnMeas'          true      Full-on
%                             'HalfOnMeas'          false     Half-on
%                             'CalStateMeas'    true  State measurements
%                             'SkipBackground'      false     Background
%                             'ReducedPowerLevels'  true      Only 3 levels
%                             'NoAdjustment      '  true      Does not pause
%                             'REFERENCE_OBSERVER_AGE'         32        Standard obs.
%                             'selectedCalType'     'EyeTrackerLongCableEyePiece1'
%                                                             Calibration
%                                                             type
%                             'powerLevels'         scalar    Which power levels
%                             'NIter'               scalar    number of
%                                                             iterations
%                             'lambda'              scalar    Learning rate
%                             'postreceptoralCombinations'  scalar     Post-receptoral combinations to calculate contrast w.r.t.
%
% Output:
% results (struct) - Results struct. This is different depending on which
% mode is used.
% validationDir (str) - Validation directory.
%
% 1/21/14  dhb, ms  Convert to use OLSettingsToStartsStops.
% 1/30/14  ms       Added keyword parameters to make this useful.
% 7/06/16  npc      Adapted to use PR650dev/PR670dev objects

% Parse the input
p = inputParser;
p.addOptional('ReferenceMode', true, @islogical);
p.addOptional('FullOnMeas', true, @islogical);
p.addOptional('HalfOnMeas', false, @islogical);
p.addOptional('DarkMeas', false, @islogical);
p.addOptional('CalStateMeas', false, @islogical);
p.addOptional('SkipBackground', false, @islogical);
p.addOptional('ReducedPowerLevels', true, @islogical);
p.addOptional('NoAdjustment', false, @islogical);
p.addOptional('REFERENCE_OBSERVER_AGE', 32, @isscalar);
p.addOptional('NIter', 20, @isscalar);
p.addOptional('lambda', 0.8, @isscalar);
p.addOptional('selectedCalType', [], @isstr);
p.addOptional('CALCULATE_SPLATTER', true, @islogical);
p.addOptional('powerLevels', 32, @isnumeric);
p.addOptional('doCorrection', true, @islogical);
p.addOptional('postreceptoralCombinations', [], @isnumeric);
p.addOptional('srfIncorporateFilter', [], @isnumeric);
p.addOptional('outDir', [], @isstr);

p.parse(varargin{:});
describe = p.Results;
powerLevels = describe.powerLevels;

if isempty(emailRecipient)
    emailRecipient = GetWithDefault('Send status email to','igdalova@mail.med.upenn.edu');
end

% All variables assigned in the following if (isempty(..)) block (except
% spectroRadiometerOBJ) must be declared as persistent
persistent S
persistent nAverage
persistent theMeterTypeID
if (isempty(spectroRadiometerOBJ))
    % Open up the radiometer if this is the first cache file we validate
    try
        switch (meterType)
            case 'PR-650',
                theMeterTypeID = 1;
                S = [380 4 101];
                nAverage = 1;
                
                % Instantiate a PR650 object
                spectroRadiometerOBJ  = PR650dev(...
                    'verbosity',        1, ...       % 1 -> minimum verbosity
                    'devicePortString', [] ...       % empty -> automatic port detection)
                    );
                spectroRadiometerOBJ.setOptions('syncMode', 'OFF');
                
            case 'PR-670',
                theMeterTypeID = 5;
                S = [380 2 201];
                nAverage = 1;
                
                % Instantiate a PR670 object
                spectroRadiometerOBJ  = PR670dev(...
                    'verbosity',        1, ...       % 1 -> minimum verbosity
                    'devicePortString', [] ...       % empty -> automatic port detection)
                    );
                
                % Set options Options available for PR670:
                spectroRadiometerOBJ.setOptions(...
                    'verbosity',        1, ...
                    'syncMode',         'OFF', ...      % choose from 'OFF', 'AUTO', [20 400];
                    'cyclesToAverage',  1, ...          % choose any integer in range [1 99]
                    'sensitivityMode',  'STANDARD', ... % choose between 'STANDARD' and 'EXTENDED'.  'STANDARD': (exposure range: 6 - 6,000 msec, 'EXTENDED': exposure range: 6 - 30,000 msec
                    'exposureTime',     'ADAPTIVE', ... % choose between 'ADAPTIVE' (for adaptive exposure), or a value in the range [6 6000] for 'STANDARD' sensitivity mode, or a value in the range [6 30000] for the 'EXTENDED' sensitivity mode
                    'apertureSize',     '1 DEG' ...   % choose between '1 DEG', '1/2 DEG', '1/4 DEG', '1/8 DEG'
                    );
            otherwise,
                error('Unknown meter type');
        end
        
    catch err
        if (~isempty(spectroRadiometerOBJ))
            spectroRadiometerOBJ.shutDown();
            openSpectroRadiometerOBJ = [];
        end
        SendEmail(emailRecipient, 'OLValidateCacheFileOOC Failed', ...
            ['Calibration failed with the following error' 10 err.message]);
        keyboard;
        rethrow(err);
    end
end
openSpectroRadiometerOBJ = spectroRadiometerOBJ;

% Populate the filter with onesif it is passed as empty
if isempty(p.Results.srfIncorporateFilter)
    ndFilter = ones(S(3), 1);
else
    ndFilter = p.Results.srfIncorporateFilter;
end

% Force the file to be an absolute path instead of a relative one.  We do
% this because files with relative paths can match anything on the path,
% which may not be what was intended.  The regular expression looks for
% string that begins with '/' or './'.
m = regexp(cacheFileName, '^(\.\/|\/).*', 'once');
assert(~isempty(m), 'OLValidateCacheFile:InvalidPathDef', ...
    'Cache file name must be an absolute path.');

% Make sure the file exists.
assert(logical(exist(cacheFileName, 'file')), 'OLValidateCacheFile:FileNotFound', ...
    'Cannot find cache file: %s', cacheFileName);

% Deduce the cache directory.
cacheDir = fileparts(cacheFileName);
% Load the cache file.
data = load(cacheFileName);
assert(isstruct(data), 'OLValidateCacheFile:InvalidCacheFile', ...
    'Specified file doesn''t seem to be a cache file: %s', cacheFileName);

% List the available calibration types found in the cache file.
foundCalTypes = sort(fieldnames(data));

% Make sure the all the calibration types loaded seem legit. We want to
% make sure that we have at least one calibration type which we know of.
% Otherwise, we abort.
[~, validCalTypes] = enumeration('OLCalibrationTypes');
for i = 1:length(foundCalTypes)
    typeExists(i) = any(strcmp(foundCalTypes{i}, validCalTypes));
end
assert(any(typeExists), 'OLValidateCacheFile:InvalidCacheFile', ...
    'File contains does not contain at least one valid calibration type');

% Display a list of all the calibration types contained in the file and
% have the user select one to validate.
while true
    fprintf('\n- Calibration Types in Cache File (*** = valid)\n\n');
    
    for i = 1:length(foundCalTypes)
        if typeExists(i)
            typeState = '***';
        else
            typeState = '---';
        end
        fprintf('%i (%s): %s\n', i, typeState, foundCalTypes{i});
    end
    fprintf('\n');
    
    % Check if 'selectedCalType' was passed.
    if (isfield(describe, 'selectedCalType')) && any(strcmp(foundCalTypes, describe.selectedCalType))
        selectedCalType = describe.selectedCalType;
        break;
    end
    
    t = GetInput('Select a Number', 'number', 1);
    
    if t >= 1 && t <= length(foundCalTypes) && typeExists(t);
        fprintf('\n');
        selectedCalType = foundCalTypes{t};
        break;
    else
        fprintf('\n*** Invalid selection try again***\n\n');
    end
end

% Load the calibration file associated with this calibration type.
cal = LoadCalFile(OLCalibrationTypes.(selectedCalType).CalFileName, [], getpref('OneLight', 'OneLightCalData'));

% Pull out the file name
cacheFileNameFull = cacheFileName;
[~, cacheFileName] = fileparts(cacheFileName);

%% Determine which meters to measure with
% It is probably a safe assumption that we will not validate a cache file
% with the Omni with respect to a calibration that was done without the
% Omni. Therefore, we read out the toggle directly from the calibration
% file. First entry is PR-6xx and is always true. Second entry is omni and
% can be on or off, depending on content of calibration.
meterToggle = [1 cal.describe.useOmni];

% Setup the OLCache object.
olCache = OLCache(cacheDir, cal);

% Load the calibration data.  We do it through the cache object so that we
% make sure that the cache is current against the latest calibration data.
[~, simpleCacheFileName] = fileparts(cacheFileName);
[cacheData, wasRecomputed] = olCache.load(simpleCacheFileName);

% If we recomputed the cache data, save it.  We'll load the cache data
% after we save it because cache data is uniquely time stamped upon save.
if wasRecomputed
    olCache.save(simpleCacheFileName, cacheData);
    cacheData = olCache.load(simpleCacheFileName);
end

if ~(describe.doCorrection)
    return; % Just return with no correction
end

% Connect to the OceanOptics spectrometer.
if (cal.describe.useOmni)
    od = OmniDriver;
    od.Debug = true;
    % Turn on some averaging and smoothing for the spectrum acquisition.
    od.ScansToAverage = 10;
    od.BoxcarWidth = 2;
    
    % Make sure electrical dark correction is enabled.
    od.CorrectForElectricalDark = true;
    
    % Set the OmniDriver integration time to match up with what's in the
    % calibration file.
    od.IntegrationTime = cal.describe.omniDriver.integrationTime;
else
    od = [];
end

% Open up the OneLight
ol = OneLight;

% Turn the mirrors full on so the user can focus the radiometer.
if describe.NoAdjustment
    ol.setAll(true);
    pauseDuration = 0;
    fprintf('- Focus the radiometer and press enter to pause %d seconds and start measuring.\n', ...
        pauseDuration);
    input('');
    ol.setAll(false);
    pause(pauseDuration);
else
    ol.setAll(false);
end

try
    startMeas = GetSecs;
    fprintf('- Performing radiometer measurements.\n');
    
    % Take reference measurements
    if describe.FullOnMeas
        fprintf('- Full-on measurement \n');
        [starts,stops] = OLSettingsToStartsStops(cal,1*ones(cal.describe.numWavelengthBands, 1));
        results.fullOnMeas.meas = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, S, meterToggle, nAverage);
        results.fullOnMeas.starts = starts;
        results.fullOnMeas.stops = stops;
        results.fullOnMeas.predictedFromCal = cal.raw.fullOn(:, 1);
    end
    
    if describe.HalfOnMeas
        fprintf('- Half-on measurement \n');
        [starts,stops] = OLSettingsToStartsStops(cal,0.5*ones(cal.describe.numWavelengthBands, 1));
        results.halfOnMeas.meas = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, S, meterToggle, nAverage);
        results.halfOnMeas.starts = starts;
        results.halfOnMeas.stops = stops;
        results.halfOnMeas.predictedFromCal = cal.raw.halfOnMeas(:, 1);
    end
    
    if describe.DarkMeas
        fprintf('- Dark measurement \n');
        [starts,stops] = OLSettingsToStartsStops(cal,0*ones(cal.describe.numWavelengthBands, 1));
        results.offMeas.meas = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, S, meterToggle, nAverage);
        results.offMeas.starts = starts;
        results.offMeas.stops = stops;
        results.offMeas.predictedFromCal = cal.raw.darkMeas(:, 1);
    end
    
    if describe.CalStateMeas
        fprintf('- State measurements \n');
        [~, calStateMeas] = OLCalibrator.TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, 'standAlone',true);
        OLCalibrator.SaveStateMeasurements(cal, calStateMeas);
    end
    
    % Loop over the stimuli in the cache file and take a measurement with
    % the PR-670.
    theCanonicalPhotoreceptors = cacheData.data(describe.REFERENCE_OBSERVER_AGE).describe.photoreceptors;
    T_receptors = cacheData.data(describe.REFERENCE_OBSERVER_AGE).describe.T_receptors;
    
    iter = 1;
    switch cacheData.computeMethod
        case 'ReceptorIsolate'
            while iter <= describe.NIter
                % Set up the power levels to use.
                NPowerLevels = length(powerLevels);
                
                % Only get the primaries from the cache file if it's the first
                % iteration
                if iter == 1
                    backgroundPrimary = cacheData.data(describe.REFERENCE_OBSERVER_AGE).backgroundPrimary;
                    differencePrimary = cacheData.data(describe.REFERENCE_OBSERVER_AGE).differencePrimary;
                    modulationPrimary = cacheData.data(describe.REFERENCE_OBSERVER_AGE).backgroundPrimary+cacheData.data(describe.REFERENCE_OBSERVER_AGE).differencePrimary;
                else
                    backgroundPrimary = backgroundPrimaryCorrected;
                    modulationPrimary = modulationPrimaryPositiveCorrected;
                end
                
                % Refactor the cache data spectrum primaries to the power
                % level.
                for i = 1:NPowerLevels
                    fprintf('- Measuring spectrum %d, level %g...\n', i, powerLevels(i));
                    if powerLevels(i) == 1
                        primaries = modulationPrimary;
                    elseif powerLevels(i) == 0
                        primaries = backgroundPrimary;
                    else
                        primaries = backgroundPrimary+powerLevels(i).*differencePrimary;
                    end
                    
                    % Convert the primaries to mirror settings.
                    settings = OLPrimaryToSettings(cal, primaries);
                    
                    % Compute the stop mirrors.
                    [starts,stops] = OLSettingsToStartsStops(cal, settings);
                    
                    % Take the measurements
                    results.modulationAllMeas(i).meas = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, S, meterToggle, nAverage);
                    
                    % Multiply with filter
                    results.modulationAllMeas(i).meas.pr650.spectrum = results.modulationAllMeas(i).meas.pr650.spectrum .* ndFilter;
                    
                    % Save out information about this.
                    results.modulationAllMeas(i).powerLevel = powerLevels(i);
                    results.modulationAllMeas(i).primaries = primaries;
                    results.modulationAllMeas(i).settings = settings;
                    results.modulationAllMeas(i).starts = starts;
                    results.modulationAllMeas(i).stops = stops;
                    if iter == 1
                        results.modulationAllMeas(i).predictedSpd = cal.computed.pr650M*primaries + cal.computed.pr650MeanDark;
                        results.modulationAllMeas(i).predictedSpd = results.modulationAllMeas(i).meas.pr650.spectrum .* ndFilter;
                    end
                end
                
                % For convenience we pull out the max., min. and background.
                theMaxIndex = find([results.modulationAllMeas(:).powerLevel] == 1);
                theMinIndex = find([results.modulationAllMeas(:).powerLevel] == -1);
                theBGIndex = find([results.modulationAllMeas(:).powerLevel] == 0);
                
                % Background
                if ~isempty(theBGIndex)
                    results.modulationBGMeas = results.modulationAllMeas(theBGIndex);
                    bgSpdAll(:, iter) = results.modulationBGMeas.meas.pr650.spectrum;
                    
                    % Figure out a scaling factor from the first measurement
                    % which puts the measured spectrum into the same range as
                    % the predicted spectrum. This deals with fluctuations with
                    % absolute light level.
                    if iter == 1
                        % Determine the scale factor
                        kScale = results.modulationBGMeas.meas.pr650.spectrum \ results.modulationBGMeas.predictedSpd;
                    end
                    
                    % Infer the primaries
                    deltaBackgroundPrimaryInferred = OLSpdToPrimary(cal, (kScale*results.modulationBGMeas.meas.pr650.spectrum)-...
                        results.modulationBGMeas.predictedSpd, 'differentialMode', true);
                    backgroundPrimaryCorrected = backgroundPrimary - describe.lambda*deltaBackgroundPrimaryInferred;
                    backgroundPrimaryCorrected(backgroundPrimaryCorrected > 1) = 1;
                    backgroundPrimaryCorrected(backgroundPrimaryCorrected < 0) = 0;
                    backgroundPrimaryCorrectedAll(:, iter) = backgroundPrimaryCorrected;
                    deltaBackgroundPrimaryInferredAll(:, iter)= deltaBackgroundPrimaryInferred;
                end
                
                % Positive swing
                if ~isempty(theMaxIndex)
                    results.modulationMaxMeas = results.modulationAllMeas(theMaxIndex);
                    modMaxSpdAll(:, iter) = results.modulationMaxMeas.meas.pr650.spectrum;
                    
                    % Infer the primaries
                    deltaModulationPrimaryPositiveInferred = OLSpdToPrimary(cal, (kScale*results.modulationMaxMeas.meas.pr650.spectrum)-...
                        results.modulationMaxMeas.predictedSpd, 'differentialMode', true);
                    modulationPrimaryPositiveCorrected = modulationPrimary - describe.lambda*deltaModulationPrimaryPositiveInferred;
                    modulationPrimaryPositiveCorrected(modulationPrimaryPositiveCorrected > 1) = 1;
                    modulationPrimaryPositiveCorrected(modulationPrimaryPositiveCorrected < 0) = 0;
                    modulationPrimaryPositiveCorrectedAll(:, iter) = modulationPrimaryPositiveCorrected;
                    deltaModulationPrimaryPositiveInferredAll(:, iter)= deltaModulationPrimaryPositiveInferred;
                    
                    [contrastsPos(:, iter) postreceptoralContrastsPos(:, iter)] = ComputeAndReportContrastsFromSpds(['Iteration ' num2str(iter, '%02.0f')] ,theCanonicalPhotoreceptors,T_receptors,...
                        results.modulationBGMeas.meas.pr650.spectrum,results.modulationMaxMeas.meas.pr650.spectrum,describe.postreceptoralCombinations,true);
                end
                
                % Negative swing
                if ~isempty(theMinIndex)
                    results.modulationMinMeas = results.modulationAllMeas(theMinIndex);
                    modMinSpdAll(:, iter) = results.modulationMaxMeas.meas.pr650.spectrum;
                    
                    % Infer the primaries
                    deltaModulationPrimaryNegativeInferred = OLSpdToPrimary(cal, (kScale*results.modulationMaxMeas.meas.pr650.spectrum)-...
                        results.modulationMaxMeas.predictedSpd, 'differentialMode', true);
                    modulationPrimaryNegativeCorrected = modulationPrimary - describe.lambda*deltaModulationPrimaryNegativeInferred;
                    modulationPrimaryNegativeCorrected(modulationPrimaryNegativeCorrected > 1) = 1;
                    modulationPrimaryNegativeCorrected(modulationPrimaryNegativeCorrected < 0) = 0;
                    modulationPrimaryNegativeCorrectedAll(:, iter) = modulationPrimaryNegativeCorrected;
                    deltaModulationPrimaryNegativeInferredAll(:, iter)= deltaModulationPrimaryNegativeInferred;
                    [contrastsNeg(:, iter) postreceptoralContrastsNeg(:, iter)] = ComputeAndReportContrastsFromSpds(['Iteration ' num2str(iter, '%02.0f')] ,theCanonicalPhotoreceptors,T_receptors,...
                        results.modulationBGMeas.meas.pr650.spectrum,results.modulationMinMeas.meas.pr650.spectrum,describe.postreceptoralCombinations,true);
                else
                    modMinSpdAll = [];
                    deltaModulationPrimaryInferred = [];
                    modulationPrimaryNegativeCorrected = [];
                    modulationPrimaryNegativeCorrectedAll = [];
                    deltaModulationPrimaryNegativeInferredAll = [];
                    contrastsNeg = [];
                    postreceptoralContrastsNeg = [];
                end
                
                % Increment
                iter = iter+1;
            end
    end
    
    % Replace the old nominal settings with the corrected ones.
    for ii = 1:length(cacheData.data)
        if ii == describe.REFERENCE_OBSERVER_AGE;
            cacheData.data(ii).backgroundPrimary = backgroundPrimaryCorrectedAll(:, end);
            cacheData.data(ii).modulationPrimarySignedPositive = modulationPrimaryPositiveCorrectedAll(:, end);
            cacheData.data(ii).modulationPrimarySignedNegative = modulationPrimaryNegativeCorrectedAll(:, end);
            
            cacheData.data(ii).differencePrimary = modulationPrimaryPositiveCorrectedAll(:, end)-backgroundPrimaryCorrectedAll(:, end);
            cacheData.data(ii).correction.backgroundPrimaryCorrectedAll = backgroundPrimaryCorrectedAll;
            cacheData.data(ii).correction.deltaBackgroundPrimaryInferredAll = deltaBackgroundPrimaryInferredAll;
            cacheData.data(ii).correction.bgSpdAll = bgSpdAll;
            
            cacheData.data(ii).correction.modulationPrimaryPositiveCorrectedAll = modulationPrimaryPositiveCorrectedAll;
            cacheData.data(ii).correction.deltaModulationPrimaryPositiveInferredAll = deltaModulationPrimaryPositiveInferredAll;
            cacheData.data(ii).correction.modMaxSpdAll = modMaxSpdAll;
            
            cacheData.data(ii).correction.modulationPrimaryNegativeCorrectedAll = modulationPrimaryNegativeCorrectedAll;
            cacheData.data(ii).correction.deltaModulationPrimaryNegativeInferredAll = deltaModulationPrimaryNegativeInferredAll;
            cacheData.data(ii).correction.modMinSpdAll = modMinSpdAll;
            
            cacheData.data(ii).correction.contrastsPos = contrastsPos;
            cacheData.data(ii).correction.postreceptoralContrastsPos = postreceptoralContrastsPos;
            
            cacheData.data(ii).correction.contrastsNeg = contrastsNeg;
            cacheData.data(ii).correction.postreceptoralContrastsNeg = postreceptoralContrastsNeg;
            
            cacheData.data(ii).correction.contrasts = contrastsPos;
            cacheData.data(ii).correction.postreceptoralContrasts = postreceptoralContrastsPos;
        else
            cacheData.data(ii).describe = [];
            cacheData.data(ii).backgroundPrimary = [];
            cacheData.data(ii).backgroundSpd = [];
            cacheData.data(ii).differencePrimary = [];
            cacheData.data(ii).differenceSpd = [];
            cacheData.data(ii).modulationPrimarySignedPositive = [];
            cacheData.data(ii).modulationPrimarySignedNegative = [];
            cacheData.data(ii).modulationSpdSignedPositive = [];
            cacheData.data(ii).modulationSpdSignedNegative = [];
            cacheData.data(ii).ambientSpd = [];
            cacheData.data(ii).operatingPoint = [];
            cacheData.data(ii).computeMethod = [];
        end
    end
    
    % Turn the OneLight mirrors off.
    ol.setAll(false);
    
    % Close the radiometer
    if (spectroRadiometerOBJWillShutdownAfterMeasurement)
        if (~isempty(spectroRadiometerOBJ))
            spectroRadiometerOBJ.shutDown();
            openSpectroRadiometerOBJ = [];
        end
    end
    
    % Check if we want to do splatter calculations
    try
        OLAnalyzeValidationReceptorIsolate(validationPath, 'short');
    end
catch e
    if (~isempty(spectroRadiometerOBJ))
        spectroRadiometerOBJ.shutDown();
        openSpectroRadiometerOBJ = [];
    end
    rethrow(e)
end
