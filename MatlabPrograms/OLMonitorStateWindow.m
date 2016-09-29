% OLMonitorStateWindow - Opens a window which monitors and visualizes the OneLightState 
%
% Monitoring continues until the user closes the figure. When the figure is
% closed, the monitoredData are returned to the user. This function call 
% is intended to be inserted right before data collection begins. 
%
% Syntax:
% monitoredData = OLMonitorStateWindow(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage)
%
% See testOLMonitorStateWindow for usage of this function.
%
% 9/12/16   npc     Wrote it.
% 9/29/16   npc     Optionally record temperature.
%

function monitoredData = OLMonitorStateWindow(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, varargin)

    p = inputParser;
    p.addParameter('takeTemperatureMeasurements', false, @islogical);
    % Execute the parser
    p.parse(varargin{:});
    takeTemperatureMeasurements = p.Results.takeTemperatureMeasurements;
    
    
    measurementIndex = 0;
    monitoredData = [];
    referenceTime = [];
    referencePowerSPD = [];
    referenceCombSPD = [];
    wavelengthIndices = [];
    spectralAxis = SToWls(cal.describe.S);
    
    % Generate the GUI
    S = generateGUI(spectralAxis);            
    set(S.figHandle,'closeRequestFcn',{@closeRequestFunction})
    
    if (takeTemperatureMeasurements)
        % Init temperature probe
        LJTemperatureProbe('close');
        status = LJTemperatureProbe('open');
        if (status == 0)
            fprintf('<strong>Could not open the UE9 device.</strong>\n');
            selection = input(sprintf('Continue without temperature measurements <strong>[Y]</strong> or try again after making sure it is connected <strong>[A]</strong>? '), 's');
            if (isempty(selection) || strcmp(selection, 'Y'))
                takeTemperatureMeasurements = false;
            else
                fprintf('Trying to open UE9 device once more\n');
                status = LJTemperatureProbe('open');
                if (status == 1)
                    fprintf('Opened UE9 device !!\n');
                else
                    fprintf('Failed to open UE9 device again. Quitting.\n');
                    return;
                end
            end
        end
    end
    
    % Add the timer for triggering data acquisition
    S.tmr = timer('Name','MeasurementTimer',...
                'Period', 1,...           % Fire every 1 second
                'StartDelay', 1, ...      % Start after 1 second.
                'TasksToExecute',inf,...  % Number of times to update
                'ExecutionMode','fixedSpacing',...
                'TimerFcn',{@guiUpdaterFunction});
            
    % Start the timer object.
    start(S.tmr);
    
    % Wait until user closes the figure
    uiwait(S.figHandle);
    
    if (takeTemperatureMeasurements)
        % Close temperature probe
        LJTemperatureProbe('close')
    end
    
    % Callback function for when the user closes the figure
    function closeRequestFunction(varargin)
       
       % Stop the timer
       stop(S.tmr);
       
       selection = questdlg('Stop monitoring OLstate?',...
          'OLMonitorStateWindow',...
          'Yes','No','Yes'); 
      
       switch selection, 
          case 'Yes',
                delete(S.tmr);
                fprintf('Please wait for completion of current state measurement ...\n');
                delete(gcf)
          case 'No'
                % Restart the timer
                start(S.tmr);
                fprintf('\tWill not stop.\n');
          return 
       end
    end


    % Updater function - data collection & visualization
    function [] = guiUpdaterFunction(varargin)
         
        combPeaks = [480 540 596 652]+10;
        
        try 
             % Measure and retrieve the data
             fprintf('Measuring state data (measurement index: %d) ... ', measurementIndex+1);
             [~, calStateMeas] = OLCalibrator.TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, 'standAlone', true, 'takeTemperatureMeasurements', takeTemperatureMeasurements);
    
             % Initialize everything);
             OLCalibrator.SaveStateMeasurements(cal, calStateMeas);
             
             data.shiftSPD  = calStateMeas.raw.spectralShiftsMeas.measSpd;
             data.shiftSPDt = calStateMeas.raw.spectralShiftsMeas.t;
             data.powerSPD  = calStateMeas.raw.powerFluctuationMeas.measSpd;
             data.powerSPDt = calStateMeas.raw.powerFluctuationMeas.t;
             data.datestr   = datestr(now);
             if (takeTemperatureMeasurements)
                data.temperature = calStateMeas.raw.temperature.value;
             end
             
             measurementIndex = measurementIndex + 1;
             monitoredData.measurements{measurementIndex} = data;
             
             if (measurementIndex == 1)
                 wavelengthIndices = find(data.powerSPD(:) > 0.2*max(data.powerSPD(:)));
                 referencePowerSPD = data.powerSPD(wavelengthIndices);
                 referenceCombSPD = data.shiftSPD;
                 referenceTime = data.powerSPDt;
                 monitoredData.spectralAxis = spectralAxis;
                 [~, ~, fitParams] = OLComputeSpectralShiftBetweenCombSPDs(referenceCombSPD, referenceCombSPD, combPeaks, spectralAxis);
                 monitoredData.timeSeries = [];
                 monitoredData.powerRatioSeries = [];
                 monitoredData.spectralShiftSeries = [];
                 monitoredData.temperatureSeries = [];
             else
                 newSPDRatio = 1.0 / (data.powerSPD(wavelengthIndices) \ referencePowerSPD);
                 [spectralShifts, refPeaks, fitParams] = OLComputeSpectralShiftBetweenCombSPDs(data.shiftSPD, referenceCombSPD, combPeaks, spectralAxis);
                 monitoredData.timeSeries = cat(2, monitoredData.timeSeries, (data.powerSPDt-referenceTime)/60);
                 monitoredData.powerRatioSeries = cat(2, monitoredData.powerRatioSeries, newSPDRatio);
                 monitoredData.spectralShiftSeries = cat(2, monitoredData.spectralShiftSeries, median(spectralShifts));
                 if (takeTemperatureMeasurements)
                    monitoredData.temperatureSeries = cat(2, monitoredData.temperatureSeries, (data.temperature)');
                 end
             end
             
             % save fitted params time series as well
             monitoredData.fitParamsTimeSeries(:,:,measurementIndex) = fitParams;
             
             if (isvalid(S.figHandle))
                 % Update GUI
                 set(S.currentPowerPlot, 'yData', data.powerSPD);
                 set(S.currentShiftPlot, 'yData', data.shiftSPD);
                 title(S.currentPowerAxes, sprintf('Full ON & Comb SPD - measurement no: %3d (%2.1f mins)', measurementIndex, (data.powerSPDt-referenceTime)/60), 'FontSize', 16);

                 if (measurementIndex > 1)
                     set(S.currentShiftPlotFit, 'xData', refPeaks);
                     set(S.currentShiftPlotFit, 'yData', max(data.shiftSPD(:)) * ones(size(refPeaks)));
                     set(S.timeSeriesPowerPlot, 'xData', monitoredData.timeSeries);
                     set(S.timeSeriesPowerPlot, 'yData', monitoredData.powerRatioSeries);
                     set(S.timeSeriesShiftPlot, 'xData', monitoredData.timeSeries);
                     set(S.timeSeriesShiftPlot, 'yData', monitoredData.spectralShiftSeries);
                     if (takeTemperatureMeasurements)
                        set(S.timeSeriesTemperaturePlot1, 'xData', monitoredData.timeSeries);
                        set(S.timeSeriesTemperaturePlot1, 'yData', monitoredData.temperatureSeries(1,:));
                        set(S.timeSeriesTemperaturePlot2, 'xData', monitoredData.timeSeries);
                        set(S.timeSeriesTemperaturePlot2, 'yData', monitoredData.temperatureSeries(2,:));
                        set(S.timeSeriesTemperatureAxes, 'YLim', [min(monitoredData.temperatureSeries(:)) max(monitoredData.temperatureSeries(:))]);
                     end
                 end
             end
             
         catch e
             % Close it all down.
             spectroRadiometerOBJ.shutDown();
             fprintf('Error: %s\n', e.message);
             delete(S.figHandle); 
             rethrow(e)
        end       
    end
    
end

function S = generateGUI(spectralAxis)

    figureHandle = figure('units','pixels',...
                  'position',[30 30 1200 900],...
                  'menubar','none',...
                  'name','OLMonitoringStateWindow',...
                  'numbertitle','off',...
                  'resize','off');
              
    S.figHandle = figureHandle;
    subplotPosVectors2 = NicePlot.getSubPlotPosVectors(...
           'rowsNum', 2, ...
           'colsNum', 2, ...
           'heightMargin',   0.08, ...
           'widthMargin',    0.06, ...
           'leftMargin',     0.07, ...
           'rightMargin',    0.01, ...
           'bottomMargin',   0.06, ...
           'topMargin',      0.05);
       
    S.currentPowerSubPlot = subplot('Position', subplotPosVectors2(1,1).v);
    S.timeSeriesTemperatureSubPlot = subplot('Position', subplotPosVectors2(1,2).v);
    S.timeSeriesPowerSubPlot = subplot('Position', subplotPosVectors2(2,1).v);
    S.timeSeriesShiftSubPlot = subplot('Position', subplotPosVectors2(2,2).v);
    
    x = spectralAxis;
    y = x*0;

    subplot(S.currentPowerSubPlot);
    S.currentPowerPlot = plot(x,y, 'rs-', 'MarkerFaceColor', [1.0 0.7 0.7]);
    hold on;
    S.currentShiftPlot = plot(x,y, 'bs-', 'MarkerFaceColor', [0.7 0.7 1.0]);
    x = x(1); y = [0];
    S.currentShiftPlotFit = plot(x,y, 'k*', 'MarkerSize', 12);
    hold off;
    S.currentPowerAxes = gca;
    set(gca, 'FontSize', 14);
    xlabel('wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('power', 'FontSize', 16, 'FontWeight', 'bold');
    title(S.currentPowerAxes, sprintf('Full ON & Comb SPD'), 'FontSize', 16);
    
    x = [0];
    y = [0];
    subplot(S.timeSeriesTemperatureSubPlot);
    S.timeSeriesTemperaturePlot1 = plot(x,y, 'rs-', 'MarkerSize', 8, 'MarkerFaceColor', [1.0 0.7 0.7]);
    hold on
    S.timeSeriesTemperaturePlot2 = plot(x,y, 'bs-', 'MarkerSize', 8, 'MarkerFaceColor', [0.7 0.7 1.0]);
    hold off
    legend({'OneLight probe', 'Ambient'}, 'Location', 'NorthWest');
    S.timeSeriesTemperatureAxes = gca;
    set(gca, 'FontSize', 14, 'YLim',[10 110]);
    xlabel('time (mins)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('temperature (deg Celcius)', 'FontSize', 16, 'FontWeight', 'bold');
    title('Ambient and OneLight temperature', 'FontSize', 16);
    
    subplot(S.timeSeriesPowerSubPlot);
    S.timeSeriesPowerPlot = plot(x,y, 'ks-', 'MarkerSize', 8, 'MarkerFaceColor', [1.0 0.7 0.7]);
    S.timeSeriesPowerAxes = gca;
    set(gca, 'FontSize', 14);
    xlabel('time (mins)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('power (current : first) ratio', 'FontSize', 16, 'FontWeight', 'bold');
    
    subplot(S.timeSeriesShiftSubPlot);
    S.timeSeriesShiftPlot = plot(x,y, 'ks-', 'MarkerSize', 8, 'MarkerFaceColor', [0.7 0.7 1.0]);
    S.timeSeriesShiftAxes = gca;
    set(gca, 'FontSize', 14);
    xlabel('time (mins)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('spectral shift (nm)', 'FontSize', 16, 'FontWeight', 'bold');
end