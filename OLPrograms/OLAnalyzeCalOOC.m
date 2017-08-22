function OLAnalyzeCalOOC

    cal = OLGetCalibrationStructure;
    
    calAnalyzer = OLCalAnalyzer(...
        'refitGammaTablesUsingLinearInterpolation', false, ...
        'forceOLInitCal', true, ...
        'cal', cal);
    
    
    describe = calAnalyzer.cal.describe;
    describe
    
    % Select what to plot
    
    % 0. Plot temperature during the course of the calibration
    plotTemperatureMeasurements = false;
    
    % 1. Analysis of how FULLON and COMB spectra vary over time
    plotDriftAnalysis = false;
    
    % 2. Results of composite SPD measurements
    plotCompositeMeasurents = false;
    
    % 3. SPDs of a subset of the primaries
    plotSampledSpectra = true;
    
    % 4. SPDs of all primaries
    plotFullSpectra = true;
    
    % 5. SPDs at different gamma values
    plotGammaSPDs = true;
    
    % 6. The gamma tables
    plotGammaTables = true;
    
    % 7. The predicted SPDs
    plotPredictions = true;
    
    % 8. Results from the primary additivity tests
    plotAdditivityCheck = false;
  
    % Action !
    if (plotTemperatureMeasurements)
        plotValidationTemperatureMeasurements = true;
        calAnalyzer.plotTemperatureMeasurements();
    end
    
    if (plotDriftAnalysis)
        calAnalyzer.generateDriftAnalysisPlots();
    end
    
    if (plotCompositeMeasurents)
        % Plot dark, half-on, and full-on raw measurements
        spdType = 'raw';
        calAnalyzer.plotSPD(spdType, 'darkMeas'); 
        calAnalyzer.plotSPD(spdType, 'halfOnMeas');
        calAnalyzer.plotSPD(spdType, 'fullOn');
        calAnalyzer.plotSPD(spdType, 'wigglyMeas');
        
        spdType = 'computed';
        calAnalyzer.plotSPD(spdType, 'halfOnMeas');
        calAnalyzer.plotSPD(spdType, 'fullOn');
        calAnalyzer.plotSPD(spdType, 'wigglyMeas');
    end
        
    if (plotSampledSpectra)
        % Bands for which to plot spectral measurements
        nBandsToPlot = 6;
        whichBandIndicesToPlot = round(linspace(1,calAnalyzer.cal.describe.numWavelengthBands, nBandsToPlot));

        % Computed spectra
        spdType = 'computed';
        calAnalyzer.plotSPD(spdType, 'pr650M', 'bandIndicesToPlot', whichBandIndicesToPlot);

        % Raw spectra
        spdType = 'raw';
        calAnalyzer.plotSPD(spdType, 'lightMeas', 'bandIndicesToPlot', whichBandIndicesToPlot);
        if (calAnalyzer.cal.describe.specifiedBackground)
            calAnalyzer.plotSPD(spdType, 'effectiveBgMeas', 'bandIndicesToPlot', whichBandIndicesToPlot);
        end
    end
    
    if (plotFullSpectra)
        spdType = 'computed';
        calAnalyzer.plotSPD(spdType, 'pr650M', 'bandIndicesToPlot', []);
        spdType = 'raw';
        calAnalyzer.plotSPD(spdType, 'lightMeas', 'bandIndicesToPlot', []);
    end
    
    if (plotGammaSPDs)
        % SPDs at different gamma values
        gammaSPDType = 'raw';
        calAnalyzer.plotGammaSPD(gammaSPDType, 'rad');
    end
    
    if (plotGammaTables)
        % Two views of the measured and fitted gamma tables
        gammaType = 'computed';
        calAnalyzer.plotGamma(gammaType, 'plotRatios', false);
    end
    
    if (plotPredictions)
        spdType = 'raw';
        calAnalyzer.plotPredictions(spdType, 'darkMeas');
        calAnalyzer.plotPredictions(spdType, 'halfOnMeas');
        calAnalyzer.plotPredictions(spdType, 'fullOn');
        calAnalyzer.plotPredictions(spdType, 'wigglyMeas');
        
        spdType = 'computed';
        calAnalyzer.plotPredictions(spdType, 'halfOnMeas');
        calAnalyzer.plotPredictions(spdType, 'fullOn');
        calAnalyzer.plotPredictions(spdType, 'wigglyMeas');
    end
    
    if (plotAdditivityCheck)
        calAnalyzer.plotAdditivityCheck();
    end
        
    if (calAnalyzer.cal.describe.specifiedBackground)
        fprintf('Specified background figure, how repeatable - NOT IMPLEMENTED YET\n');
    end

    % Ask if the user would like to save the figures.
    commandwindow;
    if GetWithDefault('Save the figures?', 0)
        fileFormat = GetWithDefault('File format (png or pdf):', 'png');
        calAnalyzer.exportFigs(fileFormat);
    end
end