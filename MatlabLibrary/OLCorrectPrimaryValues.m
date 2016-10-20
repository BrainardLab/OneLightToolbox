function [correctedPrimaryValues, primariesCorrectedAll, deltaPrimariesCorrectedAll, measuredSpd, measuredSpdRaw, predictedSpd, varargout] = OLCorrectPrimaryValues(cal, cal0, primaryValues, NIter, lambda, NDFilter, meterType, spectroRadiometerOBJ, spectroRadiometerOBJWillShutdownAfterMeasurement, varargin)
% [correctedPrimaryValues, primariesCorrectedAll, deltaPrimariesCorrectedAll, measuredSpd, measuredSpdRaw, predictedSpd, varargout] = OLCorrectPrimaryValues(cal, cal0, primaryValues, NIter, lambda, NDFilter, meterType, spectroRadiometerOBJ, spectroRadiometerOBJWillShutdownAfterMeasurement);
%
% This function corrects abunch of primary settings.
% varargin (keyword-value)  - A few keywords which determine the behavior
%                             'takeTemperatureMeasurements' false  Whether
%                             to take temperature measurements (requires a
%                             connected LabJack dev with a temperature
%                             probe). If set to true, the varagout{1} will
%                             contain the temperature data
%
% 10/8/16   ms      Wrote it.
% 10/20/16 npc      Added ability to record temperature measurements

% Parse the input
p = inputParser;
p.addOptional('takeTemperatureMeasurements', false, @islogical);
p.parse(varargin{:});
takeTemperatureMeasurements = p.Results.takeTemperatureMeasurements;

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
        
        % Attempt to open the LabJack temperature sensing device
        if (takeTemperatureMeasurements)
            % Gracefully attempt to open the LabJack
            [takeTemperatureMeasurements, quitNow] = OLCalibrator.OpenLabJackTemperatureProbe(takeTemperatureMeasurements);
            if (quitNow)
                return;
            end
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
    meterToggle = [1 0];
    
    % Open up the OneLight
    ol = OneLight;
    
    % Print out some information
    fprintf('\n- <strong>Starting correction procedure</strong>...');
    iter = 1;
    while iter <= NIter
        fprintf('\n\n* Iteration\t <strong>%g / %g</strong>', iter, NIter);
        % Iterate over the primary values to correct
        for ii = 1:NPrimaryValues
            fprintf('\n  * Primary\t <strong>%g / %g</strong> ...', ii, NPrimaryValues);
            % Pull out the primary values
            if iter == 1
                primaries = primaryValues(:, ii);
            else
                primaries = primariesCorrectedAll{ii}(:, iter-1);
            end
            
            % Predict the spectra
            if iter == 1
                % Make a prediction
                predictedSpdRaw(:, ii) = cal.computed.pr650M*primaries + cal.computed.pr650MeanDark;
                % Incorporate the filter
                predictedSpd(:, ii) = predictedSpdRaw(:, ii) ./ NDFilter;
            end
            
            % Convert the primaries to mirror settings.
            settings = OLPrimaryToSettings(cal0, primaries);
            
            % Compute the start/stop mirrors.
            [starts, stops] = OLSettingsToStartsStops(cal0, settings);
            
            % Take measurement
            tmpMeas = OLTakeMeasurementOOC(ol, [], spectroRadiometerOBJ, starts, stops, S, meterToggle, nAverage);
            measuredSpdRaw{ii}(:, iter) = tmpMeas.pr650.spectrum;
            measuredSpd{ii}(:, iter) = measuredSpdRaw{ii}(:, iter);
            
            % Figure out a scaling factor from the first measurement
            % which puts the measured spectrum into the same range as
            % the predicted spectrum. This deals with fluctuations with
            % absolute light level.
            if iter == 1 && ii == 1
                % Determine the scale factor
                kScale = measuredSpd{ii}(:, iter) \ predictedSpd(:, ii);
            end
            
            % Infer the primaries
            deltaPrimaryInferred = OLSpdToPrimary(cal0, (kScale * measuredSpd{ii}(:, iter))-predictedSpd(:, ii), ...
                'differentialMode', true);
            primariesCorrected = primaries - lambda * deltaPrimaryInferred;
            primariesCorrected(primariesCorrected > 1) = 1;
            primariesCorrected(primariesCorrected < 0) = 0;
            primariesCorrectedAll{ii}(:, iter) = primariesCorrected;
            deltaPrimariesCorrectedAll{ii}(:, iter) = deltaPrimaryInferred;
            
            % Add the filter back in
            measuredSpd{ii}(:, iter) = measuredSpd{ii}(:, iter) .* NDFilter;
            
            % Take temperature
            if (takeTemperatureMeasurements)
                temperatureData.measuredSPD{ii}(:, iter) = LJTemperatureProbe('measure');
            end
        
            % Some status info.
            fprintf('Done.');
        end
        
        % Increment
        iter = iter+1;
    end
    fprintf('\n- <strong>Correction done.</strong>')
    
    %% Assemble the values to be returned
    for ii = 1:NPrimaryValues
        correctedPrimaryValues(:, ii) = primariesCorrectedAll{ii}(:, end);
    end
    
    %% Return temperature data if so specified
    if (takeTemperatureMeasurements)
        varargout{1} = temperatureData;
    end
    
    % Shutdown the spectrometer
    spectroRadiometerOBJ.shutDown();
    
catch e
    if (~isempty(spectroRadiometerOBJ))
        spectroRadiometerOBJ.shutDown();
        openSpectroRadiometerOBJ = [];
    end
    rethrow(e)
end