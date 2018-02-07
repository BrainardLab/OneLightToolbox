classdef OLDirectionParams_LightFluxChrom < OLDirectionParams
% Parameter-object for LightFluxChrom directions
%   Detailed explanation goes here
    
    properties
        lightFluxDesiredXY(1,2) = [0.5400 0.3800];                         % Modulation chromaticity.
        lightFluxDownFactor(1,1) = 5;                                      % Size of max flux increase from background
                
        backgroundName = '';
        backgroundParams = [];
        backgroundPrimary = [];
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