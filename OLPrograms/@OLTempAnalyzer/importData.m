function importData(obj)

    [obj.testData.allTemperatureData,  obj.testData.stabilitySpectra, obj.testData.DateStrings, obj.testData.fullFileName] = retrieveData(obj, obj.testFile, []);
    [obj.calData.allTemperatureData, obj.calData.stabilitySpectra, obj.calData.DateStrings, obj.calData.fullFileName] = retrieveData(obj, obj.calibrationFile, 'cals');

    presentGUI(obj);
end