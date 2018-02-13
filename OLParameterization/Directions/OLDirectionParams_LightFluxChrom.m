classdef OLDirectionParams_LightFluxChrom < OLDirectionParams
% Parameter-object for LightFluxChrom directions
%   Detailed explanation goes here
    
    properties
        lightFluxDesiredXY(1,2) = [0.5400 0.3800];                         % Modulation chromaticity.
        lightFluxDownFactor(1,1) = 5;                                      % Size of max flux increase from background
        %backgroundObserverAge = 32;
    end    
    
    methods
        function obj = OLDirectionParams_LightFluxChrom  
            obj.type = 'lightfluxchrom';
            obj.baseName = 'LightFluxChrom';
            obj.name = '';
            obj.cacheFile = '';
                      
            obj.primaryHeadRoom = .01;
        end
        
        function name = OLDirectionNameFromParams(directionParams)
        	name = sprintf('%s_%d_%d_%d',directionParams.baseName,round(1000*directionParams.lightFluxDesiredXY(1)),round(1000*directionParams.lightFluxDesiredXY(2)),round(10*directionParams.lightFluxDownFactor)); 
        end
        
        function directionStruct = OLDirectionNominalStructFromParams(directionParams, calibration, varargin)
            % Generate a parameterized direction from the given parameters
            %
            % Syntax:
            %   directionStruct = OLDirectionNominalStructFromParams(OLDirectionParams_LightFluxChrom, calibration)
            %   directionStruct = OLDirectionNominalStructFromParams(OLDirectionParams_LightFluxChrom, calibration, backgroundPrimary)            
            %   directionStruct = OLDirectionNominalStructFromParams(..., 'observerAge', obseverAge)
            %
            % Description:
            %    A light flux modulation, which has the same chromaticity
            %    as the background, but higher total flux.
            % 
            %    Note: This has access to useAmbient and primaryHeadRoom
            %    parameters but does not currently use them. That is
            %    because this counts on the background having been set up
            %    to accommodate the desired modulation. Modulation.  This
            %    is the background scaled up by the factor that the
            %    background was originally scaled down by.   
            %
            % Inputs:
            %    directionParams   - OLDirectionParams_LightFluxChrom
            %                        object defining the parameters for a
            %                        light flux direction
            %    calibration       - OneLight calibration struct
            %    backgroundPrimary - [OPTIONAL] the primary values for the
            %                        background. If not passed, will try
            %                        and construct background from primary,
            %                        params, or name stored in
            %                        directionParams
            %
            % Outputs:
            %    directionStruct   - a 1x60 struct array (one struct per
            %                        observer age 1:60 yrs), with the
            %                        following fields:
            %                          * backgroundPrimary   : the primary
            %                                                  values for
            %                                                  the
            %                                                  background.
            %                          * differentialPositive: the
            %                                                  difference
            %                                                  in primary
            %                                                  values to be
            %                                                  added to the
            %                                                  background
            %                                                  primary to
            %                                                  create the
            %                                                  positive
            %                                                  direction
            %                          * differentialNegative: the
            %                                                  difference
            %                                                  in primary
            %                                                  values to be
            %                                                  added to the
            %                                                  background
            %                                                  primary to
            %                                                  create the
            %                                                  negative
            %                                                  direction
            %                          * calibration         : OneLight
            %                                                  calibration
            %                                                  struct used
            %                                                  to generate
            %                                                  the
            %                                                  directionStruct
            %                          * describe            : Any
            %                                                  additional
            %                                                  (meta)-
            %                                                  information
            %                                                  that might
            %                                                  be stored
            %
            % Optional key/value pairs:
            %    observerAge       - (vector of) observer age(s) to
            %                        generate direction struct for. When
            %                        numel(observerAge > 1), output
            %                        directionStruct will still be of size
            %                        [1,60], so that the index is the
            %                        observerAge. When numel(observerAge ==
            %                        1), directionStruct will be a single
            %                        struct. Default is 20:60.
            %
            % Notes:
            %    None.
            %
            % See also:
            %    OLBackgroundNominalPrimaryFromParams, 
            %    OLDirectionParamsDictionary

            % History:
            %    01/31/18  jv  wrote it, based on OLWaveformFromParams and
            %                  OLReceptorIsolateMakeDirectionNominalPrimaries
            %    02/12/18  jv  inserted in OLDirectionParams_ classes.
            
            %% Input validation
            parser = inputParser();
            parser.addRequired('directionParams',@(x) isstruct(x) || isa(x,'OLDirectionParams'));
            parser.addRequired('calibration',@isstruct);
            parser.addOptional('backgroundPrimary',[],@isnumeric);
            parser.addParameter('verbose',false,@islogical);
            parser.addParameter('observerAge',1:60,@isnumeric);
            parser.parse(directionParams,calibration,varargin{:});            
            
            %% Get / make background primary
            if isempty(parser.Results.backgroundPrimary) % No primary specified in call            
                if isempty(directionParams.backgroundPrimary) % No primary specified in params
                    if isempty(directionParams.backgroundParams) % No params specified
                        assert(isprop(directionParams,'backgroundName') && ~isempty(directionParams.backgroundName),'No backgroundPrimary, backgroundParams, or backgroundName specified')
                        
                        % Get backgroundParams from stored name
                        directionParams.backgroundParams = OLBackgroundParamsFromName(directionParams.backgroundName);
                    end
                    
                    % Make backgroundPrimary from params
                    directionParams.backgroundPrimary = OLBackgroundNominalPrimaryFromParams(directionParams.backgroundParams, calibration);
                end
                
                % Use backgroundPrimary stored in directionParams
                currentBackgroundPrimary = directionParams.backgroundPrimary;
            else
                % Use backgroundPrimary specified in function call
                currentBackgroundPrimary = parser.Results.backgroundPrimary;
            end
                       
            %% Make direction
            modulationPrimarySignedPositive = currentBackgroundPrimary*directionParams.lightFluxDownFactor;
            differentialPositive = modulationPrimarySignedPositive - currentBackgroundPrimary;
            differentialNegative = 0 * differentialPositive;

            %% Check gamut
            if (any(modulationPrimarySignedPositive > 1) || any(modulationPrimarySignedPositive < 0))
                error('Out of gamut error for the modulation');
            end
            
            %% Calculate SPDs
            backgroundSpd = OLPrimaryToSpd(calibration, currentBackgroundPrimary);
            nominalSPDPositive = OLPrimaryToSpd(calibration, currentBackgroundPrimary + differentialPositive);
            nominalSPDNegative = OLPrimaryToSpd(calibration, currentBackgroundPrimary + differentialNegative);

            %% Assign all the fields
            for observerAgeInYears = parser.Results.observerAge            
                % Business end
                directionStruct(observerAgeInYears).backgroundPrimary = currentBackgroundPrimary;              
                directionStruct(observerAgeInYears).differentialPositive = differentialPositive;                            
                directionStruct(observerAgeInYears).differentialNegative = differentialNegative;            
                directionStruct(observerAgeInYears).calibration = calibration;
                
                % Description
                directionStruct(observerAgeInYears).describe.observerAge = observerAgeInYears;
                directionStruct(observerAgeInYears).describe.directionParams = directionParams;
                directionStruct(observerAgeInYears).describe.SPDAmbient = zeros(size(backgroundSpd,1),1);
                directionStruct(observerAgeInYears).describe.NominalSPDBackground = backgroundSpd;
                directionStruct(observerAgeInYears).describe.NominalSPDPositiveModulation = nominalSPDPositive;
                directionStruct(observerAgeInYears).describe.NominalSPDNegativeModulation = nominalSPDNegative;
            end 
            
            %% If a single age was specified, pull out just that struct.
            if numel(parser.Results.observerAge == 1)
                directionStruct = directionStruct(parser.Results.observerAge);
            end            
        end
        
        function valid = OLDirectionParamsValidate(directionParams)
            valid = true;
        end
    end
    
end