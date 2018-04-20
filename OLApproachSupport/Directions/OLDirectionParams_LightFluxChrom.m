classdef OLDirectionParams_LightFluxChrom < OLDirectionParams
    % Parameter-object for LightFluxChrom directions
    %   Detailed explanation goes here
    
    properties
        desiredxy(1,2) = [0.333 0.333];                                    % Modulation chromaticity.
        whichXYZ(1,:) char = 'xyzCIEPhys10';                               % Which XYZ cmfs.
        desiredMaxContrast(1,1) = 1;                                       % Size of max contrast
        desiredBackgroundLuminance(1,1) = 200;                              % Desired background luminance in cd/m2.
        polarType(1,:) char = 'unipolar';                                  % Unipolar or bipolar light flux direction
        search(1,1) struct = struct([]);                                    % Primary search parameter struct

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
            %
            %   'background'     - [OLDirection_unipolar object (default
            %                      empty) specifying the background to
            %                      build this direction around
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
            parser.addRequired('directionParams',@(x) isstruct(x) || isa(x,'OLDirectionParams'));
            parser.addRequired('calibration',@isstruct);
            parser.addOptional('background',[],@isnumeric);
            parser.addParameter('verbose',false,@islogical);
            parser.addParameter('alternateBackgroundDictionaryFunc','',@ischar);
            parser.parse(directionParams,calibration,varargin{:});
            
            %% Get / make background
            if isempty(parser.Results.background) % No primary specified in call
                if isempty(directionParams.background) % No primary specified in direction params
                    % Grab the primaries directly from
                    % OLPrimaryInvSolveChrom, as well as what it things the
                    % best choice is.
                    [backgroundPrimary,maxBackgroundPrimary,minBackgroundPrimary] = OLBackgroundNominalPrimaryFromParams(directionParams.backgroundParams,calibration);
                    background = OLDirection_unipolar(backgroundPrimary,calibration);
                    background.describe.params = params;
                    [directionParams.background,maxBackgroundPrimary,minBackgroundPrimary] = OLBackgroundNominalFromParams(directionParams.backgroundParams, calibration);
                         
                end
                
                % Use background stored in directionParams
                background = directionParams.background;
            else
                % Use background specified in function call
                background = parser.Results.background;
            end
            
            %% Make direction
            switch (directionParams.polarType)
                case 'unipolar'
                    if (~exist('maxBackgroundPrimary','var'))
                        % Old way
                        backgroundPrimary = background.differentialPrimaryValues;
                        targetSpdPositive = OLPrimaryToSpd(calibration,backgroundPrimary)*(1 + directionParams.desiredMaxContrast);
                        modulationPrimaryPositive = OLSpdToPrimary(calibration,targetSpdPositive,'lambda',directionParams.backgroundParams.search.lambda);
                    else
                        % New way.  Only works if aimed
                        % OLPrimaryInvSolveChrom at the desired target
                        % contrast, which you should do if we decide this
                        % method works.
                        background.differentialPrimaryValues = minBackgroundPrimary;
                        modulationPrimaryPositive = maxBackgroundPrimary;
                        targetSpdPositive = OLPrimaryToSpd(calibration,modulationPrimaryPositive);
                    end
                    
                    % Update background
                    differentialPrimaryPositive = modulationPrimaryPositive - background.differentialPrimaryValues;
                    
                    % Create direction object
                    describe.directionParams = directionParams;
                    describe.backgroundNominal = background.copy();
                    describe.background = background;
                    direction = OLDirection_unipolar(differentialPrimaryPositive, calibration, describe);
                case 'bipolar'
                    backgroundPrimary = background.differentialPrimaryValues;
                    backgroundSpd = OLPrimaryToSpd(calibration,backgroundPrimary);
                    
                    targetSpdPositive = OLPrimaryToSpd(calibration,backgroundPrimary)*(1 + directionParams.desiredMaxContrast);
                    targetSpdNegative = backgroundSpd - (targetSpdPositive-backgroundSpd);
                    
                    modulationPrimaryPositive = OLSpdToPrimary(calibration,targetSpdPositive,'lambda',directionParams.backgroundParams.search.lambda);
                    modulationPrimaryNegative = OLSpdToPrimary(calibration,targetSpdNegative,'lambda',directionParams.backgroundParams.search.lambda);
                    
                    % Update background
                    differentialPrimaryPositive = modulationPrimaryPositive - backgroundPrimary;
                    differentialPrimaryNegative = modulationPrimaryNegative - backgroundPrimary;
                    
                    % Check negative primary does what we want
                    %{
                        predSpdPositive = OLPrimaryToSpd(calibration,backgroundPrimary+differentialPrimaryPositive);
                        predSpdNegative = OLPrimaryToSpd(calibration,backgroundPrimary+differentialPrimaryNegative);
                        figure; clf; hold on;
                        plot(targetSpdNegative,'g','LineWidth',3);
                        plot(predSpdNegative,'k','LineWidth',1);
                        plot(backgroundSpd,'k','LineWidth',3);
                        plot(targetSpdPositive,'r','LineWidth',3);
                        plot(predSpdPositive,'k','LineWidth',1);
                    %}
                    
                    % Create direction object
                    describe.directionParams = directionParams;
                    describe.backgroundNominal = background.copy();
                    describe.background = background;
                    direction = OLDirection_bipolar(differentialPrimaryPositive, differentialPrimaryNegative, calibration, describe);
                    
                otherwise
                    error('Unknown polarType specified');
            end     
        end
        
        function [backgroundPrimary,maxBackgroundPrimary,minBackgroundPrimary] = OLLightFluxBackgroundNominalPrimaryFromParams(params, calibration)
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
            parser.addRequired('params',@(x) isa(x,'OLBackgroundParams_LightFluxChrom'));
            parser.addRequired('calibration',@isstruct);
            parser.parse(params,calibration);
            
            % Generate background
            [maxBackgroundPrimary, minBackgroundPrimary, maxLum, minLum]  = ...
                OLPrimaryInvSolveChrom(calibration, params.desiredxy, ...
                'whichXYZ',params.whichXYZ, ...
                params.search);
            %{
            fprintf('Max lum %0.2f, min lum %0.2f\n',maxLum,minLum);
            fprintf('Luminance weber contrast, low to high: %0.2f%%\n',100*(maxLum-minLum)/minLum);
            fprintf('Luminance michaelson contrast, around mean: %0.2f%%\n',100*(maxLum-minLum)/(maxLum+minLum));
                %}
                
                % Get background spd
                maxBackgroundSpd = OLPrimaryToSpd(calibration,maxBackgroundPrimary);
                minBackgroundSpd = OLPrimaryToSpd(calibration,minBackgroundPrimary);
                checkLum = maxLum/(1 + params.desiredMaxContrast);
                switch (params.polarType)
                    case 'unipolar'
                        if (checkLum < minLum)
                            desiredLum = minLum;
                        else
                            desiredLum = minLum + (checkLum-minLum)/2;
                        end
                        targetBackgroundSpd = maxBackgroundSpd*(desiredLum/maxLum);
                        
                        % Convert target spd back to primary space.
                        % The problem is that this does not reproduce the
                        % primaries that we got above, even when we pass in the
                        % spd that results from those primaries. That is,
                        % OLSpdToPrimary does not invert OLPrimaryToSpd, even
                        % when there is a perfect inverse possible.  Ugh!
                        [backgroundPrimary,predBackgroundSpd,fractionalError] = OLSpdToPrimary(calibration,targetBackgroundSpd, ...
                            'primaryHeadroom',params.search.primaryHeadroom,'primaryTolerance',params.search.primaryTolerance, ...
                            'lambda',params.search.lambda, 'checkSpd',false, ...
                            'spdToleranceFraction',params.search.spdToleranceFraction, ...
                            'verbose',params.search.verbose);
                        
                        % Figure for debugging
                        %{
                    figure; clf; hold on;
                    plot(maxBackgroundSpd,'r','LineWidth',3);
                    plot(minBackgroundSpd,'g','LineWidth',4);
                    plot((minBackgroundSpd\maxBackgroundSpd)*minBackgroundSpd,'k-','LineWidth',1);
                    plot(targetBackgroundSpd,'b','LineWidth',3);
                    plot(predBackgroundSpd,'k');
                    fprintf('Fractional spd error between desired and found background spectrum: %0.1f%%\n',100*fractionalError);
                        %}
                    case 'bipolar'
                        desiredLum = (maxLum+minLum)/2;
                        targetBackgroundSpd = maxBackgroundSpd*(desiredLum/maxLum);
                        
                        % Convert back spd to primary space
                        [backgroundPrimary,predBackgroundSpd,fractionalError] = OLSpdToPrimary(calibration,targetBackgroundSpd, ...
                            'primaryHeadroom',params.search.primaryHeadroom,'primaryTolerance',params.search.primaryTolerance, ...
                            'lambda',params.search.lambda, 'checkSpd',false, 'spdToleranceFraction',params.search.spdToleranceFraction);
                        
                        % Figure for debugging
                        %{
                    figure; clf; hold on;
                    plot(maxBackgroundSpd,'r','LineWidth',3);
                    plot(minBackgroundSpd,'g','LineWidth',3);
                    plot((minBackgroundSpd\maxBackgroundSpd)*minBackgroundSpd,'k-','LineWidth',1);
                    plot(targetBackgroundSpd,'b','LineWidth',3);
                    plot(predBackgroundSpd,'y');
                    fprintf('Fractional spd error between desired and found background spectrum: %0.1f%%\n',100*fractionalError);
                    fprintf('Maximum available bipolar contrast is %0.1f%%\n',100*(maxLum-desiredLum)/desiredLum);
                        %}
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
                
                 % Validate desiredBackgroundLuminance
                property = 'desiredBackgroundLuminance';
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