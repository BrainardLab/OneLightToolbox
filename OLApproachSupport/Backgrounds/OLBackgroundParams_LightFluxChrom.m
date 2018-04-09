classdef OLBackgroundParams_LightFluxChrom < OLBackgroundParams
    % Parameter-object for light flux backgrounds at a chromaticity
    %
    % Syntax:
    %   params = OLBackgroundParams_LightFluxChrom
    %   backgroundPrimary = OLBackgroundNominalPrimaryFromParams(OLBackgroundParams_LightFluxChromObject,calibration)
    %
    % Description:
    %    These parameters generate a background of specified CIE x, y
    %    chromaticity. The luminance of this background is a specified flux
    %    factor down from the max luminance at this chromaticity.
    %
    % See also:
    %    OLBackgroundParams, OLBackgroundParams_Optimized,
    %    OLPrimaryInvSolveChrom
    %
    
    % History:
    %    02/07/18  jv  Wote it.
    %    04/09/18  dhb Update properties towards current search methods
    
    properties
        lightFluxDesiredXY(1,2) = [0.54 0.38];                              % Modulation chromaticity.
        lightFluxDownFactor(1,1) = 5;                                       % Factor to decrease background after initial values found.  Determines how big a pulse we can put on it.
        polarType(1,:) char = 'unipolar';                                   % Background set for unipolar or bipolar modulation?
        lambda(1,1) = 0;                                                    % Primary smoothing parameter
        spdToleranceFraction(1,1) = 0.005;                                  % Fractional tolerance for relative spd
        optimizationTarget(1,:) char = 'maxContrast';                       % Method used in search for background
        primaryHeadroomForInitialMax(1,1) = 0.05;                           % Parameter used when finding max spd in search for background
        maxScaleDownForStart(1,1) = 2;                                      % Parameter used to scale down max spd in some background search methods
    end
    
    methods
        function obj = OLBackgroundParams_LightFluxChrom
            obj = obj@OLBackgroundParams;
        end
        
        function name = OLBackgroundNameFromParams(params)
            name = sprintf('%s_%d_%d_%d',params.baseName,round(1000*params.lightFluxDesiredXY(1)),round(1000*params.lightFluxDesiredXY(2)),round(10*params.lightFluxDownFactor));
        end
        
        function backgroundPrimary = OLBackgroundNominalPrimaryFromParams(params, calibration)
            % Generate nominal primary for these parameters, for calibration
            %
            % Syntax:
            %   backgroundPrimary = OLBackgroundNominalPrimary(OLBackgroundParams_LightFluxChrom,calibration);
            %
            % Description:
            %    Generate the nominal primary values that would correspond
            %    to the given parameter, under the given calibration.
            %
            %    Background at specified chromaticity that allows a large
            %    light flux pulse modulation.
            %
            % Inputs:
            %    params            - OLBackgroundParams_LightFluxChrom
            %                        defining the parameters for this
            %                        LightFluxChrom background.
            %    calibration       - OneLight calibration struct
            %
            % Outputs:
            %    backgroundPrimary - column vector of primary values for
            %                        the background
            %
            % Optional key/value pairs:
            %    None.
            %
            
            % Input validation
            parser = inputParser();
            parser.addRequired('params',@(x) isa(x,'OLBackgroundParams_LightFluxChrom'));
            parser.addRequired('calibration',@isstruct);
            parser.parse(params,calibration);
            
            % Generate background
            [maxBackgroundPrimary, minBackgroundPrimary, maxLum, minLum]  = ...
                OLPrimaryInvSolveChrom(calibration, params.lightFluxDesiredXY, ...
                'primaryHeadroom',params.primaryHeadRoom, 'lambda',params.lambda, 'spdToleranceFraction',params.spdToleranceFraction, ...
                'optimizationTarget',params.optimizationTarget, 'primaryHeadroomForInitialMax', params.primaryHeadroomForInitialMax, ...
                'maxScaleDownForStart', params.maxScaleDownForStart);
            %{
            fprintf('Max lum %0.2f, min lum %0.2f\n',maxLum,minLum);
            fprintf('Luminance weber contrast, low to high: %0.2f%%\n',100*(maxLum-minLum)/minLum);
            fprintf('Luminance michaelson contrast, around mean: %0.2f%%\n',100*(maxLum-minLum)/(maxLum+minLum));
                %}
                
                % Get background spd
                maxBackgroundSpd = OLPrimaryToSpd(calibration,maxBackgroundPrimary);
                minBackgroundSpd = OLPrimaryToSpd(calibration,minBackgroundPrimary);
                checkLum = maxLum/params.lightFluxDownFactor;
                switch (params.polarType)
                    case 'unipolar' 
                        if (checkLum < minLum)
                            desiredLum = minLum;
                        else
                            desiredLum = minLum + (checkLum-minLum)/2;
                        end
                        backgroundSpd = maxBackgroundSpd*(desiredLum/maxLum);
                        
                        % Downfactor it and convert back to primary space
                        [backgroundPrimary,predBackgroundSpd,fractionalError] = OLSpdToPrimary(calibration,backgroundSpd, ...
                            'lambda',params.lambda, 'checkSpd',false, 'spdToleranceFraction',params.spdToleranceFraction);
                        
                        % Figure for debugging
                        %{
                        figure; clf; hold on;
                        plot(maxBackgroundSpd,'r','LineWidth',3);
                        plot(minBackgroundSpd,'g');
                        plot((minBackgroundSpd\maxBackgroundSpd)*minBackgroundSpd,'k-','LineWidth',1);
                        plot(backgroundSpd,'k');
                        plot(predBackgroundSpd,'b');
                        fprintf('Fractional spd error between desired and found background spectrum: %0.1f%%\n',100*fractionalError);
                        %}
                    case 'bipolar'
                    otherwise
                        error('Unknown background polarType property provided');
                end
        end
        
        function background = OLBackgroundNominalFromParams(params, calibration)
            % Generate nominal background for given parameters, for calibration
            %
            % Syntax:
            %   background = OLBackgroundNominalFromParams(OLBackgroundParams_optimized,calibration);
            %
            % Description:
            %    Generate the nominal primary values that would correspond
            %    to the given parameter, under the given calibration.
            %
            %    These backgrounds get optimized according to the
            %    parameters in the structure.  Backgrounds are optimized
            %    with respect to a backgroundObserverAge year old observer,
            %    and no correction for photopigment bleaching is applied.
            %    We are just trying to get pretty good backgrounds, so we
            %    don't need to fuss with small effects.
            %
            % Inputs:
            %    params            - OLBackgroundParams_optimized
            %                        defining the parameters for this
            %                        optimized background.
            %    calibration       - OneLight calibration struct
            %
            % Outputs:
            %    background        - an OLDirection_unipolar object
            %                        corresponding to the optimized
            %                        background for the parameterized
            %                        direction
            %
            % Optional key/value pairs:
            %    None.
            %
            % See also:
            %    OLDirection_unipolar, OLDirectionNominalFromParams
            
            % History:
            %    03/30/18  jv  OLDirection_unipolar from backgroundParams
            backgroundPrimary = OLBackgroundNominalPrimaryFromParams(params,calibration);
            background = OLDirection_unipolar(backgroundPrimary,calibration);
            background.describe.params = params;
        end
        
        function valid = OLBackgroundParamsValidate(params)
            % Validate passed background parameters
            %
            % Syntax:
            %   valid = OLBackgroundParamsValidate(entry)
            %
            % Description:
            %    This function checks whether a given
            %    OLBackgroundParams_LightFluxChrom has valid values in all
            %    properties. Throws an error if a property contains an
            %    unexpected value.
            %
            % Inputs:
            %    params - OLBackgroundParams_LightFluxChrom defining the
            %             parameters for this LightFluxChrom background.
            %
            % Outputs:
            %    valid  - logical boolean. True if entry contains all those fields, and
            %             only those fields, returned by
            %             OLBackgroundParamsDefaults for the given type. False
            %             if missing or additional fields.
            %
            % Optional key/value pairs:
            %    None.
            
            try
                % Validate lightFluxDesiredXY
                property = 'lightFluxDesiredXY';
                mustBeNumeric(params.(property));
                mustBeNonnegative(params.(property));
                mustBeLessThanOrEqual(params.(property),1);
                
                % Validate lightFluxDownFactor
                property = 'lightFluxDownFactor';
                mustBePositive(params.(property));
                
                % Validate primary headroom
                property = 'primaryHeadRoom';
                mustBeNonnegative(params.(property));
                
                % Validate lambda
                property = 'lambda';
                mustBeNonnegative(params.(property));
                
                % Validate spdToleranceFraction
                property = 'spdToleranceFraction';
                mustBeNonnegative(params.(property));
                
                % Validate optimizationTarget
                %property = 'optimizationTarget';
                %if (~ischar(params.(property))), error('Property %s is not a string',property); end
                
                % Validate primaryHeadroomForInitialMax
                property = 'primaryHeadroomForInitialMax';
                mustBeNonnegative(params.(property));
                
                % Validate maxScaleDownForStart
                property = 'maxScaleDownForStart';
                mustBePositive(params.(property));
                
            catch valueException
                % Add more descriptive message
                propException = MException(sprintf('BackgroundParams:Validate:%s',property),...
                    sprintf('%s is invalid: %s',property,valueException.message));
                addCause(propException,valueException);
                throw(propException);
            end
            
            valid = true;
        end
        
        
    end
    
end