function photopicLuminanceCdM2 = OLAnalyzeValidationReceptorIsolate(valFileNameFull, postreceptoralCombinations)
% OLAnalyzeValidationReceptorIsolate  Compute photoreceptor contrasts for spectra in a validation file and report
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

%% Read in validation
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