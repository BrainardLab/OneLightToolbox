function cal = OLInitCal(calFileName, varargin)
% OLInitCal - Initializes a OneLight calibration file with computed data.
%
% Syntax:
% oneLightCal = OLInitCal(calFileName)
% oneLightCal = OLInitCal(calFileName, initOpts);
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

%
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
parser.addOptional('FactorsMethod', 2, @isnumeric);
parser.addOptional('UseAverageGamma',[],@(x)isnumeric(x) || islogical(x));
parser.addOptional('GammaFitType',[],@(x) ischar(x) || isnumeric(x));
parser.addOptional('CorrectLinearDrift',[],@(x)isnumeric(x) || islogical(x));

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

% Wavelength sampling
cal.computed.pr650S = cal.describe.S;
cal.computed.pr650Wls = SToWls(cal.computed.pr650S);
cal.computed.commonWls = cal.computed.pr650Wls;

% Figure out the scalar to correct for the linear drift
if cal.describe.correctLinearDrift
    fullOn0 = cal.raw.fullOn(:,1);
    fullOn1 = cal.raw.fullOn(:,2);
    s = fullOn0 \ fullOn1;
    t0 = cal.raw.t.fullOn(1);
    t1 = cal.raw.t.fullOn(2);
    returnScaleFactor = @(t) 1./((1-(1-s)*((t-t0)./(t1-t0))));
else
    returnScaleFactor = @(t) 1;
end

% Get data
cal.computed.D = cal.raw.cols;
cal.computed.pr650M = bsxfun(@times, cal.raw.lightMeas, returnScaleFactor(cal.raw.t.lightMeas));
cal.computed.pr650Md = bsxfun(@times, cal.raw.darkMeas, returnScaleFactor(cal.raw.t.darkMeas));
if (cal.describe.specifiedBackground)
    cal.computed.pr650MSpecifiedBg = bsxfun(@times, cal.raw.specifiedBackgroundMeas, returnScaleFactor(cal.raw.t.specifiedBackgroundMeas));
    cal.computed.pr650MeanSpecifiedBackground = mean(cal.computed.pr650MSpecifiedBg,2);
    cal.computed.pr650MEffectiveBg = bsxfun(@times, cal.raw.effectiveBgMeas, returnScaleFactor(cal.raw.t.effectiveBgMeas));
end

% Subtract appropriate measurement to get the incremental spectrum for each
% primary.  We have two options for this.  In the standard option, only the
% mirrors for the primary were one when the primary was measured, and so we
% just need to subtract the dark spectrum.  If we measured the primary
% around a custom specified background, however, we need to subtract an
% individualized measurement from each spectrum.  Because spectra are the
% incremental effect either way (that is, the effect of taking a primary's
% mirrors from all off to all on), we still handle computing what we want
% to do from spectra in the same manner in either case.
cal.computed.pr650MeanDark = mean(cal.computed.pr650Md,2);
cal.computed.pr650MeanDark(cal.computed.pr650MeanDark < 0) = 0;
if (cal.describe.specifiedBackground)
    cal.comptude.pr650M = cal.computed.pr650M-cal.computed.pr650MEffectiveBg;
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

% Use the stops information to get the fraction of max power for each gamma measurement, in range [0,1].
cal.computed.gammaInputRaw = [0 ; cal.describe.gamma.gammaLevels'];

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
    % calibrated around dark or around a specified background.  The end
    % result of this makes the two sets of measurements equivalent going
    % onwards.
    gammaTemp = bsxfun(@times, cal.raw.gamma.rad(k).meas, returnScaleFactor(cal.raw.t.gamma.rad(k).meas));
    if (cal.describe.specifiedBackground)
        gammaEffectiveBgTemp = ...
            bsxfun(@times, cal.raw.gamma.rad(k).effectiveBgMeas, returnScaleFactor(cal.raw.t.gamma.rad(k).effectiveBgMeas));
    end
    if (cal.describe.specifiedBackground)
        gammaMeas{k} = gammaTemp - gammaEffectiveBgTemp(:,ones(1,size(gammaTemp,2)));
    else
        gammaMeas{k} = gammaTemp - cal.computed.pr650MeanDark(:,ones(1,size(cal.raw.gamma.rad(k).meas,2)));
    end 
    [~,peakWlIndices{k}] = max(gammaMeas{k}(:,end));
    
    % Get wavelength indices around peak to use.
    cal.describe.peakWlIndex(k) = peakWlIndices{k}(1);
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
    for i = 1:cal.describe.nGammaLevels
        cal.computed.gammaData1{k}(i) = gammaMeas{k}(cal.describe.minWlIndex(k):cal.describe.maxWlIndex(k),end)\ ...
            gammaMeas{k}(cal.describe.minWlIndex(k):cal.describe.maxWlIndex(k),i); %#ok<*AGROW>
    end
end

% Fit each indivdually measured gamma function to finely spaced real valued
% primary levels.
cal.computed.gammaInput = linspace(0,1,cal.describe.nGammaFitLevels)';
for k = 1:cal.describe.nGammaBands
    cal.computed.gammaTableMeasuredBands(:,k) = [0 ; cal.computed.gammaData1{k}'];
    cal.computed.gammaTableMeasuredBandsFit(:,k) = OLFitGamma(cal.computed.gammaInputRaw,cal.computed.gammaTableMeasuredBands(:,k),cal.computed.gammaInput,cal.describe.gammaFitType);
end

% Interpolate the measured bands out across all of the bands
for l = 1:cal.describe.nGammaFitLevels
    cal.computed.gammaTable(l,:) = interp1(cal.describe.gamma.gammaBands',cal.computed.gammaTableMeasuredBandsFit(l,:)',(1:cal.describe.numWavelengthBands)','linear','extrap')';   
end
for b = 1:cal.describe.numWavelengthBands
    cal.computed.gammaTable(b,:) = MakeMonotonic(cal.computed.gammaTable(b,:));
end

% Average gamma measurements over bands
cal.computed.gammaTableAvg = median(cal.computed.gammaTableMeasuredBandsFit,2);
