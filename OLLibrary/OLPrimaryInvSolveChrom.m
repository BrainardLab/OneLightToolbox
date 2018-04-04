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
%   This function helps produce desired modulations.  First, it finds the
%   maximum luminance that can be produced at a given chromaticity.
%
%   Then it finds the minimum luminance possible with the same relative
%   spectral power distribution.  This information then allows us to figure
%   out the range of luminances over which we can make light flux
%   modulations with the desired chromaticity, and with the relative
%   spectral power distribution held fixed.
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
%   'PrimaryHeadroom'         - Scalar.  Headroom to leave on primaries.  Default
%                               0.1.
%   'PrimaryTolerance         - Scalar. Truncate to range [0,1] if primaries are
%                               within this tolerance of [0,1]. Default 1e-6, and
%                               'CheckOutOfRange' value is true.
%   'CheckOutOfRange'         - Boolean. Perform tolerance check.  Default true.
%   'InitialLuminanceFactor'  - Scaler. We need to start the search at an in gamut
%                               set of primaries that produce the desired
%                               chromaticity. This requires guessing an in
%                               gamut luminance for that chromaticity. We
%                               do this as a scaling down by this factor of
%                               the max device luminance. The routine does
%                               a little searching if the initial value
%                               doesn't do the trick.  If that fails,
%                               adjusting this may help. Default 0.2.
%   'WhichXYZ'                - String giving XXX in T_XXX, where that is the
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
%                               Default 0.
%   'spdToleranceFraction'   -  Scalar. How closely min spectrum must match max in
%                               relative spd, in fractional terms. Relaxing
%                               this can get you more contrast between min
%                               and max. Default 0.01.
%
% See also:
%

% History:
%   05/22/15  ms      Wrote it.
%   06/29/17  dhb     Clean up.
%   03/27/18  dhb     Add 'PrimaryHeadroom' key/value pair.
%   04/01/18  dhb     Primary range stuff.
%   04/02/18  dhb     Rename and rewrite.

%% Examples:
%{
% Get the OneLightToolbox demo cal structure
cal = OLGetCalibrationStructure('CalibrationType','DemoCal','CalibrationFolder',fullfile(tbLocateToolbox('OneLightToolbox'),'OLDemoCal'),'CalibrationDate','latest');
[maxPrimary,minPrimary,maxLum,minLum] = OLPrimaryInvSolveChrom(cal, [0.54,0.38], ...
    'lambda',0,'spdToleranceFraction',0.005);
fprintf('Max lum %0.2f, min lum %0.2f\n',maxLum,minLum);
fprintf('Luminance weber contrast, low to high: %0.2f%%\n',100*(maxLum-minLum)/minLum);
fprintf('Luminance michaelson contrast, around mean: %0.2f%%\n',100*(maxLum-minLum)/(maxLum+minLum));
%}

%% Input parser
p = inputParser;
p.addParameter('PrimaryHeadroom',0.1,@isscalar);
p.addParameter('PrimaryTolerance',1e-6,@isscalar);
p.addParameter('CheckOutOfRange',true,@islogical);
p.addParameter('InitialLuminanceFactor',0.2,@isnumeric);
p.addParameter('WhichXYZ','xyzCIEPhys10',@ischar);
p.addParameter('lambda', 0.0, @isscalar);
p.addParameter('spdToleranceFraction', 0.01, @isscalar);
p.parse(varargin{:});

%% Set up some parameters
S = cal.describe.S;

%% Load XYZ functions according to chosen type
eval(['tempXYZ = load(''T_' p.Results.WhichXYZ ''');']);
eval(['T_xyz = SplineCmf(tempXYZ.S_' p.Results.WhichXYZ ',683*tempXYZ.T_' p.Results.WhichXYZ ',S);']);

%% Pull out key properties of OneLight cal
devicePrimaryBasis = cal.computed.pr650M;
nPrimaries = size(devicePrimaryBasis, 2);
ambientSpd = cal.computed.pr650MeanDark;

%% Get the maximum device luminance for this calibration
maxSpd = devicePrimaryBasis*ones(size(devicePrimaryBasis,2),1) + ambientSpd;
maxXYZ = T_xyz*maxSpd;
maxLuminance = maxXYZ(2);
maxxyY = XYZToxyY(maxXYZ);
ambientLuminance = T_xyz(2,:)*ambientSpd;

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
initialLuminanceTries = 3;
luminanceGuess = maxLuminance*p.Results.InitialLuminanceFactor;
for ii = 1:initialLuminanceTries
    % Set up initial XYZ based on luminance guess and desired chromaticity
    xyY_target = [desiredChromaticity(1) desiredChromaticity(2) luminanceGuess]';
    xy_target = xyY_target(1:2);
    XYZ_target = xyYToXYZ(xyY_target);
    
    % Solve for initial primaries with a linear method
    initialPrimaryWeights = M_XYZToPrimaryWeights*XYZ_target;
    initialPrimaries = primaryWeightBasis*initialPrimaryWeights;
    if (all(initialPrimaries >= 0 & initialPrimaries <= 1))
        % If we're good, break out of loop
        break;
    end
    
    % Try adjusting initial luminace
    luminanceGuess = 0.99*luminanceGuess/max(initialPrimaries(:));  
end

%% Are initial primaries in gamut and do they produce desired chromaticity.
if (any(initialPrimaries < 0 | initialPrimaries > 1))
        fprintf('Cannot find within gamut primaries for guess at initial luminance.\n');
        fprintf('Try adjusting value for ''InitialLuminanceFactor'' key.\n');
        error('');
end
    
%% Chromaticity check
initialxyYTolerance = 1e-5;
initialXYZ = T_xyz*devicePrimaryBasis*initialPrimaries;
initialxyY = XYZToxyY(initialXYZ);
if (any( max(abs(xy_target-initialxyY(1:2))) > initialxyYTolerance))
    error('Initial primaries do not have desired chromaticity');
end

%% Maximize luminance while staying at chromaticity
options = optimset('fmincon');
options = optimset(options,'Diagnostics','off','Display','off','LargeScale','off','Algorithm','active-set', 'MaxIter', 10000, 'MaxFunEvals', 100000, 'TolFun', 1e-10, 'TolCon', 1e-10, 'TolX', 1e-10);
maxHeadroom = p.Results.PrimaryHeadroom;
vub = ones(size(devicePrimaryBasis, 2), 1)-maxHeadroom;
vlb = ones(size(devicePrimaryBasis, 2), 1)*maxHeadroom;
x = fmincon(@(x) ObjFunction(x, devicePrimaryBasis, ambientSpd, T_xyz),initialPrimaries,[],[],[],[],vlb,vub,@(x)ChromaticityNonlcon(x, devicePrimaryBasis, ambientSpd, T_xyz, xy_target),options);
maxPrimary = x;

%% Check that primaries are within gamut to tolerance.
maxPrimary(maxPrimary > 1 & maxPrimary < 1 + p.Results.PrimaryTolerance) = 1;
maxPrimary(maxPrimary < 0 & maxPrimary > -p.Results.PrimaryTolerance) = 0;
if (p.Results.CheckOutOfRange && (any(maxPrimary(:) > 1) || any(maxPrimary(:) < 0) ))
    error('At one least primary value is out of range [0,1]');
end

%% Can look at these to see if things came out right
% checkXYZ = T_xyz*B_primary*backgroundPrimary;
% checkxyY = XYZToxyY(checkXYZ)

%% Get max spd and its luminance
maxSpd = OLPrimaryToSpd(cal,maxPrimary);
maxLum = T_xyz(2,:)*maxSpd;

%% Get spd and then find minimum luminance with same spd
lambda = 0;
[minSpd, minPrimary] = OLFindMaxSpectrum(cal, maxSpd, ...
    'lambda', lambda, ...
    'findMin', true, ...
    'spdToleranceFraction', p.Results.spdToleranceFraction, ...
    'checkSpd', true);
minLum = T_xyz(2,:)*minSpd;

end

%% Objective function to maximize luminance
function f = ObjFunction(x, devicePrimaryBasis, ambientSpd, T_xyz)

% Get spectrum and luminance
theSpd = devicePrimaryBasis*x + ambientSpd;
theLuminance = T_xyz(2,:)*theSpd;

% Maximize the luminance
f = -theLuminance;

end

%% Constraint function for the optimization
%
% Forces chromaticity to stay at target
function [c ceq] = ChromaticityNonlcon(x, devicePrimaryBasis, ambientSpd, T_xyz, target_xy)

% Calculate spectrum and chromaticity
theSpd = devicePrimaryBasis*x + ambientSpd;
theXYZ = T_xyz*theSpd;
thexyY = XYZToxyY(theXYZ);

c = [];
ceq = [(target_xy-thexyY(1:2)).^2];

end