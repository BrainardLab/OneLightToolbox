function OLMakeDirectionCorrectedPrimaries(ol,protocolParams,varargin)
%OLMakeDirectionCorrectedPrimaries  Make the corrected primaries from the nominal primaries
%
% Syntax:
%    OLMakeDirectionCorrectedPrimaries(ol,protocolParams);
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
%
% Input:
%     ol (object)            Open OneLight object.
%     protocolParams         Protocol parameters structure.
%
% Optional key/value pairs
%     'verbose' (boolean)    Print out diagnostic information?
% 
% See also: OLCorrectCacheFileOOC, OLGetCacheAndCalData.

% 6/18/17  dhb       Added header comments.  Renamed.
% 6/19/17  mab, jr   Added saving the cache data to the outDir location specified in OLCorrectCacheFileOOC.m 

%% Parse input to get key/value pairs
p = inputParser;
p.addParameter('verbose',true,@islogical);
p.parse(varargin{:});

%% Update session log file
OLSessionLog(protocolParams,mfilename,'StartEnd','start');

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
corrD = OLCorrectionParamsDictionary();
if (p.Results.verbose), fprintf('* Getting correction params for <strong>%s</strong>\n', protocolParams.boxName); end;
correctionParams = corrD(protocolParams.boxName);

%% Loop through and do correction for each desired direction.
for corrD = 1:length(theDirections)
  
    % Print out some information
    if (p.Results.verbose), fprintf(' * Direction:\t<strong>%s</strong>\n', theDirections{corrD}); end;
    if (p.Results.verbose), fprintf(' * Observer:\t<strong>%s</strong>\n', protocolParams.observerID); end;
    if (p.Results.verbose), fprintf(' * Date:\t<strong>%s</strong>\n', protocolParams.todayDate); end;
    
    % Correct the cache
    if (p.Results.verbose), fprintf(' * Starting spectrum-seeking loop...\n'); end;
    [cacheData, cal] = OLCorrectCacheFileOOC(sprintf('%s.mat', fullfile(nominalPrimariesDir, theDirectionCacheFileNames{corrD})),ol, 'PR-670', ...
        'approach',                     protocolParams.approach, ...
        'simulate',                     protocolParams.simulate, ...
        'doCorrection',                 theDirectionsCorrect(corrD), ...
        'observerAgeInYrs',             protocolParams.observerAgeInYrs, ...
        'calibrationType',              protocolParams.calibrationType, ...
        'takeTemperatureMeasurements',  protocolParams.takeTemperatureMeasurements, ...
        'learningRate',                 correctionParams.learningRate, ...
        'learningRateDecrease',         correctionParams.learningRateDecrease, ...
        'asympLearningRateFactor',      correctionParams.asympLearningRateFactor, ...
        'smoothness',                   correctionParams.smoothness, ...
        'iterativeSearch',              correctionParams.iterativeSearch, ...
        'nIterations',                  correctionParams.nIterations, ...
        'postreceptoralCombinations',   correctionParams.postreceptoralCombinations, ...
        'useAverageGamma',              correctionParams.useAverageGamma, ...
        'zeroPrimariesAwayFromPeak',    correctionParams.zeroPrimariesAwayFromPeak, ...
        'emailRecipient',               protocolParams.emailRecipient, ...
        'verbose',                      p.Results.verbose);    
    if (p.Results.verbose), fprintf(' * Spectrum seeking finished!\n'); end;
    
    % Save the cache
    if (p.Results.verbose), fprintf(' * Saving cache ...'); end;
    olCache = OLCache(correctedPrimariesDir,cal);
    protocolParams.modulationDirection = theDirections{corrD};
    protocolParams.cacheFile = fullfile(nominalPrimariesDir, theDirectionCacheFileNames{corrD});
    if (p.Results.verbose), fprintf('Cache saved to %s\n', protocolParams.cacheFile); end
    olCache.save(protocolParams.cacheFile, cacheData);
    if (p.Results.verbose), fprintf('Cache saved to %s\n', protocolParams.cacheFile); end
end

%% Update session log info
protocolParams = OLSessionLog(protocolParams,mfilename,'StartEnd','end');
