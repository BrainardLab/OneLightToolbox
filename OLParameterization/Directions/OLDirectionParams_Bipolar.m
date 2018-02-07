classdef OLDirectionParams_Bipolar < OLDirectionParams
% Parameter-object for Unipolar directions
%   Detailed explanation goes here
    
    properties %(SetAccess = protected)       
        whichReceptorGenerator = 'SSTPhotoreceptorSensitivity';
        photoreceptorClasses = {'LConeTabulatedAbsorbance'  'MConeTabulatedAbsorbance'  'SConeTabulatedAbsorbance'  'Melanopsin'};
        fieldSizeDegrees = 27.5;
        pupilDiameterMm = 8.0;
        maxPowerDiff = 0.1;
        baseModulationContrast = 2/3;        
        modulationContrast = [2/3 2/3 2/3];
        whichReceptorsToIsolate = [4];
        whichReceptorsToIgnore = [];
        whichReceptorsToMinimize = [];
        directionsYoked = 0;
        directionsYokedAbs = 0;
        receptorIsolateMode = 'Standard';
        doSelfScreening = false;
        
        backgroundType = 'optimized';
        backgroundName = '';
        backgroundObserverAge = 32;
    end
    
    methods
        function obj = OLDirectionParams_Bipolar
            obj.type = 'bipolar';
            obj.name = '';
            obj.cacheFile = '';
            
            obj.primaryHeadRoom = .005;
        end
    end
    
end