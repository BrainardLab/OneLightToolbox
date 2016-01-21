function OLInitAndSaveCal(calFileName,varargin)
% OLInitAndSaveCal - Computes an existing calibration file and saves it.
%
% Syntax:
% OLInitAndSaveCal
% OLInitAndSaveCal(calFileName)
% OLInitAndSaveCal(calFileName)
% OLInitAndSaveCal(calFileName,initOptions)
% OLInitAndSaveCal(cal)
% OLInitAndSaveCal(cal,initOptions);
%
% Description:
% Runs a calibration file through OLInitCal, then saves the updated
% calibration data.  Prompts for a calibration file if one isn't specified.
%
% You can also pass a calibration structure, in which case the file
% is not read but the initialization is run on the passed calibration structure.
%
% Initialization options are passed through to OLInitCal.  See that function for
% option descriptions.
%
% 3/31/14  dhb  Pass options through.

error(nargchk(0, Inf, nargin));

if nargin == 0
	% Get the calibration file.
	calFileName = GetWithDefault('Enter calibration file name', 'OneLightShortCable');
end

% Run the calibration file through the function that computes the data.
% This function checks to make sure that the calibration file exists.
oneLightCal = OLInitCal(calFileName,varargin{:});

% Save the compute calibration file.
SaveCalFile(oneLightCal, calFileName);
