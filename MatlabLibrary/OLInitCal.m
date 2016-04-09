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
%              Throw an error if cal.describe.useOmni is true.  That code
%              is not updated.
%              Comment out most instances of conditionals for the useOmni
%              option.  I think we should move towards gutting these both
%              here and in the calibration code.

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

if (~isempty(parser.Results.CorrectLinearDrift))
    cal.describe.correctLinearDrift = parser.Results.CorrectLinearDrift;
end

% Backwards compatibiilty
cal = OLCalBackwardsCompatibility(cal);

% Wavelength sampling
cal.computed.pr650S = cal.describe.S;
cal.computed.pr650Wls = SToWls(cal.computed.pr650S);
if (cal.describe.useOmni)
    error('The omni driver code is obsolete and needs to be updated or given up on');
    cal.computed.omniWls = cal.describe.omniDriver.wavelengths;
    cal.computed.omniSplineWls = linspace(cal.computed.omniWls(1), ...
        cal.computed.omniWls(end),length(cal.computed.omniWls))';
    cal.computed.omniSplineS = WlsToS(cal.computed.omniSplineWls);
    cal.computed.commonWlsIndex = cal.computed.omniWls > ...
        cal.computed.pr650Wls(1) & cal.computed.omniWls < ...
        cal.computed.pr650Wls(end);
    cal.computed.commonWls = cal.computed.omniWls(cal.computed.commonWlsIndex);
else
    cal.computed.commonWls = cal.computed.pr650Wls;
end

% Figure out the scalar to correct for the linear drift
if cal.describe.correctLinearDrift
    fullOn0 = cal.raw.fullOn(:,1);
    fullOn1 = cal.raw.fullOn(:,2);
    s = fullOn0 \ fullOn1;
    t0 = cal.raw.t.fullOn(1);
    t1 = cal.raw.t.fullOn(2);
    returnScaleFactor = @(t) 1./((1-(1-s)*((t-t0)./(t1-t0))));
end

% Get data
cal.computed.D = cal.raw.cols;
if cal.describe.correctLinearDrift
    cal.computed.pr650M = bsxfun(@times, cal.raw.lightMeas, returnScaleFactor(cal.raw.t.lightMeas));
    cal.computed.pr650Md = bsxfun(@times, cal.raw.darkMeas, returnScaleFactor(cal.raw.t.darkMeas));
    if (cal.describe.specifiedBackground)
        cal.computed.pr650MEffectiveBg = bsxfun(@times, cal.raw.effectiveBgMeas, returnScaleFactor(cal.raw.t.cal.raw.effectiveBgMeas));
    end
else
    cal.computed.pr650M = cal.raw.lightMeas;
    cal.computed.pr650Md = cal.raw.darkMeas;]
    if (cal.describe.specifiedBackground)
        cal.computed.pr650MEffectiveBg = cal.raw.effectiveBgMeas;
    end
end
% if (cal.describe.useOmni)
%     cal.computed.omniM = cal.raw.omniDriver.lightMeas;
%     cal.computed.omniMd = cal.raw.omniDriver.darkMeas;
%     if (cal.describe.specifiedBackground)
%         cal.computed.omniMEffectiveBg = cal.raw.omniDriver.EffectiveBgMeas;
%     end
% end

% Subtract appropriate measurement to get the incremental spectrum for each
% primary.  We have two options for this.  In the standard option, only the
% mirrors for the primary were one when the primary was measured, and so we
% just need to subtract the dark spectrum.  If we measured the primary
% around a custom specified background, however, we need to subtract an
% individualized measurement from each spectrum.  Because spectra are the
% incremental effect either way (that is, the effect of taking a primary's
% mirrors from all off to all on), we still handle computing what we want
% to do from spectra in the same manner in either case.
if (cal.describe.specifiedBackground)
    cal.comptude.pr650M = cal.computed.pr650M-cal.computed.pr650MEffectiveBg;
    cal.computed.pr650M(cal.computed.pr650M < 0) = 0;
    % if (cal.describe.useOmni)
    %     cal.computed.omniM = cal.computed.omniM - cal.computed.omniMEffectiveBg;
    %     cal.computed.omniM(cal.computed.omniM < 0) = 0;
    % end
else
    cal.computed.pr650MeanDark = mean(cal.computed.pr650Md,2);
    cal.computed.pr650MeanDark(cal.computed.pr650MeanDark < 0) = 0;
    cal.computed.pr650M = cal.computed.pr650M - ...
        cal.computed.pr650MeanDark(:,ones(1,size(cal.computed.pr650M,2)));
    cal.computed.pr650M(cal.computed.pr650M < 0) = 0;
    % if (cal.describe.useOmni)
    %     cal.computed.omniMeanDark = mean(cal.computed.omniMd,2);
    %     cal.computed.omniMeanDark(cal.computed.omniMeanDark < 0) = 0;
    %     cal.computed.omniM = cal.computed.omniM - ...
    %         cal.computed.omniMeanDark(:,ones(1,size(cal.computed.omniM,2)));
    %     cal.computed.omniM(cal.computed.omniM < 0) = 0;
    % end
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

%% This code is set up to bring PR-6xx and omni into register.
% Don't do it if no omni measurements.
% 
% [DHB, 4/9/16] It is possible we should strip the omni stuff out of the whole
% suite of calibration code because we never really got it to work well and
% we never use it.  Getting rid of it would simplify reading and modifying the code.
% if (cal.describe.useOmni)
%     % Set up convolution filter for simulating PR-650
%     % The PR-650 is specified to have an 8 nm full-width
%     % at half-max.
%     switch (cal.describe.meterType)
%         case 1
%             cal.computed.pr650fwhm = 8;
%         case 5
%             cal.computed.pr650fwhm = 5;
%         otherwise
%             error('Unexpected meter type');
%     end
%     cal.computed.gaussWls = (0:cal.computed.omniSplineWls(2) - cal.computed.omniSplineWls(1):30)';
%     cal.computed.sigma = cal.computed.pr650fwhm/(2*sqrt(2*log(2)));
%     cal.computed.gaussConv = normpdf(cal.computed.gaussWls, 15, cal.computed.sigma);
%     cal.computed.gaussConv = cal.computed.gaussConv/sum(cal.computed.gaussConv(:));
%     
%     % Get PR-650 and omni measurements on common wavelength scale,
%     % and simulate PR-650 fwhm via omni measurements.
%     for i = 1:size(cal.computed.omniM, 2)
%         cal.computed.pr650MCommon(:,i) = ...
%             interp1(cal.computed.pr650Wls,cal.computed.pr650M(:,i),cal.computed.commonWls);
%         cal.computed.omniMSpline(:,i) = ...
%             interp1(cal.computed.omniWls,cal.computed.omniM(:,i),cal.computed.omniSplineWls);
%         cal.computed.omniMConv(:,i) = conv(cal.computed.omniMSpline(:,i),cal.computed.gaussConv,'same');
%         cal.computed.omniMConvCommon = ...
%             interp1(cal.computed.omniSplineWls,cal.computed.omniMConv,cal.computed.commonWls);
%         [~, tempIndex] = max(cal.computed.omniMConvCommon(:,i));
%         cal.computed.omniMPeakWls(i) = cal.computed.commonWls(tempIndex(1));
%     end
%     
%     % Find factor at each common wl to bring omni measurement into
%     % alignment with pr650 measurement.
%     switch cal.computed.FactorsMethod
%         case 1
%             for i = 1:size(cal.computed.omniM, 2)
%                 cal.computed.omniToPr650FactorsRaw(i) = ...
%                     cal.computed.omniMConvCommon(:,i)\cal.computed.pr650MCommon(:,i);
%             end
%             cal.computed.omniToPr650FactorsCommon = ...
%                 interp1(cal.computed.omniMPeakWls, cal.computed.omniToPr650FactorsRaw, ...
%                 cal.computed.commonWls,'linear','extrap');
%             
%         case {0, 2}
%             cal.computed.usePowerFraction = 0.2;
%             numRows = 0;
%             for j = 1:length(cal.computed.commonWls)
%                 maxPow = max(cal.computed.pr650MCommon(j,:));
%                 useIndex = find(cal.computed.pr650MCommon(j,:) >= cal.computed.usePowerFraction*maxPow);
%                 cal.computed.omniToPr650FactorsCommon(j) = ...
%                     cal.computed.omniMConvCommon(j,useIndex)'\cal.computed.pr650MCommon(j,useIndex)';
%                 numRows = numRows + length(useIndex);
%             end
%             cal.computed.omniToPr650FactorsCommon = cal.computed.omniToPr650FactorsCommon';
%             C1 = zeros(numRows,length(cal.computed.commonWls));
%             d1 = zeros(numRows,1);
%             
%             if cal.computed.FactorsMethod == 2
%                 % Enforce constraints.
%                 outIndex = 1;
%                 for j = 1:length(cal.computed.commonWls)
%                     maxPow = max(cal.computed.pr650MCommon(j,:));
%                     useIndex = find(cal.computed.pr650MCommon(j,:) >= cal.computed.usePowerFraction*maxPow);
%                     for k = 1:length(useIndex)
%                         C1(outIndex,j) = cal.computed.omniMConvCommon(j,useIndex(k));
%                         d1(outIndex) = cal.computed.pr650MCommon(j,useIndex(k));
%                         outIndex = outIndex + 1;
%                     end
%                 end
%                 lambda1 = 1;
%                 C2 = zeros(length(cal.computed.commonWls) - 1, length(cal.computed.commonWls));
%                 for i = 1:length(cal.computed.commonWls) - 1
%                     C2(i,i) = lambda1;
%                     C2(i,i+1) = -lambda1;
%                 end
%                 d2 = zeros(length(cal.computed.commonWls) - 1, 1);
%                 C = [C1 ; C2];
%                 d = [d1 ; d2];
%                 
%                 % Commented out code uses lsqlin, but actually I realized this can just be done
%                 % with simple regression, because the constraint itself is expressed as a
%                 % squared-error function of the solution.
%                 %options = optimset('lsqlin');
%                 %options = optimset(options,'Diagnostics','off','Display','off','LargeScale','off');
%                 %oneLightCal.computed.omniToPr650FactorsCommon = lsqlin(C,oneLightCal.computed.D,[],[],[],[],zeros(size(oneLightCal.computed.omniToPr650FactorsCommon)),[],oneLightCal.computed.omniToPr650FactorsCommon0,options);
%                 cal.computed.omniToPr650FactorsCommon0 = cal.computed.omniToPr650FactorsCommon;
%                 cal.computed.omniToPr650FactorsCommon = sparse(C)\d;
%             end
%     end
% end

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
    if (cal.describe.correctLinearDrift)
        gammaTemp = bsxfun(@times, cal.raw.gamma.rad(k).meas, returnScaleFactor(cal.raw.t.gamma.rad(k).meas));
        if (cal.describe.specifiedBackground)
            gammaEffectiveBgTemp = ...
                bsxfun(@times, cal.raw.gamma.rad(k).effectiveBgMeas, returnScaleFactor(cal.raw.t.gamma.rad(k).effectiveBgMeas));
        end
    else
        gammaTemp = cal.raw.gamma.rad(k).meas;
        if (cal.describe.specifiedBackground)
            gammaEffectiveBgTemp = cal.raw.gamma.rad(k).effectiveBgMeas;
        end
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

% Extract the gamma data for the OmniDriver.
%
% The odds that this still works are very very low.
% if (cal.describe.useOmni)
%     error('The omni code is way out of date and will need to be carefully thought about and updated');
%     for k = 1:size(cal.raw.gamma.omnidriver,2)
%         omniGammaMeas{k} = cal.raw.gamma.omnidriver(k).meas - cal.computed.omniMeanDark(:,ones(1,size(cal.raw.gamma.omnidriver(k).meas,2)));
%         for i = 1:size(cal.raw.gamma.omnidriver(1).meas,2)
%             cal.computed.omniGammaData1{k}(i) = omniGammaMeas{k}(:,end)\omniGammaMeas{k}(:,i); %#ok<*AGROW>
%         end
%     end
%     cal.computed.omniGammaData = 0;
%     for k = 1:size(cal.raw.gamma.rad,2);
%         cal.computed.omniGammaData = cal.computed.omniGammaData + cal.computed.omniGammaData1{k}';
%     end
%     cal.computed.omniGammaData = cal.computed.omniGammaData/size(cal.raw.gamma.omnidriver,2);
%     cal.computed.omniGammaInput = linspace(0,1,1024)';
%     cal.computed.omniGammaTable = FitGamma(cal.computed.gammaInputRaw, [0 ; cal.computed.omniGammaData],cal.computed.gammaInput,6);
%     cal.computed.omniGammaTable = MakeMonotonic(cal.computed.omniGammaTable);
% end
