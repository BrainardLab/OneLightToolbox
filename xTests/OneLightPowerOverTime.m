function OneLightPowerOverTime
% OneLightPowerOverTime - Tests power over time using the OmniDriver.
%
% Syntax:
% OneLightPowerOverTime
%
% Description:
% Sets the mirrors to all on and takes continuous OmniDriver measurements
% for a specified amount of time (currenty 20 minutes).  Each measurement
% is summed to get an overal power measurement at a given point in time.
% The data is plotted and saved when the measurements are complete.

% Open the OneLight device.
ol = OneLight;

% Connect to the OceanOptics spectrometer.
od = OmniDriver;

% Turn on some averaging and smoothing for the spectrum acquisition.
od.ScansToAverage = 10;
od.BoxcarWidth = 2;

% Make sure electrical dark correction is enabled.
od.CorrectForElectricalDark = true;

% Turn all the mirrors on.
ol.setAll(true);

% Total time to measure in minutes.
measureDuration = 20;

% Load the cal file so we can get the OmniDriver integration time.
oneLightCal = LoadCalFile(OLCalibrationTypes.GlobeShortCable.CalFileName);

% Set the integration time.
od.IntegrationTime = oneLightCal.describe.omniDriver.integrationTime;

% Pre-allocate memory to store the spectrum power that we'll record.  We
% assume that the OmniDriver can make about 4-5 measurements per second, but
% we'll allocate for 10 just so we don't overrun our pre-allocated memory.
powerData = zeros(1, 10*measureDuration*60);
timeData = powerData;
measIndex = 0;

% Ask the user if this is a plugged test or an uplugged test.
while true
	isPlugged = GetWithDefault('Plugged (1) or Unplugged (0)', 1);
	
	if any(isPlugged == [0 1])
		break;
	else
		fprintf('*** Invalid choice, try again. ***\n');
	end
end

% Wait until the user hits enter to start the test.
numPauseSeconds = 10;
if isPlugged
	input(sprintf('*** Press enter to pause %d seconds and then begin.', numPauseSeconds));
else
	input(sprintf('*** Unplug the OneLight USB cable.  Press enter to pause %d seconds and then begin.', numPauseSeconds));
end

% Take continuous measurements until our time is up.
t0 = mglGetSecs;
mileStone = 0.1;
fprintf('- Starting measurements\n');
while (mglGetSecs-t0)/60 <= measureDuration
	% Print out some data every 10% of the way through just so the
	% experimenter knows somethings happening.
	t = (mglGetSecs-t0)/60;
	if t >= (measureDuration * mileStone)
		fprintf('- %d%% complete, %g minutes remaining.\n', round(mileStone*100), ...
			measureDuration - measureDuration * mileStone);
		mileStone = mileStone + 0.1;
	end
	
	% Take only an OmniDriver measurement.
	meas = OLTakeMeasurement([], od, [], [], [], [false true]);
	
	% Sum the spectrum and store it.
	measIndex = measIndex + 1;
	powerData(measIndex) = sum(meas.omni.spectrum);
	
	% Also store the time the measurement was taken.  Subtract off the
	% start time so we see the time relative to when the program started.
	timeData(measIndex) = meas.omni.time(1) - t0;
end
fprintf('- Done!\n');

% Chop off unused data entries at the end.
powerData = powerData(1:measIndex);
timeData = timeData(1:measIndex);

% Save the data.
if isPlugged
	saveFileNameBase = sprintf('OneLightPowerOverTime-Plugged-%s', strrep(strrep(datestr(now), ':', '-'), ' ', '_'));
else
	saveFileNameBase = sprintf('OneLightPowerOverTime-Unplugged-%s', strrep(strrep(datestr(now), ':', '-'), ' ', '_'));
end
saveFile = sprintf('%s.mat', saveFileNameBase);
saveDir = sprintf('%s/xPowerOverTimeOutput', fileparts(which('OneLightPowerOverTime')));
clear ol od; % We don't need to save these.
save(fullfile(saveDir, saveFile));

% Plot the results and save as a PDF.
figure; clf;
plot(timeData, powerData);
ylim([0 1.2*max(powerData)]);
saveFile = sprintf('%s.pdf', saveFileNameBase);
cwd = pwd;
cd(saveDir);
savefig(saveFile, gcf, 'pdf');
cd(cwd);

SendEmail('chrg@sas.upenn.edu', 'OneLight Power Over Time Test Complete', 'I am done.');
