function photopicLuminance = OLAnalyzeValidationReceptorIsolateShort(valFileNameFull, postreceptoralCombinations)
% OLAnalyzeValidationReceptorIsolate(valFileNameFull)

[validationDir, valFileName] = fileparts(valFileNameFull);
val = LoadCalFile(valFileName, [], [validationDir '/']);

% Pull out the data for the reference observer
data = val.describe.cache.data;

% Pull out the cal ID to add to file names and titles. We can't use
% OLGetCalID since we don't necessary have the cal struct.
if isfield(val.describe, 'calID')
    calID = val.describe.calID;
    calIDTitle = val.describe.calIDTitle;
else
    calID = '';
    calIDTitle = '';
end

% Pull out S
S = val.describe.S;

theReceptors = data(val.describe.OBSERVER_AGE).describe.photoreceptors;
T_receptors = data(val.describe.OBSERVER_AGE).describe.T_receptors;

load T_xyz1931
T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);
photopicLuminanceCdM2 = T_xyz(2,:)*val.modulationBGMeas.meas.pr650.spectrum;

fid = fopen(fullfile(validationDir, [valFileName '.txt']), 'w');
fprintf(fid, 'Background luminance [cd/m2]: %.2f cd/m2\n', photopicLuminanceCdM2);
fprintf('Background luminance [cd/m2]: %.2f cd/m2\n', photopicLuminanceCdM2);
if ~strcmp(val.describe.cache.data(val.describe.OBSERVER_AGE).describe.params.receptorIsolateMode, 'PIPR')
    % Calculate the receptor activations to the background
    bgSpd = val.modulationBGMeas.meas.pr650.spectrum;
    modSpd = val.modulationMaxMeas.meas.pr650.spectrum;
    try
        [contrasts postreceptorContrasts postreceptorStrings] = ComputeAndReportContrastsFromSpds(val.describe.cache.cacheFileName,theReceptors,T_receptors,bgSpd,modSpd,postreceptoralCombinations,[]);
    catch
        contrasts = ComputeAndReportContrastsFromSpds(val.describe.cache.cacheFileName,theReceptors,T_receptors,bgSpd,modSpd,[],[]);
    end

    % Save contrasts
    for j = 1:size(T_receptors, 1)
        fprintf(fid, '  - %s: contrast = \t%f \n',theReceptors{j},contrasts(j));
    end
    
    if exist('postreceptorContrasts', 'var')
        % Save postreceptoral contrasts
        for j = 1:length(postreceptorStrings)
            fprintf(fid, '  - %s: contrast = \t%f \n',postreceptorStrings{j},postreceptorContrasts(j));
        end
    end
    fclose(fid);
end