function OLMakeDirectionNominalPrimaries(approachParams)
% OLMakeDirectionNominalPrimaries - Calculate the nominal direction primaries for the experiment
%
% Usage:
%     OLMakeDirectionNominalPrimaries(approachParams)
%
% Description:
%     This function calculations the nominal direction primaries required for the
%     this approach, for the extrema of the modulations.  Typically,
%     these will be tuned up by spectrum seeking on the day of the experiment.
%
%     The primaries depend on the calibration file and on parameters of
%     field size and pupil size, and also observer age.  The whole range of
%     ages is computed inside a cache file, with the cache file name giving
%     field size and pupil size info.
%
%     The output is cached in the directory specified by
%     getpref(approachParams.approach,'DirectionNominalPrimariesPath');

% 6/18/17  dhb  Added header comment.
% 6/22/17  npc  Dictionarized direction params, cleaned up.
% 7/05/17  dhb  Big rewrite.

    % Make dictionary with direction-specific params for all directions
    paramsDictionary = DirectionNominalParamsDictionary();
    
    %% Loop over directions
    for ii = 1:length(approachParams.directionNames)
        generateAndSaveBackgroundPrimaries(approachParams,paramsDictionary,approachParams.directionNames{ii});
    end
    
%     %% Melanopsin-directed
%     [paramsMelBackground, paramsMaxMel, cacheDataBackground, cacheDataMaxMel] = generateAndSavePrimaries(baseParams, paramsDictionary, 'MelanopsinDirected', 'MelanopsinDirectedSuperMaxMel');
% 
%     %% MaxLMS-directed
%     [paramsLMSBackground, paramsMaxLMS, cacheDataBackground, cacheDataMaxLMS] = generateAndSavePrimaries(baseParams, paramsDictionary, 'LMSDirected', 'LMSDirectedSuperMaxLMS');
% 
%     %% Light flux
%     %
%     % For the light flux, we'd like a background that is the average
%     % chromaticity between the two MaxMel and MaxLMS backgrounds. The
%     % appropriate chromaticities are (approx.):
%     %   x = 0.54, y = 0.38
% 
%     % Get the cal files
%     cal = LoadCalFile(OLCalibrationTypes.(baseParams.calibrationType).CalFileName, [], fullfile(getpref(baseParams.approach, 'MaterialsPath'), 'Experiments',baseParams.approach,'OneLightCalData'));
%     cacheDir = fullfile(getpref(baseParams.approach, 'MaterialsPath'),'Experiments',baseParams.approach,'DirectionNominalPrimaries');
%     
%     % Modulation 
%     desiredChromaticity = [0.54 0.38];
%     modPrimary = OLInvSolveChrom(cal, desiredChromaticity);
% 
%     % Background
%     %
%     % This 5 here is hard coding the fact that we want a 400% light flux
%     % modulation.
%     bgPrimary = modPrimary/5;
% 
%     % We copy over the information from the LMS cache file
%     cacheDataMaxPulseLightFlux = cacheDataMaxLMS;
%     paramsMaxPulseLightFlux = paramsMaxLMS;
% 
%     % Set up the cache structure
%     olCacheMaxPulseLightFlux = OLCache(cacheDir, cal);
% 
%     % Replace the values
%     for observerAgeInYrs = 20:60
%         cacheDataMaxPulseLightFlux.data(observerAgeInYrs).backgroundPrimary = bgPrimary;
%         cacheDataMaxPulseLightFlux.data(observerAgeInYrs).backgroundSpd = [];
%         cacheDataMaxPulseLightFlux.data(observerAgeInYrs).differencePrimary = modPrimary-bgPrimary;
%         cacheDataMaxPulseLightFlux.data(observerAgeInYrs).differenceSpd = [];
%         cacheDataMaxPulseLightFlux.data(observerAgeInYrs).modulationPrimarySignedPositive = [];
%         cacheDataMaxPulseLightFlux.data(observerAgeInYrs).modulationSpdSignedPositive = [];
%         cacheDataMaxPulseLightFlux.data(observerAgeInYrs).modulationPrimarySignedNegative = [];
%         cacheDataMaxPulseLightFlux.data(observerAgeInYrs).modulationSpdSignedNegative = [];
%     end
% 
%     % Save the cache
%     paramsMaxPulseLightFlux.modulationDirection = 'LightFluxMaxPulse';
%     paramsMaxPulseLightFlux.cacheFile = ['Cache-' paramsMaxPulseLightFlux.modulationDirection '.mat'];
%     OLReceptorIsolateSaveCache(cacheDataMaxPulseLightFlux, olCacheMaxPulseLightFlux, paramsMaxPulseLightFlux);
end

function generateAndSaveBackgroundPrimaries(approachParams, paramsDictionary, directionName)
    % Get background primaries
    directionParams = MergeBaseParamsWithParamsFromDictionaryEntry(approachParams, paramsDictionary, directionName);
    
    % The called routine checks whether the cacheFile exists, and if so and
    % it isnt' stale, just returns the data.
    [cacheDataDirection, olCacheDirection, wasRecomputed] = OLReceptorIsolateMakeDirectionNominalPrimaries(approachParams.approach,directionParams,false);

    % Save the direction primaries in a cache file, if it was recomputed.
    if (wasRecomputed)
        [~, cacheFileName] = fileparts(directionParams.cacheFile);
        olCacheDirection.save(cacheFileName, cacheDataDirection);
    end
end

% function [backgroundParams, maxDirectionParams, cacheDataBackground, cacheDataMaxDirection] = generateAndSavePrimaries(baseParams, paramsDictionary, backgroundDirectionName, maxDirectionName)
%     % background direction
%     backgroundParams = MergeBaseParamsWithParamsFromDictionaryEntry(baseParams, paramsDictionary, backgroundDirectionName);
%     [cacheDataBackground, olCacheBackground, backgroundParams] = OLReceptorIsolateMakeBackgroundNominalPrimaries(backgroundParams, true);
%     OLReceptorIsolateSaveCache(cacheDataBackground, olCacheBackground, backgroundParams);
% 
%     % max direction
%     maxDirectionParams = MergeBaseParamsWithParamsFromDictionaryEntry(baseParams, paramsDictionary, maxDirectionName);
%     [cacheDataMaxDirection, olCacheMaxDirection, maxDirectionParams] = OLReceptorIsolateMakeDirectionNominalPrimaries(maxDirectionParams, true);
% 
%     % Replace the backgrounds
%     for observerAgeInYrs = 20:60
%         cacheDataMaxDirection.data(observerAgeInYrs).backgroundPrimary = cacheDataMaxDirection.data(observerAgeInYrs).modulationPrimarySignedNegative;
%         cacheDataMaxDirection.data(observerAgeInYrs).backgroundSpd = cacheDataMaxDirection.data(observerAgeInYrs).modulationSpdSignedNegative;
%         cacheDataMaxDirection.data(observerAgeInYrs).differencePrimary = cacheDataMaxDirection.data(observerAgeInYrs).modulationPrimarySignedPositive-cacheDataMaxDirection.data(observerAgeInYrs).modulationPrimarySignedNegative;
%         cacheDataMaxDirection.data(observerAgeInYrs).differenceSpd = cacheDataMaxDirection.data(observerAgeInYrs).modulationSpdSignedPositive-cacheDataMaxDirection.data(observerAgeInYrs).modulationSpdSignedNegative;
%         cacheDataMaxDirection.data(observerAgeInYrs).modulationPrimarySignedNegative = [];
%         cacheDataMaxDirection.data(observerAgeInYrs).modulationSpdSignedNegative = [];
%     end
% 
%     % Save the modulations
%     OLReceptorIsolateSaveCache(cacheDataMaxDirection, olCacheMaxDirection, maxDirectionParams);
% end


