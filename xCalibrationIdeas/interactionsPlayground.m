function interactionsPlayground

    nRows = 1024;
    nColsPerPrimary = 16;
    settingsValues = 0.0:1/1024:1.0;
    
    
    hFig = figure(1);
    clf;
    set(hFig, 'Color', [0 0 0], 'MenuBar', 'none', 'Position', [10 10 675 720]);
    colormap(gray(512))
    
    
    speeds = [0.25 1.0 2.0 8.0 32.0];
    axisInterval = 1.0/numel(speeds);
    axisWidth  = axisInterval - 0.02;
    
    for sIndex = 1:numel(speeds)
        [x,y, mirrorActivations(sIndex,:,:,:), fillFactors(sIndex,:)] = computeMirrorActivation(nRows, nColsPerPrimary, settingsValues, speeds(sIndex));
        axesHandles(sIndex) = axes('parent', hFig,'unit','normalized','position',[0.01+(sIndex-1)*axisInterval 0 axisWidth 0.97], 'Color', [0 0 0]);
    end
   
    writerObj = VideoWriter('MirrorActivationFunctions.m4v', 'MPEG-4'); % H264 format
    writerObj.FrameRate = 60; 
    writerObj.Quality = 100;
    writerObj.open();
    for k = 1:numel(settingsValues)
        for sIndex = 1:numel(speeds)
            if (k == 1)
                pHandles(sIndex) = imagesc(x,y, squeeze(mirrorActivations(sIndex,k,:,:)), 'parent', axesHandles(sIndex));
                set(axesHandles(sIndex), 'CLim', [0 1], 'XLim', [1 nColsPerPrimary], 'YLim', [1 nRows], 'XTick', (1:nColsPerPrimary), 'YTick', (1:2:nRows), 'XTickLabel', {}, 'YTickLabel', {});
                grid(axesHandles(sIndex), 'on');
                set(axesHandles(sIndex), 'XColor', 'none', 'YColor', 'none');
            else
                set(pHandles(sIndex), 'CData', squeeze(mirrorActivations(sIndex,k,:,:)))
            end
            title(axesHandles(sIndex), sprintf('Settings: %2.3f', settingsValues(k)), 'Color', 'g', 'FontSize', 14);
        end
        drawnow;
        writerObj.writeVideo(getframe(hFig));
    end
    writerObj.close();
    
end

function [x,y,mirrorActivations, fillFactors] = computeMirrorActivation(nRows, nCols, settingsValues, speed)

    nMirrorsPerPrimary = nCols*nRows;
    
    rX = nCols/2;
    rY = nRows/2;
    x = (1:nCols);
    y = (1:nRows);
    xc = x-(rX)-0.5;
    yc = y-(rY)-0.5;
    
    [X,Y] = meshgrid(xc,yc);
    if (speed < 1)
        radii = ((X/rX).^(2/speed) + (Y/rY).^2).^0.1;
    else
        radii = ((X/rX).^2.0 + (Y/rY).^(2*speed)).^0.1;
    end
    radii = reshape(radii, [1 nRows*nCols]);
    [~, indices] = sort(radii);
    
    fillFactors = zeros(1, numel(settingsValues));
    for k = 1:numel(settingsValues)
        mirrorActivation = zeros(nRows, nCols);
        mirrorActivation = reshape(mirrorActivation, [1 nRows*nCols]);
        if (k == 1)
            mirrorActivations = zeros(numel(settingsValues), nRows, nCols);
        end
        maxIndex = round(settingsValues(k)*nMirrorsPerPrimary);
        mirrorActivation(indices(1:maxIndex)) = 1;
        fillFactors(k) = numel(find(mirrorActivation>0))/nMirrorsPerPrimary;
        mirrorActivations(k,:,:) = reshape(mirrorActivation, [nRows nCols]);
    end
end


function cal = getCal()
    % Get the calibration file
    cal = OLGetCalibrationStructure;

    % Backwards compatibility via OLInitCal
    if (~isfield(cal.describe,'numWavelengthBands'))
        fprintf('This is an old calibration file.  Running OLInit (but not saving)\n');
        cal = OLInitCal(cal);
    end
    
    if (~isfield(cal.describe,'specifiedBackground'))
        cal = OLInitCal(cal);
    end
    if (cal.describe.useOmni)
        error('We do not use the omni for calibration.')
    end
end
