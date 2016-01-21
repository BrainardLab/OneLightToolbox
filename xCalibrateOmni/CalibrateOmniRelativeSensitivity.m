% CalibrateOmniRelativeSensitivity
%
% The Omni radiometer comes to us with unknown relative sensitivity.  To
% make it useful, we need to figure that out.  We do this by measuring
% the same source with both the PR-6xx (or equivalent) and the Omni.
% The we can divide out and get a correction to apply to Omni data.
%
% We'll store the results of this calibration in PsychCalLocalData
% under name OmniDriverCal.
%
% Typical setup is to use the integrating sphere, point the PR-6xx down
% the bore, and stick the end of the Omni fiber into the aperture of the
% sphere.  It's a little tricky to hold it there, we found a gently
% tightenend small C-clamp could work pretty well in combination with
% the ND filter holder.
%
% Ideally, you'll have characterized the omni wl shift first, but you
% can redo that later if you like.  See OmniWavelenghtsTest.
%
% 7/16/12  dhb, ks, pl, js  Started to write it.
% 8/19/12  dhb              Adhered to power per wavelength band conventions
% 8/30/12  dhb, ks          Modify to allow PR-670

%% Clear
clear; close all
calFileName = 'OmniDriverCal';

%% Measure or just reanalyze?
fprintf('\n');
MEASURE = GetWithDefault('Measure? (0 -> analyze only, 1 -> measure and analyze)',1);


%% Measurement section
if (MEASURE)
    
    % Initialize PR-6XX.  This gets it ready to measure
    whichMeter = 5;
    global g_useIOPort
    if strcmp(computer, 'MACI64')
        g_useIOPort = 0;
    end
    CMCheckInit(whichMeter);
    
    % Initialize calibration structure
    cal.date = date;
    cal.pauseTimeSecs = 10;                 % Time for operator to leave the room
    cal.measureDark = false;
    cal.nMeasAverage = 20;                  % Number of measurements to average
    cal.omniScansToAvearge = 2;             % Omni parameter
    cal.omniBoxcarWidth = 2;                % Another one
    cal.omniCorrectForDarkCurrent = true;   % And yet one more
    cal.S = [380 2 201];                    % PR-6xx returns at these wavelengths
    
    % Connect to the Omni radiometer and initialize
    od = OmniDriver;
    od.Debug = true;
    od.ScansToAverage = cal.omniScansToAvearge;
    od.BoxcarWidth = cal.omniBoxcarWidth;
    od.CorrectForElectricalDark = cal.omniCorrectForDarkCurrent;
    cal.rawomniwls = od.Wavelengths;
    cal.omnifirmware = od.FirmwareVersion;
    cal.omniserialnumber = od.SerialNumber;
    cal.omnitype = od.SpectrometerType;
    cal.omnimaxinttime = od.MaxIntegrationTime;
    cal.omnimininttime = od.MinIntegrationTime;
    
    % Set up email to user
    emailToStr = GetWithDefault('Enter email address for done notification (empty string for none)','simmk@mail.med.upenn.edu');
    setpref('Internet', 'SMTP_Server', 'smtp-relay.upenn.edu');
    setpref('Internet', 'E_Mail', emailToStr);
    
    %% Blue or black fiber
    cal.fiberType = GetWithDefault('Which fiber is attached to the omni (Blue or Black)','Black');
    
    % Tell user to get things set up
    fprintf('Conguluations, you have initialized both the PR-6xx and the Omni spectrometer\n');
    fprintf('Now point them both at the same stable source\n');
    fprintf('Once you hit return, you''ll have %d seconds to turn lights off and leave the room if you like\n',cal.pauseTimeSecs);
    input('Hit return key when it''s time to begin the measurements');
    pause(cal.pauseTimeSecs);
    
    % Loop and make measurements
    for i = 1:cal.nMeasAverage
        % Make a measurement with the PR-6xx
        fprintf('Measuring with PR-6xx ...');
        cal.pr6xx(i).spd = MeasSpd(cal.S,whichMeter);
        fprintf('done.\n');
        
        % Make a measurement with the Omni
        fprintf('Finding omni integration time\n');
        od.IntegrationTime = od.findIntegrationTime(1000, 2, 20000);
        od.IntegrationTime = round(0.95*od.IntegrationTime);
        fprintf('Using time of %d us\n',od.IntegrationTime);
        cal.omni(i).integrationTime = od.IntegrationTime;
        fprintf('Measuring with omni ...');
        cal.omni(i).rawspectrum = od.getSpectrum';
        fprintf('done.\n');
        cal.omni(i).spectrum = cal.omni(i).rawspectrum/cal.omni(i).integrationTime;
        
        % Make a measurement with half the integration time.
        od.IntegrationTime = cal.omni(i).integrationTime/2;
        fprintf('Using time of %d us\n',od.IntegrationTime);
        cal.omni(i).halfIntegrationTime = od.IntegrationTime;
        fprintf('Measuring with omni ...');
        cal.omni(i).halfrawspectrum = od.getSpectrum';
        fprintf('done.\n');
        cal.omni(i).halfSpectrum = cal.omni(i).halfrawspectrum/cal.omni(i).halfIntegrationTime;
        
        % Make a measurement with one quarter of the integration time.
        od.IntegrationTime = cal.omni(i).integrationTime/4;
        fprintf('Using time of %d us\n',od.IntegrationTime);
        cal.omni(i).quarterIntegrationTime = od.IntegrationTime;
        fprintf('Measuring with omni ...');
        cal.omni(i).quarterrawspectrum = od.getSpectrum';
        fprintf('done.\n');
        cal.omni(i).quarterSpectrum = cal.omni(i).quarterrawspectrum/cal.omni(i).quarterIntegrationTime;
    end
    
    % Dark measurements
    if (cal.measureDark)
        fprintf('Now turn off the light source\n');
        fprintf('Once you hit return, you''ll have %d seconds to turn lights off and leave the room if you like\n',cal.pauseTimeSecs);
        input('Hit return key when it''s time to begin the measurements');
        pause(cal.pauseTimeSecs);
        
        %% Loop and make measurements
        for i = 1:cal.nMeasAverage
            % Make a measurement with the Omni
            od.IntegrationTime = cal.omni(i).integrationTime;
            fprintf('Measuring with omni ...');
            cal.omni(i).rawdarkspectrum = od.getSpectrum';
            fprintf('done.\n');
            cal.omni(i).darkspectrum = cal.omni(i).rawdarkspectrum/cal.omni(i).integrationTime;
        end
    else
        for i = 1:cal.nMeasAverage
            cal.omni(i).rawdarkspectrum = zeros(size(cal.omni(i).spectrum));
            cal.omni(i).darkspectrum = cal.omni(i).rawdarkspectrum/cal.omni(i).integrationTime;
        end
    end
    
    % Send email that we are done
    if (~isempty(emailToStr))
        sendmail(emailToStr, 'OmniDriver calibration measurements done', 'Time to move on to whatever is next');
    end
    
else
    % Load previous measurements
    cal = LoadCalFile(calFileName);
    
    % In early versions we didn't do wl correction.  Fix structure for new scheme.
    if (~isfield(cal,'rawomniwls'))
        cal.rawomniwls = cal.omniwls;
        cal = rmfield(cal,'omniwls');
    end
    
    % Enter fiber type field if it isn't there
    if (~isfield(cal,'fiberType'))
        cal.fiberType = GetWithDefault('Which fiber was attached to the omni (Blue or Black)','Black');
    end
end

%% Enter wavelength shift correction for omni.
% This value is subtracted from nominal omni wavelengths
% to get actual wavelengths.  See OmniWavelengthTest
% for how the appropriate shift is determined.
fprintf('Measurements made or loaded\n');
fprintf('Mean integration time was %d microseconds\n',mean([cal.omni.integrationTime]));
cal.wlShift = GetWithDefault('Enter wavelength shift (nm) to subtract from nominal omni wavelengths',0);
cal.omniwls = cal.rawomniwls - cal.wlShift;
    
%% Let's average and plot each set of measurements
figure; clf;
set(gcf,'Position',[1000 924 1132 414]);

% Plot PR-6xx spectra.
subplot(1,3,1); hold on
cal.avgPR6xx = zeros(size(cal.pr6xx(1).spd));
for i = 1:cal.nMeasAverage
    plot(SToWls(cal.S),cal.pr6xx(i).spd,'r');
    cal.avgPR6xx = cal.avgPR6xx + cal.pr6xx(i).spd;
end
cal.avgPR6xx = cal.avgPR6xx/cal.nMeasAverage;
plot(SToWls(cal.S),cal.avgPR6xx,'k');
title('PR-6xx Measurements');
xlabel('Wavelength (nm)')
ylabel('Calibrated Power');

% Plot Omni spectra.
subplot(1,3,2); hold on
cal.avgOmni = zeros(size(cal.omni(1).spectrum));
for i = 1:cal.nMeasAverage
    darkSubtractedSpectrum = cal.omni(i).spectrum - cal.omni(i).darkspectrum;
    plot(cal.omniwls,darkSubtractedSpectrum,'r');
    if (cal.measureDark)
        plot(cal.omniwls,cal.omni(i).darkspectrum,'k');
    end
    cal.avgOmni = cal.avgOmni + darkSubtractedSpectrum;
end
cal.avgOmni = cal.avgOmni/cal.nMeasAverage;
plot(cal.omniwls,cal.avgOmni,'k');
title('Omni Measurements');
xlabel('Wavelength (nm)')
ylabel('Uncalibrated Power');

%% Figure out factor to bring omni measurements into relative radiometric calibration

% Need common wavelength sampling and keep PR-6xx data in power per wavelength band.
pr6xxWls = SToWls(cal.S);
cal.commonWlsIndex = cal.omniwls > pr6xxWls(1) & cal.omniwls < pr6xxWls(end);
cal.commonWls = cal.omniwls(cal.commonWlsIndex);
deltaPR6xx = pr6xxWls(2)-pr6xxWls(1);
deltaCommon = cal.commonWls(2)-cal.commonWls(1);
cal.avgPR6xxCommonWls = interp1(pr6xxWls,cal.avgPR6xx,cal.commonWls)*deltaCommon/deltaPR6xx;
cal.avgOmniCommonWls = interp1(cal.omniwls,cal.avgOmni,cal.commonWls);

% Get correction factor, end up in power per wavelength band
cal.omniCorrect = cal.avgPR6xxCommonWls ./ cal.avgOmniCommonWls;
subplot(1,3,3)
plot(cal.commonWls,cal.omniCorrect,'k');
title('Correction Function');
xlabel('Wavelength (nm)')
ylabel('Correction');

%% Plot Omni spectra for full, half, and quarter integration times.
figure; clf;
hold on
cal.avgHalfOmni = zeros(size(cal.omni(1).halfSpectrum));
cal.avgQuarterOmni = zeros(size(cal.omni(1).quarterSpectrum));
for i = 1:cal.nMeasAverage
    darkSubtractedSpectrum = cal.omni(i).spectrum - cal.omni(i).darkspectrum;
    plot(cal.omniwls,darkSubtractedSpectrum,'r');
    
    darkSubtractedSpectrum = cal.omni(i).halfSpectrum - cal.omni(i).darkspectrum;
    plot(cal.omniwls,darkSubtractedSpectrum,'g');
    cal.avgHalfOmni = cal.avgHalfOmni + darkSubtractedSpectrum;
    
    darkSubtractedSpectrum = cal.omni(i).quarterSpectrum - cal.omni(i).darkspectrum;
    plot(cal.omniwls,darkSubtractedSpectrum,'b');
    cal.avgQuarterOmni = cal.avgQuarterOmni + darkSubtractedSpectrum;
    
    if (cal.measureDark)
        plot(cal.omniwls,cal.omni(i).darkspectrum,'k');
    end
end
cal.avgHalfOmni = cal.avgHalfOmni/cal.nMeasAverage;
cal.avgQuarterOmni = cal.avgQuarterOmni/cal.nMeasAverage;
% plot(cal.omniwls,cal.avgOmni,'k');
% plot(cal.omniwls,cal.avgHalfOmni,'k--');
% plot(cal.omniwls,cal.avgQuarterOmni,'k.-');
title('Omni Measurements');
xlabel('Wavelength (nm)')
ylabel('Uncalibrated Power');

%% Save the calibration file
if (MEASURE)
    fprintf('Saving calibration\n');
    SaveCalFile(cal,calFileName);
else
    saveIt = GetWithDefault('Save reanalyzed data (0 -> no, 1 -> yes)?',0);
    if (saveIt)
        fprintf('Saving calibration\n');
        SaveCalFile(cal,calFileName); 
    end
end




