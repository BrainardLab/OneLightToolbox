function [maxPrimary,minPrimary,maxLum,minLum] = ...
    OLPrimaryInvSolveChrom(cal, desiredChromaticity, varargin)
% Find OneLight primaries to produce spectra at desired chromaticity
%
% Syntax:
%   [primaryTarget,primaryMax,primaryMin,maxLum,minLum] = ...
%       OLPrimaryInvSolveChrom(cal, desiredChromaticity, varargin)
%
% Describe:
%   Sometimes we want to produce lights with fixed relative spectra, for
%   example when we want to show a light flux modulation.  This is
%   surprisingly tricky: because of the ambient spectrum we can't just
%   scale primaries up and down to acheive this.
%
%   This function helps produce such modulations.  It has a few different
%   modes in terms of how it tries to optimize, see 'optimizationTarget' key
%   below.
%
%   This is a fairly brittle routine, in that fussing with the various of
%   the keys below can make a big difference to the outcome.
%
%   The 'lamda' value could be incorporated into the searches
%   performed within this routine. Currently it is just passed on
%   OLFindMaxSpd.
%
%   The 'primaryHeadroom' value is not respected for the maxContrast
%   optimization. This would be good to add.
%
% Inputs:
%   cal                       - OneLight calibration structure
%   desiredChrmaticity        - Column vector with desired CIE 1931 chromaticity.
%
% Outputs:
%   maxPrimary                - Primary settings that produce a spectrum
%                               with desired chromaticity at max possible in
%                               gamut luminance.
%   minPrimary                - Primary settings that produce same relative
%                               spd as max, but with minimum in gamut luminance.
%
% Optional key/value pairs:
%   'primaryHeadroom'         - Scalar.  Headroom to leave on primaries.  Default
%                               0.01. Adjusting this parameter to be larger
%                               will tend to decrease the maximum
%                               luminance, but increase the available Weber
%                               contrast of the modulation between min and
%                               max.  This is a little counterintuitive,
%                               and I believe has to do with the indirect
%                               effect of adjusting this parameter on the
%                               spectral shape of the maximum modulation.
%   'primaryTolerance         - Scalar. Truncate to range [0,1] if primaries are
%                               within this tolerance of [0,1]. Default 1e-6, and
%                               'checkPrimaryOutOfRange' value is true.
%   'checkPrimaryOutOfRange'  - Boolean. Perform tolerance check.  Default true.
%   'initialLuminanceFactor'  - Scaler. We need to start the search at an in gamut
%                               set of primaries that produce the desired
%                               chromaticity. This requires guessing an in
%                               gamut luminance for that chromaticity. We
%                               do this as a scaling down by this factor of
%                               the max device luminance. The routine does
%                               a little searching if the initial value
%                               doesn't do the trick.  If that fails,
%                               adjusting this may help. Default 0.2.
%   'whichXYZ'                - String giving XXX in T_XXX, where that is the
%                               loaded set of XYZ color matching functions.
%                               These can be anything that is in an appropriate
%                               T_ format file on the path.  Thes include
%                                 T_xyz1931
%                                 T_xyz1964
%                                 T_xyzJuddVos
%                                 T_xyzCIEPhys2
%                                 T_xyzCIEPhys10
%                             - Default 'xyzCIEPhys10'
%   'lambda'                  - Scalar. Smoothing value passed through to called
%                               routines, eventually for use in OLSpdToPrimary.
%                               Default 0.005.
%   'spdToleranceFraction'   -  Scalar. How closely min spectrum must match max in
%                               relative spd, in fractional terms. Relaxing
%                               this can get you more contrast between min
%                               and max. Default 0.01.
%   'chromaticityTolerance'  -  How close to desired chromaticity do we
%                               need to stay? Default 0.0001;
%   'optimizationTarget'     -  String. What to try to optimize.
%                                 'maxLum' maximize max luminance.
%                                 'minLum' minimize min luminance'
%                                 'maxContrast' maximize contrast.
%                               Default 'maxLum'.
%   'targetContrast'          - Scalar (default []). If not empty and
%                               target is 'maxContrast', then tries to
%                               produce this contrast instead of
%                               maximizing.
%   'primaryHeadroomForInitialMax' - Use this headroom when finding initial
%                               max luminance spd to use in turn to
%                               initialize search for minLum or maxContrast
%                               cases. Default 0.005.
%   'maxScaleDownForStart'    - How much to scale down initially found
%                               maxSpd, when determining starting point for
%                               minLum and maxContrast methods. Default 2.
%   'maxSearchIter'           - Control how long the search goes for.
%                               Default, 300.  Reduce if you don't need
%                               to go that long and things will get faster.
%   'verbose'                 - Boolean, provide various output if true.  Defalt false.
%
% See also:
%

% History:
%   05/22/15  ms      Wrote it.
%   06/29/17  dhb     Clean up.
%   03/27/18  dhb     Add 'primaryHeadroom' key/value pair.
%   04/01/18  dhb     Primary range stuff.
%   04/02/18  dhb     Rename and rewrite.
%   04/12/18  dhb     Update to call OLCheckPrimaryGamut.

%% Examples:
%{
    % Maximize luminance first, let min lumiance and contrast be what they are.
    % This does OK, but not as well as maximizing contrast (next example
    % below.)
    cal = OLGetCalibrationStructure('CalibrationType','DemoCal','CalibrationFolder',fullfile(tbLocateToolbox('OneLightToolbox'),'OLDemoCal'),'CalibrationDate','latest');
    [maxPrimary,minPrimary,maxLum,minLum] = OLPrimaryInvSolveChrom(cal, [0.54,0.38], ...
        'primaryHeadroom',0.005, 'lambda',0, 'spdToleranceFraction',0.005, 'verbose', true);
    fprintf('Max lum %0.2f, min lum %0.2f\n',maxLum,minLum);
    fprintf('Luminance weber contrast, low to high: %0.2f%%\n',100*(maxLum-minLum)/minLum);
    fprintf('Luminance michaelson contrast, around mean: %0.2f%%\n',100*(maxLum-minLum)/(maxLum+minLum));
%}
%{
    % Maximize contrast, let max/min luminances be what they are. This
    % needs a lot of iterations to converge, although it will eventually
    % yield a pretty a good solution with enormous contrast.
    cal = OLGetCalibrationStructure('CalibrationType','DemoCal','CalibrationFolder',fullfile(tbLocateToolbox('OneLightToolbox'),'OLDemoCal'),'CalibrationDate','latest');
    [maxPrimary,minPrimary,maxLum,minLum] = OLPrimaryInvSolveChrom(cal, [0.54,0.38], ...
        'primaryHeadroom',0.005, 'lambda',0, 'spdToleranceFraction',0.005,  ...
        'optimizationTarget','maxContrast', 'primaryHeadroomForInitialMax', 0.005, ...
        'maxScaleDownForStart', 2, 'chromaticityTolerance', 0.001, 'maxSearchIter', 1000, 'verbose',true);
    fprintf('Max lum %0.2f, min lum %0.2f\n',maxLum,minLum);
    fprintf('Luminance weber contrast, low to high: %0.2f%%\n',100*(maxLum-minLum)/minLum);
    fprintf('Luminance michaelson contrast, around mean: %0.2f%%\n',100*(maxLum-minLum)/(maxLum+minLum));
%}
%{
    % Minimize luminance first, let max lumiance and contrast be what they
    % are.  This seems to back itself into a search corner, and fail to find an
    % acceptable solution. Maybe with a little more parameter fussing....
    cal = OLGetCalibrationStructure('CalibrationType','DemoCal','CalibrationFolder',fullfile(tbLocateToolbox('OneLightToolbox'),'OLDemoCal'),'CalibrationDate','latest');
    [maxPrimary,minPrimary,maxLum,minLum] = OLPrimaryInvSolveChrom(cal, [0.54,0.38], ...
        'primaryHeadroom',0.005, 'lambda',0, 'spdToleranceFraction',0.005, ...
        'optimizationTarget','minLum', 'primaryHeadroomForInitialMax', 0.005, ...
        'maxScaleDownForStart', 2, 'verbose', true);
    fprintf('Max lum %0.2f, min lum %0.2f\n',maxLum,minLum);
    fprintf('Luminance weber contrast, low to high: %0.2f%%\n',100*(maxLum-minLum)/minLum);
    fprintf('Luminance michaelson contrast, around mean: %0.2f%%\n',100*(maxLum-minLum)/(maxLum+minLum));
%}

%% Input parser
p = inputParser;
p.addParameter('primaryHeadroom', 0.01, @isscalar);
p.addParameter('primaryTolerance', 1e-6, @isscalar);
p.addParameter('checkPrimaryOutOfRange', true, @islogical);
p.addParameter('initialLuminanceFactor', 0.2, @isnumeric);
p.addParameter('whichXYZ', 'xyzCIEPhys10', @ischar);
p.addParameter('lambda', 0.005, @isscalar);
p.addParameter('spdToleranceFraction', 0.01, @isscalar);
p.addParameter('chromaticityTolerance',0.0001, @isscalar);
p.addParameter('optimizationTarget', 'maxLum', @ischar);
p.addParameter('primaryHeadroomForInitialMax', 0.005, @isscalar);
p.addParameter('targetContrast', [], @(x) (isempty(x) || isscalar(x)));
p.addParameter('maxScaleDownForStart', 2, @isscalar);
p.addParameter('maxSearchIter',300,@isscalar);
p.addParameter('verbose', false, @islogical);
p.parse(varargin{:});

%% Set up some parameters
S = cal.describe.S;
if (p.Results.verbose)
    fminconDisplaySetting = 'iter';
else
    fminconDisplaySetting = 'off';
end

%% Load XYZ functions according to chosen type
eval(['tempXYZ = load(''T_' p.Results.whichXYZ ''');']);
eval(['T_xyz = SplineCmf(tempXYZ.S_' p.Results.whichXYZ ',683*tempXYZ.T_' p.Results.whichXYZ ',S);']);

%% Pull out key properties of OneLight cal
%
% Need this information to construct initial primaries
% with a little bit of linear algebra.
devicePrimaryBasis = cal.computed.pr650M;
nPrimaries = size(devicePrimaryBasis, 2);
ambientSpd = cal.computed.pr650MeanDark;

%% Get the maximum device luminance for this calibration
maxSpd = OLPrimaryToSpd(cal,ones(nPrimaries,1));
maxXYZ = T_xyz*maxSpd;
maxLuminance = maxXYZ(2);
maxxyY = XYZToxyY(maxXYZ);
ambientXYZ = T_xyz*ambientSpd;
ambientxyY = XYZToxyY(ambientXYZ);
ambientLuminance = ambientXYZ(2);

% Which headroom for initial max we want to use depends
% a bit on what we are doing, handle that specially here.
switch (p.Results.optimizationTarget)
    case 'maxLum'
        maxLumPrimaryHeadroom = p.Results.primaryHeadroom;
    case {'minLum', 'maxContrast'}
        maxLumPrimaryHeadroom = p.Results.primaryHeadroomForInitialMax;
    otherwise
        error('Unknown optimization target specified');
end

%% Construct basis functions for primaries
%
% We'll look for backgrounds within this space of primary weights.
B1 = 0.5*ones(nPrimaries,1);            % Half-on
B2 = 1-linspace(0, 1, nPrimaries);      % Linear ramp
B3 = 1-linspace(-1, 1, nPrimaries).^2;  % Quadratic
primaryWeightBasis = [B1 B2' B3'];      % Put them together

%% Construct matrix that goes between primary basis weights w and XYZ
M_primaryWeightsToXYZ = T_xyz*devicePrimaryBasis*primaryWeightBasis;
M_XYZToPrimaryWeights = inv(M_primaryWeightsToXYZ);

%% Define the target chromaticities and luminance
%
% Take an initial guess at in gamut luminance and then do a little
% searching if necessary.
initialLuminanceTries = 20;
luminanceGuess = maxLuminance*p.Results.initialLuminanceFactor;
for kki = 1:initialLuminanceTries
    % Set up initial XYZ based on luminance guess and desired chromaticity
    targetxyY = [desiredChromaticity(1) desiredChromaticity(2) luminanceGuess]';
    targetXYZ = xyYToXYZ(targetxyY);
    targetxy = targetxyY(1:2);
    
    % Solve for initial primaries with a linear method
    initialPrimaryWeights = M_XYZToPrimaryWeights*(targetXYZ-ambientXYZ);
    initialPrimaries = primaryWeightBasis*initialPrimaryWeights;
    
    %% Are initial primaries in gamut 
    [initialPrimaries,inGamut] = OLCheckPrimaryGamut(initialPrimaries, ...
        'primaryHeadroom',maxLumPrimaryHeadroom, ...
        'primaryTolerance',p.Results.primaryTolerance, ...
        'checkPrimaryOutOfRange',false);
    if (inGamut)
        % If we're good, break out of loop
        break;
    end
    
    % Try adjusting initial luminace
    luminanceGuess = 0.90*luminanceGuess/max(initialPrimaries(:));
end

%% Are initial primaries in gamut 
initialPrimaries = OLCheckPrimaryGamut(initialPrimaries, ...
    'primaryHeadroom',maxLumPrimaryHeadroom, ...
    'primaryTolerance',p.Results.primaryTolerance, ...
    'checkPrimaryOutOfRange',p.Results.checkPrimaryOutOfRange);

%% Chromaticity check
initialXYZ = T_xyz*OLPrimaryToSpd(cal,initialPrimaries, ...
    'primaryHeadroom',maxLumPrimaryHeadroom, ...
    'primaryTolerance',p.Results.primaryTolerance, ...
    'checkPrimaryOutOfRange',p.Results.checkPrimaryOutOfRange);
initialXYZ = T_xyz*OLPrimaryToSpd(cal,initialPrimaries,'skipAllChecks',true);
initialxyY = XYZToxyY(initialXYZ);
if (sqrt(sum((targetxy-initialxyY(1:2)).^2)) > p.Results.chromaticityTolerance)
    error('Initial primaries do not have desired chromaticity');
end

% Maximize luminance while staying at chromaticity.
%
% This seems to work robustly, and thus we use it for helping to
% start other options.
options = optimset('fmincon');
options = optimset(options,'Diagnostics','off','Display',fminconDisplaySetting,'LargeScale','off','Algorithm','active-set', 'MaxIter', p.Results.maxSearchIter, 'MaxFunEvals', 1000000, 'TolFun', 1e-3, 'TolCon', 1e-6, 'TolX', 1e-4);
vub = ones(size(devicePrimaryBasis, 2), 1)  - maxLumPrimaryHeadroom;
vlb = zeros(size(devicePrimaryBasis, 2), 1) + maxLumPrimaryHeadroom;
x = fmincon(@(x) ObjFunctionMaxLum(x, cal, T_xyz), ...
    PrimaryToX(initialPrimaries),[],[],[],[],vlb,vub, ...
    @(x)ChromaticityNonlcon(x, cal, T_xyz, targetxy, p.Results.chromaticityTolerance), ...
    options);
maxPrimary = XToPrimary(x); clear x;

%{
[c, ceq] = ChromaticityNonlcon(x, devicePrimaryBasis, ambientSpd, T_xyz, targetxy, p.Results.chromaticityTolerance)
%}

%% Check that primaries are still within gamut to tolerance.
maxPrimary = OLCheckPrimaryGamut(maxPrimary,...
    'primaryHeadroom',maxLumPrimaryHeadroom, ...
    'primaryTolerance',p.Results.primaryTolerance, ...
    'checkPrimaryOutOfRange',p.Results.checkPrimaryOutOfRange);

%% Get max spd and its luminance
maxSpd = OLPrimaryToSpd(cal,maxPrimary);
maxLum = T_xyz(2,:)*maxSpd;

% Maximize
switch (p.Results.optimizationTarget)
    case 'maxLum'
        % Find minimum luminance spd with same relative luminance as max
        [minSpd, minPrimary] = OLFindMaxSpd(cal, maxSpd, maxPrimary, T_xyz, ...
            'lambda', p.Results.lambda, ...
            'primaryHeadroom',p.Results.primaryHeadroom, ...
            'primaryTolerance',p.Results.primaryTolerance, ...
            'findMin', true, ...
            'spdToleranceFraction', p.Results.spdToleranceFraction, ...
            'checkSpd', true, ...
            'verbose', p.Results.verbose);
        minLum = T_xyz(2,:)*minSpd;
        
    case 'minLum'
        % Obtain some initial primaries from the max
        %initialPrimaries = OLSpdToPrimary(cal, maxSpd/p.Results.maxScaleDownForStart, 'lambda', p.Results.lambda);
        initialPrimaries = maxPrimary;
        
        % Minimize luminance while staying at chromaticity
        % Then take resulting maxSpd and find the spd with same
        % relative spectrum that has maximum within gamut luminance.
        options = optimset('fmincon');
        options = optimset(options,'Diagnostics','off','Display',fminconDisplaySetting,'LargeScale','off','Algorithm','active-set', 'MaxIter', p.Results.maxSearchIter, 'MaxFunEvals', 1000000, 'TolFun', 1e-3, 'TolCon', 1e-6, 'TolX', 1e-4);
        vub = ones(size(devicePrimaryBasis, 2), 1)-p.Results.primaryHeadroom;
        vlb = ones(size(devicePrimaryBasis, 2), 1)*p.Results.primaryHeadroom;
        x = fmincon(@(x) ObjFunctionMinLum(x, cal, T_xyz), ...
            PrimaryToX(initialPrimaries),[],[],[],[],vlb,vub, ...
            @(x)ChromaticityNonlcon(x, cal, T_xyz, targetxy, p.Results.chromaticityTolerance), ...
            options);
        minPrimary = XToPrimary(x); clear x;
        
        %% Check that primaries are within gamut to tolerance.
        minPrimary = OLCheckPrimaryGamut(minPrimary,...
            'primaryHeadroom',p.Results.primaryHeadroom, ...
            'primaryTolerance',p.Results.primaryTolerance, ...
            'checkPrimaryOutOfRange',p.Results.checkPrimaryOutOfRange);
                
        % Get min spd and its luminance
        minSpd = OLPrimaryToSpd(cal,minPrimary);
        minLum = T_xyz(2,:)*minSpd;
        
        % Find maximum luminance spd with same relative luminance as max
        [maxSpd, maxPrimary] = OLFindMaxSpd(cal, minSpd, minPrimary, T_xyz, ...
            'primaryHeadroom',p.Results.primaryHeadroom, ...
            'primaryTolerance',p.Results.primaryTolerance, ...
            'lambda', p.Results.lambda, ...
            'findMin', false, ...
            'spdToleranceFraction', p.Results.spdToleranceFraction, ...
            'checkSpd', true, ...
            'verbose', p.Results.verbose);
        maxLum = T_xyz(2,:)*maxSpd;
        
    case 'maxContrast'
        % Find maxSpd and minSpd that maximize luminance contrast.
        
        % Obtain some initial primaries from the max
        % initialSpd = maxSpd/p.Results.maxScaleDownForStart;
        % initialPrimaries = OLSpdToPrimary(cal, initialSpd, 'lambda', p.Results.lambda);
        
        % Maximize luminance while staying at chromaticity
        % Then take resulting maxSpd and find the spd with same
        % relative specrum that has minimum within gamut luminance.
        options = optimset('fmincon');
        options = optimset(options,'Diagnostics','off','Display',fminconDisplaySetting,'LargeScale','off','Algorithm','active-set', 'MaxIter', p.Results.maxSearchIter, 'MaxFunEvals', 1000000, 'TolFun', 1e-3, 'TolCon', 1e-6, 'TolX', 1e-4);
        vub = ones(size(devicePrimaryBasis, 2), 2)-p.Results.primaryHeadroom;
        vlb = ones(size(devicePrimaryBasis, 2), 2)*p.Results.primaryHeadroom;
        x = fmincon(@(x) ObjFunctionMaxContrast(x, cal, T_xyz, p.Results.targetContrast), ...
            PrimaryToX([initialPrimaries initialPrimaries]),[],[],[],[],vlb,vub, ...
            @(x)RelativeSpdNonlcon(x, cal, T_xyz, targetxy, p.Results.spdToleranceFraction, p.Results.chromaticityTolerance), ...
            options);
        maxPrimary = XToPrimary(x(:,1));
        minPrimary = XToPrimary(x(:,2));
        
        % Take a look at how well we did on contraints
        %{
        [c, ceq] = RelativeSpdNonlcon(x, cal, ...
            T_xyz, targetxy, p.Results.spdToleranceFraction, p.Results.chromatiticyTolerance);
        %}
        
        % Check that primaries are within gamut to tolerance.
        maxPrimary = OLCheckPrimaryGamut(maxPrimary,...
            'primaryHeadroom',p.Results.primaryHeadroom, ...
            'primaryTolerance',p.Results.primaryTolerance, ...
            'checkPrimaryOutOfRange',p.Results.checkPrimaryOutOfRange);
        minPrimary = OLCheckPrimaryGamut(minPrimary,...
            'primaryHeadroom',p.Results.primaryHeadroom, ...
            'primaryTolerance',p.Results.primaryTolerance, ...
            'checkPrimaryOutOfRange',p.Results.checkPrimaryOutOfRange);
        
        % Get spds and their luminances
        maxSpd = OLPrimaryToSpd(cal,maxPrimary);
        maxLum = T_xyz(2,:)*maxSpd;
        minSpd = OLPrimaryToSpd(cal,minPrimary);
        minLum = T_xyz(2,:)*minSpd;
        
        %{
        maxContrast = (maxLum-minLum)/minLum
        save foo maxSpd minSpd maxPrimary minPrimary
        %}
        
    otherwise
        error('Unknown optimization target');
end



% Can look at these to see if chromaticities came out right
if (p.Results.verbose)
    checkXYZMax = T_xyz*maxSpd;
    checkxyYMax = XYZToxyY(checkXYZMax)
    checkXYZMin = T_xyz*minSpd;
    checkxyYMin = XYZToxyY(checkXYZMin)
end

% Figure for checking
if (p.Results.verbose)
    figure; hold on
    plot(maxSpd,'r','LineWidth',3);
    plot(minSpd,'g');
    plot((minSpd\maxSpd)*minSpd,'k-','LineWidth',1);
end

end

%% Objective function to maximize luminance
function f = ObjFunctionMaxLum(x, cal, T_xyz)

% Convert x to primary
primary = XToPrimary(x);

% Get spectrum and luminance
theSpd = OLPrimaryToSpd(cal,primary,'skipAllChecks',true);
theLuminance = T_xyz(2,:)*theSpd;

% Maximize the luminance
f = -theLuminance;
end

%% Objective function to minimize luminance
function f = ObjFunctionMinLum(x, cal, T_xyz)

% Convert x to primary
primary = XToPrimary(x);

% Get spectrum and luminance
theSpd = OLPrimaryToSpd(cal,primary,'skipAllChecks',true);
theLuminance = T_xyz(2,:)*theSpd;

% Minimize the luminance
f = theLuminance;
end

%% Objective function to maximize contrast
function f = ObjFunctionMaxContrast(x, cal, T_xyz, targetContrast)

% Convert x to primary
primary = XToPrimary(x);

% Get spectrum and luminance
theSpds = OLPrimaryToSpd(cal,primary,'skipAllChecks',true);
theLuminances= T_xyz(2,:)*theSpds;
theContrast = (theLuminances(1)-theLuminances(2))/theLuminances(2);

if (isempty(targetContrast))
    % Maximize the contrast 
    f = -theContrast;
else
    % Minimize deviation from target
    f = (theContrast-targetContrast)^2;
end
end

%% Constraint function for chromaticity optimization
%
% Forces chromaticities to stay at target
function [c, ceq] = ChromaticityNonlcon(x, cal, T_xyz, targetxy, chromaticityTolerance)

% Convert x to primary
primary = XToPrimary(x);

% Calculate spectra and chromaticities
theSpds = OLPrimaryToSpd(cal,primary,'skipAllChecks',true);
theXYZs = T_xyz*theSpds;
thexyYs = XYZToxyY(theXYZs);

chromErrs = zeros(size(thexyYs,2),1);
for kk = 1:size(thexyYs,2)
    chromErrs(kk) = sqrt(sum((targetxy-thexyYs(1:2,kk)).^2));
end

% Set constraints.  The 0.95 gives us a little room in the numercal
% search.
c = chromErrs - 0.95*chromaticityTolerance;
ceq = [];

end

%% Constraint function for relative spd optimization
%
% Forces chromaticities to stay at target and relative spds to match within
% tolerance
function [c, ceq] = RelativeSpdNonlcon(x, cal, T_xyz, targetxy, spdToleranceFraction, chromaticityTolerance)

% Convert x to primary
primary = XToPrimary(x);

% Calculate spectra
theSpds = OLPrimaryToSpd(cal,primary,'skipAllChecks',true);

% Get how well we're doing on target chromaticity
[c1, ~] = ChromaticityNonlcon(primary, cal, T_xyz, targetxy, chromaticityTolerance);

% Take mean spectra as target for relative spds
targetSpd = mean(theSpds,2);

% Get tolerance for spd matching
spdTolerance = max(abs(spdToleranceFraction*targetSpd(:)));

% Evalute how close each spectrum is to target after best scaling
cRaw = zeros(size(theSpds,2),1);
for kk = 1:size(theSpds,2)
    predictedRelativeSpd = (theSpds(:,kk)\targetSpd)*theSpds(:,kk);
    [~, errorFraction] = OLCheckSpdTolerance(targetSpd,predictedRelativeSpd, ...
        'checkSpd', false, 'spdToleranceFraction', spdToleranceFraction);
    cRaw(kk) = errorFraction-0.95*spdToleranceFraction; 
end

% Set inequality contraints
c2 = cRaw(:) - spdTolerance;
c = [c1(:) ; c2(:)];

% No equality constraint
ceq = [];

% Figure for debugging
%{
figure; clf; hold on
plot(targetSpd,'k','LineWidth',3);
plot(predTargetSpd,'r');
%}

end

%% PrimaryToX
function x = PrimaryToX(primary)

x = primary;

% This was a sort of clever idea,
% but hard to put vlb and vub in place
% doing it this way.
%
% x = zeros(size(primary));
% for ii = 1:size(x,2)
%     meanVal = mean(primary(:,ii));
%     x(1,ii) = meanVal;    
%     x(2:end,ii) = primary(1:end-1,ii)/meanVal;
% end

end

function primary = XToPrimary(x)

primary = x;

% This was a sort of clever idea,
% but hard to put vlb and vub in place
% doing it this way.
%
% primary = zeros(size(x));
% for ii = 1:size(x,2)
%     meanVal = x(1,ii);
%     primary(1:end-1,ii) = x(2:end,ii)*meanVal;
%     sumPrimary = meanVal*size(primary,1);
%     primary(end,ii) = sumPrimary-sum(primary(1:end-1,ii));
% end


end

