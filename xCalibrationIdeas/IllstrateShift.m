function IllstrateShift
    
    center = 564;
    width = 5.6;
    shift = 0;

    [mirrorFilter, wavelengthAxis] = makeMirrorFilter(center, width, shift);
    [~, idx1] = min(abs(wavelengthAxis-564-6.5));
    trackingWavelength1 = wavelengthAxis(idx1);
    [~, idx2] = min(abs(wavelengthAxis-564+6.5));
    trackingWavelength2 = wavelengthAxis(idx2);
    [~, idx3] = min(abs(wavelengthAxis-564));
    trackingWavelength3 = wavelengthAxis(idx3);
    
    
    videoFilename = 'shiftillustation.m4v';
    writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
    writerObj.FrameRate = 15; 
    writerObj.Quality = 100;
    writerObj.open();
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
           'rowsNum', 2, ...
           'colsNum', 2, ...
           'heightMargin',   0.03, ...
           'widthMargin',    0.05, ...
           'leftMargin',     0.04, ...
           'rightMargin',    0.000, ...
           'bottomMargin',   0.04, ...
           'topMargin',      0.01);
       
    hFig = figure(1); clf; set(hFig, 'Color', [1 1 1], 'Position', [10 10 1500 1300]);
    
    kk = -20:20;
    
    for shiftRange = [0.1 0.2 0.3]/2
    for frequency = 0.2:0.1:1.0
    for phase = pi/10*(-10:10)
        
        for k = 1:numel(kk)
            shift(k) = sin(2*pi*frequency*kk(k)/numel(kk) - phase)*shiftRange;
            [mirrorFilterShifts(k,:), wavelengthAxis] = makeMirrorFilter(center, width, shift(k));
        end
   
        clf;
        pos = subplotPosVectors(2,1).v;
        subplot('Position', [pos(1) pos(2) pos(3) 2*pos(4)]);
        plot(wavelengthAxis, mirrorFilter, 'k-', 'LineWidth', 4.0);
        hold on;
        plot(wavelengthAxis, mean(mirrorFilterShifts,1), 'c--', 'LineWidth', 4.0);
        plot(wavelengthAxis, 100*std(mirrorFilterShifts,0,1), 'r-', 'LineWidth', 2.0);
        plot(trackingWavelength1, mirrorFilter(idx1), 'ko', 'MarkerSize', 12, 'MarkerFaceColor', [0.5 0.5 1.0]);
        plot(trackingWavelength2, mirrorFilter(idx2), 'ko', 'MarkerSize', 12, 'MarkerFaceColor', [0.5 1.0 0.5]);
        plot(trackingWavelength3, mirrorFilter(idx3), 'ko', 'MarkerSize', 12, 'MarkerFaceColor', [0.5 0.5 0.5]);
        set(gca, 'YLim', [-0.25 1], 'XLim', [wavelengthAxis(1) wavelengthAxis(end)],  'FontSize', 16);
        legend({'mirror filter', 'mean', '100*std'});
        plot(wavelengthAxis, 10*bsxfun(@minus, mirrorFilterShifts, mean(mirrorFilterShifts,1)), 'k-', 'LineWidth', 1.0, 'Color', [0.5 0.5 0.5]);
        xlabel('wavelength', 'FontSize', 18, 'FontWeight', 'bold');
        ylabel('power', 'FontSize', 18, 'FontWeight',' bold');
        box off
    
        subplot('Position', subplotPosVectors(1,2).v);
        plot(kk, mirrorFilterShifts(:, idx1) - squeeze(mean(mirrorFilterShifts(:,idx1),1)), 'ko-',  'LineWidth', 1.0, 'MarkerSize', 10, 'MarkerFaceColor', [0.5 0.5 1.0]);
        hold on
        plot(kk, mirrorFilterShifts(:, idx2) - squeeze(mean(mirrorFilterShifts(:,idx2),1)), 'ko-',  'LineWidth', 1.0, 'MarkerSize', 10, 'MarkerFaceColor', [0.5 1.0 0.5]);
        plot(kk, mirrorFilterShifts(:, idx3) - squeeze(mean(mirrorFilterShifts(:,idx3),1)), 'ko-',  'LineWidth', 1.0, 'MarkerSize', 10, 'MarkerFaceColor', [0.5 0.5 0.5]);
        set(gca, 'YLim', 0.05*[-1 1],  'FontSize', 16, 'XTick', [])
        hold off;
        ylabel('diff power', 'FontSize', 18, 'FontWeight', 'bold');
        xlabel('measurement time', 'FontSize', 18, 'FontWeight', 'bold');
        box off
        
        subplot('Position', subplotPosVectors(2,2).v);
        plot(kk, shift, 'ko-', 'LineWidth', 1.0, 'MarkerSize', 10, 'MarkerFaceColor', [0.5 0.5 0.5]);
        hold on;
        plot(kk, kk*0, 'k-');
        ylabel('spectral shift (nm)', 'FontSize', 18, 'FontWeight', 'bold');
        xlabel('measurement time', 'FontSize', 18, 'FontWeight', 'bold');
        set(gca, 'YLim', 0.3*[-1 1], 'FontSize', 16, 'XTick', []);
        text(-9.5, 0.28, sprintf('phase: %2.0f, freq: %2.1f, shiftRange: %2.2fnm', phase/pi*180, frequency, shiftRange), 'FontSize', 16, 'FontName', 'Menlo');
        box off
        drawnow;
        writerObj.writeVideo(getframe(hFig)); 
    end
    end
    end
    writerObj.close();
    
end

function [mirrorFilter, wavelengthAxis] = makeMirrorFilter(center, width, shift)

    wavelengthAxis = (530:0.05:600);
    mirrorFilter = normpdf(wavelengthAxis,center-shift,width);
    mirrorFilter = mirrorFilter/max(mirrorFilter);
    
end
