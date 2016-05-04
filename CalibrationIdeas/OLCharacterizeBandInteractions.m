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
    load(fileName, 'data', 'primaryLevels', 'referenceBands', 'interactingBands', 'nRepeats', 'randomizedSpectraIndices', 'cal');
    
    nSpectraMeasured = numel(data);
    fprintf('There are %d distinct spectra measured (each measured %d times). \n', nSpectraMeasured, nRepeats);
    
    nPrimariesNum = numel(data{1}.activation);
    wavelengthAxis = SToWls(Svector);
    nSpectralSamples = numel(wavelengthAxis);
    
    % Compute average and range of measured spectra
    for repeatIndex = 1:nRepeats
        stimulationSequence = squeeze(randomizedSpectraIndices(repeatIndex,:)); 
            
        % Show stimulation sequence for this repeat
        figure(2);
        clf;
        subplot('Position', [0.04 0.04 0.95 0.95]);
        pcolor(1:nPrimariesNum, 1:nSpectraMeasured, retrieveActivationSequence(data, stimulationSequence));
        xlabel('primary no');
        ylabel('spectrum no');
        set(gca, 'CLim', [0 1], 'XLim', [1 nPrimariesNum], 'YLim', [0 nSpectraMeasured+1]);
        colormap(gray);
        title(sprintf('Repeat %d\n', repeatIndex));
    end
    
    
    for spectrumIndex = 1:nSpectraMeasured
        
        data{spectrumIndex}.meanSPD = mean(data{spectrumIndex}.measuredSPD(:, 1:nRepeats), 2);
        data{spectrumIndex}.minSPD  = min(data{spectrumIndex}.measuredSPD(:, 1:nRepeats), 2);
        data{spectrumIndex}.maxSPD  = max(data{spectrumIndex}.measuredSPD(:, 1:nRepeats), 2);
        
        activationLevelIndex = data{spectrumIndex}.activationLevelIndex;
        
        if (strcmp(spdType, 'singetonSPDi'))
            interactingBand = data{spectrumIndex}.interactingBand;
            singletonSPD(activationLevelIndex, interactingBand,:) = data{spectrumIndex}.meanSPD;
        
        elseif (strcmp(spdType, 'singetonSPDb'))
            referenceBand = data{spectrumIndex}.referenceBand;
            singletonSPD(activationLevelIndex, referenceBand,:) = data{spectrumIndex}.meanSPD;
            
        elseif (strcmp(spdType, 'comboSPD'))
            interactingBand = data{spectrumIndex}.interactingBand;
            referenceBand = data{spectrumIndex}.referenceBand;
            comboSPD(activationLevelIndex, referenceBand, interactingBand,:) = data{spectrumIndex}.meanSPD;
            
        elseif (strcmp(spdType, 'darkSPD'))
            darkSPD = data{spectrumIndex}.meanSPD;
            
        else
            error('How can this be?')
        end 
    end
    
    % Substract darkSPD
    singletonSPD = bsxfun(@minus, singletonSPD, reshape(darkSPD, [1 1 nSpectralSamples]));
    comboSPD = bsxfun(@minus, comboSPD, reshape(darkSPD, [1 1 1 nSpectralSamples]));
    
    % Compute predictions for comboSPDs
    for activationLevelIndex = 1:size(comboSPD,1)
        for referenceBand = 1:size(comboSPD,2)
            for interactingBand = 1:size(comboSPD,3)
                comboSPDpredictions(activationLevelIndex, referenceBand, interactingBand,:) = ...
                    singletonSPD(activationLevelIndex, interactingBand,:) + singletonSPD(activationLevelIndex, referenceBand,:);
            end % interactingBandIndex
        end % referenceBandIndex
    end %  activationLevelIndex
end


function measureData(rootDir, Svector)

    % check that hardware is responding
    checkHardware();
    
    % Ask for email recipient
    emailRecipient = GetWithDefault('Send status email to','cottaris@psych.upenn.edu');
    
    % Import a calibration 
    cal = OLGetCalibrationStructure;
    
    nPrimariesNum = cal.describe.numWavelengthBands;
    
    % Measure at these levels
    primaryLevels = [0.33 0.66 1.0];
    
    referenceBands = round(nPrimariesNum/2); % For now fix the reference band to the center band. 
    % referenceBands = 6:10:nPrimariesNum-6;
    
    interactionRange = 10;
    interactingBands = [(-interactionRange:-1) (1:interactionRange)];
 
    nRepeats = 2;
    
    stimPattern = 0;
    for activationLevelIndex = 1:numel(primaryLevels)
        for referenceBandIndex = 1:numel(referenceBands)    
            
            referenceBand = referenceBands(referenceBandIndex);
            for interactingBandIndex = 1:numel(interactingBands)
                
                interactingBand = referenceBand + interactingBands(interactingBandIndex);                
                for spdType = {'singetonSPDi', 'comboSPD'}
                    stimPattern = stimPattern + 1;
                    activation = zeros(nPrimariesNum,1);
                
                    if strcmp(spdType, 'comboSPD')
                        % combo SPD
                        activation(interactingBand) = primaryLevels(activationLevelIndex);
                        activation(referenceBand)   = primaryLevels(activationLevelIndex);
                    elseif strcmp(spdType, 'singetonSPDi')
                        % singleton SPD for the interacting band
                        activation(interactingBand) = primaryLevels(activationLevelIndex);
                        activation(referenceBand)   = 0;
                    else
                        error('What the ?')
                    end
                    
                    data{stimPattern} = struct(...
                        'spdType', spdType, ...
                        'activation', activation, ...
                        'referenceBand', referenceBand, ...
                        'interactingBand', interactingBand, ...
                        'activationLevelIndex', activationLevelIndex, ...
                        'measurementTime', [], ...
                        'measuredSPD', [] ....
                    );
            
                end % for spdType
            end % interactingBandIndex
            
            % singleton for the reference band
            spdType = 'singetonSPDb';
            stimPattern = stimPattern + 1;
            activation = zeros(nPrimariesNum,1);  
            activation(referenceBand)   = primaryLevels(activationLevelIndex);
            data{stimPattern} = struct(...
                        'spdType', spdType, ...
                        'activation', activation, ...
                        'referenceBand', referenceBand, ...
                        'interactingBand', 0, ...
                        'activationLevelIndex', activationLevelIndex, ...
                        'measurementTime', [], ...
                        'measuredSPD', [] ....
                    );
                
        end % for refBandIndex
    end  % for activationLevelIndex
    
    % add dark SPD
    stimPattern = stimPattern + 1;
    activation = zeros(nPrimariesNum,1);
    data{stimPattern} = struct(...
        'spdType', 'dark', ...
        'activation', activation, ...
        'referenceBand', 0, ...
        'interactingBand', 0, ...
        'activationLevelIndex', 0, ...
        'measurementTime', [], ...
        'measuredSPD', [] ....
    );       
                 
    nSpectraMeasured = numel(data);
    fprintf('There will be %d distinct spectra measured (%d reps). \n', nSpectraMeasured, nRepeats);
    
    figure(1);
    clf;
    subplot('Position', [0.04 0.04 0.95 0.95]);
    pcolor(1:nPrimariesNum, 1:nSpectraMeasured, retrieveActivationSequence(data, 1:nSpectraMeasured));
    xlabel('primary no');
    ylabel('spectrum no');
    set(gca, 'CLim', [0 1]);
    title('primary values');
    colormap(gray);
    
    
    spectroRadiometerOBJ = [];
    ol = [];
    
    try
        meterToggle = [1 0];
        od = [];
        nAverage = 1;
        
        
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
         
            % Randomize presentation sequence
            randomizedSpectraIndices(repeatIndex,:) = randperm(nSpectraMeasured); 
            
            % Show randomized stimulation sequence
            figure(2);
            clf;
            subplot('Position', [0.04 0.04 0.95 0.95]);
            pcolor(1:nPrimariesNum, 1:nSpectraMeasured, retrieveActivationSequence(data, squeeze(randomizedSpectraIndices(repeatIndex,:))));
            hold on
            xlabel('primary no');
            ylabel('spectrum no');
            set(gca, 'CLim', [0 1], 'XLim', [1 nPrimariesNum], 'YLim', [0 nSpectraMeasured+1]);
            colormap(gray);
    
            for spectrumIter = 1:nSpectraMeasured
                
                % Show where in the stimulation sequence we are right now.
                figure(2);
                plot([1 nPrimariesNum], (spectrumIter+0.5)*[1 1], 'g-');
                drawnow;
                
                fprintf('Measuring spectrum %d of %d (repeat: %d/%d)\n', spectrumIter, nSpectraMeasured, repeatIndex, nRepeats);
                
                % Get randomized index
                spectrumIndex = randomizedSpectraIndices(repeatIndex,spectrumIter);
                
                primaryValues  = data{spectrumIndex}.activation;
                settingsValues = OLPrimaryToSettings(cal, primaryValues);
                [starts,stops] = OLSettingsToStartsStops(cal,settingsValues);
                measurement = OLTakeMeasurementOOC(ol, od, spectroRadiometerOBJ, starts, stops, Svector, meterToggle, nAverage);
                data{spectrumIndex}.measuredSPD(:, repeatIndex)     = measurement.pr650.spectrum;
                data{spectrumIndex}.measurementTime(:, repeatIndex) = measurement.pr650.time(1);
                data{spectrumIndex}.repeatIndex = repeatIndex;
                
                figure(3);
                clf;
                subplot(2,1,1);
                bar(primaryValues, 1);
                set(gca, 'YLim', [0 1], 'XLim', [0 nPrimariesNum+1]);
                subplot(2,1,2);
                plot(SToWls(Svector), measurement.pr650.spectrum, 'k-');
                drawnow;
            end  % spectrumIter
        end % repeatIndex
        
        % Save data
        filename = fullfile(rootDir,sprintf('BandInteractions_%s_%s.mat', cal.describe.calType, datestr(now, 'dd-mmm-yyyy_HH_MM_SS')));
        save(filename, 'data', 'primaryLevels', 'referenceBands', 'interactingBands', 'nRepeats', 'randomizedSpectraIndices', 'cal', '-v7.3');
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

function activationSequence = retrieveActivationSequence(data, presentationIndices)
    for spectrumIter = 1:numel(presentationIndices)
        % Get presentation index
        spectrumIndex = presentationIndices(spectrumIter);
        activationSequence(spectrumIter,:)  = data{spectrumIndex}.activation;
    end
end

function checkHardware()

    spectroRadiometerOBJ = [];
    ol = [];
    
    try
        % Instantiate a PR670 object
        spectroRadiometerOBJ  = PR670dev(...
            'verbosity',        1, ...       % 1 -> minimum verbosity
            'devicePortString', [] ...       % empty -> automatic port detection)
        );

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

