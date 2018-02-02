function OLMakeDirectionCorrectedPrimaries(ol,protocolParams,varargin)
%%OLMakeDirectionCorrectedPrimaries  Make the corrected primaries from the nominal primaries
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
%    getpref(protocolParams.protocol, 'DirectionCorrectedPrimariesBasePath');
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
% 8/21/17  dhb       Add protocol params to what is save out. We may want this later for analysis.
% 09/25/17 dhb       Change name of the flag that determines whether corrections get done to correctBySimulation.
%                    The sense of this is flipped from the old name, and this flip was implemented in the call to
%                    OLCorrectCacheFileOOC, where a ~ was added to the value for the 'doCorretion' flag.

%% Parse input to get key/value pairs
p = inputParser;
p.addParameter('verbose',true,@islogical);
p.parse(varargin{:});

%% Update session log file
OLSessionLog(protocolParams,mfilename,'StartEnd','start');

%% Grab the relevant directions name and get the cache file name
theDirections = protocolParams.directionNames;
directionCacheFileNames = OLMakeDirectionCacheFileNames(protocolParams);

%% Make sure we have booleans for all of the passed directions
assert(numel(protocolParams.directionNames) == numel(protocolParams.correctBySimulation), 'protocolParams.correctBySimulation does not have the same length protocolParams.directionNames');
theCorrectBySimulation = protocolParams.correctBySimulation;

%% Get dir where the nominal and corrected primaries live
%
% Need to change over to use the directly specified preference rather than to build it up.
nominalPrimariesDir =  fullfile(getpref(protocolParams.approach, 'DirectionNominalPrimariesPath'));
correctedPrimariesDir = fullfile(getpref(protocolParams.protocol, 'DirectionCorrectedPrimariesBasePath'), protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
if(~exist(correctedPrimariesDir,'dir'))
    mkdir(correctedPrimariesDir);
end

%% Obtain correction params from OLCorrectionParamsDictionary
%
% This is box specific, and specified as protocolParams.boxName
corrD = OLCorrectionParamsDictionary();
if (p.Results.verbose), fprintf('\nSpectrum seeking\n\tGetting correction params for %s\n', protocolParams.boxName); end
correctionParams = corrD(protocolParams.boxName);

%% Open up a radiometer object
if (~protocolParams.simulate.oneLight)
    [spectroRadiometerOBJ,S] = OLOpenSpectroRadiometerObj('PR-670');
else
    spectroRadiometerOBJ = [];
    S = [];
end

%% Open up lab jack for temperature measurements
if (~protocolParams.simulate.oneLight & protocolParams.takeTemperatureMeasurements)
    % Gracefully attempt to open the LabJack.  If it doesn't work and the user OK's the
    % change, then the takeTemperature measurements flag is set to false and we proceed.
    % Otherwise it either worked (good) or we give up and throw an error.
    [protocolParams.takeTemperatureMeasurements, quitNow, theLJdev] = OLCalibrator.OpenLabJackTemperatureProbe(protocolParams.takeTemperatureMeasurements);
    if (quitNow)
        error('Unable to get temperature measurements to work as requested');
    end
else
    theLJdev = [];
end

%% Loop through and do correction for each desired direction.

for corrD = 1:length(theDirections)
    if (protocolParams.doCorrectionAndValidationFlag{corrD})
        % Print out some information
        if (p.Results.verbose), fprintf('\n\tDirection: %s\n', theDirections{corrD}); end
        if (p.Results.verbose), fprintf('\tObserver: %s\n', protocolParams.observerID); end
        
        % Correct the cache
        if (p.Results.verbose), fprintf('\tStarting spectrum-seeking loop\n'); end
        [cacheData, cal] = OLCorrectCacheFileOOC(sprintf('%s.mat', fullfile(nominalPrimariesDir, directionCacheFileNames{corrD})), ol, spectroRadiometerOBJ, S, theLJdev, ...
            'approach',                     protocolParams.approach, ...
            'simulate',                     protocolParams.simulate.oneLight, ...
            'doCorrection',                 ~theCorrectBySimulation(corrD), ...
            'observerAgeInYrs',             protocolParams.observerAgeInYrs, ...
            'calibrationType',              protocolParams.calibrationType, ...
            'takeTemperatureMeasurements',  protocolParams.takeTemperatureMeasurements, ...
            'learningRate',                 correctionParams.learningRate, ...
            'learningRateDecrease',         correctionParams.learningRateDecrease, ...
            'asympLearningRateFactor',      correctionParams.asympLearningRateFactor, ...
            'smoothness',                   correctionParams.smoothness, ...
            'iterativeSearch',              correctionParams.iterativeSearch, ...
            'nIterations',                  correctionParams.nIterations, ...
            'verbose',                      p.Results.verbose);
        if (p.Results.verbose), fprintf('\tSpectrum seeking loop finished!\n'); end
        
        % Save the cache
        olCache = OLCache(correctedPrimariesDir,cal);
        protocolParams.modulationDirection = theDirections{corrD};
        protocolParams.cacheFile = fullfile(correctedPrimariesDir, directionCacheFileNames{corrD});
        cacheData.protocolParams = protocolParams;
        olCache.save(protocolParams.cacheFile, cacheData);
        if (p.Results.verbose), fprintf('\tCache saved to %s\n', protocolParams.cacheFile); end
    end
end
%% Close the radiometer object
if (~protocolParams.simulate.oneLight)
    if (~isempty(spectroRadiometerOBJ))
        spectroRadiometerOBJ.shutDown();
    end
    
    if (~isempty(theLJdev))
        theLJdev.close;
    end
end

%% Update session log info
protocolParams = OLSessionLog(protocolParams,mfilename,'StartEnd','end');
