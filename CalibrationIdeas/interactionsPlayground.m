function interactionsPlayground(exp2)

    
    nRows = 1024;
    nColsPerPrimary = 16;

    figure(1);
    clf;
    colormap(gray(512))
    
    settingsValues = 0.0:1/1024:1.0;
    for k = 1:numel(settingsValues)
        [x,y,ellipse] = computeMirrorActivation(nRows, nColsPerPrimary, settingsValues(k), exp2);
    
        imagesc(x,y, ellipse);
        set(gca, 'CLim', [0 1]);
        drawnow;
    end
    
    
end

function [x,y,ellipse] = computeMirrorActivation(nRows, nCols, settingsValue, exp2)

    nMirrorsPerPrimary = nCols*nRows;
    activatedMirrorsNum = round(settingsValue*nMirrorsPerPrimary);
    
    mirrorActivation = zeros(nRows, nCols);
    x = (1:nCols)-(nCols/2)-0.5;
    y = (1:nRows)-(nRows/2)-0.5;
    
    rX = nCols/2;
    rY = nRows/2;
    [X,Y] = meshgrid(x,y);
    ellipse = sqrt(((X/rX).^2.0 + (Y/rY).^exp2));
    ellipse(ellipse < settingsValue) = 0.0;
    ellipse(ellipse > 0.0) = 1.0;
    ellipse = 1-ellipse;
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
