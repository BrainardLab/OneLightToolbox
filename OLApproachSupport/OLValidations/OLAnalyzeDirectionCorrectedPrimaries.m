function photopicLuminanceCdM2 = OLAnalyzeDirectionCorrectedPrimaries(protocolParams,prePost)
% OLAnalyzeDirectionCorrectedPrimaries  Compute photoreceptor contrasts for spectra in a validation file and report
%
% Usage:
%     photopicLuminanceCdM2 = OLAnalyzeValidationReceptorIsolate(valFileNameFull)
%
% Description:
%     This is basically a wrapper for the descriptive function SilentSubstitutionToolbox/ComputeAndReportContrastsFromSpds.
%     It provides a printout to the command wndow of some basic facts about the contrasts produced by the modulation specified
%     in a validation file.
%
%     Also writes its output into a text file that lives in the same place as the file being analyzed.
%
%     This has some crufty things in it.
%       a) Why is it using LoadCalFile rather than just load?
%       b) It special cases substrings in the input filename to control its behavior.
%       c) It is very difficult to understand, primarily because the underlying ComputeAndReportContrastsFromSpds is
%          not well commented, and because what values postreceptoralCombinations may take on and what these values
%          mean is opaque.
%
% Input:
%      valFileNameFull (string)              Name of validation file to be analyzed.
%
%      postreceptoralCombinations (what)     Presumably controls what this produces.
%
% Output:
%      photopicLuminanceCdM2 (number         Photopic luminance of background in cd/m2.
%
% Optional key/value pairs:
%    None.
%
% See also: OLCorrectCacheFileOOC, OLValidateCacheFileOOC, ComputeAndReportContrastsFromSpds.

% 7/21/17  dhb   Put in comment placeholders and did my best.

%% Cache files to validate
theDirectionCacheFileNames = OLMakeDirectionCacheFileNames(protocolParams);

%% Input and output file locations.
directionDir = getpref(protocolParams.approach, 'DirectionNominalPrimariesPath');
validationDir = fullfile(getpref(protocolParams.protocol, 'DirectionCorrectedValidationBasePath'), protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
if(~exist(validationDir,'dir'))
    mkdir(validationDir)
end

%% Compute receptors against which to report contrasts;


%% Get validation results
for dd = 1:length(theDirectionCacheFileNames)
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
            if isfield(directionCacheData.directionParams,'photoreceptorClasses')
                photoreceptorClasses = directionCacheData.directionParams.photoreceptorClasses;
            else
                photoreceptorClasses = {'LConeTabulatedAbsorbance'  'MConeTabulatedAbsorbance'  'SConeTabulatedAbsorbance'  'Melanopsin'};
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
        fprintf('\nDirection %d, measurement %d\n',dd,ii);
        fprintf('\tBackground luminance: %0.1f cd/m2\n',backgroundXYZ(2));
        
        % Loop over other spectra and report luminance and receptor contrasts
        validateIndices = setdiff(1:nValidationMeas,bgIndex);
        for mm = 1:length(validateIndices)
            XYZ{ii,dd} = T_xyz*spectrum(:,validateIndices(mm));
            fprintf('\tPower level %g, luminance %0.1f cd/m2\n',powerLevels(mm),XYZ{ii,dd}(2));
            
        end
    end
end

theReceptors = data(val.describe.OBSERVER_AGE).describe.photoreceptors;
T_receptors = data(val.describe.OBSERVER_AGE).describe.T_receptors;



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