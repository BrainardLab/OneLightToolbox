function OLMakeDirectionCorrectedPrimaries(protocolParams, oneLight, radiometer, varargin)
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
%    temperatureProbe - LJTemperatureProbe object to drive a LabJack
%                       temperature probe
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
p.addRequired('protocolParams',@isstruct);
p.addRequired('oneLight',@(x) isa(x,'OneLight'));
p.addRequired('radiometer',@(x) isempty(x) || isa(x,'Radiometer'));
p.addParameter('verbose',true,@islogical);
p.addParameter('temperatureProbe',[],@(x) isempty(x) || isa(x,'LJTemperatureProbe'));
p.parse(protocolParams, oneLight, radiometer, varargin{:});

%% Update session log file
OLSessionLog(protocolParams,mfilename,'StartEnd','start');

%% Grab the relevant directions name and get the cache file name
theDirections = unique(protocolParams.directionNames);

%% Make sure we have booleans for all of the passed directions
assert(numel(protocolParams.directionNames) == numel(protocolParams.correctBySimulation), 'protocolParams.correctBySimulation does not have the same length protocolParams.directionNames');

%% Get dir where the nominal and corrected primaries live
%
% Need to change over to use the directly specified preference rather than to build it up.
nominalPrimariesDir =  fullfile(getpref(protocolParams.approach, 'DirectionNominalPrimariesPath'));
correctedPrimariesDir = fullfile(getpref(protocolParams.protocol, 'DirectionCorrectedPrimariesBasePath'), protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
if(~exist(correctedPrimariesDir,'dir'))
    mkdir(correctedPrimariesDir);
end

%% Obtain correction params from OLCorrectionParamsDictionary
% This is box specific, and specified as protocolParams.boxName
corrD = OLCorrectionParamsDictionary();
if (p.Results.verbose), fprintf('\nSpectrum seeking\n\tGetting correction params for %s\n', protocolParams.boxName); end
correctionParams = corrD(protocolParams.boxName);

%% Loop through and do correction for each desired direction.
for corrD = 1:length(theDirections)
        % Print out some information
        if (p.Results.verbose), fprintf('\n\tDirection: %s\n', theDirections{corrD}); end
        
        % Get cached direction
        nominalCacheFileName = fullfile(nominalPrimariesDir, sprintf('Direction_%s.mat', theDirections{corrD}));
        [cacheData,calibration] = OLGetCacheAndCalData(nominalCacheFileName, protocolParams);
        
        % Get directionStruct to correct
        nominalDirectionStruct = cacheData.data(protocolParams.observerAgeInYrs);
        
        % Correct direction struct
        if (p.Results.verbose), fprintf('\tStarting spectrum-seeking loop\n'); end        
        correctedDirectionStruct = OLCorrectDirection(nominalDirectionStruct, calibration, oneLight, radiometer,...
            'nIterations', correctionParams.nIterations,...
            'learningRate', correctionParams.learningRate,...
            'learningRateDecrease',  correctionParams.learningRateDecrease,...
            'asympLearningRateFactor', correctionParams.asympLearningRateFactor,...
            'smoothness', correctionParams.smoothness,...
            'iterativeSearch', correctionParams.iterativeSearch);
        if (p.Results.verbose), fprintf('\tSpectrum seeking loop finished!\n'); end
        
        % Store information about corrected modulations for return.
        % Since this routine only does the correction for one age, we set the
        % data for that and zero out all the rest, just to avoid accidently
        % thinking we have corrected spectra where we do not.
        for ii = 1:length(cacheData.data)
            if ii == protocolParams.observerAgeInYrs
                cacheData.data(ii) = correctedDirectionStruct;
            else
                cacheData.data(ii).describe = [];
                cacheData.data(ii).backgroundPrimary = [];
                cacheData.data(ii).differentialPositive = [];
                cacheData.data(ii).differentialNegative = [];
            end
        end
        
        % Save the cache
        olCache = OLCache(correctedPrimariesDir,calibration);
        cacheFile = fullfile(correctedPrimariesDir, sprintf('Direction_%s.mat', theDirections{corrD}));
        cacheData.protocolParams = protocolParams;
        olCache.save(cacheFile, cacheData);
        if (p.Results.verbose), fprintf('\tCache saved to %s\n', cacheFile); end
end

%% Close the radiometer object
if (~protocolParams.simulate.oneLight)
    if (~isempty(radiometer))
        radiometer.shutDown();
    end
    
    if (~isempty(theLJdev))
        theLJdev.close;
    end
end

%% Update session log info
OLSessionLog(protocolParams,mfilename,'StartEnd','end');
