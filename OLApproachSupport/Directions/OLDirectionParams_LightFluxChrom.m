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
            %   direction = OLDirectionNominalFromParams(..., 'observerAge', observerAge)
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
            %   'observerAge'    - (vector of) observer age(s) to
            %                      generate direction for. When
            %                      numel(observerAge > 1), output
            %                      directionStruct will still be of size
            %                      [1,60], so that the index is the
            %                      observerAge. When numel(observerAge ==
            %                      1), directionStruct will be a single
            %                      struct. If this is a single number and
            %                      the backround gets made here, then this
            %                      value orverrides what is in the
            %                      background parameters structure. Default
            %                      age is 32.
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
            %    04/01/18  dhb Override age passed to background from
            %                  params with age used here. Also
            %                  alternateBackgroundDictionaryFunc.
            
            %% Input validation
            parser = inputParser();
            parser.addRequired('directionParams',@(x) isstruct(x) || isa(x,'OLDirectionParams'));
            parser.addRequired('calibration',@isstruct);
            parser.addOptional('background',[],@isnumeric);
            parser.addParameter('verbose',false,@islogical);
            parser.addParameter('observerAge',32,@isnumeric);
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
                    
                    % Make backgroundPrimary from params, using local
                    % observer age if there is just one, otherwise whatever
                    % is in the background structure.
                    backgroundParamsTemp = directionParams.backgroundParams;
                    if (length(parser.Results.observerAge) == 1)
                        backgroundParamsTemp.backgroundObserverAge = parser.Results.observerAge;
                    end
                    directionParams.background = OLBackgroundNominalFromParams(backgroundParamsTemp.backgroundObserverAge, calibration);
                    clear backgroundParamsTemp
                end
                
                % Use background stored in directionParams
                background = directionParams.background;
            else
                % Use background specified in function call
                background = parser.Results.background;
            end
            
            backgroundSPD = background.ToPredictedSPD;
            
            %% Make direction
            currentBackgroundPrimary = background.differentialPrimaryValues;
            modulationPrimaryPositive = currentBackgroundPrimary*directionParams.lightFluxDownFactor;
            differentialPrimaryValues = modulationPrimaryPositive - currentBackgroundPrimary; 
            
            % Update background
            background = OLDirection_unipolar(background.differentialPrimaryValues-differentialPrimaryValues,calibration,background.describe);
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