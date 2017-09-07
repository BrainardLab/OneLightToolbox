function protocolParams = OLValidateDirectionCorrectedPrimaries(ol,protocolParams,prePost)
%%OLValidateCorrectedPrimaries  Measure and check the corrected primaries
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

% 06/18/17  dhb  Added header comment.
% 08/21/17  dhb  Save out protocolParams as part of results structure. May be useful for later analysis.

%% Update session log file
OLSessionLog(protocolParams,mfilename,'StartEnd','start','PrePost',prePost);

%% Cache files to validate
theDirectionCacheFileNames = OLMakeDirectionCacheFileNames(protocolParams);

%% Input and output file locations.
cacheDir = fullfile(getpref(protocolParams.protocol, 'DirectionCorrectedPrimariesBasePath'), protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
outDir = fullfile(getpref(protocolParams.protocol, 'DirectionCorrectedValidationBasePath'), protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
if(~exist(outDir,'dir'))
    mkdir(outDir)
end

%% Obtain correction params from OLCorrectionParamsDictionary,
%
% These are box specific, according to the boxName specified in
% protocolParams.boxName
d = OLCorrectionParamsDictionary();
correctionParams = d(protocolParams.boxName);

%% Open up a radiometer object
if (~protocolParams.simulate)
    [spectroRadiometerOBJ,S] = OLOpenSpectroRadiometerObj('PR-670');
else
    spectroRadiometerOBJ = [];
    S = [];
end

%% Open up lab jack for temperature measurements
if (~protocolParams.simulate & protocolParams.takeTemperatureMeasurements)
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

%% Validate each direction
for ii = 1:protocolParams.nValidationsPerDirection
    for d = 1:length(theDirectionCacheFileNames)
        if protocolParams.doCorrectionFlag{d} == true

        % Take the measurement
        results = OLValidateCacheFileOOC(fullfile(cacheDir,[theDirectionCacheFileNames{d} '.mat']), ol, spectroRadiometerOBJ, S, theLJdev, ...
            'approach',                     protocolParams.approach, ...
            'simulate',                     protocolParams.simulate, ...
            'observerAgeInYrs',             protocolParams.observerAgeInYrs, ...
            'calibrationType',              protocolParams.calibrationType, ...
            'takeCalStateMeasurements',     protocolParams.takeCalStateMeasurements, ...
            'takeTemperatureMeasurements',  protocolParams.takeTemperatureMeasurements, ...
            'useAverageGamma',              correctionParams.useAverageGamma, ...
            'zeroPrimariesAwayFromPeak',    correctionParams.zeroPrimariesAwayFromPeak, ...
            'verbose',                      protocolParams.verbose);
          
        % Save the validation information in an ordinary .mat file.  Append prePost and iteration number in name.
        if (protocolParams.verbose), fprintf(' * Saving validation results ...'); end
        outputFile = fullfile(outDir,sprintf('%s_%s_%d.mat', theDirectionCacheFileNames{d},prePost,ii));
        results.protocolParams = protocolParams;
        save(outputFile,'results');
        if (protocolParams.verbose), fprintf('saved to %s\n', outputFile); end
        end
    end
end

%% Close the radiometer object
if (~protocolParams.simulate)
    if (~isempty(spectroRadiometerOBJ))
        spectroRadiometerOBJ.shutDown();
    end
    
    if (~isempty(theLJdev))
        theLJdev.close;
    end
end

%% Log that we did the validation
OLSessionLog(protocolParams,mfilename,'StartEnd','end','PrePost',prePost);
