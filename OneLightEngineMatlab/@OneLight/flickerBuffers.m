function timingData = flickerBuffers(obj, bufferSettings, bufferPattern, flickerRate, duration)
%

error('Function deprecated.');

% Check the number of inputs.
error(nargchk(5, 5, nargin));

% Make sure the device is open.
assert(obj.IsOpen, 'OneLight:flickerBuffers:DeviceNotOpen', ...
	'Device must be open before flickering the mirrors.');

obj.InputPatternBuffer = 0;
obj.setAll(true);
obj.InputPatternBuffer = 1;
obj.setAll(false);
obj.OutputPatternBuffer = 0;

timingData = OneLightEngine(OneLightFunctions.FlickerPatternBuffers.UInt32, ...
	obj.DeviceID, flickerRate, uint32(bufferPattern), duration);
