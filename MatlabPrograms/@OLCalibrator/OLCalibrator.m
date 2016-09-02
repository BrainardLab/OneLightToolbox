% Static class with OneLight calibration-related methods
%
% 9/2/2016  npc   Wrote it
%

classdef OLCalibrator
    
    methods (Static = true)    
        % Method to take state measurements for a OneLight calibration. In stand alone mode,
        % the data are added to a barebones calibration structure.
        [cal, calMeasOnly] = TakeStateMeasurements(cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, standAlone);
    
        % Method to take full ON measurements.
        cal = TakeFullOnMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
        
        % Method to take half ON measurements.
        cal = TakeHalfOnMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
            
        % Method to take wiggly spectrum measurements.
        cal = TakeWigglyMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
        
        % Method to take dark measurements.
        cal = TakeDarkMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
        
        % Method to take specified background measurements.
        cal = TakeSpecifiedBackgroundMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
    
        % Method to take primary SPD measurements.
        [cal, primaryMeasurement] = TakePrimaryMeasurement(cal0, primaryIndex, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
    
        % Method to take gamma measurements.
        cal = TakeGammaMeasurements(cal0, gammaBandIndex, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
    
        % Method to take measurements that assess primary independence
        cal = TakeIndependenceMeasurements(cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage);
    
        % Method to visualize the OneLight state progression during a calibration.
        VisualizeStateProgression();      
    end
end
