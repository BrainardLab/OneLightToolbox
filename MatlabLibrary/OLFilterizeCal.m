function calOut = OLFilterizeCal(calIn, S_filter, srf_filter)
% OLFilterizeCal - Incorporate filter measurements into an OL calibration structure.
%
% Syntax:
% oneLightCal = OLFilterizeCal(oneLightCalIn, S_filter, srf_filter)
%
% Description:
% Multiplies relevant calibration spectra by filter absorption.  This
% is meand to be called a wrapper program which reads in the filter
% data and which also reads/writes the calibration file.
%
% Modifies the raw measurements and then runs the init routine over
% the result.
%
% Does not handle omni measurments.  Throws an error if they are present
% in the calibration file.
%
% 7/3/13  dhb  Wrote it.

% Check for the number of arguments.
narginchk(3, 3, );

% Initialize
calOut = calIn;
if (~isfield(calOut.describe,'useOmni'))
    calOut.describe.useOmni = 1;
end

% Check for omni.  We don't handle that, throw
% an error to avoid stupidity if we ever put 
% omni measurements back into the whole system.
if (calOut.describe.useOmni)
    error('Filterizing process does not handle omni measurements.  Think about what to do.');
end

% Wavelength sampling and spline filter to match cal file
S = calOut.describe.S;
srf_filter = SplineSrf(S_filter,srf_filter,S);

% Now attenuate all PR-6xx measurements by the filter.
% We don't do the omni.
calOut.raw.darkMeas = calIn.raw.darkMeas.*srf_filter(:,ones(1,size(calIn.raw.darkMeas,2)));
calOut.raw.halfOnMeas = calIn.raw.halfOnMeas.*srf_filter(:,ones(1,size(calIn.raw.halfOnMeas,2)));
calOut.raw.lightMeas = calIn.raw.lightMeas.*srf_filter(:,ones(1,size(calIn.raw.lightMeas,2)));
for ii = 1:length(calIn.raw.gamma.rad)
    calOut.raw.gamma.rad(ii).meas = calIn.raw.gamma.rad(ii).meas.*srf_filter(:,ones(1,size(calIn.raw.gamma.rad(ii).meas,2)));
end
calOut.raw.independence.meas = calIn.raw.independence.meas.*srf_filter(:,ones(1,size(calIn.raw.independence.meas,2)));
calOut.raw.independence.measAll = calIn.raw.independence.measAll.*srf_filter(:,ones(1,size(calIn.raw.independence.measAll,2)));

% Initialize the modified calibration structure, so that the measurement changes propagate
calOut = OLInitCal(calOut);

