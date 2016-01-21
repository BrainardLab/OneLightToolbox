clc;
whichBoxTest = 'BoxA';
whichDate = datestr(now, 'yyyymmdd');

% Set up the OneLight
ol = OneLight;

% We do not use the Omni for this, but need to pass the empty matrix.
od = OmniDriver;

% Set up properties of the spectrometer
whichMeter = 'PR-670';
prWhichMeter = 5;
S = [380 2 201];
nAverage = 1;

t0 = mglGetSecs();
%% Load CIE functions.
load T_xyz1931
T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);

while true
    clear meas;
    
    % Turn the OneLight to full-on
    ol.setAll(true); pause(0.1);
    
    % Take a measurement
    meas.time = mglGetSecs(t0);
    fprintf('%s : Taking measurement.', datestr(now));
    %[radMeas, qual] = MeasSpd(S,prWhichMeter,'off');
    starts(1:1024) = 0; stops(1:1024) = 767;
    
    od.IntegrationTime = od.findIntegrationTime(100, 2, 100);
    od.IntegrationTime = round(0.8*od.IntegrationTime);
    
    tmp = OLTakeMeasurement(ol, od, starts, stops, S, [0 1], [], 10)
    fprintf('- Done.\n');
    meas.spectrum = tmp.omni.spectrum;
    meas.S = S;
    %meas.photopicLuminanceCdM2 = T_xyz(2,:)*meas.spectrum;
    mglWaitSecs(60);
    
    SaveCalFile(meas, [whichBoxTest '_' whichDate '_ContFullOn.mat'], '/Users/Shared/MATLAB/Toolboxes/PsychCalLocalData/OneLight')
    dlmwrite(fullfile('/Users/Shared/MATLAB/Toolboxes/PsychCalLocalData/OneLight', [whichBoxTest '_' whichDate '_ContFullOn.csv']), [meas.time sum(tmp.omni.spectrum)], '-append');
end