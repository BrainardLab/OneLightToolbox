% Method to initialize the stateTracking substruct of cal
function cal = InitStateTracking(cal0)

    cal = cal0;
    nPrimaries = cal.describe.numWavelengthBands;
    
    % Specify how often (every how many stimuli) to gauge the system state
    % In other words when to insert the power fluctuation and the spectral
    % shift gauge stimuli
    cal.describe.stateTracking.calibrationStimInterval = 5;
    cal.describe.stateTracking.calibrationStimIndex = 0;
    cal.describe.stateTracking.stateMeasurementIndex = 0;
    
    % Define the state tracking stimulus settings
    cal.describe.stateTracking.stimSettings.powerFluctuationsStim = ones(nPrimaries,1);
    cal.describe.stateTracking.stimSettings.spectralShiftsStim = zeros(nPrimaries,1);
    cal.describe.stateTracking.stimSettings.spectralShiftsStim(2:10:end) = 1.0;
end
