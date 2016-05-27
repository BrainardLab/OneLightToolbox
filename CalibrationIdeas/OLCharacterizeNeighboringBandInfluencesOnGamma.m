function OLCharacterizeNeighboringBandInfluencesOnGamma
% OLCharacterizeNeighboringBandInfluencesOnGamma - Characterize influences of neighboring bands on target band gamma function
% Syntax:
% OLCharacterizeNeighboringBandInfluencesOnGamma
%
% 5/10/16  npc  Wrote it.
%

    [rootDir,~] = fileparts(which(mfilename()));
    cd(rootDir);
    
    choice = input('Measure data(0), or analyze data(1) : ', 's');
    if (str2double(choice) == 0)
        radiometerType = GetWithDefault('Enter PR-6XX radiometer type','PR-670');
        switch (radiometerType)
            case 'PR-650'
                    Svector = [380 4 101];
            case 'PR-670'
                    Svector = [380 2 201];
            otherwise
                error('Unknown radiometer type: ''%s''.', radiometerType)
        end
        
        %stimulusSetType = 'warmUpDataOnly';
        %stimulusSetType = 'wigglySpectrumVariation1';
        %stimulusSetType = 'wigglySpectrumVariation2';
        stimulusSetType = 'fastFullON';
        stimulusSetType = 'combFunctionTest';
        %stimulusSetType = 'combinatorialFull';
        %stimulusSetType = 'combinatorialSmall';
        %stimulusSetType = 'slidingInteraction';
        measureData(rootDir, Svector, radiometerType, stimulusSetType);
    else
        analyzeData(rootDir);
    end
end


function analyzeData(rootDir)

    % ============================== Load data ============================
    [fileName, pathName] = uigetfile('*.mat', 'Select a file to analyze', fullfile(rootDir, 'Data'));
    load(fullfile(pathName,fileName), 'status', 'data',  'nRepeats', 'Svector', 'setType', 'interactingBandSettingsLevels', 'referenceBandSettingsLevels', 'referenceBands', 'interactingBands', 'randomizedSpectraIndices', 'cal');
    
    s = whos('-file', fullfile(pathName,fileName));
    fileContainsWarmUpData = false;
    fileContainsSteadyBandsData = false;
    completionStatus = status;
    
    for k = 1:numel(s)
        if(strcmp(s(k).name, 'warmUpData'))
            fileContainsWarmUpData = true;
        end
        if (strcmp(s(k).name, 'steadyBands'))
            fileContainsSteadyBandsData = true;
        end
    end
    
    nPrimariesNum = numel(data{1}.activation);
    fileContainsWarmUpData = false
    fileContainsSteadyBandsData = false
    
    if (fileContainsSteadyBandsData)
        load(fullfile(pathName,fileName),'steadyBands', 'steadyBandSettingsLevels');
        steadyBandActivation = zeros(nPrimariesNum,1);
        steadyBandActivation(steadyBands) = steadyBandSettingsLevels;
    else
        steadyBands = [];
        steadyBandSettingsLevels = [];
        steadyBandActivation = zeros(nPrimariesNum,1);
    end
    
    
    wavelengthAxis = SToWls(Svector);
    
    
    if (strcmp(setType, 'fastFullON'))
        load(fullfile(pathName,fileName),'warmUpData', 'warmUpRepeats');
        Core.parseFastFullONData(warmUpData, wavelengthAxis);
        return
    end
     
    % ================= Do Linear Drift Correction =========================
    if (fileContainsWarmUpData)
        load(fullfile(pathName,fileName),'warmUpData', 'warmUpRepeats');
        Core.analyzeWarmUpData(warmUpData, warmUpRepeats, completionStatus, wavelengthAxis);
        if (strcmp(setType, 'warmUpDataOnly'))
            return;
        end
        [data, measurementTimes] = Core.doLinearDriftCorrectionUsingMultipleMeasurements(data, nRepeats, wavelengthAxis);
    else
        [data, measurementTimes] = Core.doLinearDriftCorrection(data, nRepeats);
    end
    
    
    % ================= Show stimulation patterns =========================
    %Core.showActivationSequences(randomizedSpectraIndices, data);
    
    if (strcmp(setType, 'wigglySpectrumVariation2'))
        Core.parseWiggly2Data(data, nRepeats, wavelengthAxis);
    else
        % === Parse the data to generate separate dictionaries for different stimulation patterns
        [referenceBandData, interactingBandData, comboBandData, ...
            allSingletonSPDrKeys, allSingletonSPDiKeys,allComboKeys, ...
            darkSPD, darkSPDrange, steadyBandsOnlySPD, steadyBandsOnlySPDrange] = Core.parseData(data, referenceBands, referenceBandSettingsLevels, interactingBands, interactingBandSettingsLevels);

        fprintf('Found %d singleton reference spectra\n', numel(allSingletonSPDrKeys));
        fprintf('Found %d singleton interacting spectra\n', numel(allSingletonSPDiKeys));
        fprintf('Found %d combo spectra\n', numel(allComboKeys));
    
        % Subtract darkSPD from the interacting band data
        interactingBandData = Core.subtractDarkSPD(interactingBandData, darkSPD);

        % Subtract darkSPD from the reference band data
        referenceBandData = Core.subtractDarkSPD(referenceBandData, darkSPD);

        % Compute combo predictions
        [comboBandData, maxSPD] = Core.computeComboPredictions(comboBandData, referenceBandData, interactingBandData, steadyBandsOnlySPD, darkSPD);

        % Compute gamma of the reference band, by subtracting the comboBandSPD from the interactingBand SPD
        effectiveSPDcomputationMethod = 'Reference - Steady';
        referenceBandGammaData1 = Core.computeReferenceBandGammaCurves(effectiveSPDcomputationMethod, comboBandData, referenceBandData, interactingBandData, steadyBandsOnlySPD, steadyBandActivation, darkSPD);

        effectiveSPDcomputationMethod = 'Combo - Interacting';
        referenceBandGammaData2 = Core.computeReferenceBandGammaCurves(effectiveSPDcomputationMethod, comboBandData, referenceBandData, interactingBandData, steadyBandsOnlySPD, steadyBandActivation, darkSPD);



        % =========================== Plot SPD variability =========================
        Core.plotSPDvariability(rootDir, allComboKeys, comboBandData, referenceBandData, interactingBandData, nPrimariesNum, wavelengthAxis);

        % =========================== Plot gamma data =========================
        Core.plotGammaSet(rootDir, referenceBandGammaData1, referenceBandGammaData2, wavelengthAxis);
    end
    
    return
    
    pause
        
    nSpectraMeasured = numel(data);
    nSpectralSamples = numel(wavelengthAxis);
    
    
    
    
    % Plotting
    % plot in milliWatts
    gain = 1000;
    maxSPD = maxSPD * gain;
    maxSPD = round((maxSPD+4)/10)*10;
    
    maxSingleTrialsSPDdiffFromMean = 3.0;
    
    % Plot single trial max deviation from mean as a function of # of bands activated
    hFig = figure(12); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [1 1 1590 1290]);
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
                   'rowsNum', 1, ...
                   'colsNum', 2, ...
                   'heightMargin',   0.01, ...
                   'widthMargin',    0.05, ...
                   'leftMargin',     0.04, ...
                   'rightMargin',    0.001, ...
                   'bottomMargin',   0.05, ...
                   'topMargin',      0.04);
               
    for k = 3:-1:1
        if (k == 1)
            faceColor = [1.0 0.8 0.8];
            edgeColor = [1.0 0.0 0.0];
        elseif (k == 2)
            faceColor = [0.4 0.8 0.4];
            edgeColor = [0.0 0.8 0.0];
        elseif (k == 3)
            faceColor = [0.7 0.7 1.0];
            edgeColor = [0.0 0.0 1.0];
        end
        
        subplot('Position', subplotPosVectors(1,1).v);
        if (k == 1)
            dataSubSet = referenceBandData;
            titleString = 'reference band';
        elseif (k == 2)
            dataSubSet = interactingBandData;
            titleString = 'interacting band(s)';
        else 
            dataSubSet = comboBandData;
            titleString = 'reference + interacting band(s)';
        end
        selectKeys = keys(dataSubSet);
        for keyIndex = 1:numel(selectKeys)
            key = selectKeys{keyIndex};
            s = dataSubSet(key);
            diffs = s.allSPDmaxDeviationsFromMean;
            activatedBandsNo = numel(find(s.activation > 0));
            plot(activatedBandsNo*ones(1,numel(diffs)), gain*diffs, 'rs', 'MarkerFaceColor', [1.0 0.5 0.5], 'MarkerFaceColor', faceColor, 'MarkerEdgeColor', edgeColor);
            if (keyIndex == 1)
                hold on
            end
        end
        set(gca, 'YLim', [-0.2 maxSingleTrialsSPDdiffFromMean], 'FontSize', 14);
        grid on;
        box off
        if (k == 3)
            xlabel('number of activated bands', 'FontSize', 16,  'FontWeight', 'bold');
        end
        ylabel(sprintf('mean - single trial\ndiff. power (mWatts)'), 'FontSize', 16, 'FontWeight', 'bold');
        text(0.25, 2.8+(k-1)*0.05, 5, titleString, 'FontSize', 16, 'FontName', 'Menlo');
        
        
        subplot('Position', subplotPosVectors(1,2).v);
        if (k == 1)
            dataSubSet = referenceBandData;
            titleString = 'reference band';
        elseif (k == 2)
            dataSubSet = interactingBandData;
            titleString = 'interacting band(s)';
        else 
            dataSubSet = comboBandData;
            titleString = 'reference + interacting band(s)';
        end
        selectKeys = keys(dataSubSet);
        for keyIndex = 1:numel(selectKeys)
            key = selectKeys{keyIndex};
            s = dataSubSet(key);
            diffs = s.allSPDmaxDeviationsFromMean;
            totalActivation = sum(s.activation);
            plot(totalActivation*ones(1,numel(diffs)), gain*diffs, 'rs', 'MarkerFaceColor', [1.0 0.5 0.5], 'MarkerFaceColor', faceColor, 'MarkerEdgeColor', edgeColor);
            if (keyIndex == 1)
                hold on
            end
        end
        set(gca, 'YLim', [-0.2 maxSingleTrialsSPDdiffFromMean], 'FontSize', 14);
        grid on;
        box off
        if (k == 3)
            xlabel('total activation (settings)', 'FontSize', 16,  'FontWeight', 'bold');
        end
        ylabel(sprintf('mean - single trial\ndiff. power (mWatts)'), 'FontSize', 16, 'FontWeight', 'bold');
        text(0.25, 2.8+(k-1)*0.05, 5, titleString, 'FontSize', 16, 'FontName', 'Menlo');        
    end
    

    
    
    % Plot single trial max deviation from mean as a function of measurement time
    hFig = figure(14); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [1 1 2550 770]);
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
                   'rowsNum', 3, ...
                   'colsNum', 1, ...
                   'heightMargin',   0.05, ...
                   'widthMargin',    0.00, ...
                   'leftMargin',     0.04, ...
                   'rightMargin',    0.001, ...
                   'bottomMargin',   0.05, ...
                   'topMargin',      0.04);
               
    for k = 1:3
        if (k == 1)
            faceColor = [1.0 0.8 0.8];
            edgeColor = [1.0 0.0 0.0];
        elseif (k == 2)
            faceColor = [0.4 0.8 0.4];
            edgeColor = [0.0 0.8 0.0];
        elseif (k == 3)
            faceColor = [0.7 0.7 1.0];
            edgeColor = [0.0 0.0 1.0];
        end
        subplot('Position', subplotPosVectors(k,1).v);
        if (k == 1)
            dataSubSet = referenceBandData;
            titleString = 'reference band measurements';
        elseif (k == 2)
            dataSubSet = interactingBandData;
            titleString = 'interacting band measurements';
        else 
            dataSubSet = comboBandData;
            titleString = 'reference + interacting band combo measurements';
        end
        selectKeys = keys(dataSubSet);
        for keyIndex = 1:numel(selectKeys)
            key = selectKeys{keyIndex};
            s = dataSubSet(key);
            diffs = s.allSPDmaxDeviationsFromMean;
            times = s.allSPDtimes/(60*60);
            plot(times, gain*diffs, 'rs', 'MarkerFaceColor', faceColor, 'MarkerEdgeColor', edgeColor);
            if (keyIndex == 1)
                hold on
            end
        end
        set(gca, 'YLim', [-0.2 maxSingleTrialsSPDdiffFromMean], 'XTick', [0:1:(max(measurementTimes)/(60*60))], 'XLim', [min(measurementTimes) max(measurementTimes)]/(60*60), 'FontSize', 14);
        grid on;
        box off
        if (k == 3)
            xlabel('time (hours)', 'FontSize', 16,  'FontWeight', 'bold');
        end
        ylabel(sprintf('mean - single trial\ndiff. power (mWatts)'), 'FontSize', 16, 'FontWeight', 'bold');
        title(titleString);
    end
    drawnow;
    pause;
    
    
    generateVideo = true;
    
    if (generateVideo)
        % Open video stream
        videoFilename = sprintf('%s.m4v', fileName);
        writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
        writerObj.FrameRate = 15; 
        writerObj.Quality = 100;
        writerObj.open();

        hFig = figure(11); clf; set(hFig, 'Position', [10 10 1750 1100], 'Color', [1 1 1]); clf;
        subplotPosVectors = NicePlot.getSubPlotPosVectors(...
                   'rowsNum', 2, ...
                   'colsNum', 2, ...
                   'heightMargin',   0.05, ...
                   'widthMargin',    0.05, ...
                   'leftMargin',     0.03, ...
                   'rightMargin',    0.005, ...
                   'bottomMargin',   0.04, ...
                   'topMargin',      0.005);
               
        pos11 = subplotPosVectors(1,1).v;
        axesStruct.activationAxes = axes('parent', hFig, 'unit', 'normalized', 'position', [pos11(1) pos11(2) pos11(3)*0.45 pos11(4)]);
        axesStruct.gammaAxes      = axes('parent', hFig, 'unit', 'normalized', 'position', [pos11(1)+pos11(3)*0.45+0.04 pos11(2) pos11(3)*0.45 pos11(4)*0.92]);
        axesStruct.singletonSPDAxes = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(1,2).v);
        axesStruct.comboSPDAxes = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(2,1).v);
        axesStruct.residualSPDAxes = axes('parent', hFig, 'unit', 'normalized', 'position', subplotPosVectors(2,2).v);
    end
    
 
    theOldGammas = {};
    maxResidualSPD = zeros(1,numel(allComboKeys));
    for keyIndex = 1:numel(allComboKeys) 
        key          = allComboKeys{keyIndex};
        s            = comboBandData(key);
        refS         = referenceBandData(s.referenceBandKey);
        interactingS = interactingBandData(s.interactingBandKey);
        refSettingsValue     = refS.settingsValue;
        refSettingsIndex     = refS.settingsIndex;
        refActivation         = refS.activation;
        interactingActivation = interactingS.activation;
        interactingSettingsValue = interactingS.settingsValue;
        refSPD              = gain * refS.meanSPD;
        refSPDmin           = gain * refS.minSPD;
        refSPDmax           = gain * refS.maxSPD;
        interactingSPD      = gain * interactingS.meanSPD;
        interactingSPDmin   = gain * interactingS.minSPD;
        interactingSPDmax   = gain * interactingS.maxSPD;
        predictedComboSPD   = gain * s.predictionSPD;
        measuredComboAllSPDs= gain * s.allSPDs;
        measuredComboSPD    = gain * s.meanSPD;
        measuredComboSPDmin = gain * s.minSPD;
        measuredComboSPDmax = gain * s.maxSPD;
        maxResidualSPD(keyIndex)  = max(abs(measuredComboSPD - predictedComboSPD));
        gammaBackgroundConditionKey = sprintf('interactingBandsSettingsIndex: %d, interactingBandsIndex: %d', interactingS.settingsIndex, interactingS.interactingBandsIndex);
        theGamma = gamma(gammaBackgroundConditionKey);
        if (generateVideo)
            Core.plotFrame(axesStruct, refActivation, interactingActivation, wavelengthAxis, theGamma, theOldGammas, refSettingsIndex, refSettingsValue, interactingSettingsValue, refSPD, refSPDmin, refSPDmax, interactingSPD, interactingSPDmin, interactingSPDmax, measuredComboAllSPDs, measuredComboSPD, predictedComboSPD, measuredComboSPDmin, measuredComboSPDmax, maxSPD, subplotPosVectors);
            writerObj.writeVideo(getframe(hFig));
        end
        theOldGammas{numel(theOldGammas)+1} = theGamma;
    end
   
    if (generateVideo)
        % Close video stream
        writerObj.close();
    end
    
    % Now show SPDs in decreasing residual error
    [~, indices] = sort(maxResidualSPD, 'descend');
    
    
    % Open video stream
    videoFilename = sprintf('%s_ranked.m4v', fileName);
    writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
    writerObj.FrameRate = 15; 
    writerObj.Quality = 100;
    writerObj.open();
        
    measurementsPerFigure = 4;
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
                   'rowsNum', 4, ...
                   'colsNum', measurementsPerFigure, ...
                   'heightMargin',   0.05, ...
                   'widthMargin',    0.02, ...
                   'leftMargin',     0.02, ...
                   'rightMargin',    0.005, ...
                   'bottomMargin',   0.04, ...
                   'topMargin',      0.005);
               
    hFig = figure(100); set(hFig, 'Position', [1 1 2000 1150], 'Color', [1 1 1]);
    
    for groupNo = 1:floor(numel(allComboKeys)/measurementsPerFigure)
        clf;
  
        for k = 1:measurementsPerFigure
            key     = allComboKeys{indices((groupNo-1)*measurementsPerFigure+k)};
            s            = comboBandData(key);
            refS         = referenceBandData(s.referenceBandKey);
            interactingS = interactingBandData(s.interactingBandKey);
            refSettingsValue     = refS.settingsValue;
            refActivation         = refS.activation;
            interactingActivation = interactingS.activation;
            interactingSettingsValue = interactingS.settingsValue;
            refSPD              = gain * refS.meanSPD;
            refSPDmin           = gain * refS.minSPD;
            refSPDmax           = gain * refS.maxSPD;
            interactingSPD      = gain * interactingS.meanSPD;
            interactingSPDmin   = gain * interactingS.minSPD;
            interactingSPDmax   = gain * interactingS.maxSPD;
            predictedComboSPD   = gain * s.predictionSPD;
            measuredComboSPD    = gain * s.meanSPD;
            measuredComboSPDmin = gain * s.minSPD;
            measuredComboSPDmax = gain * s.maxSPD;
            maxResidualSPD  = max(abs(measuredComboSPD - predictedComboSPD)); 
            meanResidualSPD = mean(abs(measuredComboSPD - predictedComboSPD));
            Core.plotSummarySubFrame(refActivation, interactingActivation, wavelengthAxis, refSettingsValue, interactingSettingsValue, refSPD, refSPDmin, refSPDmax, interactingSPD, interactingSPDmin, interactingSPDmax, measuredComboSPD, predictedComboSPD, measuredComboSPDmin, measuredComboSPDmax, maxSPD, maxResidualSPD, meanResidualSPD ,squeeze(subplotPosVectors(:,k)));
        end
        
        writerObj.writeVideo(getframe(hFig));
        pause(0.5);
    end % groupNo
    
    writerObj.close();
    
end



function measureData(rootDir, Svector, radiometerType, setType)
    
    % check that hardware is responding
    Measure.checkHardware(radiometerType);
    
    % Ask for email recipient
    emailRecipient = GetWithDefault('Send status email to','cottaris@psych.upenn.edu');
    
    % Import a calibration 
    cal = OLGetCalibrationStructure;
    nPrimariesNum = cal.describe.numWavelengthBands;

    [ warmUpData, data, warmUpRepeats, nRepeats, ...
      referenceBands, referenceBandSettingsLevels, ...
      interactingBands, interactingBandSettingsLevels, ...
      steadyBands, steadyBandSettingsLevels ] = Measure.configExperiment(setType, nPrimariesNum);
    
  
    disp('Hit enter to continue'); pause
    
    spectroRadiometerOBJ = []; ol = [];
    try
        meterToggle = [1 0];
        od = [];
        nAverage = GetWithDefault('nAverage',1);
        randomizedSpectraIndices = [];
         
        spectroRadiometerOBJ = Measure.initRadiometerObject(radiometerType);
        pause(0.2);
        
        % Get handle to OneLight
        ol = OneLight;

        % Prepare figure to show progress
        hFig = figure(2); set(hFig, 'Position', [10 10 1500 970], 'Color', [0 0 0]); clf;
        
        % Do the warming up data collection to allow for the unit to warm up
        for repeatIndex = 1:warmUpRepeats
           randomizedPatternIndices(repeatIndex,:) = randperm(numel(warmUpData)); 
           for stimPatternIter = 1:numel(warmUpData)

                stimPattern = randomizedPatternIndices(repeatIndex,stimPatternIter);
                settingsValues  = warmUpData{stimPattern}.activation;
                [starts,stops] = OLSettingsToStartsStops(cal,settingsValues);
                measurement = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, Svector, meterToggle, nAverage);
                warmUpData{stimPattern}.oneLightStateBeforeStimOnset{repeatIndex}  = measurement.oneLightState1;
                warmUpData{stimPattern}.oneLightStateAfterMeasurement{repeatIndex} = measurement.oneLightState2;
                warmUpData{stimPattern}.measuredSPDallSpectraToBeAveraged(repeatIndex,:,:) = measurement.pr650.allSpectra;
                warmUpData{stimPattern}.measuredSPDallSpectraToBeAveragedTimes(repeatIndex,:) = measurement.pr650.allSpectraTimes;
                warmUpData{stimPattern}.measuredSPD(:, repeatIndex)     = measurement.pr650.spectrum;
                warmUpData{stimPattern}.measurementTime(:, repeatIndex) = measurement.pr650.time(1);
                warmUpData{stimPattern}.repeatIndex = repeatIndex;
                
                subplot('Position', [0.51 0.03 0.45 0.47]);
                bar(settingsValues, 1, 'FaceColor', [0.3 0.8 0.9]);
                set(gca, 'YLim', [0 1.05], 'XLim', [0 nPrimariesNum+1], 'XTick', [], 'YTick', [], 'Color', [0 0 0]);
                subplot('Position', [0.51 0.52 0.45 0.44]);
                plot(SToWls(Svector), measurement.pr650.spectrum, 'g-', 'LineWidth', 2.0);
                set(gca, 'XTick', [], 'YTick', [], 'Color', [0 0 0]);
                title(sprintf('warm up data (pattern: %d, repeat %d/%d)', stimPattern, repeatIndex, warmUpRepeats), 'Color', [1 1 1], 'FontSize', 14, 'FontName', 'Menlo')
                drawnow;
           end
        end
        
        nSpectraMeasured = numel(data);
        repeatIndex = 0;
        
        % Do all the measurements
        for repeatIndex = 1:nRepeats
         
            SendEmail(emailRecipient, 'OLCharacterizeNeighboringBandInfluencesOnGamma', ...
                sprintf('Started iteration: %d of %d', repeatIndex, nRepeats));
        
            % Randomize presentation sequence
            randomizedSpectraIndices(repeatIndex,:) = randperm(nSpectraMeasured); 
            
            % Show randomized stimulation sequence
            
            subplot('Position', [0.03 0.03 0.45 0.95]);
            pcolor(1:nPrimariesNum, 1:nSpectraMeasured, Core.retrieveActivationSequence(data, squeeze(randomizedSpectraIndices(repeatIndex,:))));
            hold on
            xlabel('primary no');
            ylabel('spectrum no');
            set(gca, 'CLim', [0 1], 'XLim', [1 nPrimariesNum], 'YLim', [0 nSpectraMeasured+1]);
            colormap(gray);
    
            for spectrumIter = 1:nSpectraMeasured
                fprintf('Measuring spectrum %d of %d (repeat: %d/%d)\n', spectrumIter, nSpectraMeasured, repeatIndex, nRepeats);
                % Indicate where in the stimulation sequence we are at this point in time.
                subplot('Position', [0.03 0.03 0.45 0.95]);
                plot([1 nPrimariesNum], (spectrumIter+0.5)*[1 1], 'g-');
                drawnow;
                
                % Get randomized index
                spectrumIndex = randomizedSpectraIndices(repeatIndex,spectrumIter);
                
                settingsValues  = data{spectrumIndex}.activation;
                [starts,stops] = OLSettingsToStartsStops(cal,settingsValues);
                measurement = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, Svector, meterToggle, nAverage);
                data{spectrumIndex}.oneLightStateBeforeStimOnset{repeatIndex}  = measurement.oneLightState1;
                data{spectrumIndex}.oneLightStateAfterMeasurement{repeatIndex} = measurement.oneLightState2;
                data{spectrumIndex}.measuredSPD(:, repeatIndex)     = measurement.pr650.spectrum;
                data{spectrumIndex}.measurementTime(:, repeatIndex) = measurement.pr650.time(1);
                data{spectrumIndex}.repeatIndex = repeatIndex;
                
                subplot('Position', [0.51 0.04 0.45 0.47]);
                bar(settingsValues, 1, 'FaceColor', [0.9 0.8 0.3]);
                set(gca, 'YLim', [0 1.05], 'XLim', [0 nPrimariesNum+1], 'XTick', [], 'YTick', [], 'Color', [0 0 0]);
                subplot('Position', [0.51 0.52 0.45 0.44]);
                plot(SToWls(Svector), measurement.pr650.spectrum, 'g-', 'LineWidth', 2.0);
                set(gca, 'XTick', [], 'YTick', [], 'Color', [0 0 0]);
                title(sprintf('pattern: %d, repeat %d', spectrumIter, repeatIndex), 'Color', [1 1 1], 'FontSize', 14, 'FontName', 'Menlo')
                drawnow;
            end  % spectrumIter
        end % repeatIndex
        
        % Save data
        status = 'Completed successfully';
        filename = fullfile(rootDir,sprintf('NeighboringBandInfluencesOnReferenceGamma_%s_%s.mat', cal.describe.calType, datestr(now, 'dd-mmm-yyyy_HH_MM_SS')));
        save(filename, 'status', 'data', 'nRepeats', 'warmUpData', 'warmUpRepeats', 'Svector', 'setType', ...
            'steadyBands', 'steadyBandSettingsLevels', 'interactingBandSettingsLevels', 'referenceBandSettingsLevels', 'referenceBands', 'interactingBands', 'randomizedSpectraIndices', 'cal', '-v7.3');
        fprintf('Data saved in ''%s''. \n', filename); 
        SendEmail(emailRecipient, 'OneLight Calibration Complete', 'Finished!');
        
        % Shutdown spectroradiometer
        spectroRadiometerOBJ.shutDown();
        
        % Shutdown OneLight
        ol.shutdown();
        
    catch err
        fprintf('Failed with message: ''%s''... ', err.message);
        if (~isempty(spectroRadiometerOBJ))
            % Shutdown spectroradiometer
            spectroRadiometerOBJ.shutDown();
        end
        
        % Attempt to save any data
        status = sprintf('Failed during repeat: %d (Error message: %s).\nAttempted to save any data.', repeatIndex, err.message);
        filename = fullfile(rootDir,sprintf('NeighboringBandInfluencesOnReferenceGamma_%s_%s.mat', cal.describe.calType, datestr(now, 'dd-mmm-yyyy_HH_MM_SS')));
        save(filename, 'status', 'data', 'nRepeats', 'warmUpData', 'warmUpRepeats', 'Svector', 'setType', 'steadyBands', 'steadyBandSettingsLevels', 'interactingBandSettingsLevels', 'referenceBandSettingsLevels', 'referenceBands', 'interactingBands', 'randomizedSpectraIndices', 'cal', '-v7.3');
        fprintf('Data saved in ''%s''. \n', filename); 
        
        SendEmail(emailRecipient, 'OneLight Calibration Failed', ...
            ['Calibration failed with the following error' err.message]);
        
        if (~isempty(ol))
            % Shutdown OneLight
            ol.shutdown();
        end
        
        keyboard;
        rethrow(e);
    end
end