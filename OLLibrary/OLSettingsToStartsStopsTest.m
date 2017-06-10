% OLSettingsToStartsStopsTest
%
% Unit test for routine OLSettingsToStartsStops
%
% Dummies up required fields of calibration structure and then
% makes sure we can do the conversions and that the matrices are filling
% up the way we expect.
%
% 2/16/14  dhb  Wrote it.

%% Clear
clear; close all;

% Flag to set if we want to save out the movie as a gif.
SAVEGIF = false;

%% To run the test, we need some fields of the calibration structure
% to exist.  Set these up here, so we can run this without a calibration
% structure already in hand.\

% These are normally extracted from the OL object at calibration time
ol.NumCols = 1024;
ol.NumRows = 768;
cal.computed = true;
cal.describe.numRowMirrors = ol.NumRows;
cal.describe.numColMirrors = ol.NumCols;

% These are normally set and computed in this way in the calibration program
cal.describe.bandWidth = 16;
cal.describe.nShortPrimariesSkip = 0;
cal.describe.nLongPrimariesSkip = 0;
cal.describe.primaryStartCols = 1 + (cal.describe.nShortPrimariesSkip*cal.describe.bandWidth:cal.describe.bandWidth:(ol.NumCols - (cal.describe.nLongPrimariesSkip+1)*cal.describe.bandWidth));
cal.describe.primaryStopCols = cal.describe.primaryStartCols + cal.describe.bandWidth-1;
cal.describe.numWavelengthBands = length(cal.describe.primaryStartCols);

% Set up a primaries vector
nPrimaries = cal.describe.numWavelengthBands;

% Just run through getting starts and stops for a
% series of settings values.
nTestLevels = 1000;
theSettingsVals = linspace(0,1,nTestLevels);
testPrimary = 64;

settings = zeros(nPrimaries,nTestLevels);
for i = 1:nTestLevels
    settings(testPrimary,i) = theSettingsVals(i);
end

[starts,stops] = OLSettingsToStartsStops(cal,settings,'verbose',false);

figure; clf;
colExpandFactor = 20;
for i = 1:nTestLevels
    mirrorMatrix = OLStartsStopsToMirrorMatrix(cal,starts(i,:),stops(i,:));
    extractMatrix = mirrorMatrix(:,1+(testPrimary-1)*cal.describe.bandWidth:testPrimary*cal.describe.bandWidth);
    showMatrix = Expand(extractMatrix,colExpandFactor,1);
    imshow(showMatrix);
    drawnow;
    
    % Save the individual frames
    if SAVEGIF
        % Save the temporary plots to tmp
        currDir = pwd;
        cd('/tmp')
        
        % Save plots
        set(gcf, 'PaperPosition', [0 0 5 4]); %Position plot at left hand corner with width 5 and height 5.
        set(gcf, 'PaperSize', [5 4]); %Set the paper to have width 5 and height 5.
        savefig(['tmp_' sprintf('%04d',i) '.png'], gcf, 'png');
        cd(currDir);
    end
end

% Make the gif
if SAVEGIF
    delayTime = 5;
    outFileName = 'OLSettingsToStartsStopsTest.gif';
    
    currDir = pwd;
    cd('/tmp');
    % Make sure gifsicle and morgify can be found in the path
    oldPath = getenv('PATH');
    if isempty(strfind(oldPath, '/opt/local/bin')) && isdir('/opt/local/bin')
        setenv('PATH', [oldPath ':/opt/local/bin']);
    end
    
    % Set the DYLD library path to empty, so that we can run mogrify
    oldLibPath = getenv('DYLD_LIBRARY_PATH');
    setenv('DYLD_LIBRARY_PATH', '');
    
    % Convert the resulting PNG files to GIF by calling mogrify
    disp('Converting to GIF');
    %[status, result] = system(['mogrify -resize 10% -format gif ' 'tmp_' '*.png']);
    
    % Check for error
    %if status ~= 0
    %    disp('WARNING: mogrify failed.');
    %    disp(['Error message: ', result]);
    %end
    
    % Loop the resulting GIF files with gifsicle
    disp('Creating GIF');
    [status, result] = system(['gifsicle --loopcount=0 --delay ' num2str(delayTime) ' ' 'tmp_' '*.gif > ' fullfile(fileparts(which('OLSettingsToStartsStopsTest')), outFileName)]);
    
    % Check for error
    if status ~= 0
        disp('WARNING: gifsicle failed.');
        disp(['Error message: ', result]);
    end
    
    % Revert changes we made to the path
    setenv('PATH', oldPath);
    setenv('DYLD_LIBRARY_PATH', oldLibPath);
    
    cd(currDir);
end