classdef OLDirectionParams_LightFluxChrom < OLDirectionParams
% Parameter-object for LightFluxChrom directions
%   Detailed explanation goes here
    
    properties
        lightFluxDesiredXY(1,2) = [0.333 0.333];                           % Modulation chromaticity.
        lightFluxDownFactor(1,1) = 0;                                      % Size of max flux increase from background
    end    
    
    methods
        function obj = OLDirectionParams_LightFluxChrom  
            obj.baseName = 'LightFluxChrom';                   
            obj.primaryHeadRoom = .01;
        end
        
        function name = OLDirectionNameFromParams(directionParams)
        	name = sprintf('%s_%d_%d_%d',directionParams.baseName,round(1000*directionParams.lightFluxDesiredXY(1)),round(1000*directionParams.lightFluxDesiredXY(2)),round(10*directionParams.lightFluxDownFactor)); 
        end
        
        function [direction, background] = OLDirectionNominalFromParams(directionParams, calibration, varargin)
            % Generate a parameterized OLDirection object from the given parameters
            %
            % Syntax:
            %   direction = OLDirectionNominalFromParams(OLDirectionParams_LightFluxChrom, calibration)
            %   [direction, background] = OLDirectionNominalFromParams(OLDirectionParams_LightFluxChrom, calibration)
            %   direction = OLDirectionNominalFromParams(OLDirectionParams_LightFluxChrom, calibration, background)
            %
            % Description:
            %
            % Inputs:
            %    directionParams - OLDirectionParams_Unipolar object
            %                      defining the parameters for a unipolar
            %                      direction
            %    calibration     - OneLight calibration struct
            %    background      - [OPTIONAL] OLDirection_unipolar object
            %                      specifying the background to build this
            %                      direction around
            %
            % Outputs:
            %    direction       - an OLDirection_unipolar object
            %                      corresponding to the parameterized
            %                      direction
            %    background      - an OLDirection_unipolar object
            %                      corresponding to the optimized
            %                      background for the parameterized
            %                      direction
            %
            % Optional key/value pairs:
            %   'verbose'        - Boolean(default false). Print diagnositc
            %                      information.
            %   'alternateBackgroundDictionaryFunc' - String with name of alternate dictionary
            %                      function to call to resolve a background
            %                      name. This must be a function on the
            %                      path. Default of empty string results in
            %                      using the dictionary included in the
            %                      OneLightToolbox.
            %
            %
            % See also:
            %    OLDirection_unipolar, OLBackgroundNominalFromParams,
            %    OLDirectionParamsDictionary
            
            % History:
            %    01/31/18  jv  Wrote it, based on OLWaveformFromParams and
            %                  OLReceptorIsolateMakeDirectionNominalPrimaries
            %    02/12/18  jv  Inserted in OLDirectionParams_ classes.
            %    03/22/18  jv  Adapted to produce OLDirection objects.
            
            %% Input validation
            parser = inputParser();
            parser.addRequired('directionParams',@(x) isstruct(x) || isa(x,'OLDirectionParams'));
            parser.addRequired('calibration',@isstruct);
            parser.addOptional('background',[],@isnumeric);
            parser.addParameter('verbose',false,@islogical);
            parser.addParameter('alternateBackgroundDictionaryFunc','',@ischar);
            parser.parse(directionParams,calibration,varargin{:});
            
            %% Get / make background
            if isempty(parser.Results.background) % No primary specified in call
                if isempty(directionParams.background) % No primary specified in params
                    if isempty(directionParams.backgroundParams) % No params specified
                        assert(isprop(directionParams,'backgroundName') && ~isempty(directionParams.backgroundName), ...
                            'No background, backgroundParams, or backgroundName specified')
                        
                        % Get backgroundParams from stored name
                        directionParams.backgroundParams = OLBackgroundParamsFromName(directionParams.backgroundName,...
                            'alternateDictionaryFunc',parser.Results.alternateBackgroundDictionaryFunc);
                    end
                    
                    directionParams.background = OLBackgroundNominalFromParams(directionParams.backgroundParams, calibration);
                end
                
                % Use background stored in directionParams
                background = directionParams.background;
            else
                % Use background specified in function call
                background = parser.Results.background;
            end
                        
            %% Make direction
            currentBackgroundPrimary = background.differentialPrimaryValues;
            targetSpd = OLPrimaryToSpd(calibration,currentBackgroundPrimary)*directionParams.lightFluxDownFactor;
            modulationPrimaryPositive = OLSpdToPrimary(calibration,targetSpd,'lambda',0.000);
            
            % Update background
            differentialPrimaryValues = modulationPrimaryPositive - background.differentialPrimaryValues;
                
            %% Create direction object
            describe.directionParams = directionParams;
            describe.backgroundNominal = background.copy();
            describe.background = background;
            direction = OLDirection_unipolar(differentialPrimaryValues, calibration, describe);
        end
            
        function valid = OLDirectionParamsValidate(directionParams)
            valid = true;
        end
    end
    
end