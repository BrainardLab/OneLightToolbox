function closeAll
% closeAll - Closes any OneLight devices attached to the computer.
%
% Syntax:
% OneLight.closeAll
%
% Description:
% Static function that closes any OneLight devices attached to the
% computer.  This will throw an error if no devices are detected.

% 09/25/17 dhb  Respect new PlotWhenSimulating property.

if (~obj.Simulate)
    OneLightEngine(OneLightFunctions.CloseAll.UInt32);
else
    if (obj.PlotWhenSimulating)
        try
            close(obj.SimFig);
        catch
        end
    end
end
