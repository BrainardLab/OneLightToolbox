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
narginchk(1, Inf);

% Diagnostic plots?
DIAGNOSTICPLOTS = true;

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
    
    % Check whether we tracked system state (i.e., calibrating via
    % OLCalibrateWithTrackingOOC)
    if (isfield(cal.describe, 'stateTracking'))
        % Over-write original scale factor with one based on tracking data
        cal.computed.returnScaleFactorOLD = returnScaleFactor;
        returnScaleFactor = @(t) piecewiseLinearScaleFactorFromStateTrackingData(t);
        cal.computed.returnScaleFactor = returnScaleFactor;
        
        % Compute spectral shift corrections from tracking data
        cal.computed.spectralShiftCorrection = OLComputeSpectralShiftCorrectionsFromStateMeasurements(cal);
    end
end

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
% NOTE, BG Version, August 2016, DHB.If we measured the primary around
% a custom specified background, however, we need to subtract an
% individualized measurement from each spectrum.  Because spectra are
% the incremental effect either way (that is, the effect of taking a
% primary's mirrors from all off to all on), we still handle computing
% what we want to do from spectra in the same manner in either case.
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
    % Time correction.
    gammaTemp = bsxfun(@times, cal.raw.gamma.rad(k).meas, returnScaleFactor(cal.raw.t.gamma.rad(k).meas));
    gammaTemp = computeSpectralShiftCorrectedSPDs(cal, gammaTemp, cal.raw.t.gamma.rad(k).meas);
    
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
    % if a specified background is not provided, and I think is
    % conceptually correct in all cases.
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
    % specified background, and regress.  This is the value for zero
    % input, which we store for now in variable
    % cal.computed.gammaDataZeroInput for each gamma function.
    if (cal.describe.specifiedBackground)
        gammaEffectiveBgTemp = bsxfun(@times, cal.raw.gamma.rad(k).effectiveBgMeas, returnScaleFactor(cal.raw.t.gamma.rad(k).effectiveBgMeas));
        gammaEffectiveBgTemp = computeSpectralShiftCorrectedSPDs(cal, gammaEffectiveBgTemp, cal.raw.t.gamma.rad(k).effectiveBgMeas);
        differentialPrimaryZeroInput(:,k) = gammaEffectiveBgTemp - cal.computed.pr650MeanSpecifiedBackground;
        cal.computed.gammaDataZeroInput(k) = thePrimary(wavelengthIndices)\differentialPrimaryZeroInput(wavelengthIndices,k);
    end
    
    % Fill in the ratios for the zero input case.  This is just zero,
    cal.computed.gammaRatios(k,1).wavelenths = cal.computed.gammaRatios(k,2).wavelenths;
    cal.computed.gammaRatios(k,1).ratios = 0*cal.computed.gammaRatios(k,2).ratios;
end

%% Diagnostic plots of the raw gamma functions, if desired
%
% These should go through zero near the specified background settings
% which the ones I have looked at do.
if (DIAGNOSTICPLOTS)
    gammaDiagFigure = figure; clf; hold on
    whichGammaDiagToPlot = 12;
    plot(cal.describe.gamma.gammaLevels',cal.computed.gammaData1{whichGammaDiagToPlot}', ...
        'ro','MarkerSize',12,'MarkerFaceColor','r');
    plot(cal.describe.specifiedBackgroundSettings(whichGammaDiagToPlot),0,'bo','MarkerFaceColor','b','MarkerSize',8);
end

% Fit each indivdually measured gamma function to finely spaced real valued
% primary levels.  We prepend zero to the measured input levels because
% we force the output for 0 input to be 0 output and thus can infer
% what it should be.  That 0 is popped onto the lead end of the
% measured data in the loop just below.
%
% NOTE, BG Version, August 2016, DHB. We should probably be using a fit form that
% forces the fit for 0 input to be 0 output. I am not sure that we are.
cal.computed.gammaInputRaw = [0 ; cal.describe.gamma.gammaLevels'];
cal.computed.gammaInput = linspace(0,1,cal.describe.nGammaFitLevels)';
for k = 1:cal.describe.nGammaBands
    if (cal.describe.specifiedBackground)
        % For this case, we subtract off the minimum value before the
        % fit and scale the data to a max of for highest input value.
        % This is because our fit routines assume this [0,1] convention for
        % gamma functions.
        % 
        % We then undo the scaling, but leave the shift so that our
        % corrections don't get truncated in funny ways.
        cal.computed.gammaTableMeasuredBands(:,k) = [0 ; cal.computed.gammaData1{k}' - cal.computed.gammaDataZeroInput(k)];
        cal.computed.gammaDataMaxInputAfterZeroInputSubtract(k) = cal.computed.gammaTableMeasuredBands(end,k);
        cal.computed.gammaTableMeasuredBands(:,k) = cal.computed.gammaTableMeasuredBands(:,k) / ...
            cal.computed.gammaDataMaxInputAfterZeroInputSubtract(k);
        
        cal.computed.gammaTableMeasuredBandsFit(:,k) = ...
            OLFitGamma(cal.computed.gammaInputRaw,cal.computed.gammaTableMeasuredBands(:,k),cal.computed.gammaInput,cal.describe.gammaFitType);
        
        cal.computed.gammaTableMeasuredBands(:,k) = cal.computed.gammaTableMeasuredBands(:,k) * ...
            cal.computed.gammaDataMaxInputAfterZeroInputSubtract(k);
        cal.computed.gammaDataMaxInputAfterZeroInputSubtract(k);cal.computed.gammaTableMeasuredBandsFit(:,k) = cal.computed.gammaTableMeasuredBandsFit(:,k) * ...
            cal.computed.gammaDataMaxInputAfterZeroInputSubtract(k);
        % cal.computed.gammaTableMeasuredBandsFit(:,k) = cal.computed.gammaTableMeasuredBandsFit(:,k) + cal.computed.gammaDataZeroInput(k);
    else
        cal.computed.gammaTableMeasuredBands(:,k) = [0 ; cal.computed.gammaData1{k}'];
        cal.computed.gammaTableMeasuredBandsFit(:,k) = ...
            OLFitGamma(cal.computed.gammaInputRaw,cal.computed.gammaTableMeasuredBands(:,k),cal.computed.gammaInput,cal.describe.gammaFitType);
    end
end

% Add fit to diagnostic figure if we made one
if (DIAGNOSTICPLOTS)
    gammaDiagFigure1 = figure; clf; hold on
    plot(cal.computed.gammaInputRaw,cal.computed.gammaTableMeasuredBands(:,whichGammaDiagToPlot), ...
        'ro','MarkerSize',12,'MarkerFaceColor','r');
    plot(cal.describe.specifiedBackgroundSettings(whichGammaDiagToPlot),-cal.computed.gammaDataZeroInput(whichGammaDiagToPlot), ...
        'bo','MarkerFaceColor','b','MarkerSize',8);
    plot(cal.computed.gammaInput,cal.computed.gammaTableMeasuredBandsFit(:,whichGammaDiagToPlot), ...
        'r','LineWidth',2);
end

% Interpolate the measured gamma bands out across all of the primary bands
for l = 1:cal.describe.nGammaFitLevels
    cal.computed.gammaTable(l,:) = interp1(cal.describe.gamma.gammaBands',cal.computed.gammaTableMeasuredBandsFit(l,:)',(1:cal.describe.numWavelengthBands)','linear','extrap')';
end

% Make each band's gamma curve monotonic
for b = 1:cal.describe.numWavelengthBands
    cal.computed.gammaTable(:,b) = MakeMonotonic(cal.computed.gammaTable(:,b));
end

% Average gamma measurements over bands
cal.computed.gammaTableAvg = median(cal.computed.gammaTableMeasuredBandsFit,2);

% NOTE, BG Version, August 2016, DHB.  Here we are going to peg the origin
% of each fit gamma table, for the specified background case. We know the
% the spectrum of the specified background and the settings that produced
% itcorrespond to the specified background.  Given these, we can add the
% appropriate constant to each fit gamma table so that the specified
% background settings produce exactly the specified background primary
% values.  This manuever guarantees that when we dial the specified
% background into our procedures, we get the settings that produced it back
% out.
%
% What is not guaranteed here is that we get 0 primary for 0 settings, or a
% primary of 1 for settings of 1.
if (cal.describe.specifiedBackground)
    desiredSpecifiedBackgroundEffectivePrimaryValues = OLSpdToPrimary(cal, cal.computed.pr650MeanSpecifiedBackground);
    currentSpecifiedBackgroundEffectivePrimaryValues = OLSettingsToPrimary(cal, cal.describe.specifiedBackgroundSettings);
    
    % Plot of the unshifted values (blue) and target values (red).
    % These should be close, but not exactly the same.
    if (DIAGNOSTICPLOTS)
        figure; clf; hold on
        plot(1:length(desiredSpecifiedBackgroundEffectivePrimaryValues),desiredSpecifiedBackgroundEffectivePrimaryValues,...
            'ro','MarkerSize',12,'MarkerFaceColor','r');
        plot(1:length(currentSpecifiedBackgroundEffectivePrimaryValues),currentSpecifiedBackgroundEffectivePrimaryValues,...
            'bs','MarkerSize',8,'MarkerFaceColor','b');
        ylim([0 1]);
        xlabel('Effective Primary');
        ylabel('Primary Value');
    end
    
    % Shift the gamma curves so that we hit the specified background
    % when we ask for the specified background.  If we were using the
    % average gamma, then we shift that separately for each primary and
    % then turn off the use of average gamma, since each primary now
    % has its own unique shifted gamma.  If we were already using
    % individual gamma functions for each primary, we adjust them individually.
    for b = 1:cal.describe.numWavelengthBands
        if (cal.describe.useAverageGamma)
            cal.computed.gammaTable(:,b) = cal.computed.gammaTableAvg - ...
                currentSpecifiedBackgroundEffectivePrimaryValues(b) + ...
                desiredSpecifiedBackgroundEffectivePrimaryValues(b);
        else
            cal.computed.gammaTable(:,b) = cal.computed.gammaTable(:,b) - ...
                currentSpecifiedBackgroundEffectivePrimaryValues(b) + ...
                desiredSpecifiedBackgroundEffectivePrimaryValues(b);
        end
    end
    
    % If this was false, it stays false.  If it was true, it becomes
    % false because we have shifted each gamma function by its own
    % constant.
    cal.describe.useAverageGamma = false;
    
    % Plot of the high and low ends of each gamma function, which should be
    % near to 0 and 1 respectively, but not exactly equal to those
    % reference values.
    if (DIAGNOSTICPLOTS)
        figure; clf; hold on
        plot((1:cal.describe.numWavelengthBands)',cal.computed.gammaTable(1,:)',...
            'ro','MarkerSize',12,'MarkerFaceColor','r');
        plot((1:cal.describe.numWavelengthBands)',cal.computed.gammaTable(end,:)',...
            'bs','MarkerSize',12,'MarkerFaceColor','b');
        plot((1:cal.describe.numWavelengthBands)',0*ones(size((1:cal.describe.numWavelengthBands)')),'k','LineWidth',3);
        plot((1:cal.describe.numWavelengthBands)',1*ones(size((1:cal.describe.numWavelengthBands)')),'k','LineWidth',3);
        ylim([-0.2 1.2]);
        xlabel('Effective Primary');
        ylabel('Low/High Value');
    end
end

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


