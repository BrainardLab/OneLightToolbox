% OmniWavelengthTest
%
% Check the wavelength calibration of the radiometer that came with the one light device.
%
% September 2, 2012, DHB.  Here are some observations.
%   First, the auto-integration time routines do not work with with the CVI
%   line sources. I am not sure why, but my guess is that the sources
%   flicker somehow, and with the very short integration times necessary
%   there is some stochasisity to the whole process.  Either that, or the
%   instruments precision on integration time is not good for such short
%   (~1000 ms) times.  So this routine uses hand chosen times that lead to
%   reasonable measurement values.  These depend on the source and which
%   fiber is used.
%
%   To deal with the stochasticity, the routine averages 500 short
%   measurements for each source.
% 
%   Even with the averaging, there is some weird variability for the HG
%   source. Sometimes its long wavelength lines have more power than the
%   short ones, and sometimes the other way around.  I have no idea why
%   this happens.  I choose an integration time that tends to produce good
%   measurements for the short wavelenght lines and forced an ignore if
%   there are some saturated numbers.  It's a good idea to look by hand at
%   the plots and make sure that none of the lines one cares about are
%   saturated (saturation is at about 60,000.  Probably right at 65,535.)
%
%   The blue fiber leads to more narrowly peaked measurements than the
%   black.  The black fiber seems to let a bit more light through. By eye,
%   the FWHM for the blue fiber is 2.5 nm while for the black fiber it is
%   about 6 nm.
%
%   There is some run-to-run variability in what happens. On average, the
%   wavelength calibration seems off by about 3 nm, but every once in a
%   while there is a run where it is just about right on.  Compare the
%   black fiber measurement 090212 (about 0.5 nm off) with 090212a (about 2 nm off).
%   I pulled the fiber out of the omni and put it back in with each run.
%   There didn't seem to be much systematic difference in the wl error
%   between the two fibers.  To correct for this, subtract the value given
%   in the figure title from the nominal wavelength to get the actual
%   wavelength.  (That is, if a peak is found at a wavelength longer than
%   it should be at, the nominal wavelengths are longer than the actual
%   wavelengths, and so should be shortened by the correction.)
%
% 12/12/11  dhb  Wrote it.
% 9/3/12    dhb  Get spectral peaks off of lamp data sheets.
% 9/4/12    dhb  Improve summary plot axis lablels.  Add test of correction routine.
%           dhb  Improved (but did not test) handling of saturated measurements.

%% Clear and close
clear; close all;

% Change so that we're running where this lives.
myDir = fileparts(mfilename('fullpath'));
cd(myDir);

%% Parameters
fiberType = 'Blue';
fiberType = 'Black';
doWlCorrect = true;

dateStr = '121211';
dateStr = '090212';
ANALYZEONLY = 1;
nAverage = 500;

%% Load cal file if needed
if (doWlCorrect)
    omniCal = LoadCalFile('OmniDriverCal');
    fprintf('Applying correction to relative sensitivity\n');
    fprintf('This includes a wavelength shift correction of %g nm\n',omniCal.wlShift);
end

%% Set up omni
if (~ANALYZEONLY)
    cal.omniScansToAverage = 2;             % Omni parameter
    cal.omniBoxcarWidth = 2;                % Another one
    cal.omniCorrectForDarkCurrent = true;   % And yet one more
    od = OmniDriver;
    od.Debug = true;
    od.ScansToAverage = cal.omniScansToAverage;
    od.BoxcarWidth = cal.omniBoxcarWidth;
    od.CorrectForElectricalDark = cal.omniCorrectForDarkCurrent;
    cal.omniwls = od.Wavelengths;
    cal.omnifirmware = od.FirmwareVersion;
    cal.omniserialnumber = od.SerialNumber;
    cal.omnitype = od.SpectrometerType;
    cal.omnimaxinttime = 1e6;
    cal.omnimininttime = od.MinIntegrationTime;
    
    %% Measure AR source
    input('Set up AR source in its holder and hit enter when ready to measure');
    switch(fiberType)
        case 'Blue'
            od.IntegrationTime = 2000;
        case 'Black';
            od.IntegrationTime = 500;
    end
    sRaw = 0;
    nOK = 0;
    for i = 1:nAverage
        [temp,isSaturated] = od.getSpectrum(true);
        if (isSaturated)
            fprintf('Warning, saturated measurement %d,ignoring\n',i);
        else
            sRaw = sRaw + temp';
            nOK = nOK+1;
        end
    end
    sRaw = sRaw/nOK;
    fprintf('Averaged %d non-saturated measurements\n',nOK);
    
    s = sRaw;
    wavelengths = od.Wavelengths; 
    save(['arspectrum_' dateStr '_' fiberType],'wavelengths','sRaw','s');
    
    input('Set up HG source in its holder and hit enter when ready to measure');
    switch(fiberType)
        case 'Blue'
            od.IntegrationTime = 3000;
        case 'Black';
            od.IntegrationTime = 1000;
    end
    sRaw = 0;
    nOK = 0;
    for i = 1:nAverage
        [temp,isSaturated] = od.getSpectrum(true);
        if (isSaturated)
            fprintf('Warning, saturated measurement %d,ignoring\n',i);
        else
            sRaw = sRaw + temp';
            nOK = nOK+1;
        end
    end
    sRaw = sRaw/nOK;
    fprintf('Averaged %d non-saturated measurements\n',nOK);
    
    s = sRaw; 
    wavelengths = od.Wavelengths;
    save(['hgspectrum_' dateStr '_' fiberType],'wavelengths','sRaw','s');
end

%% Read in measurements
armeas = load(['arspectrum_' dateStr '_' fiberType]);
hgmeas = load(['hgspectrum_' dateStr '_' fiberType]);

%% Do relative spectrum and wavelength corrections, if desired
if (doWlCorrect)
    [armeas.s,armeas.wavelengths] = OmniRawToRelative(omniCal,armeas.s);
    [hgmeas.s,hgmeas.wavelengths] = OmniRawToRelative(omniCal,hgmeas.s);
end

%% AR measurements
calibNominal = [];
calibMeasured = [];

% Plot it
figure(1); clf; hold on
plot(armeas.wavelengths,armeas.s,'b');
title('AR measurements');
drawnow;

% Now find the measured peak in each of the candidate
% peak locations
arcandidatePeaks = [696.5 706.7 727.3 738.4 763.5];
wlSpread = 4;
for i = 1:length(arcandidatePeaks)
    theIndex = find(armeas.wavelengths > arcandidatePeaks(i)-wlSpread & ...
        armeas.wavelengths < arcandidatePeaks(i)+wlSpread);
    theWls = armeas.wavelengths(theIndex);
    theData = armeas.s(theIndex);
    [nil,peakIndex] = max(theData);
    peakWl = theWls(peakIndex);
    fprintf('Candidate wavelength %g, peak at %g\n',...
        arcandidatePeaks(i),peakWl);
    
    % Draw the peaks onto the spectrum
    figure(1); hold on
    plot([peakWl peakWl],[0 max(armeas.s)],'g');
    plot([arcandidatePeaks(i) arcandidatePeaks(i)],[0 max(armeas.s)],'r');
    
    hold off
    drawnow;
    
    % Make a blowup
    figure(i+1); clf;
    plot(theWls,theData,'b');
    hold on
    plot(theWls,theData,'b+');
    plot([peakWl peakWl],[0 max(theData)],'g');
    plot([arcandidatePeaks(i) arcandidatePeaks(i)],[0 max(theData)],'r');
    hold off
    xlabel('Wavelength (nm)');
    ylabel('Power');
    title(sprintf('AR nominal peak at %g nm',arcandidatePeaks(i)));
    drawnow;
    
    calibNominal = [calibNominal arcandidatePeaks(i)];
    calibMeasured = [calibMeasured peakWl];
end

%% AR measurements

% Plot it
figure(2+length(arcandidatePeaks)); clf; hold on
plot(hgmeas.wavelengths,hgmeas.s,'b');
title('HG measurements');
drawnow;

% Now find the measured peak in each of the candidate
% peak locations
hgcandidatePeaks = [404.7 435.8 546.1 579];
wlSpread = 4;
for i = 1:length(hgcandidatePeaks)
    theIndex = find(hgmeas.wavelengths > hgcandidatePeaks(i)-wlSpread & ...
        hgmeas.wavelengths < hgcandidatePeaks(i)+wlSpread);
    theWls = hgmeas.wavelengths(theIndex);
    theData = hgmeas.s(theIndex);
    [nil,peakIndex] = max(theData);
    peakWl = theWls(peakIndex);
    fprintf('Candidate wavelength %g, peak at %g\n',...
        hgcandidatePeaks(i),peakWl);
    
    % Draw the found peaks onto the spectrum
    figure(2+length(arcandidatePeaks)); hold on
    plot([peakWl peakWl],[0 max(hgmeas.s)],'g');
    plot([hgcandidatePeaks(i) hgcandidatePeaks(i)],[0 max(hgmeas.s)],'r');
    hold off
    drawnow;
    
    % Make a blowup
    figure(i+ 2 + length(arcandidatePeaks)); clf;
    plot(theWls,theData,'b');
    hold on
    plot(theWls,theData,'b+');
    plot([peakWl peakWl],[0 max(theData)],'g');
    plot([hgcandidatePeaks(i) hgcandidatePeaks(i)],[0 max(theData)],'r');
    hold off
    xlabel('Wavelength (nm)');
    ylabel('Power');
    title(sprintf('HG nominal peak at %g nm',hgcandidatePeaks(i)));
    drawnow;
    
    calibNominal = [calibNominal hgcandidatePeaks(i)];
    calibMeasured = [calibMeasured peakWl];
end

figure; clf; hold on
plot(calibNominal,calibMeasured,'ro','MarkerSize',8,'MarkerFaceColor','r');
plot([380 780],[380 780],'r','LineWidth',1);
axis('square'); axis([380 780 380 780]);
xlabel('Known Peak Wl'); ylabel('Measured Peak Wl');

%% Print out mean difference
wavelengthCorrect = mean(calibMeasured)-mean(calibNominal);
fprintf('Nominal wavelength correct (subtract from nominal wl to get actual wl) is %0.3g nm\n',wavelengthCorrect);
plot([380 780],[380 780]+wavelengthCorrect,'k','LineWidth',0.5);
if (doWlCorrect)
    title(sprintf('After correction of %0.3g nm, found correction of %0.3g nm',omniCal.wlShift,wavelengthCorrect));
    saveas(gcf,['OmniWlTest_Corrected_' dateStr '_' fiberType '.pdf'],'pdf');
else
    title(sprintf('Found wavelength correction: %0.3g nm',wavelengthCorrect));
    saveas(gcf,['OmniWlTest_' dateStr '_' fiberType '.pdf'],'pdf');
end




