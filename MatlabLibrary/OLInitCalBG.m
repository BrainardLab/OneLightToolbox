function cal = OLInitCalBG(calFileName, varargin)
% OLInitCal - Initializes a OneLight calibration file with computed data.
%
% Syntax:
% oneLightCal = OLInitCalBG(calFileName)
% oneLightCal = OLInitCalBG(calFileName, initOpts);
%
% Input calFileName can be the name of a calibration file, or a calibration structure.
% In the latter case, the initialization is run on the passed structure without reading.
%
% Description:
% Intializes a OneLight calibration file with data computed to translate
% spectra to mirror settings.  This function also takes a variable list of
% options to modify how the data is computed.
%
% Input:
% calFileName (string) - Name of the calibration file to initialize.
% initOpts (varargin) - Options list consisting of parameters described in
%     the Options section below.
% 
% Options as string/value pairs.
% 'FactorsMethods' (scalar) - FactorsMethod sets the method that finds factors
%     at each common wavelength to bring OmniDriver measurements into alignment with PR-650 measurements.
%     Allowable values are 0, 1, and 2.  Defaults to 2.  [Note: We are not currently using the OmniDriver
%     in the calibration, so this doesn't do anything right now.]
% 'UseAverageGamma' (logical) - Sets cal.describe.useAverageGamma.  Default is to leave this unchanged.
% 'GammaFitType' (string or scalar) - Sets cal.describe.gammaFitType.  Default is to leave this unchanged.
%     See OLFitGamma for types and what they do.
% 'CorrectLinearDrift' (logical) - Correct for linear drift.  Default is to leave this unchanged.
%
% Output:
% oneLightCal (struct) - The initialized calibration file.
%
% Examples:
% oneLightCal = OLInitCal('OneLight');
% oneLightCal = OLInitCal('OneLight', 'FactorsMethod', 1);
% oneLightCal = OLInitCal('OneLight', 'GammaFitType', 'betacdfquad');

% 7/4/13  dhb  Took out low light level kluge for one particular calibration.
% 1/19/14 dhb, ms Variable name cleaning.
%              Generalize gamma/independence measurements to arbitrary number of bands.
% 1/31/14 ms   Added scaling measurements.
% 3/19/14 dhb  Parse options added.  Remove hard coded setting of correctLinearDrift field.
% 4/9/16  dhb  Put in code for handling calibrations around a background.  
%              Strip useOmni.  We don't do that anymore.
%              Have inline function returnScaleFactor return 1 if
%                cal.describe.correctForDrift is false, and then get rid of
%                all the other conditionals on this variable.
% 8/14/16 npc  Added piecewise linear drift correction for calfiles that
%              contain state tracking data (i.e., measured via
%              OLCalibrateWithStateTrackingOOC.m)
% 8/22/16 npc  Added spectral shift correction for for calfiles that
%              contain state tracking data (i.e., measured via
%              OLCalibrateWithStateTrackingOOC.m)
% 8/28/16 dhb  This version for when we calibrate around a background.ß

    % Check for the number of arguments.
    error(nargchk(1, Inf, nargin));

    % Load the calibration file.
    if (isstr(calFileName))
        cal = LoadCalFile(calFileName);
        assert(~isempty(cal), 'OLInitCal:InvalidCal', 'Cannot load calibration file: %s', calFileName);
    elseif (isstruct(calFileName))
        cal = calFileName;
    else
        error('Passed argument must be a cal file name (str) or calibration structure');
    end

    % If useOmni is set, throw an error.
    if (cal.describe.useOmni)
        error('We do not use the omni for calibration.')
    end

    % Create a parser for any optional arguments.
    parser = inputParser;
    parser.addParameter('FactorsMethod', 2, @isnumeric);
    parser.addParameter('UseAverageGamma',[],@(x)isnumeric(x) || islogical(x));
    parser.addParameter('GammaFitType',[],@(x)ischar(x) || isnumeric(x));
    parser.addParameter('CorrectLinearDrift',[],@(x)isnumeric(x) || islogical(x));

    % Execute the parser and store the results in the calibration structure
    % under the 'computed' field.
    parser.parse(varargin{:});
    cal.computed = parser.Results;

    % Override use average gamma if passed
    if (~isempty(parser.Results.UseAverageGamma))
        cal.describe.useAverageGamma = parser.Results.UseAverageGamma;
    end

    % Override gammaFitType if passsed.
    if (~isempty(parser.Results.GammaFitType))
        cal.describe.gammaFitType = parser.Results.GammaFitType;
    end

    % Override correctLinearDrift field if passed.
    if (~isempty(parser.Results.CorrectLinearDrift))
        cal.describe.correctLinearDrift = parser.Results.CorrectLinearDrift;
    end

    % Backwards compatibiilty
    cal = OLCalBackwardsCompatibility(cal);

    % Wavelength sampling.  Don't change this without carefully considering
    % all three forms of the wavelength info and making sure they stay
    % consistent.
    cal.computed.pr650S = cal.describe.S;
    cal.computed.pr650Wls = SToWls(cal.computed.pr650S);
    cal.computed.commonWls = cal.computed.pr650Wls;

    % Figure out the scalar to correct for the device drift
    if cal.describe.correctLinearDrift
        wavelengthIndices = find(cal.raw.fullOn(:,1) > 0.2*max(cal.raw.fullOn(:)));
        fullOn0 = cal.raw.fullOn(wavelengthIndices,1);
        fullOn1 = cal.raw.fullOn(wavelengthIndices,end);
        s = fullOn0 \ fullOn1;
        t0 = cal.raw.t.fullOn(1);
        t1 = cal.raw.t.fullOn(end);
        returnScaleFactor = @(t) 1./((1-(1-s)*((t-t0)./(t1-t0))));
        cal.computed.returnScaleFactor = returnScaleFactor;
        
        % Check whether we tracked system state (i.e., calibrating via OLCalibrateWithTrackingOOC
        if (isfield(cal.describe, 'stateTracking'))
            % Over-write original scale factor with one based on tracking data
            cal.computed.returnScaleFactorOLD = returnScaleFactor;
            returnScaleFactor = @(t) piecewiseLinearScaleFactorFromStateTrackingData(t);
            cal.computed.returnScaleFactor = returnScaleFactor;
            % Compute spectral shift corrections from tracking data
            cal.computed.spectralShiftCorrection = OLComputeSpectralShiftCorrectionsFromStateMeasurements(cal);
        end %  if (isfield(cal.describe, 'stateTracking'))
    end  % if cal.describe.correctLinearDrift
  
    % Get data
    cal.computed.D = cal.raw.cols;
    
    cal.computed.pr650M = bsxfun(@times, cal.raw.lightMeas, returnScaleFactor(cal.raw.t.lightMeas));
    cal.computed.pr650M = computeSpectralShiftCorrectedSPDs(cal, cal.computed.pr650M, cal.raw.t.lightMeas);
    
    cal.computed.pr650Md = bsxfun(@times, cal.raw.darkMeas, returnScaleFactor(cal.raw.t.darkMeas));
    cal.computed.pr650Md = computeSpectralShiftCorrectedSPDs(cal, cal.computed.pr650Md, cal.raw.t.darkMeas);
    
    if (cal.describe.specifiedBackground)
        cal.computed.pr650MSpecifiedBg = bsxfun(@times, cal.raw.specifiedBackgroundMeas, returnScaleFactor(cal.raw.t.specifiedBackgroundMeas));
        cal.computed.pr650MSpecifiedBg = computeSpectralShiftCorrectedSPDs(cal, cal.computed.pr650MSpecifiedBg, cal.raw.t.specifiedBackgroundMeas);
        
        cal.computed.pr650MeanSpecifiedBackground = mean(cal.computed.pr650MSpecifiedBg,2);
        cal.computed.pr650MEffectiveBg = bsxfun(@times, cal.raw.effectiveBgMeas, returnScaleFactor(cal.raw.t.effectiveBgMeas));
        cal.computed.pr650MEffectiveBg = computeSpectralShiftCorrectedSPDs(cal, cal.computed.pr650MEffectiveBg, cal.raw.t.effectiveBgMeas);
    end

    % Subtract appropriate measurement to get the incremental spectrum for each
    % primary.  We have two options for this.  In the standard option, only the
    % mirrors for the primary were one when the primary was measured, and so we
    % just need to subtract the dark spectrum.
    %
    % If we measured the primary around a custom specified background,
    % however, we need to subtract an individualized measurement from each
    % spectrum.  Because spectra are the incremental effect either way
    % (that is, the effect of taking a primary's mirrors from all off to
    % all on), we still handle computing what we want to do from spectra in
    % the same manner in either case.
    cal.computed.pr650MeanDark = mean(cal.computed.pr650Md,2);
    cal.computed.pr650MeanDark(cal.computed.pr650MeanDark < 0) = 0;
    if (cal.describe.specifiedBackground)
        cal.computed.pr650M = cal.computed.pr650M-cal.computed.pr650MEffectiveBg;
        cal.computed.pr650M(cal.computed.pr650M < 0) = 0;
    else
        cal.computed.pr650M = cal.computed.pr650M - ...
            cal.computed.pr650MeanDark(:,ones(1,size(cal.computed.pr650M,2)));
        cal.computed.pr650M(cal.computed.pr650M < 0) = 0;
    end

    % Infer meter type for backwards compatibility
    if (~isfield(cal.describe,'meterType'))
        switch (cal.describe.S(2))
            case 2
                cal.describe.meterType = 5;
            case 4
                cal.describe.meterType = 1;
            otherwise
                error('Unexpected wavelength spacing for unspecified meter');
        end
    end

    % Extract the gamma data for the PR-6XX.
    %
    % This gets the measured spectrum and dark subtracts.
    % It then computes the range of wavelengths around the peak
    % that will be used when we compute power for each gamma band
    % and computes the fraction of max power using regression on
    % the spectra from the selected wavelength bands.
    %
    % Note: raw.gamma.rad is a structure array.  Each element
    % of the structure array contains the measurements for one
    % of the measured gamma bands.
    if (size(cal.raw.gamma.rad,2) ~= cal.describe.nGammaBands)
        error('Mismatch between specified number of gamma bands and size of measurement struct array');
    end
    for k = 1:cal.describe.nGammaBands
        % Dark subtract with time correction.  As with primary spectra above,
        % there are two distinct ways we can do this, depending on whether we
        % calibrated around dark or around a specified background.
        gammaTemp = bsxfun(@times, cal.raw.gamma.rad(k).meas, returnScaleFactor(cal.raw.t.gamma.rad(k).meas));
        gammaTemp = computeSpectralShiftCorrectedSPDs(cal, gammaTemp, cal.raw.t.gamma.rad(k).meas);
        
        %  NOTE, BG Version, August 2016, DHB. I don't think we need
        %  these here, but we do use them below.  Once things are debugged
        %  well for the BG version, delete this block.
        % if (cal.describe.specifiedBackground)
        %     gammaEffectiveBgTemp = ...
        %         bsxfun(@times, cal.raw.gamma.rad(k).effectiveBgMeas, returnScaleFactor(cal.raw.t.gamma.rad(k).effectiveBgMeas));
        %     gammaEffectiveBgTemp = computeSpectralShiftCorrectedSPDs(cal, gammaEffectiveBgTemp, cal.raw.t.gamma.rad(k).effectiveBgMeas);
        % end
        
        % If we are calibrating around a specified background, then we need
        % to subtract that background from each gamma measurement.  If
        % we're calibrating around zero, we just subtract that.  Notice
        % that these two cases converge if the specified background
        % settings happened to be all zero, although they draw on
        % measurements made at different points in the calibration code.
        if (cal.describe.specifiedBackground)
            gammaMeas{k} = gammaTemp - cal.computed.pr650MeanSpecifiedBackground(:,ones(1,size(gammaTemp,2)));
        else
            gammaMeas{k} = gammaTemp - cal.computed.pr650MeanDark(:,ones(1,size(cal.raw.gamma.rad(k).meas,2)));
        end 
        
        % Get the wavelength index of the maximum for the primary for this
        % gamma band.
        % 
        % NOTE, BG Version, August 2016, DHB. Changed this code for the BG
        % version, because we can't count on the gamma measurement for the
        % highest input setting to have much signal, since the background
        % might also be high for this primary.  So, we use the primary
        % measurement itself to find the relevant wavelengths for the
        % regression.  This makes more sense in general, I think, and
        % should also work just fine when a specified background is not
        % provided.
        whichPrimary = cal.describe.gamma.gammaBands(k);
        thePrimary = cal.computed.pr650M(:,whichPrimary);
        [~,peakWlIndices{k}] = max(thePrimary);
        cal.describe.peakWlIndex(k) = peakWlIndices{k}(1);

        % Get wavelength indices around peak to use.
        cal.describe.minWlIndex(k) = cal.describe.peakWlIndex(k)-cal.describe.gammaNumberWlUseIndices;
        if (cal.describe.minWlIndex(k) < 1)
            cal.describe.minWlIndex(k) = 1;
        end
        cal.describe.maxWlIndex(k) = cal.describe.peakWlIndex(k)+cal.describe.gammaNumberWlUseIndices;
        if (cal.describe.maxWlIndex(k) > cal.describe.S(3))
            cal.describe.maxWlIndex(k) = cal.describe.S(3);
        end

        % Little check and then get power for each measured level for this measured band
        if (size(cal.raw.gamma.rad(k).meas,2) ~= cal.describe.nGammaLevels)
            error('Mismatch between specified number of gamma levels and size of measurement array');
        end    
        
        % NOTE, BG Version, August 2016, DHB. Changed this to regress
        % against the primary measurement itself, rather than against the
        % gamma measurement for an input of 1.  We need this change for
        % things to work with a specified background.  It should also be OK
        % if a specified background is not provided.
        for i = 1:cal.describe.nGammaLevels
            wavelengthIndices = cal.describe.minWlIndex(k):cal.describe.maxWlIndex(k);
            cal.computed.gammaData1{k}(i) = thePrimary(wavelengthIndices)\ ...
                gammaMeas{k}(wavelengthIndices,i); %#ok<*AGROW>
            cal.computed.gammaRatios(k,i+1).wavelenths = cal.computed.commonWls(wavelengthIndices);
            cal.computed.gammaRatios(k,i+1).ratios = gammaMeas{k}(wavelengthIndices,i) ./ thePrimary(wavelengthIndices);
        end
        
        % NOTE, BG Version, August 2016, DHB.  Added the conditional for
        % speciied background.
        %
        % Take the equivalent background measurement as the measurement for
        % 0 input (since that is in fact what it is), subtract the
        % specified background, and regress.  We take this minimum value
        % and add it to all the other gammaData1 values, so now gammaData1
        % starts at 0 for zero input.  It should end up at something close
        % to 1 for maximum input, but this is not guaranteed.  
        % 
        % For now, we'll print out the maximum value for debugging
        % purposes.
        if (cal.describe.specifiedBackground)
            gammaEffectiveBgTemp = bsxfun(@times, cal.raw.gamma.rad(k).effectiveBgMeas, returnScaleFactor(cal.raw.t.gamma.rad(k).effectiveBgMeas));
            gammaEffectiveBgTemp = computeSpectralShiftCorrectedSPDs(cal, gammaEffectiveBgTemp, cal.raw.t.gamma.rad(k).effectiveBgMeas);
            differentialPrimaryZeroInput(:,k) = gammaEffectiveBgTemp - cal.computed.pr650MeanSpecifiedBackground;
            cal.computed.gammaDataMin(k) = thePrimary(wavelengthIndices)\differentialPrimaryZeroInput(wavelengthIndices,k);
            cal.computed.gammaData1{k} = cal.computed.gammaData1{k} - cal.computed.gammaDataMin(k);
        end
        fprintf('\tMeasured gamma function %d, max value is %0.2f should be close to 1\n',k,cal.computed.gammaData1{k}(end));

        % Fill in the ratios for the zero input case.  This is just zero,
        cal.computed.gammaRatios(k,1).wavelenths = cal.computed.gammaRatios(k,2).wavelenths;
        cal.computed.gammaRatios(k,1).ratios = 0*cal.computed.gammaRatios(k,2).ratios;
    end

    % Fit each indivdually measured gamma function to finely spaced real valued
    % primary levels.  We prepend zero to the measured input levels because
    % we force the output for 0 input to be 0 output and thus can infer
    % what it should be.  That 0 is popped onto the lead end of the
    % measured data in the loop just below.
    %
    % NOTE, BG Version, August 2016, DHB. We should be using a fit form that
    % forces the fit for 0 input to be 0 output. I am not sure that we are.
    cal.computed.gammaInputRaw = [0 ; cal.describe.gamma.gammaLevels'];
    cal.computed.gammaInput = linspace(0,1,cal.describe.nGammaFitLevels)';
    for k = 1:cal.describe.nGammaBands
        cal.computed.gammaTableMeasuredBands(:,k) = [0 ; {k}'];
        cal.computed.gammaTableMeasuredBandsFit(:,k) = OLFitGamma(cal.computed.gammaInputRaw,cal.computed.gammaTableMeasuredBands(:,k),cal.computed.gammaInput,cal.describe.gammaFitType);
    end
    
    % Interpolate the measured gamma bands out across all of the primary bands
    for l = 1:cal.describe.nGammaFitLevels
        cal.computed.gammaTable(l,:) = interp1(cal.describe.gamma.gammaBands',cal.computed.gammaTableMeasuredBandsFit(l,:)',(1:cal.describe.numWavelengthBands)','linear','extrap')';   
    end
    
    % NOTE, BG Version, August 2016, DHB. This is a little ugly.  The
    % OLSpdToPrimary subtracts off the pr650MeanDark variable, and so we
    % are going to overwrite that in the structure with the fictional
    % background, in the specified background case.  Once the specified
    % backgroud stuff is working, we should do some renaming in
    % OLSpdToPrimary so that we don't need this kluge
    cal.computed.realPr650MeanDark = cal.computed.pr650MeanDark;
    if (cal.describe.specifiedBackground)
        % Interpolate the cal.computed.gammaDataMin out to all primary
        % bands.
        %
        % THIS MIGHT BREAK BECAUSE OF A TRANSPOSE ISSUE IN THE INPUTS.
        % DELETE THIS COMMENT ONCE IT WORKS.
        cal.computed.interpGammaDataMin = interp1(cal.describe.gamma.gammaBands',cal.computed.gammaDataMin',(1:cal.describe.numWavelengthBands)','linear','extrap')';

        % Start with the fictional background equal to the specified
        % background.  Then subtract off the differential for dropping each
        % of the primaries to zero.   I am pretty sure the + sign is what we want,
        % because the values in cal.computed.interpGammaDataMin should all
        % be negative while the spectra in cal.computed.pr650M should all
        % be positive.
        cal.computed.pr650MeanDark = cal.computed.pr650MeanSpecifiedBackground;
        for b = 1:cal.describe.numWavelengthBands
            cal.computed.pr650MeanDark = cal.computed.pr650MeanDark + ...
                cal.computed.interpGammaDataMin(b)*cal.computed.pr650M(:,b);
        end
    end
    
    % NOTE, BG Version, August 2016, DHB. The new fictional dark background
    % we compute here should be pretty close to the real measured dark
    % background.  It would be good to plot and check whether this is true.
    % Add here a plot of the real dark background
    % (cal.computed.realPr650MeanDark) and the fictional dark background
    % (cal.computed.pr650MeanDark) on the same graph and have a look.


    % Make each band's gamma curve monotonic
    for b = 1:cal.describe.numWavelengthBands
        cal.computed.gammaTable(:,b) = MakeMonotonic(cal.computed.gammaTable(:,b));
    end

    % Average gamma measurements over bands
    cal.computed.gammaTableAvg = median(cal.computed.gammaTableMeasuredBandsFit,2);

    % Compute drift corrected fullON, halfON and wiggly
    cal.computed.wigglyMeas.measSpd = bsxfun(@times, cal.raw.wigglyMeas.measSpd, returnScaleFactor(cal.raw.t.wigglyMeas.t));
    cal.computed.wigglyMeas.measSpd = computeSpectralShiftCorrectedSPDs(cal, cal.computed.wigglyMeas.measSpd, cal.raw.t.wigglyMeas.t);
    
    cal.computed.halfOnMeas = bsxfun(@times, cal.raw.halfOnMeas, returnScaleFactor(cal.raw.t.halfOnMeas));
    cal.computed.halfOnMeas = computeSpectralShiftCorrectedSPDs(cal, cal.computed.halfOnMeas, cal.raw.t.halfOnMeas);
    
    cal.computed.fullOn = bsxfun(@times, cal.raw.fullOn, returnScaleFactor(cal.raw.t.fullOn));
    cal.computed.fullOn = computeSpectralShiftCorrectedSPDs(cal, cal.computed.fullOn, cal.raw.t.fullOn);
    
    % % NOTE, BG Version, August 2016, DHB. Is there a reason this is nested rather than just being 
    % a function pulled out to the end of the file?
    %
    % Nested function computing scale factor based on state tracking measurements
    function scaleFactor = piecewiseLinearScaleFactorFromStateTrackingData(tInterp)
        
        wavelengthIndices = find(cal.raw.fullOn(:,1) > 0.2*max(cal.raw.fullOn(:)));
        debugByTakingOnlyFirstAndLastPoints = false;
        if (debugByTakingOnlyFirstAndLastPoints)
            meas0 = cal.raw.fullOn(wavelengthIndices,1);  
            meas1 = cal.raw.fullOn(wavelengthIndices,end);
            %meas0 = cal.raw.powerFluctuationMeas.measSpd(wavelengthIndices,1);
            %meas1 = cal.raw.powerFluctuationMeas.measSpd(wavelengthIndices,end); 
            y(1) = 1;
            y(2) = 1/ (meas0 \ meas1);
            x = [cal.raw.powerFluctuationMeas.t(1) cal.raw.powerFluctuationMeas.t(end)];
        else
            stateMeasurementsNum = size(cal.raw.powerFluctuationMeas.measSpd,2);
            meas0 = cal.raw.powerFluctuationMeas.measSpd(wavelengthIndices,1);
            for stateMeasurementIndex = 1:stateMeasurementsNum
                y(stateMeasurementIndex) = 1.0 ./ (meas0 \ cal.raw.powerFluctuationMeas.measSpd(wavelengthIndices,stateMeasurementIndex));
            end
            x = cal.raw.powerFluctuationMeas.t;
        end
        
        [~,kb] = histc(tInterp,x);
        t = (tInterp - x(kb))./(x(kb+1) - x(kb));
        scaleFactor = (1-t).*y(kb) + t.*y(kb+1);
    end

end

% Function for computing wavelength shift correction
function spectralShiftCorrectedSPDs = computeSpectralShiftCorrectedSPDs(cal, theSPDs, theTimesOfMeasurements)

    spectralShiftCorrectedSPDs = theSPDs;
    
    if (isfield(cal.describe, 'stateTracking'))
        spectralAxis = SToWls(cal.describe.S);
        measurementsNum = size(theSPDs,2);
        for measIndex = 1:measurementsNum
            
            [~,closestStateMeasIndex] = min(abs(cal.computed.spectralShiftCorrection.times - theTimesOfMeasurements(1,measIndex)));    
            spectralShiftCorrection = cal.computed.spectralShiftCorrection.amplitudes(closestStateMeasIndex);
    
            spectralShiftCorrectedSPDs(:,measIndex) = OLApplySpectralShiftCorrection(theSPDs(:, measIndex), spectralShiftCorrection, spectralAxis);
        end
    end
end


