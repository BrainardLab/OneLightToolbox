function setMirrors(obj, starts, stops)
% setMirrors - Sets the mirrors on the device.
%
% Syntax:
% obj.setMirrors(starts, stops)
%
% Description:
% Sets the mirrors of the device.  The device has obj.NumRows * obj.NumCols
% mirrors that can be set on or off.  The pattern of mirrors is defined by
% 2 vectors, starts and stops, that define the start and end row of mirrors
% for each column.
%
% This function takes vectors (1 by NumCols) of start and stop mirror values (one for each column).
% Each entry is an integer in the range [0,NumRows-1], except for the "all off" special case
% noted below.  For each column, the mirrors between start and stop inclusive are turned on, which the
% indexing of rows is 0 based.
%
% We typically set start to 0.  With this, when stop is 0 the first mirror 
% in the corresponding column is on.  When stop is NumRows-1, all the mirrors 
% in the column are on. 
%
% To turn all the mirrors in a column off, set start to NumRows+1 and stops to 0.  Sigh.
% This is inferred from the C++ source code for method setAll in OLEngine.cpp.
%
% Input:
% starts (1xNumCols) - Vector defining the start row for each column.
% stops (1xNumCols) - Vector defining the stop row for each column.
% 
% See also OLSettingsToStartsStops.

% 01/17/14  dhb, ms  Comment tuning.
% 09/25/17  dhb      Add option not to plot when simulating, based on object property
%                    PlotWhenSimulating.

assert(nargin == 3, 'OneLight:setMirrors:NumInputs', 'Invalid number of inputs.');

% Validate the start/stop vector lengths.
assert(length(starts) == obj.NumCols, 'OneLight:setMirrors:OutOfBounds', ...
	'Length of "starts" must be %d', obj.NumCols);
assert(length(stops) == obj.NumCols, 'OneLight:setMirrors:OutOfBounds', ...
	'Length of "stops" must be %d', obj.NumCols);

% All starts and stops have to be converted to unsigned 16-bit integers.
if (~obj.Simulate)
    OneLightEngine(OneLightFunctions.SendPattern.UInt32, obj.DeviceID, uint16(starts), uint16(stops));
else
    if (obj.PlotWhenSimulating)
        figure(obj.SimFig); clf;
        hold on;
        plot(stops-starts,'ko','MarkerSize',2);
        drawnow;
        hold off;
    end
end
    