function OLCharacterizeBandInteractions
% OLCharacterizeBandInteractions - Characterize interactions between bands of the OneLight device.
%
% Syntax:
% OLCharacterizeBandInteractions
%
% 5/2/16  npc  Wrote it.
%

    [rootDir,~] = fileparts(which(mfilename()));
    cd(rootDir);
    
    Svector = [380 2 201];
    
    choice = input('Measure data(0), or analyze data(1) : ', 's');
    if (str2double(choice) == 0)
        measureData(rootDir, Svector);
    else
        analyzeData(rootDir, Svector);
    end
end

function analyzeData(rootDir, Svector)
    [fileName, pathName] = uigetfile('*.mat', 'Select a file to analyze', rootDir);
    whos('-file', fileName);
    load(fileName, 'cal', 'data');
    
    nSpectraMeasured = numel(data);
    d = data(1).measurement;
    nRepeats = size(d,2);
    primaryValues = data(1).activation.primaries;
    nPrimariesNum = numel(primaryValues);
    
    
    maxSPD = 0;
    nullReferenceSPD = [];
    for spectrumIndex = 1:nSpectraMeasured 
        referenceBand   = data(spectrumIndex).activation.referenceBand;
        interactingBand = data(spectrumIndex).activation.interactingBand;
        referenceBandPrimaryLevel = data(spectrumIndex).activation.referenceBandPrimaryLevel;
        interactingBandPrimaryLevel = data(spectrumIndex).activation.interactingBandPrimaryLevel;
         
        
        d = data(spectrumIndex).measurement;
        for repeatIndex = 1:nRepeats
            if (repeatIndex == 1)
                data(spectrumIndex).meanSPD = squeeze(d(:, repeatIndex));
            else
                data(spectrumIndex).meanSPD = data(spectrumIndex).meanSPD + squeeze(d(:, repeatIndex));
            end
        end
        data(spectrumIndex).meanSPD = data(spectrumIndex).meanSPD / nRepeats;
        
        if (interactingBandPrimaryLevel == 0)
            referenceBandActivationLevelIndex = round(referenceBandPrimaryLevel*100);
            if (referenceBandActivationLevelIndex==0)
                if (isempty(nullReferenceSPD))
                    nullReferenceSPD(1,:) =  data(spectrumIndex).meanSPD;
                else
                    nullReferenceSPD(size(nullReferenceSPD,1)+1,:) = data(spectrumIndex).meanSPD;
                end
            else
                singletonReferenceSPD(referenceBand, referenceBandActivationLevelIndex,:) = data(spectrumIndex).meanSPD;
            end
        end
        
        if (referenceBandPrimaryLevel == 0)
            interactingBandActivationLevelIndex = round(interactingBandPrimaryLevel*100);
            if (interactingBandActivationLevelIndex == 0)
                if (isempty(nullReferenceSPD))
                    nullReferenceSPD(1,:) =  data(spectrumIndex).meanSPD;
                else
                    nullReferenceSPD(size(nullReferenceSPD,1)+1,:) = data(spectrumIndex).meanSPD;
                end
            else
                singletonInteractingSPD(interactingBand, interactingBandActivationLevelIndex,:) = data(spectrumIndex).meanSPD;
            end
        end
        
        
        if (max(data(spectrumIndex).meanSPD) > maxSPD)
            maxSPD = max(data(spectrumIndex).meanSPD);
        end
    end
    
    nullReferenceSPD = mean(nullReferenceSPD, 1);
    
    
    for spectrumIndex = 1:nSpectraMeasured 
        primaryValues = data(spectrumIndex).activation.primaries;
        
        referenceBand   = data(spectrumIndex).activation.referenceBand;
        interactingBand = data(spectrumIndex).activation.interactingBand;
        referenceBandPrimaryLevel = data(spectrumIndex).activation.referenceBandPrimaryLevel;
        interactingBandPrimaryLevel = data(spectrumIndex).activation.interactingBandPrimaryLevel;
        
        referenceBandActivationLevelIndex = round(referenceBandPrimaryLevel*100);
        if (referenceBandActivationLevelIndex == 0)
            referenceSPD = nullReferenceSPD-nullReferenceSPD;
        else
            referenceSPD = squeeze(singletonReferenceSPD(referenceBand,referenceBandActivationLevelIndex,:))-nullReferenceSPD(:);
        end
        
        interactingBandPrimaryLevelIndex = round(interactingBandPrimaryLevel*100);
        if (interactingBandPrimaryLevelIndex == 0)
            interactingSPD = nullReferenceSPD-nullReferenceSPD;
        else
            interactingSPD = squeeze(singletonInteractingSPD(interactingBand,interactingBandPrimaryLevelIndex,:))-nullReferenceSPD(:);
        end
        
        predictedSPD = nullReferenceSPD(:) + squeeze(referenceSPD(:) + interactingSPD(:));
        
        hFig = figure(3);
        clf;
        set(hFig, 'Position', [10 10 1150 1350], 'Color', [1 1 1], 'MenuBar', 'none');

        wavelengthAxis = SToWls(Svector);
        
        subplot('Position', [0.05 0.29 0.44 0.70]);
        plot(wavelengthAxis, data(spectrumIndex).meanSPD*1000, 'k-', 'LineWidth', 2.0);
        hL = legend('measurement');
        set(hL, 'FontSize', 12);
        set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],'YLim', [0 maxSPD*1000]);
        set(gca, 'FontSize', 12);
        xlabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
        ylabel('power (mW)', 'FontSize', 14, 'FontWeight', 'bold');
        
        
        subplot(3,2,[2 4]);
        subplot('Position', [0.55 0.29 0.44 0.70]);
        plot(wavelengthAxis, data(spectrumIndex).meanSPD*1000, 'b-', 'Color', [0 0.4 1 1.0], 'LineWidth', 2.0);
        hold on;
        plot(SToWls(Svector), predictedSPD*1000, 'r-', 'Color', [1 0 0 0.5],  'LineWidth', 5.0);
        hL = legend('measurement', 'prediction');
        set(hL, 'FontSize', 12);
        hold off;
        yTickLevels = [-100:0.5:100];
        set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)], 'YLim', [0 maxSPD*1000], 'YTick', yTickLevels, 'YTickLabel', sprintf('%2.1f\n', yTickLevels));
        set(gca, 'FontSize', 12);
        xlabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
        ylabel('power (mW)', 'FontSize', 14, 'FontWeight', 'bold');
        grid on
        box on
        
        subplot('Position', [0.05 0.05 0.44 0.20]);
        bar(1:numel(primaryValues), primaryValues, 1.0, 'FaceColor', [1.0 0.6 0.6], 'EdgeColor', [0 0 0]);
        set(gca, 'YLim', [0 1], 'XLim', [0 nPrimariesNum+1]);
        if (referenceBand < interactingBand)
            legendLabel = sprintf('%2.1f , %2.1f', referenceBandPrimaryLevel, interactingBandPrimaryLevel);
        else
            legendLabel = sprintf('%2.1f , %2.1f', interactingBandPrimaryLevel, referenceBandPrimaryLevel);
        end
        hL = legend(legendLabel);
        set(hL, 'FontSize', 12);
        set(gca, 'FontSize', 12);
        xlabel('primary index', 'FontSize', 14, 'FontWeight', 'bold');
        ylabel('primary activation', 'FontSize', 14, 'FontWeight', 'bold');
        
        
        subplot('Position', [0.55 0.05 0.44 0.20]);
        residual = (data(spectrumIndex).meanSPD(:) - predictedSPD(:))*1000;
        plot(wavelengthAxis, residual, '-', 'Color', [1.0 0.2 0.1 0.8], 'LineWidth', 2.0);
        grid on
        box on
        hL = legend('measured - prediction');
        set(hL, 'FontSize', 12);
        set(gca, 'XLim', [wavelengthAxis(1) wavelengthAxis(end)], 'YLim', [-1 1], 'YTick', yTickLevels, 'YTickLabel', sprintf('%2.1f\n', yTickLevels));
        set(gca, 'FontSize', 12);
        xlabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
        ylabel('residual power (mW)', 'FontSize', 14, 'FontWeight', 'bold');
        
        drawnow;
    end
    
end


function measureData(rootDir, Svector)
    % Ask for email recipient
    emailRecipient = GetWithDefault('Send status email to','cottaris@psych.upenn.edu');
    
    % Import a calibration 
    cal = OLGetCalibrationStructure;
    
    nPrimariesNum = cal.describe.numWavelengthBands;
    
    % Measure at these levels
    primaryLevels = 0.0:0.33:1.0;
    
    referenceBands = round(nPrimariesNum/2); % For now fix the reference band to the center band. 
    % referenceBands = 6:10:nPrimariesNum-6;
    
    % Activate (one at a time) bands +/- 5  around reference band
    range = 10;
    interactingBands = [(-range:-1) (1:range)];
    
    nSpectraMeasured = numel(referenceBands) * numel(interactingBands) * numel(primaryLevels) * numel(primaryLevels);
    primaryValues = zeros(nPrimariesNum, nSpectraMeasured); 
    
    spectrumIndex = 0;
    for referenceBandIndex = 1:numel(referenceBands)
        referenceBand = referenceBands(referenceBandIndex);
        for interactingBandIndex = 1:numel(interactingBands)
            interactingBand = referenceBand + interactingBands(interactingBandIndex);
            for referenceBandPrimaryLevelIndex = 1:numel(primaryLevels)
                referenceBandPrimaryLevel = primaryLevels(referenceBandPrimaryLevelIndex);
                for interactingBandPrimaryLevelIndex = 1:numel(primaryLevels)
                    interactingBandPrimaryLevel = primaryLevels(interactingBandPrimaryLevelIndex);
                    activation = zeros(nPrimariesNum,1);
                    activation(referenceBand) = referenceBandPrimaryLevel;
                    activation(interactingBand) = interactingBandPrimaryLevel;
                    spectrumIndex = spectrumIndex + 1;
                    primaryValues(:,spectrumIndex) = activation;
                    data(spectrumIndex).activation = struct(...
                        'referenceBand', referenceBand, ...
                        'interactingBand', interactingBand', ...
                        'referenceBandPrimaryLevel', referenceBandPrimaryLevel, ...
                        'interactingBandPrimaryLevel', interactingBandPrimaryLevel, ...
                        'primaries', activation ...
                        );
                end % interactingBandPrimaryLevelIndex
            end % referenceBandPrimaryLevelIndex
        end % interactingBandIndex
    end % referenceBandIndex
    
    figure(1);
    clf;
    subplot('Position', [0.04 0.04 0.95 0.95]);
    pcolor(1:nPrimariesNum, 1:nSpectraMeasured, primaryValues');
    xlabel('primary no');
    ylabel('spectrum no');
    set(gca, 'CLim', [0 1]);
    title('primary values');
    colormap(gray);
    
    settingsValues = OLPrimaryToSettings(cal, primaryValues);
    figure(2);
    clf;
    subplot('Position', [0.04 0.04 0.95 0.95]);
    pcolor(1:nPrimariesNum, 1:nSpectraMeasured, settingsValues');
    xlabel('primary no');
    ylabel('spectrum no');
    set(gca, 'CLim', [0 1]);
    colormap(gray);
    title('settings values');
    pause
    
    spectroRadiometerOBJ = [];
    ol = [];
    
    try
        meterToggle = [1 0];
        od = [];
        nAverage = 1;
        nRepeats = 1;
        
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
        
        % Get handle to OneLight
        ol = OneLight;

        % Do all the measurements
        for repeatIndex = 1:nRepeats
            for spectrumIndex = 1:nSpectraMeasured
                fprintf('Measuring spectrum %d of %d (repeat: %d/%d)\n', spectrumIndex, nSpectraMeasured, repeatIndex, nRepeats);
                pause(0.1);
                primaryValues = data(spectrumIndex).activation.primaries;
                settingsValues = OLPrimaryToSettings(cal, primaryValues);
                [starts,stops] = OLSettingsToStartsStops(cal,settingsValues);
                measurement = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, Svector, meterToggle, nAverage);
                data(spectrumIndex).measurement(:, repeatIndex)       = measurement.pr650.spectrum;
                data(spectrumIndex).timeOfMeasurement(:, repeatIndex) = measurement.pr650.time(1);
                figure(3);
                clf;
                subplot(2,1,1);
                bar(primaryValues);
                set(gca, 'YLim', [0 1], 'XLim', [0 nPrimariesNum+1]);
                subplot(2,1,2);
                plot(SToWls(Svector), measurement.pr650.spectrum, 'k-');
                drawnow;
            end
        end
        
        % Save data
        filename = fullfile(rootDir,sprintf('BandInteractions_%s_%s.mat', cal.describe.calType, datestr(now, 'dd-mmm-yyyy_HH_MM_SS')));
        save(filename, 'data', 'cal', '-v7.3');
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

