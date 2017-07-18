% Static class with OneLight calibration-related methods
%
% 9/2/2016  npc   Wrote it
% 9/29/16   npc   Optionally record temperature
% 12/21/16  npc   Updated for new class @LJTemperatureProbe

classdef OLCalibrator
    
    methods (Static = true)    
        
        % Method to initialize the stateTracking substruct of cal
        cal = InitStateTracking(cal0);
        
        % Method to take state measurements for a OneLight calibration. In stand alone mode,
        % the data are added to a barebones calibration structure.
        [cal, calMeasOnly] = TakeStateMeasurements(cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, standAlone, theLJdev, varargin);
    
        % Method to take full ON measurements.
        cal = TakeFullOnMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, varargin);
        
        % Method to take half ON measurements.
        cal = TakeHalfOnMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, varargin);
            
        % Method to take wiggly spectrum measurements.
        cal = TakeWigglyMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, varargin);
        
        % Method to take dark measurements.
        cal = TakeDarkMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, varargin);
        
        % Method to take specified background measurements.
        cal = TakeSpecifiedBackgroundMeasurement(measurementIndex, cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, varargin);
    
        % Method to take primary SPD measurements.
        [cal, primaryMeasurement] = TakePrimaryMeasurement(cal0, primaryIndex, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, varargin);
    
        % Method to take gamma measurements.
        cal = TakeGammaMeasurements(cal0, gammaBandIndex, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, varargin);
    
        % Method to take measurements that assess primary independence
        cal = TakeIndependenceMeasurements(cal0, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, theLJdev, varargin);

        % Method to save barebones state measurements
        SaveStateMeasurements(cal0, cal1, protocolParams);
        
        % Method to visualize the OneLight state progression during a calibration.
        VisualizeStateProgression();      
        
        % Method to gracefull open the LabJackTemperatureProbe
        [takeTemperatureMeasurements, quitNow, theLJdev] = OpenLabJackTemperatureProbe(takeTemperatureMeasurements0);
    end
end
