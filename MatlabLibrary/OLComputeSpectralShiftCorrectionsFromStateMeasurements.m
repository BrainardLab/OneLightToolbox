% OLComputeSpectralShiftCorrectionsFromStateMeasurements - Returns a struct which contains spectral shift amplitude and time information for the sequence of spectral shift measurements in a calfile.
%
% Syntax:
%   spectralShiftCorrection = OLComputeSpectralShiftCorrectionsFromStateMeasurements(cal)
%
% 8/22/16   npc     Wrote it.

function spectralShiftCorrection = OLComputeSpectralShiftCorrectionsFromStateMeasurements(cal)

    referenceSPD = cal.raw.spectralShiftsMeas.measSpd(:, 1);
    
    spectralAxis = SToWls(cal.describe.S);
    % Peaks of the comb function
    combPeaks = [480 540 596 652]+10; 
    
    for stateMeasIndex = 1:size(cal.raw.spectralShiftsMeas.measSpd,2)-1
        theSPD = cal.raw.spectralShiftsMeas.measSpd(:, stateMeasIndex);
        [spectralShifts, referenceSPDpeaks, fitParams, paramNames] = OLComputeSpectralShiftBetweenCombSPDs(theSPD, referenceSPD, combPeaks, spectralAxis);
        % median shift across the 4 peaks
        spectralShiftCorrection.amplitudes(stateMeasIndex) = -median(spectralShifts);
        spectralShiftCorrection.times(stateMeasIndex) = cal.raw.spectralShiftsMeas.t(:, stateMeasIndex);
        spectralShiftCorrection.fitParams(stateMeasIndex,:,:) = fitParams;
    end
    
    %disp('OLComputeSpectralShiftCorrectionsFromStateMeasurements:');
    spectralShiftCorrection.paramNames = paramNames;
    spectralShiftCorrection.combPeaks = combPeaks;
    spectralShiftCorrection.referenceSPDpeaks = referenceSPDpeaks;
end
