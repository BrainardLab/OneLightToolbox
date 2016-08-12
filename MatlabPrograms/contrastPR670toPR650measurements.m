function contrastPR670toPR650measurements

    PR650port = '/dev/cu.USA19H142P1.1';
    PR670port = '/dev/cu.usbmodem1461';
    %PR670port = '/dev/tty.usbmodem1461';
    
    spectroRadiometerPR670dev = [];
    skipPR670 = false;
        if (~skipPR670)
        try
            % Instantiate a PR670 object
            spectroRadiometerPR670dev  = PR670dev(...
                'verbosity',        10, ...             % 1 -> minimum verbosity
                'devicePortString', PR670port ...       % empty -> automatic port detection)
                );

            % Set options Options available for PR670:
            spectroRadiometerPR670dev.setOptions(...
                'verbosity',        1, ...
                'syncMode',         'OFF', ...      % choose from 'OFF', 'AUTO', [20 400];
                'cyclesToAverage',  1, ...          % choose any integer in range [1 99]
                'sensitivityMode',  'STANDARD', ... % choose between 'STANDARD' and 'EXTENDED'.  'STANDARD': (exposure range: 6 - 6,000 msec, 'EXTENDED': exposure range: 6 - 30,000 msec
                'exposureTime',     'ADAPTIVE', ... % choose between 'ADAPTIVE' (for adaptive exposure), or a value in the range [6 6000] for 'STANDARD' sensitivity mode, or a value in the range [6 30000] for the 'EXTENDED' sensitivity mode
                'apertureSize',     '1 DEG' ...   % choose between '1 DEG', '1/2 DEG', '1/4 DEG', '1/8 DEG'
                );

        catch err
            fprintf('Failed with message: ''%s''.\nPlease wait for the 670 spectroradiometer obj to shut down .... ', err.message);
            if (~isempty(spectroRadiometerPR670dev))
                spectroRadiometerPR670dev.shutDown();
            end
            return;
        end
        
        if (isempty(spectroRadiometerPR670dev))
            return;
        end
    
    end
    
    
    fprintf('Hit enter to proceed with PR650');
    pause;
    
    spectroRadiometerPR650dev = [];
    try
        % Instantiate a PR650 object
        spectroRadiometerPR650dev  = PR650dev(...
            'verbosity',        1, ...              % 1 -> minimum verbosity
            'devicePortString', PR650port ...        % empty -> automatic port detection)
            );
        spectroRadiometerPR650dev.setOptions('syncMode', 'OFF');

    catch err
        fprintf('Failed with message: ''%s''.\nPlease wait for the 650 spectroradiometer obj to shut down .... ', err.message);
        if (~isempty(spectroRadiometerPR650dev))
            spectroRadiometerPR650dev.shutDown();
        end
        return;
    end
    

    
          
    fprintf('Opened successfully both spectroradiometers\n');
    repeatsNum = GetWithDefault('Enter # of measurement to take : [1 -- ]:', 1);

    cal.describe.S = [380 2 201];
    wavelengthAxis = (SToWls(cal.describe.S))';
    PR670SPDs = [];
    PR650SPDs = [];
    for repeatIndex = 1:repeatsNum
        if (~isempty(spectroRadiometerPR670dev))
            try
                PR670SPDs(repeatIndex,:) = spectroRadiometerPR670dev.measure('userS', cal.describe.S);
            catch err
                fprintf('Failed with message: ''%s''.\nPlease wait for the 670 spectroradiometer obj to shut down .... ', err.message);
                spectroRadiometerPR670dev.shutDown();
            end
        end
        
        if (~isempty(spectroRadiometerPR650dev))
            try
                PR650SPDs(repeatIndex,:) = spectroRadiometerPR650dev.measure('userS', cal.describe.S);
            catch err
                fprintf('Failed with message: ''%s''.\nPlease wait for the 650 spectroradiometer obj to shut down .... ', err.message);
                spectroRadiometerPR650dev.shutDown();
            end
        end
    end

    % Plot results
    size(PR670SPDs)
    size(PR650SPDs)
    size(wavelengthAxis)
    
    figure(1);
    clf;
    hold on;
    if (~isempty(PR670SPDs))
        stem(wavelengthAxis, PR670SPDs, 'r', 'filled');
    end
    if (~isempty(PR650SPDs))
        stem(wavelengthAxis, PR650SPDs, 'b', 'filled');
    end
    legend('PR670', 'PR650');
    drawnow;
    
    % Shutdown devices
    if (~isempty(spectroRadiometerPR670dev))
        spectroRadiometerPR670dev.shutDown();
    end
    if (~isempty(spectroRadiometerPR650dev))
        spectroRadiometerPR650dev.shutDown();
    end
    
end

