function OLAnalyzeCalOOC

    calAnalyzer = OLCalAnalyzer(...
        'refitGammaTablesUsingLinearInterpolation', false, ...
        'forceOLInitCal', true);
    
    calAnalyzer.generateDriftAnalysisPlots();
    
    
    plotCompositeMeasurents = true;
    plotSampledSpectra = true;
    plotFullSpectra = true;
    plotGammaSPDs = true;
    plotGammaTables = true;
    plotPredictions = true;
    
    
    if (plotCompositeMeasurents)
        % Plot dark, half-on, and full-on raw measurements
        spdType = 'raw';
        calAnalyzer.plotSPD(spdType, 'darkMeas'); 
        calAnalyzer.plotSPD(spdType, 'halfOnMeas');
        calAnalyzer.plotSPD(spdType, 'fullOn');
    end
    pause
    
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
    pause
    if (plotFullSpectra)
        % Full set of spectral measurements
%         for bandIndex = 1:calAnalyzer.cal.describe.numWavelengthBands
%             startCol = calAnalyzer.cal.describe.primaryStartCols(bandIndex);
%             stopCol  = calAnalyzer.cal.describe.primaryStopCols(bandIndex);
%             fprintf('band:%2d, mirror cols:%d-%d (total mirror cols: %d)\n', bandIndex, startCol, stopCol, calAnalyzer.cal.describe.numColMirrors);
%         end
        
        spdType = 'computed';
        calAnalyzer.plotSPD(spdType, 'pr650M', 'bandIndicesToPlot', []);
        spdType = 'raw';
        calAnalyzer.plotSPD(spdType, 'lightMeas', 'bandIndicesToPlot', []);
    end
    pause
    
    if (plotGammaSPDs)
        % SPDs at different gamma values
        gammaSPDType = 'raw';
        calAnalyzer.plotGammaSPD(gammaSPDType, 'rad');
    end
    pause
    
    if (plotGammaTables)
        % Two views of the measured and fitted gamma tables
        gammaType = 'computed';
        calAnalyzer.plotGamma(gammaType);
    end
    pause
    
    if (plotPredictions)
        spdType = 'raw';
        calAnalyzer.plotPredictions(spdType, 'darkMeas');
        calAnalyzer.plotPredictions(spdType, 'halfOnMeas');
        calAnalyzer.plotPredictions(spdType, 'fullOn');
        calAnalyzer.plotPredictions(spdType, 'wigglyMeas');
    end
    pause
    
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