function cal = OLCalWithStateMatchingCurrentDeviceState(cal0, referenceFullONSPD, referenceCombSPD)
% OLCalWithStateMatchingCurrentDeviceState - Create a new cal in which the computed quantities match the power and spectral shift state as derived from the passed referenceFullONSPD and referenceCombSPD.
% Syntax:
% cal = OLCalWithStateMatchingCurrentDeviceState(cal0, referenceFullONSPD, referenceCombSPD);
%
% 8/23/16  npc      Wrote it.
%

    cal = cal0;
    spectralAxis = SToWls(cal.describe.S);
    % Peaks of the comb function
    combPeaks = [480 540 596 652]+10; 
    
    % Pick the first measurements from the cal file
    fullONSPD = cal.raw.powerFluctuationMeas.measSpd(:,1);
    combSPD = cal.raw.spectralShiftsMeas.measSpd(:, 1);
    wavelengthIndices = find(fullONSPD(:) > 0.2*max(fullONSPD(:)));
    
    % Compute daily scale factor
    cal.computed.dailyAdjustment.date = datestr(now);
    cal.computed.dailyAdjustment.scaleFactor = 1.0 / (referenceFullONSPD(wavelengthIndices) \ fullONSPD(wavelengthIndices,1));
   
    % Compute daily spectral shift amount that needs to be applied to the referenceSPD in order to align it with the current combSPD
    [spectralShifts, referenceSPDpeaks] = OLComputeSpectralShiftBetweenCombSPDs(combSPD, referenceCombSPD, combPeaks, spectralAxis);
    % median shift across the 4 peaks
    cal.computed.dailyAdjustment.spectralShiftCorrection = -median(spectralShifts);
      
    % Adjust all computed SPDs according to the computed (1) scale factor and (2) spectral shift amount
    % 1. scale factor
    fprintf('Applying scale factor ,<strong> %2.5f</strong>, to the cal SPDs\n', cal.computed.dailyAdjustment.scaleFactor);
    cal.computed.pr650M = cal.computed.pr650M * cal.computed.dailyAdjustment.scaleFactor;
    cal.computed.pr650Md = cal.computed.pr650Md * cal.computed.dailyAdjustment.scaleFactor;
    if (cal.describe.specifiedBackground)
        cal.computed.pr650MSpecifiedBg = cal.computed.pr650MSpecifiedBg * cal.computed.dailyAdjustment.scaleFactor;
        cal.computed.pr650MEffectiveBg = cal.computed.pr650MEffectiveB * cal.computed.dailyAdjustment.scaleFactor;
    end
    
    cal.computed.wigglyMeas.measSpd = cal.computed.wigglyMeas.measSpd * cal.computed.dailyAdjustment.scaleFactor;
    cal.computed.halfOnMeas = cal.computed.halfOnMeas * cal.computed.dailyAdjustment.scaleFactor;
    cal.computed.fullOn = cal.computed.fullOn * cal.computed.dailyAdjustment.scaleFactor;
    
    % 2. spectral shift correction
    fprintf('\nApplying spectral shift correction, <strong>%2.5f nm</strong>, to the cal SPDs\n', cal.computed.dailyAdjustment.spectralShiftCorrection);
    cal.computed.pr650M = OLApplySpectralShiftCorrection(cal.computed.pr650M, cal.computed.dailyAdjustment.spectralShiftCorrection, spectralAxis);
    cal.computed.pr650Md = OLApplySpectralShiftCorrection(cal.computed.pr650Md, cal.computed.dailyAdjustment.spectralShiftCorrection, spectralAxis);
    if (cal.describe.specifiedBackground)
        cal.computed.pr650MSpecifiedBg = OLApplySpectralShiftCorrection(cal.computed.pr650MSpecifiedBg, cal.computed.dailyAdjustment.spectralShiftCorrection, spectralAxis);
        cal.computed.pr650MEffectiveBg = OLApplySpectralShiftCorrection(cal.computed.pr650MEffectiveBg, cal.computed.dailyAdjustment.spectralShiftCorrection, spectralAxis);
    end
    
    cal.computed.wigglyMeas.measSpd = OLApplySpectralShiftCorrection(cal.computed.wigglyMeas.measSpd, cal.computed.dailyAdjustment.spectralShiftCorrection, spectralAxis);
    cal.computed.halfOnMeas = OLApplySpectralShiftCorrection(cal.computed.halfOnMeas, cal.computed.dailyAdjustment.spectralShiftCorrection, spectralAxis);
    cal.computed.fullOn = OLApplySpectralShiftCorrection(cal.computed.fullOn, cal.computed.dailyAdjustment.spectralShiftCorrection, spectralAxis);

% just for testing
%     combSPDadjusted =  OLApplySpectralShiftCorrection(combSPD, cal.computed.dailyAdjustment.spectralShiftCorrection, spectralAxis);
%     
%     figure();
%     clf;
% 
%     plot(spectralAxis, combSPD-referenceCombSPD, 'k-'); hold on;
%     plot(spectralAxis, combSPDadjusted-referenceCombSPD, 'r-');
   
end

