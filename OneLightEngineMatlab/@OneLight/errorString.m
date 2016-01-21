function codeString = errorString(errorCode)
% errorString - Converts a numerical OneLightEngine error code to a string.
%
% Syntax:
% codeString = errorString(errorCode)
%
% Description:
% The OneLightEngine returns several numeric error codes.  This function
% converts the error code into a readable string.
%
% Input:
% errorCode (scalar) - One of the error codes as define by the OneLight
%     Spectra SDK Programming Guide on page 12.
%
% Output:
% codeString (string) - The description corresponding to the error code.

error(nargchk(1, 1, nargin));

assert(isscalar(errorCode) && isnumeric(errorCode), 'OneLight:errorString:InvalidInput', ...
	'Input must be a numeric scalar value.');

switch errorCode
	case -4
		codeString = 'Invalid parameter or function not implemented.';
		
	case -3
		codeString = 'Data was not sent successfully to the device.';
		
	case -2
		codeString = 'Error opening the USB device.';
		
	case -1
		codeString = 'Invalid device or lost connection.';
		
	case 0
		codeString = 'No error occurred.';
	
	otherwise
		error('Invalid error code %d.', errorCode);
end
