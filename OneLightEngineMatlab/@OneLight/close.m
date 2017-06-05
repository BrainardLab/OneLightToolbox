function close(obj)
% close - Closes the connection to the OneLight device.
%
% Syntax:
% obj.close
%
% Description:
% If currently connected to the OneLight device, close the connection.
% When the connection is closed, you will hear the device power down
% briefly.  Don't try connecting until 10 seconds after the device sounds
% powered up again or the connection will fail.

if (~obj.Simulate)
    if obj.IsOpen
        OneLightEngine(OneLightFunctions.Close.UInt32, obj.DeviceID);
    end
else
    obj.IsOpen = false;
end
