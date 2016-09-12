% OLMonitorStateWindow - Opens a window which monitors and visualizes the OneLightState 
%
% Monitoring continues until the user closes the figure. When the figure is
% closed, the monitoredData are returned to the user. This function call 
% is intended to be inserted right before data collection begins. 
%
% Syntax:
% [figureHandle, monitoredData] = OLMonitorStateWindow(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage)
%
% 9/12/16   npc     Wrote it.
%

function [figureHandle, monitoredData] = OLMonitorStateWindow(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage)

    measurementIndex = 0;
    monitoredData = [];
    spectralAxis = SToWls(cal.describe.S);
    
    % Generate the GUI
    S = generateGUI(spectralAxis);
    figureHandle = S.figHandle;
    
    % Add the timer for triggering data acquisition
    S.tmr = timer('Name','Reminder',...
                'Period', 1,...  % Fire every 1 second
                'StartDelay', 1, ... % Start after 1 second.
                'TasksToExecute',inf,...  % number of times to update
                'ExecutionMode','fixedSpacing',...
                'TimerFcn',{@guiUpdaterFunction}); 
            
    % Kill timer if fig is closed.
    set(S.figHandle,'deletefcn',{@deleterFunction}) 
    
    % Start the timer object.
    start(S.tmr);
    
    % Deleter function
    function [] = deleterFunction(varargin)
    % If figure is deleted, so is the timer.
         stop(S.tmr);
         delete(S.tmr);
    end

    % Updater function
    function [] = guiUpdaterFunction(varargin)
         try
             % Measure and retrieve the data
             [~, calStateMeas] = OLCalibrator.TakeStateMeasurements(cal, ol, od, spectroRadiometerOBJ, meterToggle, nAverage, true);
             measurementIndex = measurementIndex + 1;
             monitoredData(measurementIndex) = struct(...
                     'combSPD', calStateMeas.raw.spectralShiftsMeas.measSpd, ...
                 'combSPDtime', calStateMeas.raw.spectralShiftsMeas.t, ...
                    'powerSPD', calStateMeas.raw.powerFluctuationMeas.measSpd, ...
                'powerSPDtime', calStateMeas.raw.powerFluctuationMeas.t ...
                 );
    
             % Update GUI
             set(S.currentPowerSubPlot, 'yData', monitoredData(measurementIndex).powerSPD);
             
         catch e
             fprintf('Error: %s\n', e.message);
             delete(S.figHandle) % Close it all down.
         end
    end
    
end

function S = generateGUI(spectralAxis)

    figureHandle = figure('units','pixels',...
                  'position',[30 30 1200 900],...
                  'menubar','none',...
                  'name','OLMonitorState',...
                  'numbertitle','off',...
                  'resize','off');
              
    S.figHandle = figureHandle;
    subplotPosVectors2 = NicePlot.getSubPlotPosVectors(...
           'rowsNum', 2, ...
           'colsNum', 2, ...
           'heightMargin',   0.06, ...
           'widthMargin',    0.06, ...
           'leftMargin',     0.05, ...
           'rightMargin',    0.01, ...
           'bottomMargin',   0.06, ...
           'topMargin',      0.01);
       
    S.currentPowerSubPlot = subplot('Position', subplotPosVectors2(1,1).v);
    S.currentShiftSubPlot = subplot('Position', subplotPosVectors2(1,2).v);
    S.timeSeriesPowerSubPlot = subplot('Position', subplotPosVectors2(2,1).v);
    S.timeSeriesShiftSubPlot = subplot('Position', subplotPosVectors2(2,2).v);
    
    x = spectralAxis;
    y = x*0;

    subplot(S.currentPowerSubPlot);
    S.currentPowerPlot = plot(x,y, 'r-');
    S.currentPowerAxes = gca;
     
    subplot(S.currentShiftSubPlot);
    S.currentShiftAxesPlot = plot(x,y, 'g-');
    S.currentShiftAxes = gca;
   
    subplot(S.timeSeriesPowerSubPlot);
    S.timeSeriesPowerPlot = plot(x,y, 'm-');
    S.timeSeriesPowerAxes = gca;

    subplot(S.timeSeriesShiftSubPlot);
    S.timeSeriesShiftPlot = plot(x,y, 'y-');
    S.timeSeriesShiftAxes = gca;
end