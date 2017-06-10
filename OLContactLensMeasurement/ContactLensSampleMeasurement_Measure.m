% Set up properties of the spectrometer
whichMeter = 'PR-670';
prWhichMeter = 5;
S = [380 2 201];
nAverage = 5;

sampleName = GetInput('Enter sample name', 'string');
sampleDetails = GetInput('Enter sample details', 'string');
CMCheckInit(5);
%% Measurement without sample
system('say Measurement without sample. Press enter to take measurements.');
input('');
radMeasAvg = 0;
measWithSample.pr650.time(1) = mglGetSecs;
for i = 1:nAverage
    [radMeas, qual] = MeasSpd(S,prWhichMeter,'off');
    radMeasAvg = radMeasAvg + radMeas;
end
radMeasAvg = radMeasAvg/nAverage;
measWithSample.pr650.spectrum = radMeasAvg;
measWithSample.pr650.time(2) = mglGetSecs;
measWithSample.pr650.S = S;
system('say Measurement done.');

%% Measurement sample sample
system('say Measurement with sample. Press enter to take measurements.');
input('');
radMeasAvg = 0;
measWithoutSample.pr650.time(1) = mglGetSecs;
for i = 1:nAverage
    [radMeas, qual] = MeasSpd(S,prWhichMeter,'off');
    radMeasAvg = radMeasAvg + radMeas;
end
radMeasAvg = radMeasAvg/nAverage;
measWithoutSample.pr650.spectrum = radMeasAvg;
measWithoutSample.pr650.time(2) = mglGetSecs;
measWithoutSample.pr650.S = S;
system('say Measurement done.');

cal.date = date;
cal.nAverage = nAverage;
cal.sampleName = sampleName;
cal.sampleDetails = sampleDetails;
cal.measWithSample = measWithSample;
cal.measWithoutSample = measWithoutSample;

save(fullfile(CalDataFolder, ['transmittance_sample_' sampleName '_' date]), 'cal');