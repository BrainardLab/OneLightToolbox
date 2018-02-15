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
% 09/25/17 dhb   Respect flag that keeps us from doing each direction file more than once.

%% Cache files to validate
theDirections = unqiue(protocolParams.directionNames);

%% Input and output file locations.
directionDir = getpref(protocolParams.approach, 'DirectionNominalPrimariesPath');
validationDir = fullfile(getpref(protocolParams.protocol, 'DirectionCorrectedValidationBasePath'), protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
if(~exist(validationDir,'dir'))
    mkdir(validationDir)
end

%% Get validation results
%
% Loop over directions. Respect the flag, as when the protocol contains
% multiple trial types that use the same direction file, we only need to
% validate once per direction.
for dd = 1:length(theDirections)
    % Do the report if the flag is true.
    if (protocolParams.doCorrection(dd))
        theDirectionCacheFileName = sprintf('Direction_%s', protocolParams.directionNames{dd});
        
        fprintf('\nReporting on validation, direction %d, %s, %s\n',dd,theDirectionCacheFileName,prePost);
        
        % Loop over validations within direction
        for ii = 1:protocolParams.nValidationsPerDirection
            
            % Load the validation information
            validationFile = fullfile(validationDir,sprintf('%s_%s_%d.mat', theDirectionCacheFileName,prePost,ii));
            validationResults{ii,dd} = load(validationFile,'results');
            
            % Get wavelength sampling and receptor spectral sensitivities on first
            % time through the inner loop.
            if (ii == 1)
                % Wavelength sampling
                S = validationResults{1,1}.results.directionMeas(1).meas.pr650.S;
                
                % Get the names of the relevant photoreceptor classes for this direction
                %
                % Load the cache file for the direction being validated
                nominalDirectionFile = fullfile(directionDir, [theDirectionCacheFileName '.mat']);
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
            
            % Loop over other spectra and report luminance, receptor contrasts and
            % post-receptoral contrasts.
            %
            % Need to check that the first three photoreceptor classes are L, M and S
            % cones, otherwise the post-receptoral contrasts will not come out in a
            % meaningful manner.
            if (strcmp(~photoreceptorClasses{1}(1:5),'Lcone'))
                error('First row of T_receptors is not an L cone sensitivity');
            end
            if (strcmp(~photoreceptorClasses{2}(1:5),'Mcone'))
                error('Second row of T_receptors is not an M cone sensitivity');
            end
            if (strcmp(~photoreceptorClasses{3}(1:5),'Scone'))
                error('Third row of T_receptors is not an S cone sensitivity');
            end
            
            validateIndices = setdiff(1:nValidationMeas,bgIndex);
            for mm = 1:length(validateIndices)
                % Luminance
                XYZ{ii,dd} = T_xyz*spectrum(:,validateIndices(mm));
                fprintf('\t\tPower level %g, luminance %0.1f cd/m2\n',powerLevels(validateIndices(mm)),XYZ{ii,dd}(2));
                
                % Receptor contrasts
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
                
                % Post-receptoral contrasts.  Pass the first three contrasts, as just above we verified
                % that these are for L, M and S cones.
                [postreceptoralContrasts{ii,dd}, postreceptoralStrings] = ComputePostreceptoralContrastsFromLMSContrasts(contrasts{ii,dd}(1:3));
                fprintf('\t\t\tPost-receptoral contrasts: ');
                for cc = 1:length(postreceptoralStrings)
                    fprintf('%s: %0.2g',postreceptoralStrings{cc},postreceptoralContrasts{ii,dd}(cc))
                    if (cc ~= length(postreceptoralStrings))
                        fprintf('; ');
                    else
                        fprintf('\n');
                    end
                end
            end
        end
    end
end