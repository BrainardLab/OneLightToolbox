function measurement = measure(obj)
% measure - Get a measurement from the device.
%
% Syntax:
% measurement = obj.measure
%
% Description:
% Tells the power meter to make a single measurement and return a value.
%
% Output:
% measurement (scalar) - The power reading from the device.

narginchk(1, 1);

% Make sure the device is open.
assert(obj.IsOpen, 'PowerMeter:Measure:NotOpen', 'Device needs to be connected to take a measurement.');

% Request a measurement.
fwrite(obj.SerialPort, '*CVU');

% Look for acknowledgment the command was received.
ack = fscanf(obj.SerialPort);

% Get the measurement value.
m = fscanf(obj.SerialPort);
measurement = str2double(m);
