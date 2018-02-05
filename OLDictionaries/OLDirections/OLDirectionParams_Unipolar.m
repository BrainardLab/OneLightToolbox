classdef OLDirectionParams_Unipolar < OLDirectionParams
% Parameter-object for Unipolar directions
%   Detailed explanation goes here
    
    properties %(SetAccess = protected)       
        whichReceptorGenerator = 'SSTPhotoreceptorSensitivity';
        photoreceptorClasses = {'LConeTabulatedAbsorbance'  'MConeTabulatedAbsorbance'  'SConeTabulatedAbsorbance'  'Melanopsin'};
        fieldSizeDegrees = 27.5;
        pupilDiameterMm = 8.0;
        maxPowerDiff = 0.1;
        modulationContrast = [2/3];
        whichReceptorsToIsolate = [4];
        whichReceptorsToIgnore = [];
        whichReceptorsToMinimize = [];
        whichPrimariesToPin = [];
        directionsYoked = 0;
        directionsYokedAbs = 0;
        receptorIsolateMode = 'Standard';
        doSelfScreening = false;
        
        backgroundType = 'optimized';
        backgroundName = '';
        backgroundObserverAge = 32;
    end
    
    methods
        function obj = OLDirectionParams_Unipolar
            obj.type = 'unipolar';
            obj.name = '';
            obj.cacheFile = '';
            
            obj.primaryHeadRoom = .005;
        end
        
        function directionStruct = GetDirectionNominalStruct(directionParams, backgroundPrimary, calibration, varargin)
            parser = inputParser();
            parser.addRequired('backgroundPrimary');
            parser.addRequired('calibration',@isstruct);
            parser.addParameter('verbose',false,@islogical);
            parser.parse(backgroundPrimary,calibration,varargin{:});

            S = calibration.describe.S;
            backgroundSpd = OLPrimaryToSpd(calibration, backgroundPrimary);

            % Set up what will be common to all observer ages
            % Pull out the 'M' matrix
            B_primary = calibration.computed.pr650M;

            % Peg desired contrasts
            desiredContrasts = directionParams.modulationContrast;

            % Assign a zero 'ambientSpd' variable if we're not using the
            % measured ambient.
            if directionParams.useAmbient
                ambientSpd = calibration.computed.pr650MeanDark;
            else
                ambientSpd = zeros(size(B_primary,1),1);
            end

            if (parser.Results.verbose), fprintf('\nGenerating stimuli which isolate receptor classes:'); end
            for i = 1:length(directionParams.whichReceptorsToIsolate)
                if (parser.Results.verbose), fprintf('\n  - %s', directionParams.photoreceptorClasses{directionParams.whichReceptorsToIsolate(i)}); end
            end
            if (parser.Results.verbose), fprintf('\nGenerating stimuli which ignore receptor classes:'); end
            if ~isempty(directionParams.whichReceptorsToIgnore)
                for i = 1:length(directionParams.whichReceptorsToIgnore)
                    if (parser.Results.verbose), fprintf('\n  - %s', directionParams.photoreceptorClasses{directionParams.whichReceptorsToIgnore(i)}); end
                end
            else
                if (parser.Results.verbose), fprintf('\n  - None'); end
            end

            % Make direction information for each observer age
            for observerAgeInYears = 20:60
                % Say hello
                if (parser.Results.verbose), fprintf('\nObserver age: %g\n',observerAgeInYears); end

                % Get original backgroundPrimary
                backgroundPrimary = parser.Results.backgroundPrimary;

                % Get fraction bleached for background we're actually using
                if (directionParams.doSelfScreening)
                    fractionBleached = OLEstimateConePhotopigmentFractionBleached(S,backgroundSpd,directionParams.pupilDiameterMm,directionParams.fieldSizeDegrees,observerAgeInYears,directionParams.photoreceptorClasses);
                else
                    fractionBleached = zeros(1,length(directionParams.photoreceptorClasses));
                end

                % Get lambda max shift.  Currently not passed but could be.
                lambdaMaxShift = [];

                % Construct the receptor matrix based on the bleaching fraction to this background.
                T_receptors = GetHumanPhotoreceptorSS(S,directionParams.photoreceptorClasses,directionParams.fieldSizeDegrees,observerAgeInYears,directionParams.pupilDiameterMm,lambdaMaxShift,fractionBleached);

                % Isolate the receptors by calling the ReceptorIsolate
                initialPrimary = backgroundPrimary;
                modulationPrimarySignedPositive = ReceptorIsolate(T_receptors, directionParams.whichReceptorsToIsolate, ...
                    directionParams.whichReceptorsToIgnore,directionParams.whichReceptorsToMinimize,B_primary,backgroundPrimary,...
                    initialPrimary,directionParams.whichPrimariesToPin,directionParams.primaryHeadRoom,directionParams.maxPowerDiff,...
                    desiredContrasts,ambientSpd);

                differentialPositive = modulationPrimarySignedPositive - backgroundPrimary;
                differentialNegative = -1 * differentialPositive;

                % UNIPOLAR, SO REPLACE BACKGROUND WITH NEGATIVE MAX EXCURSION
                backgroundPrimary = backgroundPrimary + differentialNegative;
                differentialPositive = modulationPrimarySignedPositive - backgroundPrimary;
                differentialNegative = 0 * differentialPositive;

                % Look at both negative and positive swing and double check that we're within gamut
                modulationPrimarySignedPositive = backgroundPrimary+differentialPositive;
                modulationPrimarySignedNegative = backgroundPrimary+differentialNegative;
                if any(modulationPrimarySignedNegative > 1) || any(modulationPrimarySignedNegative < 0)  || any(modulationPrimarySignedPositive > 1)  || any(modulationPrimarySignedPositive < 0)
                    error('Out of bounds.')
                end

                % Compute spds, constrasts
                backgroundSpd = OLPrimaryToSpd(calibration,backgroundPrimary);
                backgroundReceptors = T_receptors*backgroundSpd;
                differenceSpdSignedPositive = B_primary*differentialPositive;
                differenceReceptorsPositive = T_receptors*differenceSpdSignedPositive;
                isolateContrastsSignedPositive = differenceReceptorsPositive ./ backgroundReceptors;
                modulationSpdSignedPositive = backgroundSpd+differenceSpdSignedPositive;

                differenceSpdSignedNegative = B_primary*(-differentialPositive);
                modulationSpdSignedNegative = backgroundSpd+differenceSpdSignedNegative;

                % Print out contrasts. This routine is in the Silent Substitution Toolbox.
                if (parser.Results.verbose), ComputeAndReportContrastsFromSpds(sprintf('\n> Observer age: %g',observerAgeInYears),directionParams.photoreceptorClasses,T_receptors,backgroundSpd,modulationSpdSignedPositive,[],[]); end

                % [DHB NOTE: MIGHT WANT TO SAVE THE VALUES HERE AND PHOTOPIC LUMINANCE TOO.]
                % Print out luminance info.  This routine is also in the Silent Substitution Toolbox
                if (parser.Results.verbose), GetLuminanceAndTrolandsFromSpd(S, backgroundSpd, directionParams.pupilDiameterMm, true); end

                %% Assign all the cache fields
                % Business end
                directionStruct(observerAgeInYears).backgroundPrimary = backgroundPrimary;              
                directionStruct(observerAgeInYears).differentialPositive = differentialPositive;                            
                directionStruct(observerAgeInYears).differentialNegative = differentialNegative;            

                % Description
                directionStruct(observerAgeInYears).describe.params = directionParams;
                directionStruct(observerAgeInYears).describe.modulationPrimarySignedPositive = modulationPrimarySignedPositive;
                directionStruct(observerAgeInYears).describe.modulationPrimarySignedNegative = modulationPrimarySignedNegative;
                directionStruct(observerAgeInYears).describe.B_primary = B_primary;
                directionStruct(observerAgeInYears).describe.ambientSpd = ambientSpd;
                directionStruct(observerAgeInYears).describe.backgroundSpd = backgroundSpd;
                directionStruct(observerAgeInYears).describe.modulationSpdSignedPositive = modulationSpdSignedPositive;
                directionStruct(observerAgeInYears).describe.modulationSpdSignedNegative = modulationSpdSignedNegative;
                directionStruct(observerAgeInYears).describe.lambdaMaxShift = lambdaMaxShift;
                directionStruct(observerAgeInYears).describe.fractionBleached = fractionBleached;
                directionStruct(observerAgeInYears).describe.S = S;
                directionStruct(observerAgeInYears).describe.T_receptors = T_receptors;
                directionStruct(observerAgeInYears).describe.S_receptors = S;
                directionStruct(observerAgeInYears).describe.contrast = isolateContrastsSignedPositive;
                directionStruct(observerAgeInYears).describe.contrastSignedPositive = isolateContrastsSignedPositive;

                clear modulationPrimarySignedNegative modulationSpdSignedNegative
            end            
        end
    end
    
end