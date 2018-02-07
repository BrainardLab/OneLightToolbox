classdef OLDirectionParams_LightFluxChrom < OLDirectionParams
% Parameter-object for LightFluxChrom directions
%   Detailed explanation goes here
    
    properties %(SetAccess = protected)
        lightFluxDesiredXY = [0.5400 0.3800];
        lightFluxDownFactor = 5;
                
        backgroundType = 'lightfluxchrom';
        backgroundName = '';
        backgroundObserverAge = 32;
    end
    
    methods
        function obj = OLDirectionParams_LightFluxChrom  
            obj.type = 'lightfluxchrom';
            obj.name = '';
            obj.cacheFile = '';
            
            obj.primaryHeadRoom = .01;
        end        
    end
    
end