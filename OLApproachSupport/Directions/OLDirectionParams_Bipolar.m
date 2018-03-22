classdef OLDirectionParams_Bipolar < OLDirectionParams
    % Parameter-object for Bipolar directions
    %   Detailed explanation goes here
    
    properties
        photoreceptorClasses = {'LConeTabulatedAbsorbance'  'MConeTabulatedAbsorbance'  'SConeTabulatedAbsorbance'  'Melanopsin'};
        T_receptors = [];
        fieldSizeDegrees(1,1) = 27.5;
        pupilDiameterMm(1,1) = 8.0;
        maxPowerDiff(1,1) = 0.1;
        baseModulationContrast = [];
        modulationContrast = [];
        whichReceptorsToIsolate = [];
        whichReceptorsToIgnore = [];
        whichReceptorsToMinimize = [];
        whichPrimariesToPin = [];
        directionsYoked = 0;
        directionsYokedAbs = 0;
        receptorIsolateMode = 'Standard';
        doSelfScreening = false;
    end
    
    methods
        function obj = OLDirectionParams_Bipolar
            obj.primaryHeadRoom = .005;
        end
        
        function name = OLDirectionNameFromParams(directionParams)
            name = sprintf('%s_bipolar_%d_%d_%d',directionParams.baseName,round(10*directionParams.fieldSizeDegrees),round(10*directionParams.pupilDiameterMm),round(1000*directionParams.baseModulationContrast));
        end
        
        function directionStruct = OLDirectionNominalStructFromParams(directionParams, calibration, varargin)
            % DEPRECATED! USE OLDIRECTIONNOMINALFROMPARAMS INSTEAD
            
            % Generate a parameterized direction from the given parameters
            %
            % Syntax:
            %   directionStruct = OLDirectionNominalStructFromParams(OLDirectionParams_Bipolar, calibration)
            %   directionStruct = OLDirectionNominalStructFromParams(OLDirectionParams_Bipolar, calibration, backgroundPrimary)
            %   directionStruct = OLDirectionNominalStructFromParams(..., 'observerAge', obseverAge)
            %
            % Description:
            %
            % Inputs:
            %    directionParams   - OLDirectionParams_Bipolar object
            %                        defining the parameters for a unipolar
            %                        direction
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
            %    03/22/18  jv  deprecated, moved to
            %                  OLDirectionNominalFromParams. Keep as
            %                  wrapper around that method, for legacy.
            
            warning('This function has been deprecated! Use OLDirectionNominalFromParams instead');
            [direction, background] = OLDirectionNominalFromParams(directionParams, calibration, varargin{:});
            directionStruct.backgroundPrimary = background.differentialPrimaryValues;
            directionStruct.differentialPositive = direction.differentialPositive;
            directionStruct.differentialNegative = direction.differentialNegative;
            directionStruct.calibration = calibration;
            directionStruct.describe = direction.describe;
        end
        
        function [direction, background] = OLDirectionNominalFromParams(directionParams, calibration, varargin)
            % Generate a parameterized OLDirection object from the given parameters
            %
            % Syntax:
            %   direction = OLDirectionNominalFromParams(OLDirectionParams_bipolar, calibration)
            %   [direction, background] = OLDirectionNominalFromParams(OLDirectionParams_bipolar, calibration)
            %   direction = OLDirectionNominalFromParams(OLDirectionParams_bipolar, calibration, background)
            %   direction = OLDirectionNominalFromParams(..., 'observerAge', observerAge)
            %
            % Description:
            %
            % Inputs:
            %    directionParams - OLDirectionParams_bipolar object
            %                      defining the parameters for a unipolar
            %                      direction
            %    calibration     - OneLight calibration struct
            %    background      - [OPTIONAL] OLDirection_unipolar object
            %                      specifying the background to build this
            %                      direction around
            %
            % Outputs:
            %    direction       - an OLDirection_bipolar object
            %                      corresponding to the parameterized
            %                      direction
            %    background      - an OLDirection_unipolar object
            %                      corresponding to the optimized
            %                      background for the parameterized
            %                      direction
            %
            % Optional key/value pairs:
            %    observerAge     - (vector of) observer age(s) to
            %                      generate direction for. When
            %                      numel(observerAge > 1), output
            %                      directionStruct will still be of size
            %                      [1,60], so that the index is the
            %                      observerAge. When numel(observerAge ==
            %                      1), directionStruct will be a single
            %                      struct. Default is 20:60.
            %
            % See also:
            %    OLDirection_bipolar, OLBackgroundNominalFromParams,
            %    OLDirectionParamsDictionary
            
            % History:
            %    01/31/18  jv  wrote it, based on OLWaveformFromParams and
            %                  OLReceptorIsolateMakeDirectionNominalPrimaries
            %    02/12/18  jv  inserted in OLDirectionParams_ classes.
            %    03/22/18  jv  adapted to produce OLDirection objects
            
            %% Input validation
            parser = inputParser();
            parser.addRequired('directionParams',@(x) isstruct(x) || isa(x,'OLDirectionParams'));
            parser.addRequired('calibration',@isstruct);
            parser.addOptional('background',[],@isnumeric);
            parser.addParameter('verbose',false,@islogical);
            parser.addParameter('observerAge',1:60,@isnumeric);
            parser.parse(directionParams,calibration,varargin{:});
            
            %% Set some params
            % Pull out the 'M' matrix
            B_primary = calibration.computed.pr650M;
            
            % Wavelength sampling
            S = calibration.describe.S;
            
            % Assign a zero 'ambientSpd' variable if we're not using the
            % measured ambient.
            if directionParams.useAmbient
                ambientSpd = calibration.computed.pr650MeanDark;
            else
                ambientSpd = zeros(size(B_primary,1),1);
            end
            
            % Peg desired contrasts
            desiredContrasts = directionParams.modulationContrast;
            
            %% Get / make background
            if isempty(parser.Results.background) % No primary specified in call
                if isempty(directionParams.background) % No primary specified in params
                    if isempty(directionParams.backgroundParams) % No params specified
                        assert(isprop(directionParams,'backgroundName') && ~isempty(directionParams.backgroundName),'No background, backgroundParams, or backgroundName specified')
                        
                        % Get backgroundParams from stored name
                        directionParams.backgroundParams = OLBackgroundParamsFromName(directionParams.backgroundName);
                    end
                    
                    % Make backgroundPrimary from params
                    directionParams.background = OLBackgroundNominalFromParams(directionParams.backgroundParams, calibration);
                end
                
                % Use background stored in directionParams
                background = directionParams.background;
            else
                % Use background specified in function call
                background = parser.Results.background;
            end
            
            backgroundSPD = background.ToPredictedSPD;
            
            %% Set up receptors
            % Get fraction bleached for background we're actually using
            if (directionParams.doSelfScreening)
                fractionBleached = OLEstimateConePhotopigmentFractionBleached(S,backgroundSPD,directionParams.pupilDiameterMm,directionParams.fieldSizeDegrees,observerAgeInYears,directionParams.photoreceptorClasses);
            else
                fractionBleached = zeros(1,length(directionParams.photoreceptorClasses));
            end
            
            % Get lambda max shift. Currently not passed but could be.
            lambdaMaxShift = [];
            
            for observerAgeInYears = parser.Results.observerAge
                % Construct the receptor matrix based on the bleaching fraction to this background.
                directionParams.T_receptors = GetHumanPhotoreceptorSS(S,directionParams.photoreceptorClasses,directionParams.fieldSizeDegrees,observerAgeInYears,directionParams.pupilDiameterMm,lambdaMaxShift,fractionBleached);
                
                %% Determine primary values for modulation positive endpoint
                initialPrimary = background.differentialPrimaryValues;
                modulationPrimaryPositive = ReceptorIsolate(directionParams.T_receptors, directionParams.whichReceptorsToIsolate, ...
                    directionParams.whichReceptorsToIgnore,directionParams.whichReceptorsToMinimize,B_primary,background.differentialPrimaryValues,...
                    initialPrimary,directionParams.whichPrimariesToPin,directionParams.primaryHeadRoom,directionParams.maxPowerDiff,...
                    desiredContrasts,ambientSpd);
                
                %% Convert to unipolar direction
                % Negative arm becomes background primary
                differentialPositive = modulationPrimaryPositive - background.differentialPrimaryValues;
                differentialNegative = -differentialPositive;
                
                %% Create direction object
                describe.observerAge = observerAgeInYears;
                describe.directionParams = directionParams;
                describe.background = background;
                direction(observerAgeInYears) = OLDirection_bipolar(differentialPositive, differentialNegative, calibration, describe);
                
                %% Check gamut
                modulationPositive = background + direction(observerAgeInYears);
                modulationNegative = background - direction(observerAgeInYears);
                if any(modulationPositive.differentialPrimaryValues > 1)  || any(modulationPositive.differentialPrimaryValues < 0)
                    error('Out of bounds.')
                end
                if any(modulationNegative.differentialPrimaryValues > 1)  || any(modulationNegative.differentialPrimaryValues < 0)
                    error('Out of bounds.')
                end
            end
            
            if numel(parser.Results.observerAge) == 1
                % Return just the single OLDirection
                direction = direction(parser.Results.observerAge);
            end
        end
        
        
        function valid = OLDirectionParamsValidate(directionParams)
            valid = true;
        end
    end
    
end