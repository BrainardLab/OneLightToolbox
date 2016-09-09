% SaveStateMeasurements(cal0, calMeasOnly)
%
% Takes state measurements for a OneLight calibration from a stand-alone
% measurement, and saves the state measurements in a 'lite' cal file, which
% only contains the state measurements
%
% 9/9/16   ms     Wrote it

function SaveStateMeasurements(cal0, calMeasOnly)

outDir = fullfile(getpref('OneLight', 'OneLightCalData'), cal.describe.calType, cal.describe.date, 'StateMeasurements.mat');
% Save out the calibration
SaveCalFile(calMeasOnly, 'StateMeasurements.mat', outDir);