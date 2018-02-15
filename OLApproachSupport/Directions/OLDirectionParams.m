classdef OLDirectionParams < matlab.mixin.Heterogeneous
% Parameter-object superclass for all parameterized directions  
%
% Syntax:
%   <This class is abstract and thus cannot be instantiated. See
%   subclasses>
%
% Description:
%    All sets of direction parameters are stored in objects of classes
%    derived from this class. The individual subclasses differ in the
%    type of background they implement, and they encapsulate some methods
%    that are different between these types. This superclass defines the
%    properties common to all directions, as well as the methods that all
%    subclasses must implement. 
%
% See also:
%    OLBackgroundParams_LightFluxChrom, OLBackgroundParams_Optimized
%

% History:
%    02/07/18  jv  wrote it.
   
properties
    baseName = '';
    name = '';
    
    backgroundPrimary = [];
    backgroundParams = [];
    backgroundName = '';
    
    useAmbient = true;
    primaryHeadRoom = 0.005;
end

methods (Abstract) 
    % subclasses for specific direction types are required to implement
    % these methods
    OLDirectionNameFromParams(params);
    OLDirectionNominalStructFromParams(params, calibration, varargin);
    OLDirectionParamsValidate(params);        
end

end