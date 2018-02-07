classdef OLBackgroundParams < matlab.mixin.Heterogeneous
% Parameter-object superclass for all parameterized backgrounds
%
% Syntax:
%   <This class is abstract and thus cannot be instantiated. See
%   subclasses>
%
% Description:
%    All sets of background parameters are stored in objects of classes
%    derived from this class. The individual subclasses differ in the
%    type of background they implement, and they encapsulate some methods
%    that are different between these types. This superclass defines the
%    properties common to all backgrounds, as well as the methods that all
%    subclasses must implement. 
%
% See also:
%    OLBackgroundParams_LightFluxChrom, OLBackgroundParams_Optimized
%

% History:
%    02/07/18  jv  wrote it.

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