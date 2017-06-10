function importCalData(obj, cal)

    if (isempty(cal))
        % Get the calibration file
        cal = OLGetCalibrationStructure;
    end
    
    % Backwards compatibility via OLInitCal
    if (~isfield(cal.describe,'numWavelengthBands'))
        fprintf('This is an old calibration file.  Running OLInit (but not saving)\n');
        cal = OLInitCal(cal);
    end
    
    if (obj.refitGammaTablesUsingLinearInterpolation)
        cal.describe.gammaFitType = 'linearinterpolation';
        cal = OLInitCal(cal);
    else
        if ((~isfield(cal.describe,'specifiedBackground')) || (obj.forceOLInitCal))
            cal = OLInitCal(cal);
        end
    end
    
    
    if (cal.describe.useOmni)
        error('We do not use the omni for calibration.')
    end

    % Find the directory we store our calibration files.
    calFolderInfo = what(getpref('OneLight', 'OneLightCalData'));
    calFolder = calFolderInfo.path;

    %% Title and plot folder stuff
    [calID calIDTitle] = OLGetCalID(cal);

    % We'll store the plots under a folder with a unique timestamp.  We'll
    % remap the ' ' and ':' characters to '-' and '.', respectively found
    % in the date string.
    originalDir = pwd;
    calFileName = char(cal.describe.calType);
    s = strrep(cal.describe.date, ' ', '-');
    s = strrep(s, ':', '.');
    plotFolder = fullfile(calFolder, 'Plots', calFileName, s);

    % Make the proper subdirectory to store the plots if necessary.
    if ~exist(plotFolder, 'dir')
        [status, statMessage] = mkdir(plotFolder);
        assert(status, 'OLAnalyzeCal:mkdir', statMessage);
    end
    
    obj.cal = cal;
    obj.calID = calID;
    obj.figuresDir = plotFolder;
end