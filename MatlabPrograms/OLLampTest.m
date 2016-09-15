function ol = OLLampTest
% ol = OLLampTest
%
% Description:
% Some tests on the lamp properties, and whether we can set them.
%
% 1/2/14  dhb  Wrote it.
% 1/3/14  dhb  Add lamp adjustment loop.

% Close figs
close all;

% Globals for PR-6XX
global g_useIOPort;
g_useIOPort = 1;

% Adjust lamp?
adjustLamp = GetWithDefault('\nAdjust lamp position? [0 -> no, 1 -> yes)',1);
if (adjustLamp)
    useOmni = true;
    usePR6XX = GetWithDefault('Use PR-6XX? (0 -> no, 1 -> yes)',0);
else
    useOmni = false;
    usePR6XX = false;
end
meterToggle = [usePR6XX useOmni];
S = [380 2 201];

% Load XYZ to get luminance
load T_xyz1931
T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);

fprintf('\n');
try  
    % Ask which PR-6xx radiometer to use
    % Some parameters are radiometer dependent.
    %meterType = GetWithDefault('Enter PR-6XX radiometer type','PR-670');
    meterType = 'PR-670';
    if (usePR6XX)
        switch (meterType)
            case 'PR-650',
                meterType = 1;
            case 'PR-670',
                whichMeter = 'PR-670';
                meterType = 5;
                
            otherwise,
                error('Unknown meter type');
        end
        
        % Open up the radiometer.
        CMCheckInit(meterType);
    end
    
    % Connect to the OceanOptics spectrometer.
    % Turn on some averaging and smoothing for the spectrum acquisition.
    if (useOmni)
        od = OmniDriver;
        od.Debug = true;
        od.ScansToAverage = 10;
        od.BoxcarWidth = 2;
        
        % Make sure electrical dark correction is enabled.
        od.CorrectForElectricalDark = true;
    end
    
    % Open the OneLight device.
    fprintf('- Opening OneLight\n');
    ol = OneLight;
    
    pause(1);
    
    % Get serial number
    serialNumber = get(ol,'SerialNumber');
    fprintf('\nSerial number %d\n',serialNumber);
    
    % Get lamp status
    lampStatus = get(ol,'LampStatus');
    fanSpeed = get(ol,'FanSpeed');
    fprintf('Lamp status: %d, fan 0 speed %d\n',lampStatus,fanSpeed);
    
    % Get nominal and measured lamp current
    nominalCurrent = get(ol,'LampCurrent');
    nominalCurrent0 = nominalCurrent;
    measuredCurrent = get(ol,'CurrentMonitor');
    measuredVoltage = get(ol,'VoltageMonitor');
    fprintf('Nominal current (0-255): %d, measured %0.1f (amps)\n',nominalCurrent,measuredCurrent);
    fprintf('Measured voltage %0.1f (volts)\n',measuredVoltage);
    fprintf('Watts: %0.1f\n',measuredCurrent*measuredVoltage);
    
    % Try lower current
    newCurrent = 100;
    set(ol,'LampCurrent',newCurrent);
    pause(1);
    nominalCurrent = get(ol,'LampCurrent');
    measuredCurrent = get(ol,'CurrentMonitor');
    measuredVoltage = get(ol,'VoltageMonitor');
    fprintf('\nNew nominal current (0-255): %d, measured %0.1f (amps)\n',nominalCurrent,measuredCurrent);
    fprintf('Measured voltage %0.1f (volts)\n',measuredVoltage);
    fprintf('Watts: %0.1f\n',measuredCurrent*measuredVoltage);
    
    % Back again
    newCurrent = nominalCurrent0;
    set(ol,'LampCurrent',newCurrent);
    pause(1);
    nominalCurrent = get(ol,'LampCurrent');
    measuredCurrent = get(ol,'CurrentMonitor');
    measuredVoltage = get(ol,'VoltageMonitor');
    fprintf('\nAnd now nominal current (0-255): %d, measured %0.1f (amps)\n',nominalCurrent,measuredCurrent);
    fprintf('Measured voltage %0.1f (volts)\n',measuredVoltage);
    fprintf('Watts: %0.1f\n',measuredCurrent*measuredVoltage);
    
    % Adjust lamp position?
    if (useOmni)
        if (adjustLamp)
            % Get a good integration time for omni
            ol.setAll(true);
            od.IntegrationTime = od.findIntegrationTime(100, 2, 100);
            od.IntegrationTime = round(0.85*od.IntegrationTime);
            fprintf('- Using integration time of %d microseconds.\n', od.IntegrationTime);
            ol.setAll(false);
            
            % Initial state measurement
            fprintf('- Taking initial half on measurement\n');
            starts = zeros(1, ol.NumCols);
            stops = round(ones(1, ol.NumCols) * (ol.NumRows - 1));
            [measTemp, omniSpectrumSaturated] = OLTakeMeasurementOOC(ol, od, starts, stops, S, meterToggle, meterType, 1);
            if omniSpectrumSaturated
                beep; commandwindow;
                fprintf('*** OMNI SPECTRUM SATURATED. RESTART PROGRAM.\n');
                return;
            end
            if (usePR6XX)
                halfOnInitial = measTemp.pr650.spectrum;
                lumInitial = T_xyz(2,:)*halfOnInitial;
            end
            halfOnInitialOmni = measTemp.omni.spectrum;
            halfOnInitialSum = sum(halfOnInitialOmni);
            halfOnCurrentSum = halfOnInitialSum;
            halfOnMaxSum = halfOnInitialSum;
            
            % Adjustment loop
            fprintf('- Adjustment loop, hit any key to exit\n');
            figure; clf; set(gcf,'Position',[50   200   700   525]);
            while (CharAvail)
                GetChar;
            end
            while (1)
                % Update plot
                bar([1 2 3],[halfOnInitialSum halfOnCurrentSum halfOnMaxSum]); hold on;
                %ylim([0 2000]);
                plot([0 4], [halfOnMaxSum halfOnMaxSum], '--k');
                set(gca, 'XTickLabel', {num2str(halfOnInitialSum) ; num2str(halfOnCurrentSum) ; num2str(halfOnMaxSum)});
                drawnow;
                hold off;
                
                % Check for exit
                if (CharAvail)
                    break;
                end
                
                % Measure
                measTemp = OLTakeMeasurement(ol, od, starts, stops, S, [false useOmni], meterType, 1);
                halfOnCurrentOmni = measTemp.omni.spectrum;
                halfOnCurrentSum = sum(halfOnCurrentOmni);
                if (halfOnCurrentSum > halfOnMaxSum)
                    halfOnMaxSum = halfOnCurrentSum;
                end
            end
            GetChar;
            
            % Final state measurement
            fprintf('- Taking final half on measurement\n');
            measTemp = OLTakeMeasurement(ol, od, starts, stops, S, meterToggle, meterType, 1);
            if (usePR6XX)
                halfOnFinal = measTemp.pr650.spectrum;
                lumFinal = T_xyz(2,:)*halfOnFinal;
            end
            halfOnFinalOmni = measTemp.omni.spectrum;
            halfOnFinalSum = sum(halfOnFinalOmni);       
            fprintf('\nInitial sum %0.3f, max sum %0.3f, final sum %0.3f\n',halfOnInitialSum,halfOnMaxSum,halfOnFinalSum);
            if (usePR6XX)
                fprintf('Initial luminance (cd/m2) %0.1f, final luminance %0.1f\n',lumInitial,lumFinal);
                CMClose(meterType);
            end
        end
        
    end

    
catch e
    rethrow(e);
    keyboard
end


