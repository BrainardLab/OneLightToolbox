function OLAnalyzeCalOOC

    calAnalyzer = OLCalAnalyzer();
    calAnalyzer.verbosity = 'normal';
   
    % Generate figures
    % (1) Dark, half-on, and full-on raw measurements
    spdType = 'raw';
    calAnalyzer.plotSPD(spdType, 'darkMeas'); 
    calAnalyzer.plotSPD(spdType, 'halfOnMeas');
    calAnalyzer.plotSPD(spdType, 'fullOn');
    
     % (2) spectral measurements
    nBandsToPlot = 6;
    whichBandIndicesToPlot = round(linspace(1,calAnalyzer.inputCal.describe.numWavelengthBands, nBandsToPlot));
    spdType = 'computed';
    calAnalyzer.plotSPD(spdType, 'pr650M', 'bandIndicesToPlot', whichBandIndicesToPlot);
    
   
    
    % Ask if the user would like to save the figures.
    commandwindow;
    if GetWithDefault('Save the figures?', 1)
        fileFormat = GetWithDefault('File format (png or pdf):', 'png');
        calAnalyzer.exportFigs(fileFormat);
    end
    
end