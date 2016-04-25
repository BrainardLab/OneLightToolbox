function OLAnalyzeCalOOC

    calAnalyzer = OLCalAnalyzer();
    calAnalyzer.verbosity = 'normal';
   
    if (1==2)
    % Generate figures
    % (1) Dark, half-on, and full-on raw measurements
    spdType = 'raw';
    calAnalyzer.plotSPD(spdType, 'darkMeas'); 
    calAnalyzer.plotSPD(spdType, 'halfOnMeas');
    calAnalyzer.plotSPD(spdType, 'fullOn');
    
    % (2) Sample spectral measurements
    nBandsToPlot = 6;
    whichBandIndicesToPlot = round(linspace(1,calAnalyzer.cal.describe.numWavelengthBands, nBandsToPlot));
    spdType = 'computed';
    calAnalyzer.plotSPD(spdType, 'pr650M', 'bandIndicesToPlot', whichBandIndicesToPlot);
    
    % Computed spectra
    spdType = 'computed';
    calAnalyzer.plotSPD(spdType, 'pr650M', 'bandIndicesToPlot', whichBandIndicesToPlot);
    
    % Raw spectra
    spdType = 'raw';
    calAnalyzer.plotSPD(spdType, 'lightMeas', 'bandIndicesToPlot', whichBandIndicesToPlot);
    if (calAnalyzer.cal.describe.specifiedBackground)
        calAnalyzer.plotSPD(spdType, 'effectiveBgMeas', 'bandIndicesToPlot', whichBandIndicesToPlot);
    end
    
    % (3) Full set of spectral measurements
    for bandIndex = 1:calAnalyzer.cal.describe.numWavelengthBands
        startCol = calAnalyzer.cal.describe.primaryStartCols(bandIndex);
        stopCol  = calAnalyzer.cal.describe.primaryStopCols(bandIndex);
        fprintf('band:%2d, mirror cols:%d-%d (total mirror cols: %d)\n', bandIndex, startCol, stopCol, calAnalyzer.cal.describe.numColMirrors);
    end
    spdType = 'computed';
    calAnalyzer.plotSPD(spdType, 'pr650M', 'bandIndicesToPlot', []);
    spdType = 'raw';
    calAnalyzer.plotSPD(spdType, 'lightMeas', 'bandIndicesToPlot', []);
    
    end

    % (4) SPDs at different gamma values
    gammaSPDType = 'raw';
    calAnalyzer.plotGammaSPD(gammaSPDType, 'rad');
    
    
    % (4) The gamma data
    %calAnalyzer.plotGamma
    
    
    if (calAnalyzer.cal.describe.specifiedBackground)
        fprintf('Specified background figure, how repeatable - NOT IMPLEMENTED YET\n');
    end

    % Ask if the user would like to save the figures.
    commandwindow;
    if GetWithDefault('Save the figures?', 1)
        fileFormat = GetWithDefault('File format (png or pdf):', 'png');
        calAnalyzer.exportFigs(fileFormat);
    end
    
end