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
%    The output is cached in a directory specified by
%    getpref(protocolParams.approach, 'DirectionCorrectedPrimariesBasePath');

% 6/18/17  dhb       Added header comments.  Renamed.
% 6/19/17  mab, jr   Added saving the cache data to the outDir location specified in OLCorrectCacheFileOOC.m  

%% Update Session Log File
protocolParams = OLSessionLog(protocolParams,mfilename,'StartEnd','start');

%% Grab the relevant directions name and get the cache file name
theDirections = protocolParams.directionNames;
theDirectionCacheFileNames = OLMakeDirectionCacheFileNames(protocolParams);

%% Make sure we have booleans for all of the passed directions
assert(numel(protocolParams.directionNames) == numel(protocolParams.directionsCorrect), 'protocolParams.directionsCorrect does not have the same length protocolParams.directionNames');
theDirectionsCorrect = protocolParams.directionsCorrect;

%% Get dir where the nominal and corrected primaries live
%
% Need to change over to use the directly specified preference rather than to build it up.
nominalPrimariesDir =  fullfile(getpref(protocolParams.approach, 'DirectionNominalPrimariesPath'));
correctedPrimariesDir = fullfile(getpref(protocolParams.approach, 'DirectionCorrectedPrimariesBasePath'), protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
if(~exist(correctedPrimariesDir,'dir'))
    mkdir(correctedPrimariesDir);
end

%% Obtain correction params from OLCorrectionParamsDictionary
%
% This is box specific, and specified as protocolParams.boxName
d = OLCorrectionParamsDictionary();
if (protocolParams.verbose), fprintf('* Getting correction params for <strong>%s</strong>\n', protocolParams.boxName); end;
correctionParams = d(protocolParams.boxName);

%% Loop through and do correction for each desired direction.
for d = 1:length(theDirections)
  
    % Print out some information
    if (protocolParams.verbose), fprintf(' * Direction:\t<strong>%s</strong>\n', theDirections{d}); end;
    if (protocolParams.verbose), fprintf(' * Observer:\t<strong>%s</strong>\n', protocolParams.observerID); end;
    if (protocolParams.verbose), fprintf(' * Date:\t<strong>%s</strong>\n', protocolParams.todayDate); end;
    
    % Correct the cache
    if (protocolParams.verbose), fprintf(' * Starting spectrum-seeking loop...\n'); end;
    
    [cacheData, cal] = OLCorrectCacheFileOOC(...
        sprintf('%s.mat', fullfile(nominalPrimariesDir, theDirectionCacheFileNames{d})),'PR-670', ...
        'doCorrection',                 theDirectionsCorrect(d), ...
        'outDir',                       fullfile(correctedPrimariesDir, protocolParams.observerID), ...
        'OBSERVER_AGE',                 protocolParams.observerAgeInYrs, ...
        'calibrationType',              protocolParams.calibrationType, ...
        'takeTemperatureMeasurements',  protocolParams.takeTemperatureMeasurements, ...
        'approach',                     protocolParams.approach, ...
        'ReducedPowerLevels',           correctionParams.reducedPowerLevels, ...
        'learningRate',                 correctionParams.learningRate, ...
        'learningRateDecrease',         correctionParams.learningRateDecrease, ...
        'asympLearningRateFactor',      correctionParams.asympLearningRateFactor, ...
        'smoothness',                   correctionParams.smoothness, ...
        'iterativeSearch',              correctionParams.iterativeSearch, ...
        'NIter',                        correctionParams.iterationsNum, ...
        'powerLevels',                  correctionParams.powerLevels, ...
        'postreceptoralCombinations',   correctionParams.postreceptoralCombinations, ...
        'useAverageGamma',              correctionParams.useAverageGamma, ...
        'zeroPrimariesAwayFromPeak',    correctionParams.zeroPrimariesAwayFromPeak, ...
        'emailRecipient',               protocolParams.emailRecipient, ...
        'verbose',                      protocolParams.verbose);    

    if (protocolParams.verbose), fprintf(' * Spectrum seeking finished!\n'); end;
    
    % Save the cache
    if (protocolParams.verbose), fprintf(' * Saving cache ...'); end;
    olCache = OLCache(correctedPrimariesDir,cal);
    protocolParams.modulationDirection = theDirections{d};
    protocolParams.cacheFile = fullfile(nominalPrimariesDir, theDirectionCacheFileNames{d});
    if (protocolParams.verbose), fprintf('Cache saved to %s\n', protocolParams.cacheFile); end
    olCache.save(protocolParams.cacheFile, cacheData);
    if (protocolParams.verbose), fprintf('Cache saved to %s\n', protocolParams.cacheFile); end
end

%% Update session log info
protocolParams = OLSessionLog(protocolParams,mfilename,'StartEnd','end');
