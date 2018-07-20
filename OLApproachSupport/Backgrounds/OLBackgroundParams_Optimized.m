classdef OLBackgroundParams_Optimized < OLBackgroundParams
% Parameter-object for optimized backgrounds
%
% Syntax:
%   params = OLBackgroundParams_Optimized
%   backgroundPrimary = OLBackgroundNominalPrimaryFromParams(OLBackgroundParams_OptimizedObject,calibration)
%
% Description:
%    The 'optimized' backgrounds are specific to a direction of modulation,
%    for which they provide the maximum (bipolar) contrast. They are
%    generated using the SilentSubstitutionToolbox. Backgrounds are
%    optimized with respect to a backgroundObserverAge year old observer,
%    and no correction for photopigment bleaching is applied. We are just
%    trying to get pretty good backgrounds, so we don't need to fuss with
%    small effects.
%
% See also:
%    OLBackgroundParams, OLBackgroundParams_LightFluxChrom
%

% History:
%    02/07/18  jv  wrote it.
    
    properties
        pegBackground(1,1) logical = false;                                 % Passed to the routine that optimizes backgrounds.
        baseModulationContrast;                                             % Legacy, for naming.
        photoreceptorClasses = ...                                          % Names of photoreceptor classes being considered.
            {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
        fieldSizeDegrees(1,1) = 27.5;                                       % Field size used in background seeking. Affects fundamentals.
        pupilDiameterMm(1,1) = 8.0;                                         % Pupil diameter used in background seeking. Affects fundamentals.
        backgroundObserverAge(1,1) = 32;                                    % Observer age used in background seeking. Affects fundamentals.
        maxPowerDiff(1,1) = 0.1;                                            % Smoothing parameter for routine that finds backgrounds.
        modulationContrast = [];                                            % Vector of constrasts sought in isolation.
        whichReceptorsToIsolate = {[]};                                    % Which receptor classes are not being silenced.
        whichReceptorsToIgnore = {[]};                                      % Receptor classes ignored in calculations.
        whichReceptorsToMinimize = {[]};                                    % These receptors are minimized in contrast, subject to other constraints.
        directionsYoked = [0];                                              % See ReceptorIsolate.
        directionsYokedAbs = [0];                                           % See ReceptorIsolate.
        
        % When we are doing chrom/lum constraint, we use these parameters.
        T_receptors = [];
        targetContrast = [];
        whichXYZ = '';
        desiredxy = [];
        desiredLum = [];
        search(1,1) struct = struct([]); 
    end
    
    methods
        function obj = OLBackgroundParams_Optimized
            obj = obj@OLBackgroundParams;
        end
        
        function name = OLBackgroundNameFromParams(params)
        	name = sprintf('%s_%d_%d_%d',params.baseName,round(10*params.fieldSizeDegrees),round(10*params.pupilDiameterMm),round(1000*params.baseModulationContrast));
        end
        
        function backgroundPrimary = OLBackgroundNominalPrimaryFromParams(params, calibration)
            % Generate nominal primary for these parameters, for calibration
            %
            % Syntax:
            %   backgroundPrimary = MakeNominalPrimary(OLBackgroundParams_Optimized,calibration);
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
            %    backgroundPrimary - column vector of primary values for
            %                        the background
            %
            % Optional key/value pairs:
            %    None.
            %
            
            % Input validation
            parser = inputParser();
            parser.addRequired('params',@(x) isa(x,'OLBackgroundParams_Optimized'));
            parser.addRequired('calibration',@isstruct);
            parser.parse(params,calibration);
            
            % Pull out the 'M' matrix as device primaries
            B_primary = calibration.computed.pr650M;
            
            %% Set up parameters for the optimization
            whichPrimariesToPin = [];
            
            % Peg desired contrasts
            if ~isempty(params.modulationContrast)
                desiredContrasts = params.modulationContrast;
            else
                desiredContrasts = [];
            end
            
            % Assign a zero 'ambientSpd' variable if we're not using the
            % measured ambient.
            if params.useAmbient
                ambientSpd = calibration.computed.pr650MeanDark;
            else
                ambientSpd = zeros(size(B_primary,1),1);
            end
            
            %% Initial background
            %
            % Start at mid point of primaries.
            initialPrimary = 0.5*ones(size(B_primary,2),1);
            
            %% Construct the receptor matrix
            lambdaMaxShift = zeros(1, length(params.photoreceptorClasses));
            fractionBleached = zeros(1,length(params.photoreceptorClasses));
            T_receptors = GetHumanPhotoreceptorSS(calibration.describe.S, params.photoreceptorClasses, params.fieldSizeDegrees, params.backgroundObserverAge, params.pupilDiameterMm, lambdaMaxShift, fractionBleached);
            
            %% Find the background. We have more than one way of doing this.
            %
            % Find the background through unipolar optimization
            if (~isempty(params.targetContrast))
                % Check
                if (~strcmp(params.search.optimizationTarget,'receptorContrast'))
                    error('If we are here we need param.search and for the optimization target to be ''receptorContrast''');
                end
                              
                [maxPrimary,backgroundPrimary,maxLum,minLum] = OLPrimaryInvSolveChrom(calibration, params.desiredxy, ...
                    'desiredLum', params.desiredLum, 'whichXYZ', params.whichXYZ, ...
                    'optimizationTarget',params.search.optimizationTarget,'T_receptors',T_receptors,'targetContrast',params.targetContrast, ...
                    params.search);
                
                % Pull out what we want
                backgroundPrimary = backgroundPrimary;
                
            % Find the background through bipolar method
            else
                optimizedBackgroundPrimaries = ReceptorIsolateOptimBackgroundMulti(T_receptors, params.whichReceptorsToIsolate, ...
                    params.whichReceptorsToIgnore,params.whichReceptorsToMinimize,B_primary,initialPrimary,...
                    initialPrimary,whichPrimariesToPin,params.primaryHeadRoom,params.maxPowerDiff,...
                    desiredContrasts,ambientSpd,params.directionsYoked,params.directionsYokedAbs,params.pegBackground);
                
                % Pull out what we want
                backgroundPrimary = optimizedBackgroundPrimaries{1};
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
            %    03/22/18  jv  OLDirection_unipolar from backgroundParams
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
                % Validate pegBackground
                property = ('pegBackground');
                mustBeNonempty(params.(property));
                
                % Validate fieldSizeDegrees
                property = ('fieldSizeDegrees');
                mustBeNonempty(params.(property));
                mustBePositive(params.(property));                
                
                % Validate pupilDiameterMm
                property = ('pupilDiameterMm');
                mustBeNonempty(params.(property));
                mustBePositive(params.(property));                
                
                % Validate backgroundObserverAge
                property = ('backgroundObserverAge');
                mustBeNonempty(params.(property));
                mustBeInteger(params.(property));
                mustBePositive(params.(property));
                
                % Validate maxPowerDiff
                property = ('maxPowerDiff');
                mustBeNonempty(params.(property)); 
                mustBeNonnegative(params.(property));
                mustBeLessThanOrEqual(params.(property),1);
                
                % Validate whichReceptorsToIsolate
                property = ('whichReceptorsToIsolate');
                assert(iscell(params.(property)),'Value must be cell');
                mustBeNonempty(params.(property));
                
                % Validate modulationContrast
                property = ('modulationContrast');
                % mustBeNonempty(params.(property));
                
                % Validate whichReceptorsToMinimize
                property = ('whichReceptorsToMinimize');
                assert(iscell(params.(property)),'Value must be cell');     
                
                % Validate whichReceptorsToIgnore
                property = ('whichReceptorsToIgnore');
                assert(iscell(params.(property)),'Value must be cell');          
                
                % Validate directionsYokedAbs
                property = ('directionsYokedAbs');
                % mustBeInteger(params.(property));
                % mustBeLessThanOrEqual(numel(params.(property)), numel(params.photoreceptorClasses));   
                
                % Validate directionsYoked
                property = ('directionsYoked');
                % mustBeInteger(params.(property));
                % mustBeLessThanOrEqual(numel(params.(property)), numel(params.photoreceptorClasses));    

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