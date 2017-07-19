function directionCacheFileNames = OLMakeDirectionCacheFileNames(protocolParams)
% OLMakeDirectionCacheFileNames  Assemble direction cache file name that captures key protocol param values.
%
% Usage:
%     directionCacheFileNames = OLMakeDirectionCacheFileNames(protocolParams)
%
% NOTES:
%   Somehow, we need to know the modulation contrast. We should probably
%   have this in protocolParams or pass it otherwise. For now manually
%   setting it to 4/6 and letting the user know big time.
%
    fprintf(2, '\n * * * * NEED TO FIGURE HOW TO GET THE CONTRAST HERE * * * * \n');
    pp.modulationContrast = 4/6
    fprintf(2,'Hit enter to continue\n');
    pause

    for k = 1:numel(protocolParams.directionNames)
        directionCacheFileNames{k} = sprintf('Direction_%s_%d_%d_%d',protocolParams.directionNames{k}, round(10*protocolParams.fieldSizeDegrees),round(10*protocolParams.pupilDiameterMm),round(1000*pp.modulationContrast));
    end
end