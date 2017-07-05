% We want to create a directory structure if the params.CALCULATE_SPLATTER flag is on, to save the output there
if params.CALCULATE_SPLATTER
    if ~exist(fullfile(cacheDir, cacheFileName))
        mkdir(fullfile(cacheDir, cacheFileName));
    end
    if ~exist(fullfile(cacheDir, cacheFileName, char(cal.describe.calType)))
        mkdir(fullfile(cacheDir, cacheFileName, char(cal.describe.calType)));
    end
    
    docDir = fullfile(cacheDir, cacheFileName, char(cal.describe.calType), strrep(strrep(cal.describe.date, ' ', '_'), ':', '_'));
    if ~exist(docDir)
        mkdir(docDir);
    end
end


[calID calIDTitle] = OLGetCalID(cal);

if params.CALCULATE_SPLATTER
    fprintf('> Requested to calculate splatter as per params.CALCULATE_SPLATTER flag...\n');
    
    % Pull out the data for the reference observer
    data = cacheData.data(params.OBSERVER_AGE);
    
    %% Make plot of spectra and save as csv
    theSpectraFig = figure;
    subplot(1, 4, 1);
    plot(SToWls(S), data.backgroundSpd);
    xlim([380 780]);
    xlabel('Wavelength [nm]'); ylabel('Power'); title('Background'); pbaspect([1 1 1]);
    
    subplot(1, 4, 2);
    plot(SToWls(S), data.modulationSpdSignedPositive); hold on;
    plot(SToWls(S), data.backgroundSpd, '--k');
    xlim([380 780]);
    xlabel('Wavelength [nm]'); ylabel('Power'); title('+ve modulation'); pbaspect([1 1 1]);
    
    subplot(1, 4, 3);
    plot(SToWls(S), data.modulationSpdSignedNegative); hold on;
    plot(SToWls(S), data.backgroundSpd, '--k');
    xlim([380 780]);
    xlabel('Wavelength [nm]'); ylabel('Power'); title('-ve modulation'); pbaspect([1 1 1]);
    
    subplot(1, 4, 4);
    plot(SToWls(S), data.modulationSpdSignedPositive-data.backgroundSpd, '-r'); hold on;
    plot(SToWls(S), data.modulationSpdSignedNegative-data.backgroundSpd, '-b'); hold on;
    xlim([380 780]);
    xlabel('Wavelength [nm]'); ylabel('Power'); title('Difference spectra'); pbaspect([1 1 1]);
    
    % Save plots
    suptitle(sprintf('%s\n%s', calIDTitle, cacheFileName));
    set(theSpectraFig, 'PaperPosition', [0 0 20 10]);
    set(theSpectraFig, 'PaperSize', [20 10]);
    
    currDir = pwd;
    
    cd(docDir);
    saveas(theSpectraFig, ['Spectra_' calID], 'pdf');
    cd(currDir)
    
    % Save as CSV
    csvwrite(fullfile(docDir, ['Spectra_' calID '.csv']), [SToWls(S) data.backgroundSpd data.modulationSpdSignedPositive data.modulationSpdSignedNegative]);
    
    % Only do the splatter calcs if the Klein is not involved
    if ~(isfield(params, 'checkKlein') && params.checkKlein);
        theCanonicalPhotoreceptors = {'LCone', 'MCone', 'SCone', 'Melanopsin', 'Rods'};
        %% Plot both the positive and the negative lobes.
        
        %% Positive modulation
        for k = 1:length(theCanonicalPhotoreceptors)
            targetContrasts{k} = data.describe.contrastSignedPositive(k);
        end
        backgroundSpd = data.backgroundSpd;
        modulationSpd = data.modulationSpdSignedPositive;
        fileNameSuffix = '_positive';
        titleSuffix = 'Positive';
        
        % Calculate the splatter
        lambdaMaxRange = [];
        ageRange = [];
        [contrastMap, nominalLambdaMax, ageRange, lambdaMaxShiftRange] = CalculateSplatter(S, backgroundSpd, modulationSpd, theCanonicalPhotoreceptors, data.describe.params.fieldSizeDegrees, [], pupilDiameterMm, [], cacheData.data(params.OBSERVER_AGE).describe.fractionBleached);
        
        % Plot the splatter
        SAVEPLOTS = 0;
        theFig = PlotSplatter(figure, contrastMap, theCanonicalPhotoreceptors, nominalLambdaMax, params.OBSERVER_AGE, ageRange, lambdaMaxShiftRange, targetContrasts, [], 1, 2, SAVEPLOTS, titleSuffix, [], 32);
        % Save out the splatter
        SaveSplatter(docDir, [fileNameSuffix '_' calID], contrastMap, theCanonicalPhotoreceptors, nominalLambdaMax, params.OBSERVER_AGE, ageRange, lambdaMaxShiftRange, targetContrasts);
        SaveSplatterConfidenceBounds(docDir, [fileNameSuffix '_95CI_' calID], contrastMap, theCanonicalPhotoreceptors, nominalLambdaMax, ageRange, lambdaMaxShiftRange, targetContrasts, 0.9545);
        SaveSplatterConfidenceBounds(docDir, [fileNameSuffix '_99CI_' calID], contrastMap, theCanonicalPhotoreceptors, nominalLambdaMax, ageRange, lambdaMaxShiftRange, targetContrasts, 0.9973);
        
        
        %% Negative modulation
        for k = 1:length(theCanonicalPhotoreceptors)
            targetContrasts{k} = data.describe.contrastSignedNegative(k);
        end
        backgroundSpd = data.backgroundSpd;
        modulationSpd = data.modulationSpdSignedNegative;
        fileNameSuffix = '_negative';
        titleSuffix = 'Negative';
        
        % Calculate the splatter
        lambdaMaxRange = [];
        ageRange = [];
        [contrastMap, nominalLambdaMax, ageRange, lambdaMaxShiftRange] = CalculateSplatter(S, backgroundSpd, modulationSpd, theCanonicalPhotoreceptors, data.describe.params.fieldSizeDegrees, ageRange, pupilDiameterMm, [], cacheData.data(params.OBSERVER_AGE).describe.fractionBleached);
        
        % Plot the splatter
        theFig = PlotSplatter(theFig, contrastMap, theCanonicalPhotoreceptors, nominalLambdaMax, params.OBSERVER_AGE, ageRange, lambdaMaxShiftRange, targetContrasts, [], 2, 2, SAVEPLOTS, titleSuffix, [], 32);
        
        % Add a suplabel
        figure(theFig);
        suplabel(sprintf('%s/%s', calIDTitle, cacheFileName));
        
        %% Save plots
        set(theFig, 'Color', [1 1 1]);
        set(theFig, 'InvertHardCopy', 'off');
        set(theFig, 'PaperPosition', [0 0 20 12]); %Position plot at left hand corner with width 15 and height 6.
        set(theFig, 'PaperSize', [20 12]); %Set the paper to have width 15 and height 6.
        currDir = pwd;
        cd(docDir);
        saveas(theFig, ['Splatter_' calID], 'pdf');
        cd(currDir);
        
        fprintf('  - Contrast plot saved to %s.\n', fullfile(docDir, ['Splatter_' calID]));
        
        % Save out the splatter
        SaveSplatter(docDir, [fileNameSuffix '_' calID], contrastMap, theCanonicalPhotoreceptors, nominalLambdaMax, params.OBSERVER_AGE, ageRange, lambdaMaxShiftRange, targetContrasts);
        SaveSplatterConfidenceBounds(docDir, [fileNameSuffix '_95CI_' calID], contrastMap, theCanonicalPhotoreceptors, nominalLambdaMax, ageRange, lambdaMaxShiftRange, targetContrasts, 0.9545);
        SaveSplatterConfidenceBounds(docDir, [fileNameSuffix '_99CI_' calID], contrastMap, theCanonicalPhotoreceptors, nominalLambdaMax, ageRange, lambdaMaxShiftRange, targetContrasts, 0.9973);
        
    end
end