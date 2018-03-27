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
            
            % Generate background
            maxBackgroundPrimary = OLBackgroundInvSolveChrom(calibration, params.lightFluxDesiredXY, 'PrimaryHeadroom', params.primaryHeadRoom);
            backgroundPrimary = maxBackgroundPrimary/params.lightFluxDownFactor;
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