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

% 07/05/17  dhb  Wrote it.


%% Make the name, according to the type of thing we're naming
switch (params.type)
    case 'pulse'
        name = sprintf('%s_%d_%d_%d',baseName,round(10*params.fieldSizeDegrees),round(10*params.pupilDiameterMm),round(1000*params.baseModulationContrast));
    otherwise
        error('Unknown direction type');
end

