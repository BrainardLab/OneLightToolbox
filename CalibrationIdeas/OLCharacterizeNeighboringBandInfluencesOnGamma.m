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
        measureData(rootDir, Svector, radiometerType);
    else
        analyzeData(rootDir);
    end
end


function analyzeData(rootDir)

    [fileName, pathName] = uigetfile('*.mat', 'Select a file to analyze', rootDir);
    load(fileName, 'data',  'nRepeats', 'Svector', 'interactingBandSettingsLevels', 'referenceBandSettingsLevels', 'referenceBands', 'interactingBands', 'randomizedSpectraIndices', 'cal');
    
    s = whos('-file', fileName);
    fileContainsWarmUpData = false;
    for k = 1:numel(s)
        if(strcmp(s(k).name, 'warmUpData'))
            fileContainsWarmUpData = true;
        end
    end
    
    if (fileContainsWarmUpData)
        load(fileName,'warmUpData', 'warmUpRepeats');
        %Core.analyzeWarmUpData(warmUpData, warmUpRepeats)
        [data, measurementTimes] = Core.doLinearDriftCorrectionWithWarpUpData(warmUpData, warmUpRepeats, data, nRepeats);
    else
        [data, measurementTimes] = Core.doLinearDriftCorrection(data, nRepeats);
    end
    
    nSpectraMeasured = numel(data);
    nPrimariesNum = numel(data{1}.activation);
    wavelengthAxis = SToWls(Svector);
    nSpectralSamples = numel(wavelengthAxis);
    
    Core.showActivationSequences(randomizedSpectraIndices, data);
    
    % Parse the data and generate separate dictionaries for different
    % stimulation patterns
    [referenceBandData, interactingBandData, comboBandData, ...
        allSingletonSPDrKeys, allSingletonSPDiKeys,allComboKeys, ...
        darkSPD, darkSPDrange] = Core.parseData(data, referenceBands, referenceBandSettingsLevels, interactingBands, interactingBandSettingsLevels);

    % Subtract darkSPD from the interacting band data
    interactingBandData = Core.subtractDarkSPD(interactingBandData, darkSPD);
    
    % Subtract darkSPD from the reference band data
    referenceBandData = Core.subtractDarkSPD(referenceBandData, darkSPD);
    
    % Compute combo predictions
    [comboBandData, maxSPD] = Core.computeComboPredictions(comboBandData, referenceBandData, interactingBandData, darkSPD);
    
    
    % Compute gamma functions for all effective backgrounds (i.e.,
    % interacting band spatial configs & settings)
    gamma = containers.Map();
    selectKeys = keys(comboBandData);
    for keyIndex = 1:numel(selectKeys)
        key = selectKeys{keyIndex};
        s = comboBandData(key);
        interactingS = interactingBandData(s.interactingBandKey);
        backgroundConditionKey = sprintf('interactingBandsSettingsIndex: %d, interactingBandsIndex: %d', interactingS.settingsIndex, interactingS.interactingBandsIndex);
        gamma(backgroundConditionKey) = struct(...
            'backgroundSubtractedSPD',[], ...
            'gammaIn', [], ...
            'gammaOut', [] ...
            );
    end
    
    for keyIndex = 1:numel(selectKeys)
        key = selectKeys{keyIndex};
        s = comboBandData(key);
        refS = referenceBandData(s.referenceBandKey);
        interactingS = interactingBandData(s.interactingBandKey);
        backgroundConditionKey = sprintf('interactingBandsSettingsIndex: %d, interactingBandsIndex: %d', interactingS.settingsIndex, interactingS.interactingBandsIndex);
        theGamma = gamma(backgroundConditionKey);
        theGamma.backgroundSubtractedSPD(refS.settingsIndex,:) = (s.meanSPD - darkSPD) - interactingS.meanSPD;
        theGamma.gammaIn(refS.settingsIndex) = refS.settingsValue;
        gamma(backgroundConditionKey) = theGamma;
     end
    
     gammaKeys = keys(gamma);
     for keyIndex = 1:numel(gammaKeys)
         theGamma = gamma(gammaKeys{keyIndex});
         maxSettingsSPD = squeeze(theGamma.backgroundSubtractedSPD(end,:));
         for settingsIndex = 1:size(theGamma.backgroundSubtractedSPD,1)
            theGamma.gammaOut(settingsIndex) = squeeze(maxSettingsSPD)' \ squeeze(theGamma.backgroundSubtractedSPD(settingsIndex,:))';
         end
         gamma(gammaKeys{keyIndex}) = theGamma;
         figure(100);
         plot(theGamma.gammaIn, theGamma.gammaOut, 'ks-');
         title(gammaKeys{keyIndex});
     end
     
     
    
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
            plotFrame(axesStruct, refActivation, interactingActivation, wavelengthAxis, theGamma, theOldGammas, refSettingsIndex, refSettingsValue, interactingSettingsValue, refSPD, refSPDmin, refSPDmax, interactingSPD, interactingSPDmin, interactingSPDmax, measuredComboAllSPDs, measuredComboSPD, predictedComboSPD, measuredComboSPDmin, measuredComboSPDmax, maxSPD, subplotPosVectors);
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
            plotSummarySubFrame(refActivation, interactingActivation, wavelengthAxis, refSettingsValue, interactingSettingsValue, refSPD, refSPDmin, refSPDmax, interactingSPD, interactingSPDmin, interactingSPDmax, measuredComboSPD, predictedComboSPD, measuredComboSPDmin, measuredComboSPDmax, maxSPD, maxResidualSPD, meanResidualSPD ,squeeze(subplotPosVectors(:,k)));
        end
        
        writerObj.writeVideo(getframe(hFig));
        pause(0.5);
    end % groupNo
    
    writerObj.close();
    
end

function plotSummarySubFrame(refActivation, interactingActivation, wavelengthAxis, referenceSettingsValue, interactingSettingsValue, refSPD, refSPDmin, refSPDmax, interactingSPD, interactingSPDmin, interactingSPDmax, measuredComboSPD, predictedComboSPD, measuredComboSPDmin, measuredComboSPDmax, maxSPD, maxResidualSPD, meanResidualSPD ,subplotPosVectors)
% The activation pattern on top-left
    subplot('Position', subplotPosVectors(1,1).v);
    bar(1:numel(refActivation), refActivation, 1.0, 'FaceColor', [1.0 0.75 0.75], 'EdgeColor', [1 0 0], 'EdgeAlpha', 0.5, 'LineWidth', 1.5);
    hold on
    bar(1:numel(interactingActivation), interactingActivation, 1.0, 'FaceColor', [0.75 0.75 1.0], 'EdgeColor', [0 0 1], 'EdgeAlpha', 0.7, 'LineWidth', 1.5);
    hold off;
    set(gca, 'YLim', [0 1.0], 'XLim', [0 numel(refActivation)+1]);
    xlabel('band no', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('settings value', 'FontSize', 14, 'FontWeight', 'bold');
    box off;
    
    % The reference and interacting SPDs pattern on top-right
    subplot('Position', subplotPosVectors(2,1).v);
    x = [wavelengthAxis(1) wavelengthAxis' wavelengthAxis(end)];
    baseline = min([0 min(refSPD)]);
    y = [baseline refSPD' baseline]; 
    patch(x,y, 'green', 'FaceColor', [1.0 0.8 0.8], 'EdgeColor', [1.0 0. 0.], 'EdgeAlpha', 0.5, 'LineWidth', 2.0);
    hold on
    plot(wavelengthAxis, refSPDmin, '-', 'Color', [0 0 0]);
    plot(wavelengthAxis, refSPDmax, '-', 'Color', [0 0 0]);
    baseline = min([0 min(interactingSPD)]);
    y = [baseline interactingSPD' baseline]; 
    patch(x,y, 'green', 'FaceColor', [0.8 0.8 1.0], 'EdgeColor', [0.0 0. 1], 'EdgeAlpha', 0.5, 'FaceAlpha', 0.5, 'LineWidth', 2.0);
    plot(wavelengthAxis, interactingSPDmin, '-', 'Color', [0 0 0]);
    plot(wavelengthAxis, interactingSPDmax, '-', 'Color', [0 0 0]);
    hold off;
    set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [0 maxSPD], 'XTick', [300:25:800]);
    set(gca, 'FontSize', 12);
    xlabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('power (mW)', 'FontSize', 14, 'FontWeight', 'bold');
    grid on
    box off

    % The measured and predicted combo SPDs on bottom-left
    subplot('Position', subplotPosVectors(3,1).v);
    plot(wavelengthAxis,predictedComboSPD, '-', 'Color', [1.0 0.1 0.9], 'LineWidth', 2.0);
    hold on;
    plot(wavelengthAxis,measuredComboSPD, '-', 'Color', [0.1 0.8 0.5],  'LineWidth', 2.0);
    plot(wavelengthAxis, measuredComboSPDmin, '-', 'Color', [0 0 0]);
    plot(wavelengthAxis, measuredComboSPDmax, '-', 'Color', [0 0 0]);
    hold off;
    hL = legend('predicted SPD', 'measured SPD', 'measured SPD (min)', 'measured SPD (max)', 'Location', 'SouthWest');
    set(hL, 'FontSize', 12, 'FontName', 'Menlo');
    legend boxoff;
    set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [0 maxSPD], 'XTick', [300:25:800]);
    set(gca, 'FontSize', 12, 'FontName', 'Menlo');
    xlabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('power (mW)', 'FontSize', 14, 'FontWeight', 'bold');
    grid on
    box off

    % The residual (measured - predicted combo SPDs) on bottom-right
    subplot('Position', subplotPosVectors(4,1).v);
    y = [0 (measuredComboSPD-predictedComboSPD)' 0];
    patch(x,y, 'green', 'FaceColor', [0.3 0.8 1.0], 'EdgeColor', [0.2 0.6 0.6], 'FaceAlpha', 0.7, 'EdgeAlpha', 0.9, 'LineWidth', 2.0);
    hold on;
    plot(wavelengthAxis, measuredComboSPD-measuredComboSPDmin, 'k--', 'LineWidth', 2.0);
    plot(wavelengthAxis, measuredComboSPD-measuredComboSPDmax, 'k:',  'LineWidth', 2.0);
    set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [-5 5], 'XTick', [300:25:800]);
    set(gca, 'FontSize', 12);
    xlabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('residual power (mW)', 'FontSize', 14, 'FontWeight', 'bold');
    grid on
    box off
    
    text(385, 4.7, sprintf('reference   band  settings: %2.2f', referenceSettingsValue), 'Color', [1.0 0.3 0.3], 'FontName', 'Menlo', 'FontSize', 12);
    text(385, 4.2, sprintf('interacting band(s) settings: %2.2f', interactingSettingsValue), 'Color', [0.3 0.3 1.0],'FontName', 'Menlo', 'FontSize', 12);
    drawnow;
    
end

function plotFrame(axesStruct, refActivation, interactingActivation, wavelengthAxis, theGamma, theOldGammas, refSettingsIndex, referenceSettingsValue, interactingSettingsValue, refSPD, refSPDmin, refSPDmax, interactingSPD, interactingSPDmin, interactingSPDmax, measuredComboAllSPDs, measuredComboSPD, predictedComboSPD, measuredComboSPDmin, measuredComboSPDmax, maxSPD, subplotPosVectors)
    
    % The gamma curves
    if (~isempty(theOldGammas)) && (refSettingsIndex == 1)
        % plot the previous gamma curves in black
        for k = 1:numel(theOldGammas)
            aGamma = theOldGammas{k};
            gammaOut(k,:) = [0 aGamma.gammaOut];
            gammaIn = [0 aGamma.gammaIn];
        end
        plot(axesStruct.gammaAxes, gammaIn,  gammaOut, '-', 'Color', [0.4 0.4 0.4 0.5], 'LineWidth', 1);
        hold(axesStruct.gammaAxes, 'on')
    end
    plot(axesStruct.gammaAxes, [0 theGamma.gammaIn(1:refSettingsIndex)],  [0 theGamma.gammaOut(1:refSettingsIndex)], 'rs-', 'Color', [1.0 0.0 0.0], 'MarkerSize', 8, 'MarkerFaceColor', [1 0.7 0.7], 'LineWidth', 1);
    if (refSettingsIndex == numel(theGamma.gammaIn))
        hold(axesStruct.gammaAxes, 'off')
    end

    set(axesStruct.gammaAxes, 'XLim', [0 1], 'YLim', [0 1.0], 'XTick', 0:0.2:1.0, 'YTick', 0:0.2:1.0, 'XTickLabel', sprintf('%0.1f\n', 0:0.2:1.0), 'YTickLabel', sprintf('%0.1f\n', 0:0.2:1.0), 'FontSize', 14);
    grid(axesStruct.gammaAxes, 'on');
    box(axesStruct.gammaAxes, 'off');
    xlabel(axesStruct.gammaAxes, 'settings value', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel(axesStruct.gammaAxes, 'gamma out', 'FontSize', 16, 'FontWeight', 'bold');
    
    % The activation pattern on top-left
    bar(axesStruct.activationAxes, 1:numel(refActivation), refActivation, 1.0, 'FaceColor', [1.0 0.75 0.75], 'EdgeColor', [1 0 0], 'EdgeAlpha', 0.5, 'LineWidth', 1.5);
    hold(axesStruct.activationAxes, 'on')
    bar(axesStruct.activationAxes, 1:numel(interactingActivation), interactingActivation, 1.0, 'FaceColor', [0.75 0.75 1.0], 'EdgeColor', [0 0 1], 'EdgeAlpha', 0.7, 'LineWidth', 1.5);
    hold(axesStruct.activationAxes, 'off')
    set(axesStruct.activationAxes, 'YLim', [0 1.0], 'XLim', [0 numel(refActivation)+1]);
    hL = legend(axesStruct.activationAxes, {'reference band', 'interacting band(s)'}, 'Location', 'NorthOutside', 'Orientation', 'Horizontal');
    legend boxoff;
    set(hL, 'FontSize', 14, 'FontName', 'Menlo');
    set(axesStruct.activationAxes, 'FontSize', 14, 'YLim', [0 1.0], 'XLim', [0 numel(interactingActivation)+1]);
    xlabel(axesStruct.activationAxes,'band no', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel(axesStruct.activationAxes,'settings value', 'FontSize', 16, 'FontWeight', 'bold');
    box(axesStruct.activationAxes, 'off');
    
    % The reference and interacting SPDs pattern on top-right
    plot(axesStruct.singletonSPDAxes, wavelengthAxis, refSPDmin, '-', 'Color', [0 0 0], 'LineWidth', 2.0);
    hold(axesStruct.singletonSPDAxes, 'on');
    plot(axesStruct.singletonSPDAxes, wavelengthAxis, refSPDmax, '-', 'Color', [0 0 0], 'LineWidth', 2.0);
    plot(axesStruct.singletonSPDAxes, wavelengthAxis, interactingSPDmin, '-', 'Color', [0 0 0], 'LineWidth', 2.0);
    plot(axesStruct.singletonSPDAxes, wavelengthAxis, interactingSPDmax, '-', 'Color', [0 0 0], 'LineWidth', 2.0);
    x = [wavelengthAxis(1) wavelengthAxis' wavelengthAxis(end)];
    baseline = min([0 min(refSPD)]);
    y = [baseline refSPD' baseline]; 
    patch(x,y, 'green', 'FaceColor', [1.0 0.8 0.8], 'EdgeColor', 'none',  'LineWidth', 2.0, 'parent', axesStruct.singletonSPDAxes);
    baseline = min([0 min(interactingSPD)]);
    y = [baseline interactingSPD' baseline]; 
    patch(x,y, 'green', 'FaceColor', [0.8 0.8 1.0], 'EdgeColor', 'none',  'FaceAlpha', 0.5, 'LineWidth', 2.0, 'parent', axesStruct.singletonSPDAxes);
    hold(axesStruct.singletonSPDAxes, 'off');
    hL = legend(axesStruct.singletonSPDAxes, {'reference band SPD(min)', 'reference band SPD(max)', 'interacting band(s) SPD (min)', 'interacting band(s) SPD (max)', 'reference band SPD', 'interacting band(s) SPD'}, 'Location', 'SouthWest');
    set(hL, 'FontSize', 14, 'FontName', 'Menlo');
    legend boxoff;
    set(axesStruct.singletonSPDAxes, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [0 maxSPD], 'XTick', [300:25:800], 'FontSize', 14);
    xlabel(axesStruct.singletonSPDAxes, 'wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel(axesStruct.singletonSPDAxes, 'power (mW)', 'FontSize', 16, 'FontWeight', 'bold');
    grid(axesStruct.singletonSPDAxes, 'on');
    box(axesStruct.singletonSPDAxes, 'off');
 
    % The measured and predicted combo SPDs on bottom-left
    repeatsColors = colormap(jet(2+size(measuredComboAllSPDs,2)));
   
    allLegends = {};
    for k = 1:size(measuredComboAllSPDs,2)
         allLegends{k} = sprintf('measured SPD (#%d)\n', k);
         plot(axesStruct.comboSPDAxes, wavelengthAxis,squeeze(measuredComboAllSPDs(:,k)), '-', 'Color', squeeze(repeatsColors(k+1,:)), 'LineWidth', 1.5);
         if (k == 1)
             hold(axesStruct.comboSPDAxes, 'on');
         end
     end
     plot(axesStruct.comboSPDAxes, wavelengthAxis,measuredComboSPD, '-', 'Color', [0.1 0.1 0.1],  'LineWidth', 3.0);
     plot(axesStruct.comboSPDAxes, wavelengthAxis,predictedComboSPD, '-', 'Color', [1.0 0.1 0.9], 'LineWidth', 3.0);
     hold(axesStruct.comboSPDAxes,'off');
%     
     allLegends{numel(allLegends)+1} = 'measured SPD (mean)';
     allLegends{numel(allLegends)+1} = 'predicted SPD (mean)';
%      
     hL = legend(axesStruct.comboSPDAxes, allLegends);
     set(hL, 'FontSize', 14, 'FontName', 'Menlo');
     legend boxoff;
     set(axesStruct.comboSPDAxes, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [0 maxSPD], 'XTick', [300:25:800]);
     set(axesStruct.comboSPDAxes, 'FontSize', 14, 'FontName', 'Menlo');
     xlabel(axesStruct.comboSPDAxes, 'wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold');
     ylabel(axesStruct.comboSPDAxes, 'power (mW)', 'FontSize', 16, 'FontWeight', 'bold');
     grid(axesStruct.comboSPDAxes, 'on');
     box(axesStruct.comboSPDAxes, 'off');
% 
    % The residual (measured - predicted combo SPDs) on bottom-right
    allLegends = {};
    for k = 1:size(measuredComboAllSPDs,2)
         allLegends{k} = sprintf('measured SPDmean - measuredSPD(#%d)\n', k);
         plot(axesStruct.residualSPDAxes, wavelengthAxis, measuredComboSPD-squeeze(measuredComboAllSPDs(:,k)), '-', 'Color', squeeze(repeatsColors(k+1,:)), 'LineWidth', 2.0);
         if (k == 1)
             hold(axesStruct.residualSPDAxes, 'on');
         end
    end
    y = [0 (measuredComboSPD-predictedComboSPD)' 0];
    patch(x,y, 'green', 'FaceColor', [0.6 0.6 0.6], 'EdgeColor', [0.3 0.3 0.3], 'FaceAlpha', 0.7, 'EdgeAlpha', 0.9, 'LineWidth', 2.0, 'parent', axesStruct.residualSPDAxes);
    hold(axesStruct.residualSPDAxes, 'off');
    allLegends{numel(allLegends)+1} = 'measured SPDmean - predicted SPD';
%     
    hL = legend(axesStruct.residualSPDAxes, allLegends, 'Location', 'SouthWest');
    set(hL, 'FontSize', 14, 'FontName', 'Menlo');
    legend boxoff;
    set(axesStruct.residualSPDAxes, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [-3 3], 'XTick', [300:25:800], 'FontSize', 14);
    xlabel(axesStruct.residualSPDAxes, 'wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel(axesStruct.residualSPDAxes, 'residual power (mW)', 'FontSize', 16, 'FontWeight', 'bold');
    grid on
    box off
%     
    text(385, 2.7, sprintf('reference   band  settings: %2.2f', referenceSettingsValue), 'Color', [1.0 0.3 0.3], 'FontName', 'Menlo', 'FontSize', 14, 'parent', axesStruct.residualSPDAxes);
    text(385, 2.2, sprintf('interacting band(s) settings: %2.2f', interactingSettingsValue), 'Color', [0.3 0.3 1.0],'FontName', 'Menlo', 'FontSize', 14, 'parent', axesStruct.residualSPDAxes);
    drawnow;
end


function measureData(rootDir, Svector, radiometerType)

    
    % check that hardware is responding
    checkHardware(radiometerType);
    
    % Ask for email recipient
    emailRecipient = GetWithDefault('Send status email to','cottaris@psych.upenn.edu');
    
    % Import a calibration 
    cal = OLGetCalibrationStructure;
    
    nPrimariesNum = cal.describe.numWavelengthBands;
    
    % Reference band: One, at the center of the band range
    referenceBands = round(nPrimariesNum/2);
    
    % Bands that are constant across all conditions
    steadyBands = [];
    steadyBandSettingsLevels = [];
    
    setType = 'wigglySpectrumVariation1';
    %setType = 'combinatorialFull';
    %setType = 'combinatorialSmall';
    %setType = 'slidingInteraction';
    
    % How many times to repeat each measurement
    nRepeats = GetWithDefault('Enter number of stimulus repeats (nRepeats): ', 6);  
    warmUpRepeats = 50;
    
    if (strcmp(setType, 'slidingInteraction'))
        % Measure at these levels
        interactingBandSettingsLevels = [0.25 0.50 0.75 1.0];
        nGammaLevels = 16;
        referenceBandSettingsLevels = linspace(1.0/nGammaLevels, 1.0, nGammaLevels);
        
       % pattern = [1 2 3 4];
        pattern = [1 2 3];
       % pattern = [1 2];
        interactingBands = {};
        
        k = 0;
        while (max(referenceBands) + max(pattern) < 56)
            k = k + 1;
            interactingBands{k} = pattern;
            pattern = pattern + numel(pattern);
        end
        max(max(referenceBands) + max(pattern))
        if (max(max(referenceBands) + max(pattern)) > 56)
            interactingBands = interactingBands(1:(numel(interactingBands)-1));
        end
        
    elseif (strcmp(setType, 'combinatorialFull'))
        % Measure at these levels
        interactingBandSettingsLevels = [0.33 0.66 1.0];
        nGammaLevels = 20;
        referenceBandSettingsLevels = linspace(1.0/nGammaLevels, 1.0, nGammaLevels);
    
        interactingBandLocation = 'BilateralToReferenceBand';
        %interactingBandLocation = 'UnilateralToReferenceBand';
        
        if (strcmp(interactingBandLocation, 'BilateralToReferenceBand'))
            % Measure interactions with bands around the reference band
            % 2 band patterns
            p0 = [ 3  4];
            p1 = [ 1  2];
            p2 = [-2 -1];
            p3 = [-4 -3];
            
            % 3 band patterns
            p0 = [ 4  5  6];
            p1 = [ 1  2  3];
            p2 = [-3 -2 -1];
            p3 = [-6 -5 -4];
            
        elseif (strcmp(interactingBandLocation, 'UnilateralToReferenceBand'))
            % OR Measure interactions with bands to the right of the reference band
            % 2 band patterns
            p0 = [7 8];
            p1 = [5 6];  
            p2 = [3 4];
            p3 = [1 2];
            
            % 3 band patterns
            p0 = [10 11 12];
            p1 = [7 8 9];  
            p2 = [4 5 6];
            p3 = [1 2 3];
        end
        
        interactingBands = { ...
             [                     p0(:) ]; ...
             [p3(:)                      ]; ...
             [              p1(:)        ]; ...
             [       p2(:)               ]; ...
             [p3(:)                p0(:) ]; ...
             [p3(:)  p2(:)               ]; ...
             [              p1(:)  p0(:) ]; ...
             [       p2(:)  p1(:)        ]; ...
             [       p2(:)  p1(:)  p0(:) ]; ...
             [p3(:)  p2(:)  p1(:)        ]; ...
             [p3(:)  p2(:)  p1(:)  p0(:) ]; ...
             [       p2(:)         p0(:) ]; ...
             [p3(:)         p1(:)        ]; ...
             [p3(:)         p1(:)  p0(:) ]; ...
             [p3(:)  p2(:)         p0(:) ]; ...
            };
 
    elseif (strcmp(setType, 'combinatorialSmall'));
        % Measure at these levels
        interactingBandSettingsLevels = [0.4 0.8];
        nGammaLevels = 6;
        referenceBandSettingsLevels = linspace(1.0/nGammaLevels, 1.0, nGammaLevels);
    
        % Measure interactions at these bands around the reference band
        pattern0 = [1 2 3 4];
        pattern1 = [-4 -3 -2 -1];
        interactingBands = { ...
            [            pattern0(:)]; ...
            [pattern1(:)            ]; ...
            [pattern1(:) pattern0(:)]; ...
            };
        
    elseif strcmp(setType, 'wigglySpectrumVariation1');
        
        referenceBands = 25;  % gamma will be measured for band# 25 for all conditions
        nGammaLevels = 20;
        referenceBandSettingsLevels = linspace(1.0/nGammaLevels, 1.0, nGammaLevels);
        
        pattern0 = [1 2 3 4 5 6 7];
        pattern1 = pattern0 + 8;
        pattern2 = pattern1 + 8;
        pattern3 = pattern2 + 8;
        pattern4 = pattern0 - 8;
        pattern5 = pattern4 - 8;
        pattern6 = pattern5 - 8;  
        
        interactingBands = { ...
            [                                                                        pattern3(:)]; ...
            [pattern6(:)                                                                        ]; ...
            [                                                            pattern2(:)            ]; ...
            [            pattern5(:)                                                            ]; ...
            [                                                pattern1(:)                        ]; ...
            [                        pattern4(:)                                                ]; ...
            [                                    pattern0(:)                                    ]; ...
            [                        pattern4(:) pattern0(:)                                    ]; ...
            [                        pattern4(:) pattern0(:) pattern1(:)                        ]; ...
            [            pattern5(:) pattern4(:) pattern0(:) pattern1(:)                        ]; ...
            [            pattern5(:) pattern4(:) pattern0(:) pattern1(:) pattern2(:)            ]; ...
            [pattern6(:) pattern5(:) pattern4(:) pattern0(:) pattern1(:) pattern2(:)            ]; ...
            [pattern6(:) pattern5(:) pattern4(:) pattern0(:) pattern1(:) pattern2(:) pattern3(:)]; ...
            [pattern6(:) pattern5(:) pattern4(:) pattern0(:) pattern1(:) pattern2(:) pattern3(:)] ...
        };
        
        interactingBandSettingsLevels = [0.1 0.3 0.5 0.7 0.9];

        % these bands will have steady settings across all conditions (except the dark SPD)
        steadyBands = referenceBands + [8 -8 16 -16 24 -24];
        steadyBandSettingsLevels = 0.8 * ones(numel(steadyBands),1);
    end
    
    
    stimPattern = 0;
    
    % add dark SPD
    spdType =  'dark';
    stimPattern = stimPattern + 1;
    activation = zeros(nPrimariesNum,1);
    data{stimPattern} = struct(...
        'spdType', spdType, ...
        'activation', activation, ...
        'referenceBandIndex', [], ...
        'interactingBandsIndex', [], ...
        'referenceBandSettingsIndex', 0, ...
        'interactingBandSettingsIndex', 0, ...
        'measurementTime', [], ...
        'measuredSPD', [] ....
    ); 

    % add temporal stability gauge #1 SPD
    spdType = 'temporalStabilityGauge1SPD';
    stimPattern = stimPattern + 1;
    activation = round(rand(nPrimariesNum,1)*100)/100;
    activation(activation < 0.05) = 0.05;
    data{stimPattern} = struct(...
        'spdType', spdType, ...
        'activation', activation, ...
        'referenceBandIndex', [], ...
        'interactingBandsIndex', [], ...
        'referenceBandSettingsIndex', 0, ...
        'interactingBandSettingsIndex', 0, ...
        'measurementTime', [], ...
        'measuredSPD', [] ....
    ); 
    
    % add temporal stability gauge #1 SPD
    spdType = 'temporalStabilityGauge2SPD';
    stimPattern = stimPattern + 1;
    data{stimPattern} = struct(...
        'spdType', spdType, ...
        'activation', 1-activation, ...
        'referenceBandIndex', [], ...
        'interactingBandsIndex', [], ...
        'referenceBandSettingsIndex', 0, ...
        'interactingBandSettingsIndex', 0, ...
        'measurementTime', [], ...
        'measuredSPD', [] ....
    ); 

    % new data set for warming up data consisting of the 2 temporal
    % stability gauge SPDs
    warmUpData{1} = data{2};
    warmUpData{2} = data{3};
    
    % if we have steady bands add an SPD with those bands only activated
    if (~isempty(steadyBands))
        spdType = 'steadyBandsOnly';
        stimPattern = stimPattern + 1;
        activation = zeros(nPrimariesNum,1);
        activation(steadyBands) = steadyBandSettingsLevels;
        data{stimPattern} = struct(...
            'spdType', spdType, ...
            'activation', activation, ...
            'referenceBandIndex', [], ...
            'interactingBandsIndex', [], ...
            'referenceBandSettingsIndex', 0, ...
            'interactingBandSettingsIndex', 0, ...
            'measurementTime', [], ...
            'measuredSPD', [] ....
        );
    end
    
    for referenceBandIndex = 1:numel(referenceBands)
        referenceBand = referenceBands(referenceBandIndex);
        for referenceBandSettingsIndex = 1:numel(referenceBandSettingsLevels)
            referenceBandSettings = referenceBandSettingsLevels(referenceBandSettingsIndex);
            
            for interactingBandIndex = 1:numel(interactingBands)
                interactingBand = referenceBand + interactingBands{interactingBandIndex};
                for interactingBandSettingsIndex = 1:numel(interactingBandSettingsLevels)
                    interactingBandSettings = interactingBandSettingsLevels(interactingBandSettingsIndex);
                    
                    spdType = 'comboSPD';
                    stimPattern = stimPattern + 1;
                    activation = zeros(nPrimariesNum,1);
                    activation(interactingBand) = interactingBandSettings;
                    activation(referenceBand) = referenceBandSettings;
                    if (~isempty(steadyBands))
                        activation(steadyBands) = steadyBandSettingsLevels;
                    end
                    data{stimPattern} = struct(...
                        'spdType', spdType, ...
                        'activation', activation, ...
                        'referenceBandIndex', referenceBandIndex, ...
                        'interactingBandsIndex', interactingBandIndex, ...
                        'referenceBandSettingsIndex', referenceBandSettingsIndex, ...
                        'interactingBandSettingsIndex', interactingBandSettingsIndex, ...
                        'measurementTime', [], ...
                        'measuredSPD', [] ....
                    );
                
                    if (referenceBandSettingsIndex == 1)
                        spdType = 'singletonSPDi';
                        stimPattern = stimPattern + 1;
                        activation = zeros(nPrimariesNum,1);
                        activation(interactingBand) = interactingBandSettings;
                        if (~isempty(steadyBands))
                            activation(steadyBands) = steadyBandSettingsLevels;
                        end
                        data{stimPattern} = struct(...
                            'spdType', spdType, ...
                            'activation', activation, ...
                            'referenceBandIndex', referenceBandIndex, ...
                            'interactingBandsIndex', interactingBandIndex, ...
                            'referenceBandSettingsIndex', 0, ...
                            'interactingBandSettingsIndex', interactingBandSettingsIndex, ...
                            'measurementTime', [], ...
                            'measuredSPD', [] ....
                        );
                    end
                    
                end % for interactingBandSettingsIndex 
            end % interactingBandIndex
            
            spdType = 'singletonSPDr';
            stimPattern = stimPattern + 1;
            activation = zeros(nPrimariesNum,1);
            activation(referenceBand) = referenceBandSettings;
            if (~isempty(steadyBands))
               activation(steadyBands) = steadyBandSettingsLevels;
            end
            data{stimPattern} = struct(...
                        'spdType', spdType, ...
                        'activation', activation, ...
                        'referenceBandIndex', referenceBandIndex, ...
                        'interactingBandsIndex', [], ...
                        'referenceBandSettingsIndex', referenceBandSettingsIndex, ...
                        'interactingBandSettingsIndex', 0, ...
                        'measurementTime', [], ...
                        'measuredSPD', [] ....
                    );
                
        end % referenceBandSettingsIndex
    end % referenceBandIndex
    

    nSpectraMeasured = numel(data);
    fprintf('There will be %d distinct spectra measured (%d reps). \n', nSpectraMeasured, nRepeats);
    
    % Plot the activations (before randomization)
    hFig = figure(1); clf; set(hFig, 'Position', [1 1 573 1290]);
    subplot('Position', [0.04 0.04 0.95 0.95]);
    pcolor(1:nPrimariesNum, 1:nSpectraMeasured, Core.retrieveActivationSequence(data, 1:nSpectraMeasured));
    xlabel('primary no');
    ylabel('spectrum no');
    set(gca, 'CLim', [0 1], 'YLim', [0 nSpectraMeasured+1]);
    title('primary values');
    colormap(gray(1024));
    disp('Hit enter to continue');
    pause
    
    spectroRadiometerOBJ = [];
    ol = [];
    
    hFig = figure(2); set(hFig, 'Position', [10 10 1500 970], 'Color', [0 0 0]);
    clf;
            
    try
        meterToggle = [1 0];
        od = [];
        nAverage = 1;
        
        spectroRadiometerOBJ = initRadiometerObject(radiometerType);
        pause(0.2);
        
        % Get handle to OneLight
        ol = OneLight;

        % Do the warming up data collection to allow for the unit to warm up
        for repeatIndex = 1:warmUpRepeats
           for stimPattern = 1:numel(warmUpData)

                settingsValues  = warmUpData{stimPattern}.activation;
                [starts,stops] = OLSettingsToStartsStops(cal,settingsValues);
                measurement = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, Svector, meterToggle, nAverage);
                warmUpData{stimPattern}.oneLightStateBeforeStimOnset{repeatIndex}  = measurement.oneLightState1;
                warmUpData{stimPattern}.oneLightStateAfterMeasurement{repeatIndex} = measurement.oneLightState2;
                warmUpData{stimPattern}.measuredSPD(:, repeatIndex)     = measurement.pr650.spectrum;
                warmUpData{stimPattern}.measurementTime(:, repeatIndex) = measurement.pr650.time(1);
                warmUpData{stimPattern}.repeatIndex = repeatIndex;
                
                subplot('Position', [0.51 0.03 0.45 0.47]);
                bar(settingsValues, 1, 'FaceColor', [0.3 0.8 0.9]);
                set(gca, 'YLim', [0 1.05], 'XLim', [0 nPrimariesNum+1], 'XTick', [], 'YTick', [], 'Color', [0 0 0]);
                subplot('Position', [0.51 0.52 0.45 0.44]);
                plot(SToWls(Svector), measurement.pr650.spectrum, 'g-', 'LineWidth', 2.0);
                set(gca, 'XTick', [], 'YTick', [], 'Color', [0 0 0]);
                title(sprintf('warm up data (pattern: %d, repeat %d)', stimPattern, repeatIndex), 'Color', [1 1 1], 'FontSize', 14, 'FontName', 'Menlo')
                drawnow;
           end
        end
        
        randomizedSpectraIndices = [];
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
                
                % Show where in the stimulation sequence we are right now.
                subplot('Position', [0.03 0.03 0.45 0.95]);
                plot([1 nPrimariesNum], (spectrumIter+0.5)*[1 1], 'g-');
                drawnow;
                
                fprintf('Measuring spectrum %d of %d (repeat: %d/%d)\n', spectrumIter, nSpectraMeasured, repeatIndex, nRepeats);
                
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
        save(filename, 'status', 'data', 'nRepeats', 'warmUpData', 'warmUpRepeats', 'Svector', 'setType', 'steadyBands', 'steadyBandSettingsLevels', 'interactingBandSettingsLevels', 'referenceBandSettingsLevels', 'referenceBands', 'interactingBands', 'randomizedSpectraIndices', 'cal', '-v7.3');
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







function checkHardware(radiometerType)

    spectroRadiometerOBJ = [];
    ol = [];

    pause(1.0);
    
    try
        spectroRadiometerOBJ = initRadiometerObject(radiometerType);

        spectroRadiometerOBJ.shutDown();
        fprintf('PR670 is good!\n');
        pause(0.5);
        
        ol = OneLight;
        fprintf('One Light is good!\n');
        fprintf('Hit enter to continue  ');
        pause
        
    catch err
        
        if (~isempty(spectroRadiometerOBJ))
            % Shutdown spectroradiometer
            spectroRadiometerOBJ.shutDown();
        end
        
        rethrow(err);
        
    end
    
end


function spectroRadiometerOBJ = initRadiometerObject(radiometerType)

    spectroRadiometerOBJ = [];
    
    switch (radiometerType)
        case 'PR-650'
            cal.describe.meterTypeNum = 1;
            cal.describe.S = [380 4 101];
            nAverage = 1;
            cal.describe.gammaNumberWlUseIndices = 3;
            
            % Instantiate a PR650 object
            spectroRadiometerOBJ  = PR650dev(...
                'verbosity',        1, ...       % 1 -> minimum verbosity
                'devicePortString', [] ...       % empty -> automatic port detection)
            );
            spectroRadiometerOBJ.setOptions('syncMode', 'OFF');
            
        case 'PR-670',
            cal.describe.meterTypeNum = 5;
            cal.describe.S = [380 2 201];
            nAverage = 1;
            cal.describe.gammaNumberWlUseIndices = 5;
            
            % Instantiate a PR670 object
            spectroRadiometerOBJ  = PR670dev(...
                'verbosity',        1, ...       % 1 -> minimum verbosity
                'devicePortString', [] ...       % empty -> automatic port detection)
            );
        
            % Set options Options available for PR670:
            spectroRadiometerOBJ.setOptions(...
                'verbosity',        1, ...
                'syncMode',         'OFF', ...      % choose from 'OFF', 'AUTO', [20 400];        
                'cyclesToAverage',  1, ...          % choose any integer in range [1 99]
                'sensitivityMode',  'EXTENDED', ... % choose between 'STANDARD' and 'EXTENDED'.  'STANDARD': (exposure range: 6 - 6,000 msec, 'EXTENDED': exposure range: 6 - 30,000 msec
                'exposureTime',     'ADAPTIVE', ... % choose between 'ADAPTIVE' (for adaptive exposure), or a value in the range [6 6000] for 'STANDARD' sensitivity mode, or a value in the range [6 30000] for the 'EXTENDED' sensitivity mode
                'apertureSize',     '1 DEG' ...   % choose between '1 DEG', '1/2 DEG', '1/4 DEG', '1/8 DEG'
            );

        otherwise,
            error('Unknown meter type');
    end
    
end