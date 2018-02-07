classdef OLDirectionParams_Unipolar < OLDirectionParams
% Parameter-object for Unipolar directions
%   Detailed explanation goes here
    
    properties  
        whichReceptorGenerator = 'SSTPhotoreceptorSensitivity';
        photoreceptorClasses = {'LConeTabulatedAbsorbance'  'MConeTabulatedAbsorbance'  'SConeTabulatedAbsorbance'  'Melanopsin'};
        fieldSizeDegrees(1,1) = 27.5;
        pupilDiameterMm(1,1) = 8.0;
        maxPowerDiff(1,1) = 0.1;
        baseModulationContrast = [];        
        modulationContrast = [];
        whichReceptorsToIsolate = [];
        whichReceptorsToIgnore = [];
        whichReceptorsToMinimize = [];
        whichPrimariesToPin = [];
        directionsYoked = 0;
        directionsYokedAbs = 0;
        receptorIsolateMode = 'Standard';
        doSelfScreening = false;
        
        backgroundName = '';
        backgroundParams = [];
        backgroundPrimary = [];
    end
    
    methods
        function obj = OLDirectionParams_Unipolar
            obj.type = 'unipolar';
            obj.name = '';
            obj.cacheFile = '';
            
            obj.primaryHeadRoom = .005;
        end
        
    end
    
end