function protocolParams = OLValidateDirectionCorrectedPrimaries(ol,protocolParams,prePost)
%OLValidateCorrectedPrimaries  Measure and check the corrected primaries
%
% Syntax:
%     protocolParams = OLValidateDirectionCorrectedPrimaries(ol,protocolParams,prePost)
%
% Description:
%     This script uses the radiometer to measure the light coming out of the eyepiece and 
%     calculates the receptor contrasts.  This is a check on how well we
%     are hitting our desired target.  Typically we run this before and
%     after the experimental session.
%
% Input:
%     ol (object)                   Open OneLight object.
%
%     protocolParams (struct)       Protocol parameters structure.
%
%     prePost (string)              'Pre' or 'Post' to indicate validations pre or post experiment.  
%
% Output:
%     protocolParams (struct)       Protocol parameters structure updated with session log info.
%
% Optional key/value pairs:
%     None.
%
% See also: OLValidateCacheFileOOC.

% 6/18/17  dhb  Added header comment.

%% Update session log file
OLSessionLog(protocolParams,mfilename,'StartEnd','start','PrePost',prePost);

%% Cache files to validate
theDirectionCacheFileNames = OLMakeDirectionCacheFileNames(protocolParams);

%% Input and output file locations.
cacheDir = fullfile(getpref(protocolParams.approach, 'DirectionCorrectedPrimariesBasePath'), protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
outDir = fullfile(getpref(protocolParams.approach, 'DirectionCorrectedValidationBasePath'), protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
if(~exist(outDir,'dir'))
    mkdir(outDir)
end

%% Obtain correction params from OLCorrectionParamsDictionary,
%
% These are box specific, according to the boxName specified in
% protocolParams.boxName
d = OLCorrectionParamsDictionary();
correctionParams = d(protocolParams.boxName);

%% Validate each direction
for ii = 1:protocolParams.nValidationsPerDirection
    for d = 1:length(theDirectionCacheFileNames);

        % Take the measurement
        results = OLValidateCacheFileOOC(fullfile(cacheDir,[theDirectionCacheFileNames{d} '.mat']), ol, 'PR-670', ...
            'approach',                     protocolParams.approach, ...
            'simulate',                     protocolParams.simulate, ...
            'observerAgeInYrs',             protocolParams.observerAgeInYrs, ...
            'calibrationType',              protocolParams.calibrationType, ...
            'takeCalStateMeasurements',     protocolParams.takeCalStateMeasurements, ...
            'takeTemperatureMeasurements',  protocolParams.takeTemperatureMeasurements, ...
            'powerLevels',                  correctionParams.powerLevels, ...
            'postreceptoralCombinations',   correctionParams.postreceptoralCombinations, ...
            'useAverageGamma',              correctionParams.useAverageGamma, ...
            'zeroPrimariesAwayFromPeak',    correctionParams.zeroPrimariesAwayFromPeak, ...
            'emailRecipient',               protocolParams.emailRecipient, ...
            'verbose',                      protocolParams.verbose);
          
        % Save the validation information in an ordinary .mat file.  Append prePost and iteration number in name.
        if (protocolParams.verbose), fprintf(' * Saving validation results ...'); end;
        outputFile = fullfile(outDir,sprintf('%s_%s_%d.mat', theDirectionCacheFileNames{d},prePost,ii));
        save(outputFile,'results');
        if (protocolParams.verbose), fprintf('saved to %s\n', protocolParams.cacheFile); end
    end
end

%% Log that we did the validation
OLSessionLog(protocolParams,mfilename,'StartEnd','end','PrePost',prePost);
