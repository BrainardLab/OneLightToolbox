function primaryGammaAdditivityTest = OLPrimaryGammaAndAdditivityTest(cal, whichPrimaryToTest, separationNPrimaries, thePowerLevels);
%
% Program to test the addivity of adjacent and non-adjacent primaries in
% the OneLight.
%
% Returns a struct
%
% 12/10/15      ms      Wrote it.

% Get the calibration structure
wls = SToWls(cal.describe.S);

% Pick the flanking primary
whichPrimaryToTestLeft = whichPrimaryToTest-separationNPrimaries;
whichPrimaryToTestRight = whichPrimaryToTest+separationNPrimaries;
whichPrimaryToTest = [whichPrimaryToTestLeft whichPrimaryToTest whichPrimaryToTestRight];

%% Initialize the OneLight and spectrometer
ol = OneLight;
pause(2);

for ii = 1:length(thePowerLevels)
    primaryBuffer = zeros(cal.describe.numWavelengthBands, 1);
    primaryBuffer(whichPrimaryToTest) = thePowerLevels{ii};
    
    settingsBuffer = OLPrimaryToSettings(cal, primaryBuffer);
    [startsBuffer, stopsBuffer] = OLSettingsToStartsStops(cal, settingsBuffer);
    predictedSpdBuffer = OLPrimaryToSpd(cal, primaryBuffer);
    
    % Take the measurement
    meas = OLTakeMeasurement(ol, [], startsBuffer, stopsBuffer, cal.describe.S, [1 0], 5, 1);
    
    % Assign these numbers to the struct
    primaryGammaAdditivityTest(ii).S = cal.describe.S;
    primaryGammaAdditivityTest(ii).wls = wls;
    primaryGammaAdditivityTest(ii).whichPrimaryToTest = whichPrimaryToTestLeft;
    primaryGammaAdditivityTest(ii).separationNPrimaries = separationNPrimaries;
    primaryGammaAdditivityTest(ii).level = thePowerLevels{ii};
    primaryGammaAdditivityTest(ii).primary = primaryBuffer;
    primaryGammaAdditivityTest(ii).settings = settingsBuffer;
    primaryGammaAdditivityTest(ii).starts = startsBuffer;
    primaryGammaAdditivityTest(ii).stops = stopsBuffer;
    primaryGammaAdditivityTest(ii).predictedSpd = predictedSpdBuffer;
    primaryGammaAdditivityTest(ii).measuredSpd = meas.pr650.spectrum;
end