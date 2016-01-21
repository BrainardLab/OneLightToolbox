function closeAll
% closeAll - Closes any OneLight devices attached to the computer.
%
% Syntax:
% OneLight.closeAll
%
% Description:
% Static function that closes any OneLight devices attached to the
% computer.  This will throw an error if no devices are detected.

OneLightEngine(OneLightFunctions.CloseAll.UInt32);
