function protocolParams = OLMakeDirectionCorrectedPrimaries(protocolParams)
%OLMakeDirectionCorrectedPrimaries - Make the corrected primaries from the nominal primaries
%
% Description:
%    The nominal primaries do not exactly have the desired properties,
%    because the OneLight does not exactly conform to its calibration
%    assumptions.  To deal with these, we use a spectrum seeking procedure
%    to tune up (aka "correct") the nominal primaries.  This routine does
%    that.
%
%    This is sufficiently time consuming that we only do it for the age of
%    the observer who is about to run.
%
%    The output is cached in the directory specified by
%    getpref('MaxPulsePsychophysics','DirectionCorrectedPrimariesDir');

% 6/18/17  dhb       Added header comments.  Renamed.
% 6/19/17  mab, jr   Added saving the cache data to the outDir location specified in OLCorrectCacheFileOOC.m  

% Modify with a "copy" versus "seek" flag.  This would determine whether it
% just copies over the nominal primaries (with appropriate name) or seeks
% and creates the whole shebang.

% Clear and close, set debugger if desired

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Correct the spectrum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic;

%% Update Session Log File
protocolParams = OLSessionLog(protocolParams,mfilename,'StartEnd','start');

theDirections = protocolParams.directionNames; % {'MaxMel' 'MaxLMS' 'LightFluxMaxPulse' };
theDirectionCacheFileNames = OLMakeDirectionCacheFileNames(protocolParams);

theDirectionsCorrect = [true true];
spectroRadiometerOBJ=[];
% CorrectedPrimariesDir is MELA_materials.../DirectionNominalPrimaries
NominalPrimariesDir =  fullfile(getpref(protocolParams.approach, 'MaterialsPath'), 'Experiments',protocolParams.approach,'DirectionNominalPrimaries');
% materialsPath, please rename, and send to
% MELA_materials.../DirectionCorrectedPrimaries
CorrectedPrimariesDir = fullfile(getpref(protocolParams.approach, 'DataPath'), 'Experiments', protocolParams.approach, protocolParams.protocol, 'DirectionCorrectedPrimaries', protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
if(~exist(CorrectedPrimariesDir))
    mkdir(CorrectedPrimariesDir)
end

for d = 1:length(theDirections)
    
    if (~theDirectionsCorrect(d))
         fprintf(' * Skipping direction:\t<strong>%s</strong>\n', theDirections{d});
        continue;
    end
    % Print out some information
    fprintf(' * Direction:\t<strong>%s</strong>\n', theDirections{d});
    fprintf(' * Observer:\t<strong>%s</strong>\n', protocolParams.observerID);
    fprintf(' * Date:\t<strong>%s</strong>\n', protocolParams.todayDate);
    
    % Correct the cache
    fprintf(' * Starting spectrum-seeking loop...\n');
    
    % THIS IS OUR ATTEMPT TO DO IT THE OLD WAY WITH THE NEW CODE.  THIS IS BOX D.  THIS IS ALSO OUR BEST
    % CURRENT GUESS FOR BOX A.
    [cacheData, olCache, spectroRadiometerOBJ, cal] = OLCorrectCacheFileOOC(...
        sprintf('%s.mat', fullfile(NominalPrimariesDir, theDirectionCacheFileNames{d})), ...
        'jryan@mail.med.upenn.edu', ...
        'PR-670', spectroRadiometerOBJ, protocolParams.spectroRadiometerOBJWillShutdownAfterMeasurement, ...
        'FullOnMeas', false, ...
        'CalStateMeas', false, ...
        'DarkMeas', false, ...
        'OBSERVER_AGE', protocolParams.observerAgeInYrs, ...
        'ReducedPowerLevels', false, ...
        'selectedCalType', protocolParams.calibrationType, ...
        'CALCULATE_SPLATTER', false, ...
        'learningRate', 0.8, ...
        'learningRateDecrease', false, ...
        'asympLearningRateFactor',0.5, ...
        'smoothness', 0.1, ...
        'iterativeSearch', false, ...
        'NIter', 1, ...
        'powerLevels', [0 1.0000], ...
        'doCorrection', theDirectionsCorrect(d), ...
        'postreceptoralCombinations', [1 1 1 0 ; 1 -1 0 0 ; 0 0 1 0 ; 0 0 0 1], ...
        'outDir', fullfile(CorrectedPrimariesDir, protocolParams.observerID), ... %fullfile(CorrectedPrimariesDir, 'MaxPulsePsychophysics', params.todayDate),
        'takeTemperatureMeasurements', protocolParams.takeTemperatureMeasurements, ...
        'useAverageGamma', false, ...
        'zeroPrimariesAwayFromPeak', false, ...
        'simulate', protocolParams.simulate, ...
        'approach', protocolParams.approach);

% THIS IS SET UP TO DO IT THE NEW WAY.  THIS IS BOX B.  ALSO OUR BEST CURRENT GUESS FOR BOX C.
%        [cacheData olCache spectroRadiometerOBJ] = OLCorrectCacheFileOOC(...
%         fullfile(NominalPrimariesDir, ['Direction_' theDirections{d} '.mat']), ...
%         'jryan@mail.med.upenn.edu', ...
%         'PR-670', spectroRadiometerOBJ, spectroRadiometerOBJWillShutdownAfterMeasurement, ...
%         'FullOnMeas', false, ...
%         'CalStateMeas', false, ...
%         'DarkMeas', false, ...
%         'OBSERVER_AGE', params.observerAgeInYrs, ...
%         'ReducedPowerLevels', false, ...
%         'selectedCalType', theCalType, ...
%         'CALCULATE_SPLATTER', false, ...
%         'learningRate', 0.5, ...
%         'learningRateDecrease', true, ...
%         'asympLearningRateFactor',0.5, ...
%         'smoothness', 0.001, ...
%         'iterativeSearch', true, ...
%         'NIter', 20, ...
%         'powerLevels', [0 1.0000], ...
%         'doCorrection', theDirectionsCorrect(d), ...
%         'postreceptoralCombinations', [1 1 1 0 ; 1 -1 0 0 ; 0 0 1 0 ; 0 0 0 1], ...
%         'outDir', fullfile(CorrectedPrimariesDir, params.observerID), ...
%         'takeTemperatureMeasurements', params.takeTemperatureMeasurements, ...
%         'useAverageGamma', true, ...
%         'zeroPrimariesAwayFromPeak', true);
    fprintf(' * Spectrum seeking finished!\n');
    
    % Save the cache
    fprintf(' * Saving cache ...');
    olCache = OLCache(CorrectedPrimariesDir,cal);
    %zparams = cacheData.data(zparams.observerAgeInYrs).describe.zparams;
    protocolParams.modulationDirection = theDirections{d};
    protocolParams.cacheFile = fullfile(NominalPrimariesDir, theDirectionCacheFileNames{d});
    fprintf('Cache saved to %s\n', protocolParams.cacheFile);
    olCache.save(protocolParams.cacheFile, cacheData);
    fprintf('done!\n');
end

if (~isempty(spectroRadiometerOBJ))
    spectroRadiometerOBJ.shutDown();
    spectroRadiometerOBJ = [];
end

protocolParams = OLSessionLog(protocolParams,mfilename,'StartEnd','end');
toc;