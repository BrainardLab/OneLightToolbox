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
%    OLBackgroundParams, OLBackgroundParams_Optimized
%

% History:
%    02/07/18  jv  wrote it.
    
    properties
        lightFluxDesiredXY(1,2) = [0.54 0.38];                              % Modulation chromaticity.
        lightFluxDownFactor(1,1) = 5;                                       % Factor to decrease background after initial values found.  Determines how big a pulse we can put on it.
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
            
            % Parameters maybe we should pass
            lambda = 0;
            spdToleranceFraction = 0.005;
            primaryHeadroomForInitialMax = 0.05;
            primaryHeadroom = params.primaryHeadRoom;
            
            % Generate background
            [maxBackgroundPrimary, minBackgroundPrimary, maxLum, minLum]  = ...
                OLPrimaryInvSolveChrom(calibration, params.lightFluxDesiredXY, ...
                'primaryHeadroom',0.005, 'lambda',lambda, 'spdToleranceFraction',spdToleranceFraction, ...
                'optimizationTarget','maxContrast', 'primaryHeadroomForInitialMax', primaryHeadroomForInitialMax, ...
                'maxScaleDownForStart', 2);
            %{
            fprintf('Max lum %0.2f, min lum %0.2f\n',maxLum,minLum);
            fprintf('Luminance weber contrast, low to high: %0.2f%%\n',100*(maxLum-minLum)/minLum);
            fprintf('Luminance michaelson contrast, around mean: %0.2f%%\n',100*(maxLum-minLum)/(maxLum+minLum));
            %}
            
            % Get nominal spd
            maxBackgroundSpd = OLPrimaryToSpd(calibration,maxBackgroundPrimary);
            minBackgroundSpd = OLPrimaryToSpd(calibration,minBackgroundPrimary);
            checkLum = maxLum/params.lightFluxDownFactor;
            if (checkLum < minLum)
                desiredLum = minLum;
            else
                desiredLum = minLum + (checkLum-minLum)/2;
            end
            backgroundSpd = maxBackgroundSpd*(desiredLum/maxLum);
            
            % Downfactor it and convert back to primary space
            [backgroundPrimary,predBackgroundSpd,fractionalError] = OLSpdToPrimary(calibration,backgroundSpd, ...
                'lambda',lambda, 'checkSpd',false, 'spdToleranceFraction',spdToleranceFraction);
            
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