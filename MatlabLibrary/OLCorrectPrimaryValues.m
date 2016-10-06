function [correctedPrimaryValues primariesCorrectedAll measuredSpd measuredSpdRaw predictedSpd] = OLCorrectPrimaryValues(cal, primaryValues, NIter, lambda, NDFilter, ...
    meterType, spectroRadiometerOBJ, spectroRadiometerOBJWillShutdownAfterMeasurement);

try
    %% Open the spectrometer
    % All variables assigned in the following if (isempty(..)) block (except
    % spectroRadiometerOBJ) must be declared as persistent
    persistent S
    persistent nAverage
    persistent theMeterTypeID
    if (isempty(spectroRadiometerOBJ))
        % Open up the radiometer if this is the first cache file we validate
        try
            switch (meterType)
                case 'PR-650',
                    theMeterTypeID = 1;
                    S = [380 4 101];
                    nAverage = 1;
                    
                    % Instantiate a PR650 object
                    spectroRadiometerOBJ  = PR650dev(...
                        'verbosity',        1, ...       % 1 -> minimum verbosity
                        'devicePortString', [] ...       % empty -> automatic port detection)
                        );
                    spectroRadiometerOBJ.setOptions('syncMode', 'OFF');
                    
                case 'PR-670',
                    theMeterTypeID = 5;
                    S = [380 2 201];
                    nAverage = 1;
                    
                    % Instantiate a PR670 object
                    spectroRadiometerOBJ  = PR670dev(...
                        'verbosity',        1, ...       % 1 -> minimum verbosity
                        'devicePortString', [] ...       % empty -> automatic port detection)
                        );
                    
                    % Set options Options available for PR670:
                    spectroRadiometerOBJ.setOptions(...
                        'verbosity',        1, ...
                        'syncMode',         'OFF', ...      % choose from 'OFF', 'AUTO', [20 400];
                        'cyclesToAverage',  1, ...          % choose any integer in range [1 99]
                        'sensitivityMode',  'STANDARD', ... % choose between 'STANDARD' and 'EXTENDED'.  'STANDARD': (exposure range: 6 - 6,000 msec, 'EXTENDED': exposure range: 6 - 30,000 msec
                        'exposureTime',     'ADAPTIVE', ... % choose between 'ADAPTIVE' (for adaptive exposure), or a value in the range [6 6000] for 'STANDARD' sensitivity mode, or a value in the range [6 30000] for the 'EXTENDED' sensitivity mode
                        'apertureSize',     '1 DEG' ...   % choose between '1 DEG', '1/2 DEG', '1/4 DEG', '1/8 DEG'
                        );
                otherwise,
                    error('Unknown meter type');
            end
            
        catch err
            if (~isempty(spectroRadiometerOBJ))
                spectroRadiometerOBJ.shutDown();
                openSpectroRadiometerOBJ = [];
            end
            keyboard;
            rethrow(err);
        end
    end
    openSpectroRadiometerOBJ = spectroRadiometerOBJ;
    
    % Populate the filter with ones if it is passed as empty
    if isempty(NDFilter)
        NDFilter = ones(S(3), 1);
    end
    
    % Determine how many settings we need to correct
    NPrimaryValues = size(primaryValues, 2);
    
    %% Determine which meters to measure with
    % It is probably a safe assumption that we will not validate a cache file
    % with the Omni with respect to a calibration that was done without the
    % Omni. Therefore, we read out the toggle directly from the calibration
    % file. First entry is PR-6xx and is always true. Second entry is omni and
    % can be on or off, depending on content of calibration.
    meterToggle = [1 cal.describe.useOmni];
    
    % Open up the OneLight
    ol = OneLight;
    
    iter = 1;
    while iter <= NIter
        iter
        % Iterate over the primary values to correct
        for ii = 1:NPrimaryValues
            ii
            % Pull out the primary values
            if iter == 1
                primaries = primaryValues(:, ii);
            else
                primaries = primariesCorrected;
            end
            
            % Predict the spectra
            if iter == 1
                % Make a prediction
                predictedSpdRaw(:, ii) = cal.computed.pr650M*primaries + cal.computed.pr650MeanDark;
                % Incorporate the filter
                predictedSpd(:, ii) = predictedSpdRaw(:, ii) .* NDFilter;
            end
            
            % Convert the primaries to mirror settings.
            settings = OLPrimaryToSettings(cal, primaries);
            
            % Compute the start/stop mirrors.
            [starts, stops] = OLSettingsToStartsStops(cal, settings);
            
            % Take measurement
            tmpMeas = OLTakeMeasurementOOC(ol, [], spectroRadiometerOBJ, starts, stops, S, meterToggle, nAverage);
            measuredSpdRaw{ii}(:, iter) = tmpMeas.pr650.spectrum;
            measuredSpd{ii}(:, iter) = measuredSpdRaw{ii}(:, iter) .* NDFilter;
            
            % Figure out a scaling factor from the first measurement
            % which puts the measured spectrum into the same range as
            % the predicted spectrum. This deals with fluctuations with
            % absolute light level.
            if iter == 1 && ii == 1
                % Determine the scale factor
                kScale = measuredSpd{ii}(:, iter) \ predictedSpd(:, ii);
            end
            
            % Infer the primaries
            deltaPrimaryInferred = OLSpdToPrimary(cal, (kScale * measuredSpd{ii}(:, iter))-...
                predictedSpd(:, ii), 'differentialMode', true);
            primariesCorrected = primaries - lambda * deltaPrimaryInferred;
            primariesCorrected(primariesCorrected > 1) = 1;
            primariesCorrected(primariesCorrected < 0) = 0;
            primariesCorrectedAll{ii}(:, iter) = primariesCorrected;
            deltaPrimariesCorrectedAll{ii}(:, iter)= deltaPrimaryInferred;
        end
        
        % Increment
        iter = iter+1;
    end
    
    %% Assemble the values to be returned
    for ii = 1:NPrimaryValues
        correctedPrimaryValues(:, ii) = primariesCorrectedAll{ii}(:, end);
    end
    
catch e
    if (~isempty(spectroRadiometerOBJ))
        spectroRadiometerOBJ.shutDown();
        openSpectroRadiometerOBJ = [];
    end
    rethrow(e)
end