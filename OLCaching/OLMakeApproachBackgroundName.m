function name = OLMakeApproachBackgroundName(baseName,params)
% OLMakeApproachBackgroundName  Make name for background files that captures key param values.
%
% Usage:
%     name = OLMakeApproachBackgroundName(baseName,params)
%
% Description:
%     Background primary values depend on things like type, field size, pupil
%     diameter, and modulation contrast.  This routine establishes a naming
%     convention that identifies the dependencies in the name.
%
% Inputs:
%     baseName      Descriptive base name for the background.
%
%     params        Background parameters structure.
%
% Output:
%     name          The name.

% 07/05/17  dhb  Wrote it.


%% Make the name, according to the type of thing we're naming
switch (params.type)
    case 'optimized'
        name = sprintf('%s_%d_%d_%d',baseName,round(10*params.fieldSizeDegrees),round(10*params.pupilDiameterMm),round(1000*params.baseModulationContrast));
    case 'lightfluxchrom'
        name = sprintf('%s_%d_%d_%d',baseName,round(1000*params.lightFluxDesiredXY(1)),round(1000*params.lightFluxDesiredXY(2)),round(10*params.lightFluxDownFactor)); 
    otherwise
        error('Unknown background type');
end

