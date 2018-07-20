classdef OLDirectionParams_LightFluxChrom < OLDirectionParams
    % Parameter-object for LightFluxChrom directions
    %   Detailed explanation goes here
    
    properties
        desiredxy(1,2) = [0.333 0.333];                                    % Modulation chromaticity.
        whichXYZ(1,:) char = 'xyzCIEPhys10';                               % Which XYZ cmfs.
        desiredMaxContrast(1,1) = 1;                                       % Size of max contrast
        desiredLum(1,1) = 200;                                             % Desired background luminance in cd/m2.
        polarType(1,:) char = 'unipolar';                                  % Unipolar or bipolar light flux direction
        search(1,1) struct = struct([]);                                   % Primary search parameter struct  
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
            % Generate a parameterized light flux OLDirection object from the given parameters
            %
            % Syntax:
            %   direction = OLDirectionNominalFromParams(OLDirectionParams_LightFluxChrom, calibration)
            %   [direction, background] = OLDirectionNominalFromParams(OLDirectionParams_LightFluxChrom, calibration)
            %   direction = OLDirectionNominalFromParams(OLDirectionParams_LightFluxChrom, calibration, background)
            %
            % Description:
            %    Make a light flux direction object given the parameters.
            %
            %    The most straightforward way to call this is not to
            %    provide a background but to let this routine find it.  Do
            %    that by not having a background field in the passed
            %    directionParams and not setting the background key/value
            %    pair.  That causes a call to OLPrimaryInvSolveChrom to try
            %    to find in gamut light flux modulations with the desired
            %    properties.
            %
            %    The code that works with a passed background is not well
            %    tested.
            %
            % Inputs:
            %    directionParams - OLDirectionParams_Unipolar object
            %                      defining the parameters for a unipolar
            %                      direction
            %    calibration     - OneLight calibration struct
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
            %   'background'     - OLDirection_unipolar object (default
            %                      empty) specifying the background to
            %                      build this direction around.
            %   'alternateBackgroundDictionaryFunc' - String with name of alternate dictionary
            %                      function to call to resolve a background
            %                      name. This must be a function on the
            %                      path. Default of empty string results in
            %                      using the dictionary included in the
            %                      OneLightToolbox.
            %
            % See also:
            %    OLDirection_unipolar, OLDirectionParamsDictionary
            
            % History:
            %    01/31/18  jv  Wrote it, based on OLWaveformFromParams and
            %                  OLReceptorIsolateMakeDirectionNominalPrimaries
            %    02/12/18  jv  Inserted in OLDirectionParams_ classes.
            %    03/22/18  jv  Adapted to produce OLDirection objects.
            
            %% Input validation
            parser = inputParser();
            parser.addRequired('directionParams',@(x) (isstruct(x) || isa(x,'OLDirectionParams')));
            parser.addRequired('calibration',@isstruct);
            parser.addParameter('background',[],@(x) (isempty(x) || isa(x,'OLDirection_unipolar')));
            parser.addParameter('verbose',false,@islogical);
            parser.addParameter('alternateBackgroundDictionaryFunc','',@ischar);
            parser.parse(directionParams,calibration,varargin{:});
            
            %% Get / make background
            if isempty(parser.Results.background) % No primary specified in call
                if isempty(directionParams.background) % No primary specified in direction params
                    % Construct the primaries directly from
                    % OLPrimaryInvSolveChrom, as well as what it things the
                    % best choice is.
                    [backgroundPrimary,modulationPrimaryPos,modulationPrimaryNeg] = ...
                       OLLightFluxBackgroundNominalPrimaryFromParams(directionParams,calibration);
                    background = OLDirection_unipolar(backgroundPrimary,calibration);
                    background.describe.params = directionParams;
                    % [directionParams.background,maxBackgroundPrimary,minBackgroundPrimary] = OLBackgroundNominalFromParams(directionParams.backgroundParams, calibration);
                else 
                    % Use background stored in directionParams
                    background = directionParams.background;
                end
            else
                % Use background specified in key/value pair
                background = parser.Results.background;
            end
            
            %% Make direction
            switch (directionParams.polarType)                   
                case 'unipolar'
                    % If we created the background in this routine, then we
                    % also created the modulation and our work is done.
                    % All that is necessary is to put things in the right
                    % place. If not, we do our best.
                    if (~exist('modulationPrimaryPos','var'))
                        % If we were handed a background, we know what
                        % positive modulation we want, and we use
                        % OLSpdTOPrimary to try to produce it.
                        backgroundPrimary = background.differentialPrimaryValues;
                        targetSpdPos = OLPrimaryToSpd(calibration,backgroundPrimary)*(1 + directionParams.desiredMaxContrast);
                        modulationPrimaryPos = OLSpdToPrimary(calibration,targetSpdPos, ...
                            'lambda',directionParams.search.lambda,'primaryHeadroom',directionParams.search.primaryHeadroom);
                    end
                    
                    % Get differential primary from modulation primary
                    differentialPrimaryPos = modulationPrimaryPos - background.differentialPrimaryValues;
                    
                    % Create direction object
                    describe.directionParams = directionParams;
                    describe.backgroundNominal = background.copy();
                    describe.background = background;
                    direction = OLDirection_unipolar(differentialPrimaryPos, calibration, describe);
                    
                case 'bipolar'
                     % If we created the background in this routine, then we
                    % also created the modulation and our work is done.
                    % All that is necessary is to put things in the right
                    % place. If not, we do our best.
                    if (~exist('modulationPrimaryPos','var'))
                        % If we were handed a background, we know what
                        % positive modulation we want, and we use
                        % OLSpdTOPrimary to try to produce it.
                        backgroundPrimary = background.differentialPrimaryValues;
                        targetSpdPos = OLPrimaryToSpd(calibration,backgroundPrimary)*(1 + directionParams.desiredMaxContrast);
                        targetSpdNeg = OLPrimaryToSpd(calibration,backgroundPrimary)*(1 - directionParams.desiredMaxContrast);
                        modulationPrimaryPos = OLSpdToPrimary(calibration,targetSpdPos, ...
                            'lambda',directionParams.search.lambda,'primaryHeadroom',directionParams.search.primaryHeadroom);
                        modulationPrimaryNeg = OLSpdToPrimary(calibration,targetSpdNeg, ...
                            'lambda',directionParams.search.lambda,'primaryHeadroom',directionParams.search.primaryHeadroom);
                    end
                              
                    % Update background
                    differentialPrimaryPos = modulationPrimaryPos -  background.differentialPrimaryValues;
                    differentialPrimaryNeg = modulationPrimaryNeg -  background.differentialPrimaryValues;
               
                    % Create direction object
                    describe.directionParams = directionParams;
                    describe.backgroundNominal = background.copy();
                    describe.background = background;
                    direction = OLDirection_bipolar(differentialPrimaryPos, differentialPrimaryNeg, calibration, describe);
                    
                otherwise
                    error('Unknown polarType specified');
            end
        end
        
        function [backgroundPrimary,modulationPrimaryPos,modulationPrimaryNeg] = OLLightFluxBackgroundNominalPrimaryFromParams(params,calibration)
            % Generate nominal primary for these parameters, for calibration
            %
            % Syntax:
            %   [backgroundPrimary,modulationPrimaryPos,modulationPrimaryNeg] = OLLightFluxBackgroundNominalPrimaryFromParams(params,calibration);
            %
            % Description:
            %    Generate the nominal primary values that would correspond
            %    to best approximation to the background, for the given parameters,
            %    under the given calibration.
            %
            %    Background at specified chromaticity that allows a large
            %    light flux pulse modulation.  This is found using
            %    OLPrimaryInvSolveChrom.  That routine returns primaries
            %    that maximize contrast at a desired chromaticity and that
            %    represent a light flux modulation.  We can then find
            %    primaries for a background spd in between these, which is
            %    done using OLSpdToPrimary. This results in the returned
            %    backgroundPrimary.
            %
            %    We also return the primary values (minBackgroundPrimary and
            %    maxBackgroundPrimary that were found directly in the
            %    search.  Because OLSpdToPrimary has some error in what it
            %    returns, it can sometimes be better to use these directly
            %    when constructing light flux directions.
            %
            % Inputs:
            %    params            - OLDIrectionParams_LightFluxChrom
            %                        defining the parameters for the light
            %                        flux modulation that we want.  This is
            %                        the informaiton we need to produce the
            %                        backgound.
            %    calibration       - OneLight calibration struct
            %
            % Outputs:
            %    backgroundPrimary - Column vector of primary values for
            %                        the background.
            %    minBackgroundPrimary - Column vector of primary values for
            %                        the low end of what was found by
            %                        OLPrimaryInvSolveChrom.
            %    maxBackgroundPrimary - Column vector of primary values for
            %                        the high end of what was found by
            %                        OLPrimayInvSolveChrom.
            %
            % Optional key/value pairs:
            %    None.
            %
            % See also: OLPrimaryInvSolveChrom, OLSpdToPrimary.
            
            % Input validation
            parser = inputParser();
            parser.addRequired('params',@(x) isa(x,'OLDirectionParams_LightFluxChrom'));
            parser.addRequired('calibration',@isstruct);
            parser.parse(params,calibration);
            
            % Generate background
            [maxBackgroundPrimary, minBackgroundPrimary, maxLum, minLum]  = ...
                OLPrimaryInvSolveChrom(calibration, params.desiredxy, ...
                'whichXYZ',params.whichXYZ, 'targetContrast', [], ...
                params.search);
            %{
            fprintf('Max lum %0.2f, min lum %0.2f\n',maxLum,minLum);
            fprintf('Luminance weber contrast, low to high: %0.2f%%\n',100*(maxLum-minLum)/minLum);
            fprintf('Luminance michaelson contrast, around mean: %0.2f%%\n',100*(maxLum-minLum)/(maxLum+minLum));
            %}
                
            % Get background spd
            maxBackgroundSpd = OLPrimaryToSpd(calibration,maxBackgroundPrimary);
            minBackgroundSpd = OLPrimaryToSpd(calibration,minBackgroundPrimary);
            
            % Find range of background luminances over which we could get
            % desired contrast
            desiredBackgroundLum = params.desiredLum;
           
            
            switch (params.polarType)
                case 'unipolar'
                    % The purpose of these next bits is to try to keep the
                    % background luminance as close as possible to the
                    % desired level, but not to sacrifice contrast.
                    %
                    % First get range of background luminances that will
                    % let us produce desired unipolar contrast.
                    maxFeasibleBackgrounLum = maxLum/(1 + params.desiredMaxContrast);
                    if (maxFeasibleBackgrounLum < minLum)
                        maxFeasibleBackgrounLum = minLum;
                    end
                    minFeasibleBackgroundLum = minLum;
            
                    % Get as close as we can for background luminance
                    if (desiredBackgroundLum < minFeasibleBackgroundLum)
                        useBackgroundLum = minLum;
                    elseif (desiredBackgroundLum < maxFeasibleBackgrounLum)
                        useBackgroundLum = desiredBackgroundLum;
                    else
                        useBackgroundLum = maxFeasibleBackgrounLum;
                    end
                    
                    % Then set modulation luminance
                    desiredModulationLumPos = useBackgroundLum*(1 + params.desiredMaxContrast);
                    if (desiredModulationLumPos < maxLum)
                        useModulationLumPos = desiredModulationLumPos;
                    else
                        useModulationLumPos = maxLum;
                    end
                    
                    % Get the desired spds.
                    targetBackgroundSpd = maxBackgroundSpd*(useBackgroundLum/maxLum);
                    targetModulationSpdPos = maxBackgroundSpd*(useModulationLumPos/maxLum);

                    % Convert desired spd back to primary space.
                    % 
                    % This counts on OLSpdToPrimary being able to produce
                    % primaries that lead to the desired spds.  This should
                    % be possible, because by the time we get here we
                    % should have guaranteed that both min and max spds are
                    % in gamut.  But, this has been a bit fussy in the
                    % past.
                    [backgroundPrimary,predBackgroundSpd,fractionalErrorBg] = OLSpdToPrimary(calibration,targetBackgroundSpd, ...
                        'primaryHeadroom',params.search.primaryHeadroom,'primaryTolerance',params.search.primaryTolerance, ...
                        'lambda',params.search.lambda, 'checkSpd',false, ...
                        'spdToleranceFraction',params.search.spdToleranceFraction, ...
                        'verbose',params.search.verbose);

                    [modulationPrimaryPos,predModulationSpdPos,fractionalErrorPos] = OLSpdToPrimary(calibration,targetModulationSpdPos, ...
                        'primaryHeadroom',params.search.primaryHeadroom,'primaryTolerance',params.search.primaryTolerance, ...
                        'lambda',params.search.lambda, 'checkSpd',false, ...
                        'spdToleranceFraction',params.search.spdToleranceFraction, ...
                        'verbose',params.search.verbose);
                    
                    modulationPrimaryNeg = [];
                    
                case 'bipolar'
                    % The purpose of these next bits is to try to keep the
                    % background luminance as close as possible to the
                    % desired level, but not to sacrifice contrast.
                    %
                    % First get range of background luminances that will
                    % let us produce desired bipolar contrast.
                    maxFeasibleBackgrounLum = maxLum/(1 + params.desiredMaxContrast);
                    if (maxFeasibleBackgrounLum < minLum)
                        maxFeasibleBackgrounLum = minLum;
                    end
                    minFeasibleBackgroundLum = minLum/(1 - params.desiredMaxContrast);
                    if (minFeasibleBackgroundLum > maxLum)
                        minFeasibleBackgroundLum = maxLum;
                    end
                    
                    if (desiredBackgroundLum >= minFeasibleBackgroundLum & ...
                            desiredBackgroundLum <= maxFeasibleBackgroundLum)
                        useBackgroundLum = desiredBackgroundLum;    
                    elseif (desiredBackgroundLum < minFeasibleBackgroundLum)
                        useBackgroundLum = minFeasibleBackgroundLum;
                    else
                        useBackgroundLum = maxFeasibleBackgrounLum;
                    end
                    
                    % Then set positive and negative modulation luminances
                    % from background
                    desiredModulationLumPos = useBackgroundLum*(1 + params.desiredMaxContrast);
                    if (desiredModulationLumPos < maxLum)
                        useModulationLumPos = desiredModulationLumPos;
                    else
                        useModulationLumPos = maxLum;
                    end
                    desiredModulationLumNeg = useBackgroundLum*(1 - params.desiredMaxContrast);
                    if (desiredModulationLumNeg > minLum)
                        useModulationLumNeg = desiredModulationLumNeg;
                    else
                        useModulationLumNeg = minLum;
                    end
                    
                    % Get the desired spds
                    targetBackgroundSpd = maxBackgroundSpd*(useBackgroundLum/maxLum);
                    targetModulationSpdPos = maxBackgroundSpd*(useModulationLumPos/maxLum);
                    targetModulationSpdNeg = maxBackgroundSpd*(useModulationLumNeg/maxLum);

                    % Convert desired spd back to primary space.
                    % 
                    % This counts on OLSpdToPrimary being able to produce
                    % primaries that lead to the desired spds.  This should
                    % be possible, because by the time we get here we
                    % should have guaranteed that both min and max spds are
                    % in gamut.  But, this has been a bit fussy in the
                    % past.
                    [backgroundPrimary,predBackgroundSpd,fractionalErrorBg] = OLSpdToPrimary(calibration,targetBackgroundSpd, ...
                        'primaryHeadroom',params.search.primaryHeadroom,'primaryTolerance',params.search.primaryTolerance, ...
                        'lambda',params.search.lambda, 'checkSpd',false, ...
                        'spdToleranceFraction',params.search.spdToleranceFraction, ...
                        'verbose',params.search.verbose);

                    [modulationPrimaryPos,predModulationSpdPos,fractionalErrorPos] = OLSpdToPrimary(calibration,targetModulationSpdPos, ...
                        'primaryHeadroom',params.search.primaryHeadroom,'primaryTolerance',params.search.primaryTolerance, ...
                        'lambda',params.search.lambda, 'checkSpd',false, ...
                        'spdToleranceFraction',params.search.spdToleranceFraction, ...
                        'verbose',params.search.verbose);
                    
                    [modulationPrimaryNeg,predModulationSpdNeg,fractionalErrorNeg] = OLSpdToPrimary(calibration,targetModulationSpdNeg, ...
                        'primaryHeadroom',params.search.primaryHeadroom,'primaryTolerance',params.search.primaryTolerance, ...
                        'lambda',params.search.lambda, 'checkSpd',false, ...
                        'spdToleranceFraction',params.search.spdToleranceFraction, ...
                        'verbose',params.search.verbose);
                    
                otherwise
                    error('Unknown background polarType property provided');
            end
        end
        
        function valid = OLDirectionParamsValidate(params)
            % Validate passed background parameters
            %
            % Syntax:
            %   valid = OLDirectionParamsValidate(entry)
            %
            % Description:
            %    This function checks whether a given
            %    OLDirectionParams_LightFluxChrom has valid values in all
            %    properties. Throws an error if a property contains an
            %    unexpected value.
            %
            % Inputs:
            %    params - OLDirectionParams_LightFluxChrom defining the
            %             parameters for this LightFluxChrom direction.
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
                property = 'desiredxy';
                mustBeNumeric(params.(property));
                mustBeNonnegative(params.(property));
                mustBeLessThanOrEqual(params.(property),1);
                
                % Validate lightFluxDownFactor
                property = 'desiredMaxContrast';
                mustBePositive(params.(property));
                
                % Validate desired background luminance
                property = 'desiredLum';
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