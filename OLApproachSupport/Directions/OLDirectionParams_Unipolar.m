classdef OLDirectionParams_Unipolar < OLDirectionParams
    % Parameter-object for Unipolar directions
    %   Detailed explanation goes here
    
    properties
        photoreceptorClasses = {'LConeTabulatedAbsorbance'  'MConeTabulatedAbsorbance'  'SConeTabulatedAbsorbance'  'Melanopsin'};
        fieldSizeDegrees(1,1) = 27.5;
        pupilDiameterMm(1,1) = 8.0;
        
        % These have to do with the original way we search
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
        
        % When we are doing chrom/lum constraint, we use these parameters.
        T_receptors = [];
        targetContrast = [];
        whichXYZ = '';
        desiredxy = [];
        desiredLum = [];
        search(1,1) struct = struct([]); 
    end
    
    methods
        function obj = OLDirectionParams_Unipolar
            obj.primaryHeadRoom = .005;
        end
        
        function name = OLDirectionNameFromParams(directionParams)
            name = sprintf('%s_unipolar_%d_%d_%d',directionParams.baseName,round(10*directionParams.fieldSizeDegrees),round(10*directionParams.pupilDiameterMm),round(1000*directionParams.baseModulationContrast));
        end
        
        function [direction, background] = OLDirectionNominalFromParams(directionParams, calibration, varargin)
            % Generate a parameterized OLDirection object from the given parameters
            %
            % Syntax:
            %   direction = OLDirectionNominalFromParams(OLDirectionParams_unipolar, calibration)
            %   [direction, background] = OLDirectionNominalFromParams(OLDirectionParams_unipolar, calibration)
            %   direction = OLDirectionNominalFromParams(OLDirectionParams_unipolar, calibration, background)
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
            % See also:
            %    OLDirection_unipolar, OLBackgroundNominalFromParams,
            %    OLDirectionParamsDictionary
            
            % History:
            %    01/31/18  jv  Wrote it, based on OLWaveformFromParams and
            %                  OLReceptorIsolateMakeDirectionNominalPrimaries
            %    02/12/18  jv  Inserted in OLDirectionParams_ classes.
            %    03/22/18  jv  Adapted to produce OLDirection objects
            %    04/01/18  dhb Override age passed to background from
            %                  params with age used here. Also
            %                  alternateBackgroundDictionaryFunc.
            
            %% Input validation
            parser = inputParser();
            parser.addRequired('directionParams',@(x) isa(x,'OLDirectionParams'));
            parser.addRequired('calibration',@isstruct);
            parser.addOptional('background',[],@(x) isempty(x) || isa(x,'OLDirection_unipolar'));
            parser.addParameter('verbose',false,@islogical);
            parser.addParameter('observerAge',32,@isnumeric);
            parser.addParameter('alternateBackgroundDictionaryFunc','',@ischar);               
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
                        assert(isprop(directionParams,'backgroundName') && ~isempty(directionParams.backgroundName), ...
                            'No background, backgroundParams, or backgroundName specified')
                        
                        % Get backgroundParams from stored name
                        directionParams.backgroundParams = OLBackgroundParamsFromName(directionParams.backgroundName, ...
                            'alternateDictionaryFunc',parser.Results.alternateBackgroundDictionaryFunc);
                    end
                    
                    % Make backgroundPrimary from params, using local
                    % observer age if there is just one, otherwise whatever
                    % is in the background structure.
                    backgroundParamsTemp = directionParams.backgroundParams;
                    if (length(parser.Results.observerAge) == 1)
                        backgroundParamsTemp.backgroundObserverAge = parser.Results.observerAge;
                    end
                    directionParams.background = OLBackgroundNominalFromParams(backgroundParamsTemp, calibration);
                    clear backgroundParamsTemp
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
                
                % Determine primary values using unipolar method
                if (~isempty(directionParams.targetContrast))
                    % Check
                    if (~strcmp(directionParams.search.optimizationTarget,'receptorContrast'))
                        error('If we are here we need param.search and for the optimization target to be ''receptorContrast''');
                    end
                    
                    [modulationPrimaryPositive,~,~,~] = OLPrimaryInvSolveChrom(calibration, directionParams.desiredxy, ...
                        'desiredLum', directionParams.desiredLum, ...
                        'optimizationTarget',directionParams.search.optimizationTarget,'T_receptors',directionParams.T_receptors,'targetContrast',directionParams.targetContrast, ... 
                        'backgroundPrimary',background.differentialPrimaryValues, ...     
                        directionParams.search);
                    
                    % Convert to unipolar direction
                    % Background is already OK here and doesn't need to be tweaked.
                    differentialPrimaryValues = modulationPrimaryPositive - background.differentialPrimaryValues;
                
                % Determine primary values for modulation positive endpoint
                % using bipolar method
                else 
                    initialPrimary = background.differentialPrimaryValues;
                    modulationPrimaryPositive = ReceptorIsolate(directionParams.T_receptors, directionParams.whichReceptorsToIsolate, ...
                        directionParams.whichReceptorsToIgnore,directionParams.whichReceptorsToMinimize,B_primary,background.differentialPrimaryValues,...
                        initialPrimary,directionParams.whichPrimariesToPin,directionParams.primaryHeadRoom,directionParams.maxPowerDiff,...
                        desiredContrasts,ambientSpd);
                    
                    % Convert to unipolar direction
                    differentialPrimaryValues = modulationPrimaryPositive - background.differentialPrimaryValues;
                    
                    % Negative arm of bipolar modulation becomes background primary
                    background = OLDirection_unipolar(background.differentialPrimaryValues-differentialPrimaryValues,calibration,background.describe);
                    differentialPrimaryValues = modulationPrimaryPositive - background.differentialPrimaryValues;
                end
                    
                % Create direction object
                describe.observerAge = observerAgeInYears;
                describe.directionParams = directionParams;
                describe.backgroundNominal = background.copy();
                describe.background = background;
                direction(observerAgeInYears) = OLDirection_unipolar(differentialPrimaryValues, calibration, describe);

                %% Check gamut
                modulation = background + direction(observerAgeInYears);
                if any(modulation.differentialPrimaryValues > 1)  || any(modulation.differentialPrimaryValues < 0)
                    error('Out of bounds.')
                    
                end
            end
            
            % Return just the single OLDirection
            % rather than an array,if there is only one direction
            if numel(parser.Results.observerAge) == 1
                direction = direction(parser.Results.observerAge);
            end
        end
        
        function valid = OLDirectionParamsValidate(directionParams)
            valid = true;
        end
    end
    
end