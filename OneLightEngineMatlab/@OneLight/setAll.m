function setAll(obj, allOn)
% setAll - Turns the mirrors all on or off.
%
% Syntax:
% obj.setAll(allOn)
%
% Description:
% Turns all the mirrors full on or off.
%
% Input:
% allOn (logical) - True = all on, false = all off.

narginchk(2, 2, );

% Validate the input.
assert(isscalar(allOn), 'OneLight:setAll:InvalidInput', 'Input must be a logical scalar.');

if (~obj.Simulate)
    OneLightEngine(OneLightFunctions.SetAll.UInt32, obj.DeviceID, logical(allOn));
end
