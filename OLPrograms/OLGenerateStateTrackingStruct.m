function stateTracking = OLGenerateStateTrackingStruct(cal)
%OLGenerateStateTrackingStruct - Generate state tracking struct from calibration file
%
% stateTracking = OLGenerateStateTrackingStruct(cal)
%
% These are baseically settings for the SPDs that we use to track fluctuations
% power spectral shifts in the OneLight
%
% 06/30/18  npc      Wrote it

    nPrimaries = cal.describe.numWavelengthBands;
    
    % Specify how often (every how many stimuli) to gauge the system state
    % In other words when to insert the power fluctuation and the spectral
    % shift gauge stimuli
    stateTracking.calibrationStimInterval = 5;
    stateTracking.calibrationStimIndex = 0;
    stateTracking.stateMeasurementIndex = 0;
    
    % Define the state tracking stimulus settings
    stateTracking.stimSettings.powerFluctuationsStim = ones(nPrimaries,1);
    stateTracking.stimSettings.spectralShiftsStim = zeros(nPrimaries,1);
    stateTracking.stimSettings.spectralShiftsStim(2:10:end) = 1.0;
end

