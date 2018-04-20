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
    %    OLBackgroundParams, OLBackgroundParams_Optimized,
    %    OLPrimaryInvSolveChrom
    %
    
    % History:
    %    02/07/18  jv  Wote it.
    %    04/09/18  dhb Update properties towards current search methods
    
    properties
        desiredxy(1,2) = [0.54 0.38];                                       % Modulation chromaticity.
        whichXYZ(1,:) char = 'xyzCIEPhys10';                                % Which XYZ cmfs.
        desiredMaxContrast(1,1) = 1;                                        % Desired maximum contrast to go on background.
        desiredBackgroundLuminance(1,1) = 200;                              % Desired background luminance in cd/m2.
        polarType(1,:) char = 'unipolar';                                   % Background set for unipolar or bipolar modulation?
        search(1,1) struct = struct([]);                                    % Primary search parameter struct
    end
    
    methods
        function obj = OLBackgroundParams_LightFluxChrom
            obj = obj@OLBackgroundParams;
        end
        
        function name = OLBackgroundNameFromParams(params)
            name = sprintf('%s_%d_%d_%d',params.baseName,round(1000*params.lightFluxDesiredXY(1)),round(1000*params.lightFluxDesiredXY(2)),round(10*params.lightFluxDownFactor));
        end
        
        function [backgroundPrimary,maxBackgroundPrimary,minBackgroundPrimary] = OLBackgroundNominalPrimaryFromParams(params, calibration)
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
            %    params            - OLBackgroundParams_LightFluxChrom
            %                        defining the parameters for this
            %                        LightFluxChrom background.
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
        
        function [background,maxBackgroundPrimary,minBackgroundPrimary] = OLBackgroundNominalFromParams(params, calibration)
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
            [backgroundPrimary,maxBackgroundPrimary,minBackgroundPrimary] = OLBackgroundNominalPrimaryFromParams(params,calibration);
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
    
end