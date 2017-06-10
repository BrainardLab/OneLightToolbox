function cal = OLZeroCalPrimariesAwayFromPeak(cal,zeroItWLRangeMinus,zeroItWLRangePlus)
%OLZeroCalPrimariesAwayFromPeak
%   cal = OLZeroCalPrimariesAwayFromPeak(cal,zeroItWLRangeMinus,zeroItWLRangePlus)
%
% Set power in primaries to zero at wavelength away from their peak.  This
% is with the thought that measured power out there is really just
% measurement noise.
%
% The two range arguments say how far away from the peak wavelength should
% be preserved before zeroing.

deviceM = cal.computed.pr650M;
wls = SToWls(cal.describe.S);
%figure;
for kk = 1:size(deviceM,2)
    [peakVals(kk),peakWlIndex] = max(deviceM(:,kk));
    peakWls(kk) = wls(peakWlIndex);
    %fprintf('Wl: %d, peak = %0.2g\n',peakWls(kk),peakVals(kk));

    zeroIndex = find(wls < peakWls(kk)-zeroItWLRangeMinus | wls > peakWls(kk)+zeroItWLRangePlus);
    deviceM(zeroIndex,kk) = 0;
    %plot(wls,cal.computed.pr650M(:,kk),'r');  hold on;
    %plot(wls,deviceM(:,kk),'g');
    %hold off;
end
cal.computed.pr650M = deviceM;