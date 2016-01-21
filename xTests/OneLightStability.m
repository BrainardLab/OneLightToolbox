function OneLightStability
% OneLightStability - Program to check the stability of spectrometer measurements.
%
%

global g_useIOPort;

% Tell the radiometer routines to use SerialComm.
g_useIOPort = 0;

% Open up the radiometer.
CMCheckInit;

% Open the OneLight device.
ol = OneLight;

% Connect to the OceanOptics spectrometer.
od = OmniDriver;

% Turn on some averaging and smoothing for the spectrum acquisition.
od.ScansToAverage = 10;
od.BoxcarWidth = 2;

% Make sure electrical dark correction is enabled.
od.CorrectForElectricalDark = true;

% Turn all mirrors on, but reduce the total power.  Otherwise, the PR-650
% gets too much light when taking a measurement.
overallPower = 0.5;
starts = zeros(1, ol.NumCols);
stops = ones(1, ol.NumCols) * round(overallPower * ol.NumRows);
ol.setMirrors(starts, stops);

% Load the OneLight calibration file.
oneLightCal = OLInitCal('OneLight');

% Set the OmniDriver integration time.  We'll use the value used in the
% most recent calibration.
od.IntegrationTime = oneLightCal.describe.omniDriver.integrationTime;

% Number of OmniDriver measurements to take per block.
numOmniMeasurements = 10;

% Number of blocks.
numBlocks = 5;

input('*** Make sure that the light is on, then press enter to continue');

for b = 1:numBlocks
	for i = 1:numOmniMeasurements
		fprintf('- Plugged OmniDriver measurement, block %d, iteration %d\n', b, i);
		
		% Take an OmniDriver measurement.
		measOmni(b, i) = OLTakeMeasurement([], od, [], [], oneLightCal.describe.S, [false true]); %#ok<*NASGU,*AGROW>
		
		% Take a PR-650 measurement.  We take a measurement once per block,
		% but in a different order location for each block.
		if b == i
			fprintf('- Plugged PR-650 measurement\n');
			measPR650(b) = OLTakeMeasurement([], od, [], [], oneLightCal.describe.S, [true false]);
		end
		
		% Wait a little bit.
		pause(6);
	end
end

% Run the same set of measurement as before, but this time we'll unplug the
% USB cable.
input('*** Unplug the OneLight device from the USB port and press enter.');

for b = 1:numBlocks
	for i = 1:numOmniMeasurements
		fprintf('- Unplugged OmniDriver measurement, block %d, iteration %d\n', b, i);
		
		% Take an OmniDriver measurement.
		measOmniUnplugged(b, i) = OLTakeMeasurement([], od, [], [], oneLightCal.describe.S, [false true]); %#ok<*AGROW>
		
		% Take a PR-650 measurement.  We take a measurement once per block,
		% but in a different order location for each block.
		if b == i
			fprintf('- Unplugged PR-650 measurement\n');
			measPR650Unplugged(b) = OLTakeMeasurement([], od, [], [], oneLightCal.describe.S, [true false]);
		end
		
		% Wait a little bit.
		pause(6);
	end
end

% Save the data.
saveFile = sprintf('OneLightStability_%s.mat', strrep(strrep(datestr(now), ':', '-'), ' ', '_'));
saveDir = sprintf('%s/xStabilityTestOutput', fileparts(which('OneLightStability')));
clear ol od; % We don't need to save these.
save(fullfile(saveDir, saveFile));

% Make a useful plot
figure; clf; hold on
for b = 1:numBlocks
	plot(SToWls(measPR650(b).pr650.S),measPR650(b).pr650.spectrum,'r');
	plot(SToWls(measPR650Unplugged(b).pr650.S),measPR650Unplugged(b).pr650.spectrum,'b');
end
saveFile = sprintf('OneLightStabilityPR650_%s.pdf', strrep(strrep(datestr(now), ':', '-'), ' ', '_'));
curDir = pwd;
cd(saveDir);
savefig(saveFile,gcf,'pdf');
cd(curDir);

% Make a useful plot
figure; clf; hold on
for b = 1:numBlocks
	for i = 1:numOmniMeasurements
		plot(measOmni(b,i).omni.spectrum,'r');
		plot(measOmniUnplugged(b,i).omni.spectrum,'b');
		max(measOmniUnplugged(b,i).omni.spectrum);
	end
end
saveFile = sprintf('OneLightStabilityOmni_%s.pdf', strrep(strrep(datestr(now), ':', '-'), ' ', '_'));
curDir = pwd;
cd(saveDir);
savefig(saveFile,gcf,'pdf');
cd(curDir);


