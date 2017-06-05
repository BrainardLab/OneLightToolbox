function open(obj)
% open - Opens the OneLight device.
%
% Syntax:
% obj.open
%
% Description:
% Opens a connection to the OneLight device.  All calls to a specific
% device need an active open connection so this function should be called
% before doing anything.  When opened, the current value of the LampCurrent
% property is applied to the device.  By default, this value is set to its
% max of 255.

% Don't try to re-open a connection, and simulate if simulating.
if (~obj.Simulate)
    if ~obj.IsOpen
        OneLightEngine(OneLightFunctions.Open.UInt32, obj.DeviceID);
    end
else
    obj.IsOpen = true;
end
