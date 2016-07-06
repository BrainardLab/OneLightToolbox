
function OLMakeModulations(configFileName, observerAgeInYears, calType, nullingID, protocolDir)
% OLMakeModulations - Creates the cache data for a given config file.
%
% Syntax:
% OLMakeModulations(configFileName)
% OLMakeModulations(configFileName, forceRecompute)
%
% Description:
%
%
% Input:
% configFileName (string) - The name of the config file, e.g.
%     flickerconfig.cfg.  Only the simple name of the config file needs to
%     be specified.  The path to the config directory will be inferred.
% forceRecompute (logical) - If true, forces a recompute of the data found
%     in the config file.  Only do this if the target spectra were changed.
%     Default: false
%
% Use:
%
% OLMakeModulations('OLFlickerSensitivity-Background-OLEyeTrackerLongCableEyePiece1.cfg')
%
% 4/19/13   dhb, ms     Update for new convention for desired contrasts in routine ReceptorIsolate.

%% Housekeeping
% Validate the number of inputs.
%error(nargchk(1, 3, nargin));

% Setup the directories we'll use.  We count on the
% standard relative directory structure that we always
% use in our (BrainardLab) experiments.
baseDir = '/Users/Shared/Matlab/Experiments/OneLight/OLFlickerSensitivity/code/';
configDir = fullfile(baseDir, 'config', 'modulations');
cacheDir = fullfile(baseDir, 'cache', 'stimuli');
cacheDir = fullfile(getpref('OneLight', 'cachePath'), 'stimuli');

% Make sure the config file is a fully qualified name including the parent
% path.
configFileName = fullfile(configDir, configFileName);

% Make sure the config file exists.
assert(logical(exist(configFileName, 'file')), 'OLMakeModulations:InvalidCacheFile', ...
    'Could not find config file: %s', configFileName);

% Read the config file and convert it to a struct.
cfgFile = ConfigFile(configFileName);

% Convert all the ConfigFile parameters into simple struct values.
params = convertToStruct(cfgFile);
params.cacheDir = cacheDir;
params.modulationDir = modulationDir;

% Load the calibration file.
if ~isempty(calType)
    params.calibrationType = calType;
end
cType = OLCalibrationTypes.(params.calibrationType);
params.oneLightCal = LoadCalFile(cType.CalFileName);

% Setup the cache.
params.olCache = OLCache(params.cacheDir, params.oneLightCal);

file_names = allwords(params.directionCacheFile,',');
for i = 1:length(file_names)
    % Create the cache file name.
    [~, params.cacheFileName{i}] = fileparts(file_names{i});
end

%% Iterate over the cache files to be loaded in.
for i = 1:length(params.cacheFileName)
    % Load the cache data.
    cacheData{i} = params.olCache.load(params.cacheFileName{i});
    
    % Store the internal date of the cache data we're using.  The cache
    % data date is a unique timestamp identifying a specific set of cache
    % data. We want to save that to associate data sets to specific
    % versions of the cache file.
    params.cacheDate{i} = cacheData{i}.date;
end

cacheData = cacheData{end}.data(observerAgeInYears);
params.cacheData = cacheData;

%% Store out the primaries from the cacheData into a cell.  The length of
% cacheData corresponds to the number of different stimuli that are being
% shown
fprintf(['\n* Running precalculations for ' params.preCacheFile '\n']);


if isempty(strfind(params.direction, 'DoublePulse'));
    % Get the background
    backgroundPrimary = cacheData.backgroundPrimary;
    
    % Do something else if we are used nulled settings
    if ~isempty(nullingID)
        dataFile = [nullingID '-nulling-1.mat'];
        tmp = load(fullfile(protocolDir, dataFile));
        % Not too sustainable but works for now.
        switch params.direction
            case 'MelanopsinDirectedUnnulled'
                modulationPrimary = backgroundPrimary+tmp.nulling{1, 1}.params.scalarPrimary*tmp.nulling{1, 1}.primaryNulling;
            case 'MelanopsinDirectedNulled'
                modulationPrimary = backgroundPrimary+tmp.nullingaverages{1}.differencePrimary;
            case 'MelanopsinDirectedLegacyNulled'
                modulationPrimary = backgroundPrimary+tmp.nullingaverages{1}.differencePrimary;
            case {'MelanopsinDirectedPenumbralIgnoreNulledPositive' 'MelanopsinDirectedPenumbralIgnoreNulledNegative'};
                modulationPrimary = backgroundPrimary+tmp.nullingaverages{1}.differencePrimary;
            case {'LMSDirectedNulled' 'LMSDirectedNulledPositive' 'LMSDirectedNulledNegative'};
                modulationPrimary = backgroundPrimary+tmp.nullingaverages{2}.differencePrimary;
            case 'NulledResidualSplatter'
                modulationPrimary = backgroundPrimary+tmp.nullingaverages{1}.nulledResidualPrimary;
            case {'Background' 'ConeNoiseOnly' 'BackgroundConeNoise'}
                modulationPrimary = backgroundPrimary;
            case 'LightFlux'
                modulationPrimary = cacheData.modulationPrimarySignedPositive;
            otherwise
                fprintf('**** NOT USING NULLED SETTINGS ****\n');
                % Get the modulation primary
                if strfind(params.preCacheFile, 'Background') % Background case
                    modulationPrimary = backgroundPrimary;
                else
                    modulationPrimary = cacheData.modulationPrimarySignedPositive;
                end
        end
        
        % Save to specific file
        params.observerAgeInYears = observerAgeInYears;
        [~, fileName, fileSuffix] = fileparts(params.preCacheFile);
        params.preCacheFile = [fileName '-' nullingID fileSuffix];
        params.preCacheFileFull = [fileName '-' nullingID '-full' fileSuffix];
        
    else
        
        % Get the modulation primary
        if strfind(params.preCacheFile, 'Background') % Background case
            modulationPrimary = backgroundPrimary;
        else
            modulationPrimary = cacheData.modulationPrimarySignedPositive;
        end
        % Save to specific file
        params.observerAgeInYears = observerAgeInYears;
        [~, fileName, fileSuffix] = fileparts(params.preCacheFile);
        params.preCacheFile = [fileName '-' num2str(params.observerAgeInYears) fileSuffix];
        params.preCacheFileFull = [fileName '-' num2str(params.observerAgeInYears) '-full' fileSuffix];
    end
    
    % Set up a few flags here
    [~, describe.modulationName] = fileparts(params.preCacheFile);
    describe.direction = params.direction;
    describe.date = datestr(now);
    describe.cal = params.oneLightCal;
    describe.calID = OLGetCalID(params.oneLightCal);
    describe.cacheDate = params.cacheDate;
    describe.params = params;
    describe.theFrequenciesHz = describe.params.carrierFrequency;
    describe.thePhasesDeg = describe.params.carrierPhase;
    describe.theContrastRelMax = describe.params.contrastScalars;
    
    
    for f = 1:params.nFrequencies
        for p = 1:params.nPhases
            for c = 1:params.nContrastScalars
                % Construct the time vector
                if strcmp(params.modulationMode, 'AM')
                    waveform.theEnvelopeFrequencyHz = params.modulationFrequencyTrials(1); % Modulation frequency
                    waveform.thePhaseDeg = params.modulationPhase(p);
                    waveform.thePhaseRad = deg2rad(params.modulationPhase(p));
                    waveform.theFrequencyHz = params.carrierFrequency(f);
                elseif ~isempty(strfind(params.modulationMode, 'pulse'))
                    waveform.phaseRandSec = params.phaseRandSec(p);
                    waveform.stepTimeSec = params.stepTimeSec(f);
                    waveform.preStepTimeSec = params.preStepTimeSec(f);
                    waveform.theFrequencyHz = -1;
                    waveform.thePhaseDeg = -1;
                else
                    waveform.thePhaseDeg = params.carrierPhase(p);
                    waveform.thePhaseRad = deg2rad(params.carrierPhase(p));
                    waveform.theFrequencyHz = params.carrierFrequency(f);
                end
                
                waveform.direction = params.direction;
                waveform.modulationPrimary = modulationPrimary;
                waveform.backgroundPrimary = backgroundPrimary;
                waveform.modulationWaveform = params.modulationWaveForm;
                waveform.modulationMode = params.modulationMode;
                
                if isfield(params, 'coneNoise')
                    if params.coneNoise
                        if strcmp(params.stimulationMode, 'peripheral')
                            % LMS
                            cacheDataTmp = params.olCache.load('Cache-LMSDirectedNoise.mat');
                            cacheDataNoisePrimary{1} = cacheDataTmp.data(observerAgeInYears).differencePrimary;
                            % L-M
                            cacheDataTmp = params.olCache.load('Cache-LMinusMDirectedNoise.mat');
                            cacheDataNoisePrimary{2} = cacheDataTmp.data(observerAgeInYears).differencePrimary;
                        elseif strcmp(params.stimulationMode, 'foveal')
                            % LMS
                            cacheDataTmp = params.olCache.load('Cache-LMSDirectedNoiseFoveal.mat');
                            cacheDataNoisePrimary{1} = cacheDataTmp.data(observerAgeInYears).differencePrimary;
                            % L-M
                            cacheDataTmp = params.olCache.load('Cache-LMinusMDirectedNoiseFoveal.mat');
                            cacheDataNoisePrimary{2} = cacheDataTmp.data(observerAgeInYears).differencePrimary;
                        elseif strcmp(params.stimulationMode, 'maxmel')
                            % LMS
                            cacheDataTmp = params.olCache.load('Cache-LMSDirectedNoiseMaxMel.mat');
                            cacheDataNoisePrimary{1} = cacheDataTmp.data(observerAgeInYears).differencePrimary;
                            % L-M
                            cacheDataTmp = params.olCache.load('Cache-LMinusMDirectedNoiseMaxMel.mat');
                            cacheDataNoisePrimary{2} = cacheDataTmp.data(observerAgeInYears).differencePrimary;
                        end
                        
                        % Make the noise vector
                        t = 0:params.timeStep:params.trialDuration-params.timeStep;
                        startIdx = 1:(1/(params.timeStep))/(params.coneNoiseFrequency):length(t);
                        endIdx = (1/(params.timeStep))/(params.coneNoiseFrequency):(1/(params.timeStep))/(params.coneNoiseFrequency):length(t);
                        nSamples = length(startIdx);
                        nContrastLevels = 11;
                        
                        possibleLevels = linspace(-1, 1, nContrastLevels);
                        theRand = possibleLevels(randi(nContrastLevels, 2, nSamples));
                        
                        for i = 1:length(startIdx)
                            sampleSuccessful = false;
                            while ~sampleSuccessful
                                noiseScalarLMS = possibleLevels(randi(nContrastLevels, 1, 1));
                                noiseScalarLMinusM = possibleLevels(randi(nContrastLevels, 1, 1));
                                tmpPrimary1 = modulationPrimary + noiseScalarLMS*cacheDataNoisePrimary{1} + noiseScalarLMinusM*cacheDataNoisePrimary{2};
                                tmpPrimary2 = backgroundPrimary + noiseScalarLMS*cacheDataNoisePrimary{1} + noiseScalarLMinusM*cacheDataNoisePrimary{2};
                                if ~(any(tmpPrimary1 > 1) | any(tmpPrimary1 < 0) | any(tmpPrimary2 > 1) | any(tmpPrimary2 < 0))
                                    sampleSuccessful = true;
                                else
                                    fprintf('* Within-gamut sample not successful at %.2f LMS and %.2f L-M, drawing another sample...\n', noiseScalarLMS, noiseScalarLMinusM);
                                end
                            end
                            noiseVectorLMS(startIdx(i):endIdx(i)) = noiseScalarLMS;
                            noiseVectorLMinusM(startIdx(i):endIdx(i)) = noiseScalarLMinusM;
                        end
                        
                        for i = 1:length(t)
                            theNoisePrimaries(:, i) = noiseVectorLMS(i)*cacheDataNoisePrimary{1} ... % LMS
                                + noiseVectorLMinusM(i)*cacheDataNoisePrimary{2};
                        end
                        waveform.noise.noisePrimary = theNoisePrimaries;
                    end
                end
                
                
                waveform.theContrastRelMax = params.contrastScalars(c);
                waveform.duration = params.trialDuration;      % Trial duration
                waveform.cal = params.oneLightCal;
                waveform.calID = OLGetCalID(params.oneLightCal);
                waveform.t = 0:params.timeStep:waveform.duration-params.timeStep;  % Time vector
                
                waveform.window.cosineWindowIn = params.cosineWindowIn;
                waveform.window.cosineWindowOut = params.cosineWindowOut;
                waveform.window.cosineWindowDurationSecs = params.cosineWindowDurationSecs;
                waveform.window.type = 'cosine';
                waveform.window.nWindowed = params.cosineWindowDurationSecs/params.timeStep;
                
                fprintf('* Calculating %0.f s of %s, %.2f Hz, %.2f deg, %.1f pct contrast (of max)\n         ', waveform.duration, waveform.direction, waveform.theFrequencyHz, waveform.thePhaseDeg, 100*waveform.theContrastRelMax);
                % Calculate it.
                modulation(f, p, c) = OLCalculateStartsStopsModulation(waveform, describe.cal, backgroundPrimary, modulationPrimary-backgroundPrimary);
                fprintf('  - Done.\n');
            end
        end
    end
end

params = rmfield(params, 'olCache'); % Throw away the olCache field

% Put everything into a modulation
modulationObj.modulation = modulation;
modulationObj.describe = describe;
modulationObj.waveform = waveform;
modulationObj.params = params;

fprintf(['* Saving full pre-calculated settings to ' params.preCacheFile '\n']);
save(fullfile(params.modulationDir, params.preCacheFile), 'modulationObj', '-v7.3');
fprintf('  - Done.\n');
params = [];
