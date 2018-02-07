classdef OLBackgroundParams < matlab.mixin.Heterogeneous
%OLBACKGROUNDPARAMS Summary of this class goes here
%   Detailed explanation goes here
    
properties
    name
    baseName;
    dictionaryType = 'Background';
    type
    cacheFile;
    useAmbient = true;                 % Use measured ambient in calculations if true. If false, set ambient to zero.
	primaryHeadRoom = 0.01;            % How close to edge of [0-1] primary gamut do we want to get?    
end
    
methods (Abstract)
    OLBackgroundNameFromParams(params);
    OLBackgroundNominalPrimaryFromParams(params, calibration); % subclasses have to implement how to make nominal primary
    OLBackgroundParamsValidate(params) % subclasses have to implement how to verify that parameters are valid
end
    
end