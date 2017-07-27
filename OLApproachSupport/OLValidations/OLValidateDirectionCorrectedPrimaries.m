function protocolParams = OLValidateDirectionCorrectedPrimaries(protocolParams,prePost)
%OLValidateCorrectedPrimaries  Measure and check the corrected primaries
%
% Description:
%     This script uses the radiometer to measure the light coming out of the eyepiece and 
%     calculates the receptor contrasts.  This is a check on how well we
%     are hitting our desired target.  Typically we run this before and
%     after the experimental session.

% 6/18/17  dhb  Added header comment.

%% Update session log file
protocolParams = OLSessionLog(protocolParams,mfilename,'StartEnd','start','PrePost',prePost);

%% Set up some parameters
spectroRadiometerOBJ = [];
theDirectionCacheFileNames = OLMakeDirectionCacheFileNames(protocolParams);

NDirections = length(theDirectionCacheFileNames);
cacheDir = fullfile(getpref(protocolParams.approach, 'DirectionCorrectedPrimariesBasePath'), protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
outDir = fullfile(getpref(protocolParams.approach, 'DirectionCorrectedValidationBasePath'), protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
if(~exist(outDir))
    mkdir(outDir)
end
NMeas = 1;

% Set up a counter
c = 1;
NTotalMeas = NMeas*NDirections;

% Obtain correction params from OLCorrectionParamsDictionary, according
% to the boxName specified in protocolParams.boxName
d = OLCorrectionParamsDictionary();
correctionParams = d(protocolParams.boxName);

%% Validate each direction
for ii = 1:NMeas;
    for d = 1:NDirections
        % Inform the user where we are in the validation
        fprintf('*** Validation %g / %g in total ***\n', c, NTotalMeas);
        
        % We also take state measurements, which we define here
        if (choiceIndex == 1) && (c == 1)
            calStateFlag = true;
        elseif (choiceIndex == 2) && (c == NTotalMeas)
            calStateFlag = true;
        else
            calStateFlag = false;
        end
        
        % Take the measurement
        results = OLValidateCacheFileOOC(fullfile(cacheDir, sprintf('%s.mat', theDirectionCacheFileNames{d})),'PR-670', ...
            'pr670sensitivityMode',         'STANDARD', ...
            'CalStateMeas',                 calStateFlag, ...
            'outDir',                       outDir, ...
            'OBSERVER_AGE',                 protocolParams.observerAgeInYrs, ...
            'selectedCalType',              protocolParams.calibrationType, ...
            'takeTemperatureMeasurements',  protocolParams.takeTemperatureMeasurements, ...
            'powerLevels',                  correctionParams.powerLevels, ...
            'postreceptoralCombinations',   correctionParams.postreceptoralCombinations, ...
            'useAverageGamma',              correctionParams.useAverageGamma, ...
            'zeroPrimariesAwayFromPeak',    correctionParams.zeroPrimariesAwayFromPeak, ...
            'emailRecipient',               protocolParams.emailRecipient, ...
            'verbose',                      p.Results.verbose);
      
        
        % Save the cache
%         if (p.Results.verbose), fprintf(' * Saving cache ...'); end;
%         olCache = OLCache(correctedPrimariesDir,cal);
%         protocolParams.modulationDirection = theDirections{d};
%         protocolParams.cacheFile = fullfile(nominalPrimariesDir, theDirectionCacheFileNames{d});
%         if (p.Results.verbose), fprintf('Cache saved to %s\n', protocolParams.cacheFile); end
%         olCache.save(protocolParams.cacheFile, cacheData);
%         if (p.Results.verbose), fprintf('Cache saved to %s\n', protocolParams.cacheFile); end
    
        % Increment the counter
        c = c+1;
    end
end

if (~isempty(spectroRadiometerOBJ))
    spectroRadiometerOBJ.shutDown();
    spectroRadiometerOBJ = [];
end

protocolParams = OLSessionLog(protocolParams,mfilename,'StartEnd','end','PrePost',prePost);
