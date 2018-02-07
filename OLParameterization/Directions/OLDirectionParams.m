classdef OLDirectionParams < matlab.mixin.Heterogeneous
% Parameter-object superclass for all directions  
%   Detailed explanation goes here
    
    properties (SetAccess = immutable)
        dictionaryType = 'Direction'; 
    end

    properties %(Abstract) %, SetAccess = protected)
        type
        name
        cacheFile
    end    
    properties
        useAmbient = true;
        primaryHeadRoom = 0.005
        
        correctionPowerLevels = [0 1];
        validationPowerLevels = [0 1];      
    end
    
    methods
    end
    
end