% OLMonitorStateWindow - Opens a window which monitors and visualizes the OneLightState 
%
% Monitoring continues until the user closes the figure. When the figure is
% closed, the monitoredData are returned to the user. This function call 
% is intended to be inserted right before data collection begins. 
%
% Syntax:
% monitoredData = OLMonitorStateWindow(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage)
%
% 9/12/16   npc     Wrote it.
%

function monitoredData = OLMonitorStateWindow(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage)

    % Initialize everything
    measurementIndex = 0;
    monitoredData = [];
    referenceTime = [];
    referencePowerSPD = [];
    referenceCombSPD = [];
    wavelengthIndices = [];
    spectralAxis = SToWls(cal.describe.S);
    
    % Generate the GUI
    S = generateGUI(spectralAxis);
    
    % Add the timer for triggering data acquisition
    S.tmr = timer('Name','MeasurementTimer',...
                'Period', 1,...           % Fire every 1 second
                'StartDelay', 1, ...      % Start after 1 second.
                'TasksToExecute',inf,...  % Number of times to update
                'ExecutionMode','fixedSpacing',...
                'TimerFcn',{@guiUpdaterFunction}); 
            
    set(S.figHandle,'closeRequestFcn',{@closeRequestFunction})
    
    % Start the timer object.
    start(S.tmr);
    
    % Wait until user closes the figure
    uiwait(S.figHandle);
    
    % Callback function for when the user closes the figure
    function closeRequestFunction(varargin)
       selection = questdlg('Stop monitoring OLstate?',...
          'OLMonitorStateWindow',...
          'Yes','No','Yes'); 
       switch selection, 
          case 'Yes',
                delete(gcf)
                stop(S.tmr);
                delete(S.tmr);
                fprintf('Please wait for completion of current state measurement ...\n');
          case 'No'
          return 
       end
    end


    % Updater function - data collection & visualization
    function [] = guiUpdaterFunction(varargin)
         
        try
             % Measure and retrieve the data
             [~, calStateMeas] = OLCalibrator.TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, true);
             
             data.shiftSPD  = calStateMeas.raw.spectralShiftsMeas.measSpd;
             data.shiftSPDt = calStateMeas.raw.spectralShiftsMeas.t;
             data.powerSPD  = calStateMeas.raw.powerFluctuationMeas.measSpd;
             data.powerSPDt = calStateMeas.raw.powerFluctuationMeas.t;
             measurementIndex = measurementIndex + 1;
             monitoredData.measurements{measurementIndex} = data;
             
             if (measurementIndex == 1)
                 wavelengthIndices = find(data.powerSPD(:) > 0.2*max(data.powerSPD(:)));
                 referencePowerSPD = data.powerSPD(wavelengthIndices);
                 referenceCombSPD = data.shiftSPD;
                 referenceTime = data.powerSPDt;
                 monitoredData.timeSeries = [];
                 monitoredData.powerRatioSeries = [];
                 monitoredData.spectralShiftSeries = [];
                 monitoredData.spectralAxis = spectralAxis;
             end
             
             if (measurementIndex > 1)
                 newSPDRatio = 1.0 / (data.powerSPD(wavelengthIndices) \ referencePowerSPD);
                 combPeaks = [480 540 596 652]+10; 
                 [spectralShifts, refPeaks, fitParams] = OLComputeSpectralShiftBetweenCombSPDs(data.shiftSPD, referenceCombSPD, combPeaks, spectralAxis);
               
                 monitoredData.powerRatioSeries = cat(2, monitoredData.powerRatioSeries, newSPDRatio);
                 monitoredData.timeSeries = cat(2, monitoredData.timeSeries, (data.powerSPDt-referenceTime)/60);
                 monitoredData.spectralShiftSeries = cat(2, monitoredData.spectralShiftSeries, -median(spectralShifts));
             end
             
             if (isvalid(S.figHandle))
                 % Update GUI
                 set(S.currentPowerPlot, 'yData', data.powerSPD);
                 set(S.currentShiftPlot, 'yData', data.shiftSPD);

                 title(S.currentPowerAxes, sprintf('Full ON SPD - measurement no: %3d', measurementIndex), 'FontSize', 16);
                 title(S.currentShiftAxes, sprintf('comb SPD - measurement time: %2.1f mins', (data.shiftSPDt-referenceTime)/60), 'FontSize', 16);

                 if (measurementIndex > 1)
                     set(S.currentShiftPlotFit, 'xData', refPeaks);
                     set(S.currentShiftPlotFit, 'yData', max(data.shiftSPD(:)) * ones(size(refPeaks)));

                     set(S.timeSeriesPowerPlot, 'xData', monitoredData.timeSeries);
                     set(S.timeSeriesPowerPlot, 'yData', monitoredData.powerRatioSeries);
                     set(S.timeSeriesShiftPlot, 'xData', monitoredData.timeSeries);
                     set(S.timeSeriesShiftPlot, 'yData', monitoredData.spectralShiftSeries);
                 end
             end
             
         catch e
             spectroRadiometerOBJ.shutDown();
             fprintf('Error: %s\n', e.message);
             delete(S.figHandle); % Close it all down.
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
    S.currentShiftSubPlot = subplot('Position', subplotPosVectors2(1,2).v);
    S.timeSeriesPowerSubPlot = subplot('Position', subplotPosVectors2(2,1).v);
    S.timeSeriesShiftSubPlot = subplot('Position', subplotPosVectors2(2,2).v);
    
    x = spectralAxis;
    y = x*0;

    subplot(S.currentPowerSubPlot);
    S.currentPowerPlot = plot(x,y, 'rs-', 'MarkerFaceColor', [1.0 0.7 0.7]);
    S.currentPowerAxes = gca;
    set(gca, 'FontSize', 14);
    xlabel('wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('power', 'FontSize', 16, 'FontWeight', 'bold');
    title(S.currentPowerAxes, sprintf('Full ON SPD'), 'FontSize', 16);
    
    subplot(S.currentShiftSubPlot);
    S.currentShiftPlot = plot(x,y, 'bs-', 'MarkerFaceColor', [0.7 0.7 1.0]);
    hold on;
    x = x(1); y = [0];
    S.currentShiftPlotFit = plot(x,y, 'r*', 'MarkerSize', 16);
    hold off;
    S.currentShiftAxes = gca;
    set(gca, 'FontSize', 14);
    xlabel('wavelength (nm)', 'FontSize', 16, 'FontWeight', 'bold');
    title(S.currentShiftAxes, sprintf('comb SPD'), 'FontSize', 16);
    
    x = [0];
    y = [0];
    subplot(S.timeSeriesPowerSubPlot);
    S.timeSeriesPowerPlot = plot(x,y, 'ks-', 'MarkerSize', 10, 'MarkerFaceColor', [1.0 0.7 0.7]);
    S.timeSeriesPowerAxes = gca;
    set(gca, 'FontSize', 14);
    xlabel('time (mins)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('power (current : first) ratio', 'FontSize', 16, 'FontWeight', 'bold');
    
    subplot(S.timeSeriesShiftSubPlot);
    S.timeSeriesShiftPlot = plot(x,y, 'ks-', 'MarkerSize', 10, 'MarkerFaceColor', [0.7 0.7 1.0]);
    S.timeSeriesShiftAxes = gca;
    set(gca, 'FontSize', 14);
    xlabel('time (mins)', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('spectral shift (nm)', 'FontSize', 16, 'FontWeight', 'bold');
end