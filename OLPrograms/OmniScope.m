function OmniScope
% OmniScope
%
% Description:
% Some tests on the lamp properties, and whether we can set them.
%
% 1/2/14  dhb  Wrote it.
% 1/3/14  dhb  Add lamp adjustment loop.

% Close figs
close all;

S = [380 2 201];

nSamplesToDisplay = 30;

% Load XYZ to get luminance

fprintf('\n');
try
    od = OmniDriver;
    od.Debug = true;
    od.ScansToAverage = 10;
    od.BoxcarWidth = 2;
    
    % Make sure electrical dark correction is enabled.
    od.CorrectForElectricalDark = true;
    
    % Get a good integration time for omni
    od.IntegrationTime = od.findIntegrationTime(1000, 2, 1000);
    od.IntegrationTime = round(0.95*od.IntegrationTime);
    fprintf('- Using integration time of %d microseconds.\n', od.IntegrationTime);
    
    
    % Adjustment loop
    fprintf('- Adjustment loop, hit any key to exit\n');
    figure('units', 'normalized', 'outerposition', [0 0 1 1]); clf;
    while (CharAvail)
        GetChar;
    end
    sampleTrack = 1;
    while (1)
        
        % Update plot
        meas.omni.time(1) = mglGetSecs;
        try
            meas.omni.spectrum = od.getSpectrum' / od.IntegrationTime;
            plotColor = 'k';
        catch e
            meas.omni.spectrum = ones(1, length(od.Wavelengths));
            plotColor = 'r';
            fprintf('*** Spectrum saturated! ***\n');
        end
        meas.omni.time(2) = mglGetSecs;
        timeMeas(sampleTrack) = meas.omni.time(2);
        currentSum(sampleTrack) = sum(meas.omni.spectrum);
        
        subplot(1, 2, 1);
        area(od.Wavelengths, meas.omni.spectrum, 'FaceColor', plotColor); hold on;
        pbaspect([1 1 1]);
        xlabel('Wavelength [nm]');
        ylabel('Power');
        ylim([0 Inf]);
        xlim([380 780]);
        title('Omni measurements: Spectrum');
        drawnow;
        hold off;
        
        % Plot spectrum sum
        subplot(1, 2, 2);
        plot(1:sampleTrack, currentSum(1:sampleTrack), '-o', 'Color', plotColor, 'MarkerFaceColor', plotColor); hold on;
        xlim([0 nSamplesToDisplay+1]);
        set(gca, 'XTick', 1:sampleTrack, 'XTickLabel', strread(num2str(round(timeMeas(1:sampleTrack)-timeMeas(1))), '%s'));
        pbaspect([1 1 1]);
        xlabel('Time');
        ylabel('Sum of spectrum');
        title('Omni measurements: Spectrum sum');
        drawnow;
        hold off;
        
        % Check for exit
        if (CharAvail)
            break;
        end
        
        % Measure
        if sampleTrack == nSamplesToDisplay
            sampleTrack = 1;
        else
            sampleTrack = sampleTrack + 1;
        end
    end
    GetChar;
    
    
    
catch e
    rethrow(e);
    keyboard
end


