function OLAnalyzeDirectionCorrectedPrimaries(protocolParams,prePost)
% OLAnalyzeDirectionCorrectedPrimaries  Compute photoreceptor contrasts for spectra in a validation file and report
%
% Usage:
%     OLAnalyzeValidationReceptorIsolate(protocolParams,prePost)
%
% Description:
%     This computes and reports luminance and photoreceptor contrasts for validated spectra.
%
%     It obtains the necessary parameters and information from the protocol parameters and the
%     nominal and corrected primary files.
%
%     [DHB NOTE: Still need to write output to text files and report median over measurements.
%     There is some commented-out code at the bottom which might be a useful point of departure.]
%     [DHB NOTE: Could consider adding report of post-receptoral contrasts.]
%     [DHB NOTE: Could integrate with new splatter calculation code in SST.]
%
% Input:
%      protocolParams (struct)               Parameters of the current protocol.
%
%      prePost (string)                      'Pre' or 'Post' experiment validation?
%
% Output:
%      None.
%
% Optional key/value pairs:
%    None.
%
% See also: OLCorrectCacheFileOOC, OLValidateCacheFileOOC, ComputeAndReportContrastsFromSpds.

% 07/21/17 dhb   Put in comment placeholders and did my best.
% 08/22/17 dhb   Made it work again.

%% Cache files to validate
theDirectionCacheFileNames = OLMakeDirectionCacheFileNames(protocolParams);

%% Input and output file locations.
directionDir = getpref(protocolParams.approach, 'DirectionNominalPrimariesPath');
validationDir = fullfile(getpref(protocolParams.protocol, 'DirectionCorrectedValidationBasePath'), protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
if(~exist(validationDir,'dir'))
    mkdir(validationDir)
end

%% Compute receptors against which to report contrasts


%% Get validation results
%
% Loop over directions
for dd = 1:length(theDirectionCacheFileNames)
    fprintf('\nDirection %d, %s, %s\n',dd,theDirectionCacheFileNames{dd},prePost);

    % Loop over validations within direction
    for ii = 1:protocolParams.nValidationsPerDirection
   
        % Load the validation information
        validationFile = fullfile(validationDir,sprintf('%s_%s_%d.mat', theDirectionCacheFileNames{dd},prePost,ii));
        validationResults{ii,dd} = load(validationFile,'results');
        
        % Get wavelength sampling and receptor spectral sensitivities on first
        % time through the inner loop.
        if (ii == 1)
            % Wavelength sampling
            S = validationResults{1,1}.results.directionMeas(1).meas.pr650.S;
            
            % Get the names of the relevant photoreceptor classes for this direction
            %
            % Load the cache file for the direction being validated
            nominalDirectionFile = fullfile(directionDir, [theDirectionCacheFileNames{dd} '.mat']);
            directionCacheData = OLGetCacheAndCalData(nominalDirectionFile,protocolParams);
            
            % Grab cell array of photoreceptor classes.  Use what was in the direction file
            % if it is there, otherwise standard L, M, S and Mel.
            %
            % This might not be the most perfect check for what is stored with the nominal direction primaries,
            % but until it breaks we'll go with it.
            if isfield(directionCacheData.directionParams,'photoreceptorClasses')
                if (directionCacheData.data(protocolParams.observerAgeInYrs).describe.params.fieldSizeDegrees ~=  protocolParams.fieldSizeDegrees)
                    error('Field size used for direction does not match that specified in protocolPrams.');
                end
                if (directionCacheData.data(protocolParams.observerAgeInYrs).describe.params.pupilDiameterMm ~=  protocolParams.pupilDiameterMm)
                    error('Pupil diameter used for direction does not match that specified in protocolPrams.');
                end
                photoreceptorClasses = directionCacheData.data(protocolParams.observerAgeInYrs).describe.photoreceptors;
                T_receptors = directionCacheData.data(protocolParams.observerAgeInYrs).describe.T_receptors;      
            else
                photoreceptorClasses = {'LConeTabulatedAbsorbance'  'MConeTabulatedAbsorbance'  'SConeTabulatedAbsorbance'  'Melanopsin'};
                T_receptors = GetHumanPhotoreceptorSS(S,photoreceptorClasses,protocolParams.fieldSizeDegrees,protocolParams.observerAgeInYrs,protocolParams.pupilDiameterMm,[],[]);
            end
                        
            % XYZ
            load T_xyz1931
            T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);
        end
        
        % Get measured spectra
        nValidationMeas = length(validationResults{ii,dd}.results.directionMeas);
        for mm = 1:nValidationMeas
            powerLevels(mm) = validationResults{ii,dd}.results.directionMeas(mm).powerLevel;
            spectrum(:,mm) = validationResults{ii,dd}.results.directionMeas(mm).meas.pr650.spectrum;
        end
        
        % Find background spectrum in measurments and report its luminance
        bgIndex = find(powerLevels == 0);
        if (isempty(bgIndex))
            error('No measurement for power level 0');
        end
        if (length(bgIndex) > 1)
            error('More than one measurement for power level 0');
        end
        backgroundSpd = spectrum(:,bgIndex);
        backgroundXYZ = T_xyz*backgroundSpd;
        backgroundReceptors = T_receptors*backgroundSpd;
        fprintf('\tMeasurement %d\n',ii);
        fprintf('\t\tBackground luminance: %0.1f cd/m2\n',backgroundXYZ(2));
        
        % Loop over other spectra and report luminance and receptor contrasts
        validateIndices = setdiff(1:nValidationMeas,bgIndex);
        for mm = 1:length(validateIndices)
            XYZ{ii,dd} = T_xyz*spectrum(:,validateIndices(mm));
            fprintf('\t\tPower level %g, luminance %0.1f cd/m2\n',powerLevels(validateIndices(mm)),XYZ{ii,dd}(2));
            receptors{ii,dd} = T_receptors*spectrum(:,validateIndices(mm));
            contrasts{ii,dd} = (receptors{ii,dd}-backgroundReceptors) ./ backgroundReceptors;
            fprintf('\t\t\tContrasts: ');
            for cc = 1:length(photoreceptorClasses)
                fprintf('%s: %0.2g',photoreceptorClasses{cc},contrasts{ii,dd}(cc))
                if (cc ~= length(photoreceptorClasses))
                    fprintf('; ');
                else
                    fprintf('\n');
                end
            end
        end
    end
end

% fid = fopen(fullfile(validationDir, [valFileName '.txt']), 'w');
% fprintf(fid, 'Background luminance [cd/m2]: %.2f cd/m2\n', photopicLuminanceCdM2);
% fprintf('Background luminance [cd/m2]: %.2f cd/m2\n', photopicLuminanceCdM2);
% if ~strcmp(val.describe.cache.data(val.describe.OBSERVER_AGE).describe.params.receptorIsolateMode, 'PIPR')
%     % Calculate the receptor activations to the background
%     bgSpd = val.modulationBGMeas.meas.pr650.spectrum;
%     modSpd = val.modulationMaxMeas.meas.pr650.spectrum;
%     try
%         [contrasts postreceptorContrasts postreceptorStrings] = ComputeAndReportContrastsFromSpds(val.describe.cache.cacheFileName,theReceptors,T_receptors,bgSpd,modSpd,postreceptoralCombinations,[]);
%     catch
%         contrasts = ComputeAndReportContrastsFromSpds(val.describe.cache.cacheFileName,theReceptors,T_receptors,bgSpd,modSpd,[],[]);
%     end
%     
%     % Save contrasts
%     for j = 1:size(T_receptors, 1)
%         fprintf(fid, '  - %s: contrast = \t%f \n',theReceptors{j},contrasts(j));
%     end
%     
%     if exist('postreceptorContrasts', 'var')
%         % Save postreceptoral contrasts
%         for j = 1:length(postreceptorStrings)
%             fprintf(fid, '  - %s: contrast = \t%f \n',postreceptorStrings{j},postreceptorContrasts(j));
%         end
%     end
%     fclose(fid);
% end