function SaveStateMeasurements(cal, calMeasOnly, protocolParams)

% SaveStateMeasurements(cal, calMeasOnly, protocolParams)
%
% Takes state measurements for a OneLight calibration from a stand-alone
% measurement, and saves the state measurements in a 'lite' cal file, which
% only contains the state measurements
%
% 9/9/16   ms     Wrote it

outDir = fullfile(getpref(protocolParams.approach,'DataPath'), 'Experiments', protocolParams.approach, protocolParams.protocol ,'DirectionValidationFiles', protocolParams.observerID, protocolParams.todayDate,protocolParams.sessionName, [strrep(strrep(cal.describe.date, ' ', '_'), ':', '_') datestr(now, 'mmddyy')]);
if ~exist(outDir)
   mkdir(outDir); 
end

% Save out the calibration
SaveCalFile(calMeasOnly, 'StateMeasurements.mat', outDir);