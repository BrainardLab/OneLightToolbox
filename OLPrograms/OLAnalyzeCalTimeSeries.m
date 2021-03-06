%%OLAnalyzeCalTimeSeries  Analyze the time series of an OLcalibration file
% Description:
%     Analyze the time series of temperature, power fluctuation, and spectral
%     shift data found in an OLcalibration file
%

% History:
%   5/31/2018  NPC Wrote it.
%   6/05/2018  NPC Import calFile based on getpref('OneLightToolbox', 'OneLightCalData')
%

function OLAnalyzeCalTimeSeries
    % Provide an estimate of the comb SPD peaks
    combSPDNominalPeaks = [468 530 590 645];
    
    % Load calibrations
    [cals, calFile] = loadCalData();
    timeSeries = extractTimeSeries(cals);
    
    % Plot the time series analysis
    plotTimeSeries(timeSeries, calFile, combSPDNominalPeaks);
end

function plotTimeSeries(timeSeries, calFile, combSPDNominalPeaks)
    % Colors and symbols for all cals (up to 12*5 = 60 measurements)
    uniqueColorsNum = 12;
    colors = brewermap(12,'Paired');
    markers = {'s', 'o', 'd', '^', '.'};
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
        'rowsNum', 2, ...
        'colsNum', 3, ...
        'heightMargin',   0.1, ...
        'widthMargin',    0.035, ...
        'leftMargin',     0.04, ...
        'rightMargin',    0.001, ...
        'bottomMargin',   0.05, ...
        'topMargin',      0.05);

    tmp = subplotPosVectors(1,1).v;
    tmp(3) = tmp(3)-0.1;
    subplotPosVectors(1,1).v = tmp;
    
    tmp = subplotPosVectors(2,1).v;
    tmp(3) = tmp(3)-0.1;
    subplotPosVectors(2,1).v = tmp;
    
    
    tmp = subplotPosVectors(1,2).v;
    tmp(1) = tmp(1)-0.12;
    tmp(3) = tmp(3)+0.12;
    subplotPosVectors(1,2).v = tmp;
    
    tmp = subplotPosVectors(2,2).v;
    tmp(1) = tmp(1)-0.12;
    tmp(3) = tmp(3)+0.12;
    subplotPosVectors(2,2).v = tmp;
    
    
    hFig = figure(1); clf;
    set(hFig, 'Color', [1 1 1], ...
        'Position', [10 10 1680 940], ...
        'Name', sprintf('TIME SERIES ANALYSIS FOR %s', strrep(calFile, '.mat', '')));
    legends = {};
    
    % Do not show the figure as it takes a while to build up
    set(hFig,'visible','off');
    
    % Find the earliest and latest time stamp for each dayTimeSeries
    calsNum = numel(timeSeries);
    for calIndex = 1:calsNum
        willPlotTemperatureTimeSeries = true;
        willPlotSpectralShiftsTimeSeries = true;
        willPlotPowerFluctuationTimeSeries = true;
        dayTimeSeries = timeSeries{calIndex};
        if (isempty(dayTimeSeries.temperature))
            willPlotTemperatureTimeSeries = false;
        end
        
        if (isempty(dayTimeSeries.spectralShiftsMeas))
            fprintf(2,'There was no spectralShiftsMeas data in calibration #%d / %d\n', calIndex, calsNum);
            willPlotSpectralShiftsTimeSeries = false;
        end
        
        if (isempty(dayTimeSeries.powerFluctuationMeas))
            fprintf(2,'There was no powerFluctuationMeas data in calibration #%d / %d\n', calIndex, calsNum);
            willPlotPowerFluctuationTimeSeries = false;
        end             
    
        if (~willPlotPowerFluctuationTimeSeries||~willPlotSpectralShiftsTimeSeries)
            fprintf('No spectral shift data\n');
            return;
        else
            if (willPlotTemperatureTimeSeries == false)
                fprintf('No temperature data in calibration #%d/%d\n', calIndex, calsNum);
                dayTimeSeries.temperature.t = dayTimeSeries.powerFluctuationMeas.t;
                dayTimeSeries.temperature.value = nan(numel(dayTimeSeries.temperature.t),2);
                timeSeries{calIndex} = dayTimeSeries;
                willPlotTemperatureTimeSeries = true;
            end
        end

        time0(calIndex) = min([min(dayTimeSeries.temperature.t) min(dayTimeSeries.spectralShiftsMeas.t) min(dayTimeSeries.powerFluctuationMeas.t)]);
        timeN(calIndex) = max([max(dayTimeSeries.temperature.t) max(dayTimeSeries.spectralShiftsMeas.t) max(dayTimeSeries.powerFluctuationMeas.t)]);
    end
        
    maxDuration = max(timeN-time0);
    
    % Reference SPD (SPD0)
    dayTimeSeries = timeSeries{1};
    SPD0power = squeeze(dayTimeSeries.powerFluctuationMeas.measSpd(:,1));
    SPD0comb = squeeze(dayTimeSeries.spectralShiftsMeas.measSpd(:,1));
    
    for calIndex = 1:calsNum
        % Get color and symbol for this cal
        symbolIndex = floor((calIndex-1)/uniqueColorsNum)+1;
        colorIndex = mod(calIndex-1,uniqueColorsNum)+1;
        
        % Get the legend for this cal
        dayTimeSeries = timeSeries{calIndex};
        legends{numel(legends)+1} = dayTimeSeries.date;
        
        % Plot the temperature data
        if (willPlotTemperatureTimeSeries)
            plotDayTemperatureTimeSeries(symbolIndex, colorIndex, colors, markers, dayTimeSeries.temperature.t-time0(calIndex), dayTimeSeries.temperature.value, subplotPosVectors);
        end
        
        if (willPlotPowerFluctuationTimeSeries)
            % Plot the power fluctuation data
            plotPowerFluctuationTimeSeries(...
                symbolIndex, colorIndex, colors, markers, ...
                dayTimeSeries.powerFluctuationMeas.t-time0(calIndex), ...
                dayTimeSeries.powerFluctuationMeas.measSpd, SPD0power, ...
                dayTimeSeries.waveAxis, subplotPosVectors);
        end
        
        % Plot the spectral shift data
        if (willPlotSpectralShiftsTimeSeries)
            maxCombSPD(calIndex) = max(dayTimeSeries.spectralShiftsMeas.measSpd(:));
            [visualizedSpectralShiftWavelength, combSPDComputedPeaks(calIndex,:)] = ...
                plotSpectralShiftTimeSeries(symbolIndex, colorIndex, colors, markers, dayTimeSeries.spectralShiftsMeas.t-time0(calIndex), dayTimeSeries.spectralShiftsMeas.measSpd, SPD0comb, dayTimeSeries.waveAxis, combSPDNominalPeaks, calIndex, subplotPosVectors);
        end
    end
    
    % Show the figure now
    set(hFig,'visible','on');
    
    % TEMPERATURE PLOTS
    % Finish OL temperature time series
    subplot('Position', subplotPosVectors(1,3).v);
    set(gca, 'XLim', [0 maxDuration/60], 'XTick', 0:10:1000, 'YTick', 1:1:100, 'YLim', [25 40]);
    grid on; box on;
    %legend(legends, 'Location', 'EastOutside');
    xlabel('time (minutes)');
    ylabel('temperature (deg C)');
    title('OneLight internal temperature');
    set(gca, 'FontSize', 14);
    
    % Finish ambient temperature time series
    subplot('Position', subplotPosVectors(2,3).v);
    set(gca, 'XLim', [0 maxDuration/60], 'XTick', 0:10:1000,  'YTick', 1:1:100, 'YLim', [25 40]);
    grid on; box on;
    %legend(legends, 'Location', 'EastOutside');
    xlabel('time (minutes)');
    ylabel('Temperature (deg C)');
    title('Ambient temperature');
    set(gca, 'FontSize', 14);
    
    % POWER FLUCTUATION PLOTS
    % Finish fluctuation factor time series
    subplot('Position', subplotPosVectors(1,2).v);
    set(gca, 'XLim', [0 maxDuration/60], 'XTick', 0:10:1000);
    grid on; box on;
    legend(legends, 'Location', 'WestOutside');
    xlabel('time (minutes)');
    ylabel('Power fluctuation factor (SPD/SPD0)');
    title(sprintf('Power fluctuation with respect to the first SPD in\n''%s'.', strrep(strrep(calFile, '.mat', ''), '_', '')));
    set(gca, 'FontSize', 14);
    
    % Finish Full on SPDs
    subplot('Position', subplotPosVectors(1,1).v);
    set(gca, 'XLim', [350 750], 'XTick', 200:50:800);
    grid on; box on;
    xlabel('wavelength (nm)');
    ylabel('Power');
    title(sprintf('Power fluctuation SPDs\n'));
    set(gca, 'FontSize', 14);
    
    % SPECTRAL SHIFTS PLOTS
    % Finish shift amount plot
    subplot('Position', subplotPosVectors(2,2).v);
    set(gca, 'XLim', [0 maxDuration/60], 'XTick', 0:10:1000);
    grid on; box on;
    legend(legends, 'Location', 'WestOutside');
    xlabel('time (minutes)');
    ylabel(sprintf('Spectral shift (nm)'));
    title(sprintf('Spectral shift (@%2.0fnm) with respect to the first SPD in\n''%s'.', visualizedSpectralShiftWavelength, strrep(strrep(calFile, '.mat', ''), '_', '')));
    set(gca, 'FontSize', 14);
    
    % Finish combd SPDs
    subplot('Position', subplotPosVectors(2,1).v);
    % Plot nominal and computed peaks
    plot(combSPDNominalPeaks,  1.1*max(maxCombSPD(:))*ones(1,numel(combSPDNominalPeaks)), 'ks', 'MarkerSize', 14);
    for calIndex = 1:calsNum
        plot(combSPDComputedPeaks, 1.1*max(maxCombSPD(:))*ones(1,size(combSPDComputedPeaks,2)), 'k.', 'MarkerSize', 10);
    end
    set(gca, 'XLim', [350 750], 'XTick', 200:50:800);
    grid on; box on;
    xlabel('wavelength (nm)');
    ylabel('Power');
    title(sprintf('Spectral shifts SPDs\n'));
    set(gca, 'FontSize', 14);
    drawnow;
    
    exportPDF = false;
    if (exportPDF)
        NicePlot.exportFigToPDF('CalTimeSeriesAnalysis.pdf', hFig, 300);
    end
end

function plotDayTemperatureTimeSeries(markerIndex, colorIndex, colors, markers, time, value, subplotPosVectors)
    timeInMinutes = time/60;
    
    subplot('Position', subplotPosVectors(1,3).v);
    if (any(isnan(value(:))))
%         t = text(30, 33, 'NO TEMPERATURE DATA');
%         set(t, 'FontSize', 16);
    else
        hold on;
        plot(timeInMinutes, value(:,1), '-', ...
            'Marker', markers{markerIndex}, ...
            'MarkerSize', 6, ...
            'Color', squeeze(colors(colorIndex,:)), ...
            'MarkerFaceColor', squeeze(colors(colorIndex,:)), ...
            'LineWidth', 1.5);
    end
    
    subplot('Position', subplotPosVectors(2,3).v);
    if (any(isnan(value(:))))
%         t = text(30, 33, 'NO TEMPERATURE DATA');
%         set(t, 'FontSize', 16);
    else
        hold on;
        plot(timeInMinutes, value(:,2), '-', ...
            'Marker', markers{markerIndex}, ...
            'MarkerSize', 6, ...
            'Color', squeeze(colors(colorIndex,:)), ...
            'MarkerFaceColor', squeeze(colors(colorIndex,:)), ...
            'LineWidth', 1.5);
    end
end

function [visualizedSpectralShiftWavelength, combSPDComputedPeaks] = ...
    plotSpectralShiftTimeSeries(markerIndex, colorIndex, colors, markers, ...
    time, SPDs, SPD0, waveAxis, combSPDNominalPeaks, calIndex, subplotPosVectors)

    timeInMinutes = time/60;
    spectralShiftsMeasurementsNum = size(SPDs,2);
    
    % Find the reference SPD peaks
    [combPeakReference, gainReference] = ...
            findPeaks(squeeze(SPD0), ...
            waveAxis, ...
            combSPDNominalPeaks);
        
    displayedPeakIndex = 2;
    visualizedSpectralShiftWavelength = combPeakReference(displayedPeakIndex);
    
    % Find the SPD peaks for all measurements
    combPeakTimeSeries = zeros(numel(combSPDNominalPeaks), spectralShiftsMeasurementsNum);
    gainTimeSeries = combPeakTimeSeries;
    progressBarHandle = waitbar(0, sprintf('Finding spectral peaks for cal. no: %d', calIndex));
    wax = findobj(progressBarHandle, 'type','axes');
    tax = get(wax,'title');
    set(tax,'fontsize',14)

    for tIndex = 1:spectralShiftsMeasurementsNum 
        waitbar(tIndex/spectralShiftsMeasurementsNum,progressBarHandle, ...
            sprintf('Finding spectral peaks for cal. no %d (%d/%d)', calIndex, tIndex,spectralShiftsMeasurementsNum));
        [combPeakTimeSeries(:, tIndex), gainTimeSeries(:, tIndex)] = ...
            findPeaks(squeeze(SPDs(:,tIndex)), ...
            waveAxis, ...
            combSPDNominalPeaks);
    end
    delete(progressBarHandle);
    
    combSPDComputedPeaks = combPeakTimeSeries(:,1);
    combPeakTimeSeries = bsxfun(@minus, combPeakTimeSeries, combPeakReference');
    gainTimeSeries = bsxfun(@times, gainTimeSeries, 1./gainReference');
    
    subplot('Position', subplotPosVectors(2,2).v);
    hold on;
    plot(timeInMinutes, squeeze(combPeakTimeSeries(displayedPeakIndex,:)), '-', ...
        'Marker', markers{markerIndex}, ...
        'MarkerSize', 6, ...
        'Color', squeeze(colors(colorIndex,:)), ...
        'MarkerFaceColor', squeeze(colors(colorIndex,:)), ...
        'LineWidth', 1.5);
    
    subplot('Position', subplotPosVectors(2,1).v);
    hold on;
    for tIndex = 1:spectralShiftsMeasurementsNum
        plot(waveAxis, squeeze(SPDs(:,tIndex)), '-', ...
            'Color', squeeze(colors(colorIndex,:)), ...
            'MarkerFaceColor', squeeze(colors(colorIndex,:)), ...
            'LineWidth', 1.5);
    end
end

function plotPowerFluctuationTimeSeries(markerIndex, colorIndex, colors, ...
    markers, time, SPDs, SPD0, waveAxis, subplotPosVectors)

    timeInMinutes = time/60;
    powerFluctuationMeasurementsNum = size(SPDs,2);
    scalar = zeros(1,powerFluctuationMeasurementsNum);
    for tIndex = 1:powerFluctuationMeasurementsNum
        scalar(tIndex) = SPD0 \ squeeze(SPDs(:,tIndex));
    end

    subplot('Position', subplotPosVectors(1,2).v);
    hold on;
    plot(timeInMinutes, scalar, '-', ...
        'Marker', markers{markerIndex}, ...
        'MarkerSize', 6, ...
        'Color', squeeze(colors(colorIndex,:)), ...
        'MarkerFaceColor', squeeze(colors(colorIndex,:)), ...
        'LineWidth', 1.5);
    
    subplot('Position', subplotPosVectors(1,1).v);
    hold on;
    for tIndex = 1:powerFluctuationMeasurementsNum
        plot(waveAxis, squeeze(SPDs(:,tIndex)), '-', ...
            'Color', squeeze(colors(colorIndex,:)), ...
            'MarkerFaceColor', squeeze(colors(colorIndex,:)), ...
            'LineWidth', 1.5);
    end
end


function timeSeries = extractTimeSeries(cals)
    calsNum = numel(cals);
    fprintf('Analyzing data from %d cals\n', calsNum);
    timeSeries = [];
    for calIndex = 1:calsNum
        c = cals{calIndex};
        timeEntry = struct(...
        	'date', c.describe.date, ...
            'waveAxis', SToWls(c.describe.S), ...
            'temperature', [], ...
            'powerFluctuationMeas', [], ...
            'spectralShiftsMeas', [] ...
            );
        fprintf('[%d]: %s\n', calIndex, timeEntry.date);
        rawData = c.raw;
        if (isfield(rawData, 'temperature'))
            if (numel(rawData.temperature)~=1)
                error('Size of temperature struct is %d. Should be 1\n', numel(rawData.temperature))
            end
            timeEntry.temperature = rawData.temperature(1);
        end
        if (isfield(rawData, 'powerFluctuationMeas'))
            if (numel(rawData.powerFluctuationMeas)~=1)
                error('Size of powerFluctuationMeas struct is %d. Should be 1\n', numel(rawData.powerFluctuationMeas))
            end
            timeEntry.powerFluctuationMeas = rawData.powerFluctuationMeas(1);
        end
        if (isfield(rawData, 'spectralShiftsMeas'))
            if (numel(rawData.spectralShiftsMeas)~=1)
                error('Size of spectralShiftsMeas struct is %d. Should be 1\n', numel(rawData.spectralShiftsMeas))
            end
            timeEntry.spectralShiftsMeas = rawData.spectralShiftsMeas(1);
        end
        timeSeries{numel(timeSeries)+1} = timeEntry;
    end
end

function [cals, file] = loadCalData()
    cals = {};
    systemInfo = GetComputerInfo();
    melaMaterialsDir = getpref('OneLightToolbox', 'OneLightCalData');
    
%     if (strcmp(systemInfo.localHostName, 'Ithaca'))
%         melaMaterialsDir = '/Users/nicolas/Desktop/OLApproach_Squint/OneLightCalData';
%     else
%         melaMaterialsDir = getpref('OneLightToolbox', 'OneLightCalData');
%     end
    
    [file, path] = uigetfile(melaMaterialsDir, '*.mat');
    calFileName = fullfile(path,file);
    
    load(calFileName, 'cals');
    if isempty(cals)
        error('Cal file ''%s'' contained no cals structs', calFileName);
    end
end

function [combPeakTimeSeries, gainTimeSeries] = findPeaks(spd, spectralAxis, combSPDNominalPeaks)

    for peakIndex = 1:numel(combSPDNominalPeaks)
        % nominal peak
        peak = combSPDNominalPeaks(peakIndex);

        % Find exact peak
        dataIndicesToFit = sort(find(abs(spectralAxis - peak) <= 15));
        [maxComb,idx] = max(spd(dataIndicesToFit));
        peak = spectralAxis(dataIndicesToFit(idx));
        refPeaks(peakIndex) = peak;

        % Select spectral region to fit
        dataIndicesToFit = sort(find(abs(spectralAxis - peak) <= 15));
        dataIndicesToFit = dataIndicesToFit(find(spd(dataIndicesToFit) > 0.1*maxComb));

        xData = spectralAxis(dataIndicesToFit);
        xDataHiRes = (xData(1):0.1:xData(end))';

        initialParams    = [0   5   peak     6.28   6.28  2.0];
        paramLowerBounds = [0   0   peak-30  1.00   1.00  1.5]; 
        paramUpperBounds = [0  100  peak+30 30.00  30.00  10.0];

        % Fit the reference SPD peak
        spdData = 1000*spd(dataIndicesToFit);  % in milliWatts
        fitParamsRef = fitGaussianToData(xData, spdData, initialParams, paramLowerBounds, paramUpperBounds);
        combPeakTimeSeries(peakIndex) = fitParamsRef(3);
        gainTimeSeries(peakIndex) = fitParamsRef(2); 
    end % peakIndex
end

function solution = fitGaussianToData(xData, yData, initialParams, paramLowerBounds, paramUpperBounds)
    Aeq = [];
    beq = [];
    A = [];
    b = [];
    nonlcon = [];
    options = optimoptions('fmincon');
    options = optimset('Display', 'off');
    solution = fmincon(@functionToMinimize, initialParams,A, b,Aeq,beq, paramLowerBounds, paramUpperBounds, nonlcon, options);
    
    function rmsResidual = functionToMinimize(params)
        yfit = twoSidedExponential(xData, params);
        rmsResidual  = sum((yfit - yData) .^2);
    end
end

function g = twoSidedExponential(wavelength, params)
    offset = params(1);
    gain = params(2);
    peakWavelength = params(3);
    leftSigmaWavelength = params(4);
    rightSigmaWavelength = params(5);
    exponent = params(6);
    leftIndices = find(wavelength < peakWavelength);
    rightIndices = find(wavelength >= peakWavelength);
    g1 = offset + gain*exp(-0.5*(abs((wavelength(leftIndices)-peakWavelength)/leftSigmaWavelength)).^exponent);    
    g2 = offset + gain*exp(-0.5*(abs((wavelength(rightIndices)-peakWavelength)/rightSigmaWavelength)).^exponent);
    g = cat(1, g1, g2);
end
