function name = OLMakeApproachDirectionName(baseName,params)
% OLMakeApproachDirectionName  Make name for direction files that captures key param values.
%
% Usage:
%     name = OLMakeApproachDirectionName(baseName,params)
%
% Description:
%     Direction primary values depend on things like type, field size, pupil
%     diameter, and modulation contrast.  This routine establishes a naming
%     convention that identifies the dependencies in the name.
%
% Inputs:
%     baseName      Descriptive base name for the direction.
%
%     params        Direction parameters structure.
%
% Output:
%     name          The name.
%
% Optional key/value pairs:
%     None.

% History:
%   07/05/17  dhb      Wrote it.
%   01/24/18  dhb, jv  Add 'modulation' type to get a different name


%% Make the name, according to the type of thing we're naming
switch (params.type)
    case 'pulse'
        name = sprintf('%s_%d_%d_%d',baseName,round(10*params.fieldSizeDegrees),round(10*params.pupilDiameterMm),round(1000*params.baseModulationContrast));
    case 'modulation'
        name = sprintf('%s_%d_%d_%d_modulation',baseName,round(10*params.fieldSizeDegrees),round(10*params.pupilDiameterMm),round(1000*params.baseModulationContrast));
    case 'lightfluxchrom'
        name = sprintf('%s_%d_%d_%d',baseName,round(1000*params.lightFluxDesiredXY(1)),round(1000*params.lightFluxDesiredXY(2)),round(10*params.lightFluxDownFactor)); 
    otherwise
        error('Unknown direction type');
end

