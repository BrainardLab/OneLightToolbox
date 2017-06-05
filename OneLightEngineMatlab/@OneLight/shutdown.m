function shutdown(obj)
% shutdown - Shuts down the OneLight device.
%
% Syntax:
% obj.shutdown
%
% Description:
% Shuts down the device.  Should be called prior to physically turning it
% off.

if (~obj.Simulate)
    if obj.IsOpen
        OneLightEngine(OneLightFunctions.Shutdown.UInt32, obj.DeviceID);
    end
end
