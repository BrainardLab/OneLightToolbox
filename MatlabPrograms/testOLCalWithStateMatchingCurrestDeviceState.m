function testOLCalWithStateMatchingCurrestDeviceState

    close all
    
    % Load calibration file that we will use
    fprintf('Cal file - Choose 3,5\n');
    cal = OLGetCalibrationStructure;
    cal = OLInitCal(cal);
    
    
    % Adjust the calibration file according to today's fullONSPD and combSPD
    todaysMeas = getTodaysMeasurements();
    calToday = OLCalWithStateMatchingCurrestDeviceState(cal, todaysMeas.fullOnSPD, todaysMeas.combSPD);
    
    figure(1); clf;
    subplot(1,2,1);
    plot(cal.computed.fullOn(:,1), 'r-');
    hold on;
    plot(todaysMeas.fullOnMeas(:,1), 'b--');
    legend({'un-adjusted cal', 'todays meas'});
    
    subplot(1,2,2);
    plot(calToday.computed.fullOn(:,1), 'r-');
    hold on;
    plot(todaysMeas.fullOnMeas(:,1), 'b--');
    legend({'adjusted cal', 'todays meas'});
    
    figure(2); clf;
    subplot(2,2,1);
    plot(cal.computed.wigglyMeas.measSpd(:,1), 'r-');
    hold on;
    plot(todaysMeas.wigglyMeas(:,1), 'b--');
    legend({'un-adjusted cal', 'todays meas'});
    subplot(2,2,3);
    plot(cal.computed.wigglyMeas.measSpd(:,1)-todaysMeas.wigglyMeas(:,1))
    
    subplot(2,2,2);
    plot(calToday.computed.wigglyMeas.measSpd(:,1), 'r-');
    hold on;
    plot(todaysMeas.wigglyMeas(:,1), 'b--');
    legend({'adjusted cal', 'todays meas'});
    subplot(2,2,4)
    plot(calToday.computed.wigglyMeas.measSpd(:,1)-todaysMeas.wigglyMeas(:,1))
    
end

function todaysMeas = getTodaysMeasurements()

    fprintf('Todays measurements from calfile - Choose 3,8\n');
    calToday = OLGetCalibrationStructure;
    calToday = OLInitCal(calToday);
  
    
    todaysMeas.wigglyMeas = calToday.computed.wigglyMeas.measSpd;
    todaysMeas.halfOnMeas = calToday.computed.halfOnMeas;
    todaysMeas.fullOnMeas = calToday.computed.fullOn;
    todaysMeas.combSPD = calToday.raw.spectralShiftsMeas.measSpd(:,1);
    todaysMeas.fullOnSPD = calToday.raw.powerFluctuationMeas.measSpd(:,1);
end
