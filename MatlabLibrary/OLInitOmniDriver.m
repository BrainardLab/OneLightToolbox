function od = OLInitOmniDriver(calibrationData, verbose)
% OLInitOmniDriver - Creates and initializes an OmniDriver object.
%
% Syntax:
% od = OLInitOmniDriver(calibrationData)
% od = OLInitOmniDriver(calibrationData, verbose)
%
% Description:
% There are a few common settings that experiments and calibration
% functions use when creating and initializing an OmniDriver object.  This
% function aims at encapsulating those common tasks.  If calibration data
% is passed to the function, then the integration time that the radiometer
% uses is taken from there.  Otherwise, the function tries to find a
% reasonable value.  To dynamically find the integration time, the OneLight
% device needs to be connected and powered on.  All mirrors will be turned
% on briefly, then turned back off, so make sure there isn't an issue with
% having a lot of light being kicked out of the device, e.g. someone is
% looking straight into the light source.
%
% Input:
% calibrationData (struct) - The calibration data for the OneLight from
%     either cache data or LoadCalFile.
% verbose (logical) - Toggles verbose diagnostic output.  Default: false
%
% Output:
% od (OmniDriver) - An initialized OmniDriver object.

% Validate the number of inputs.
narginchk(0, 2, );

if nargin <= 1
	verbose = false;
end

% Create an OmniDriver object.
od = OmniDriver;

% Turn on some averaging and smoothing for the spectrum acquisition.
od.ScansToAverage = 10;
od.BoxcarWidth = 2;

% Make sure electrical dark correction is enabled.
od.CorrectForElectricalDark = true;

if exist('calibrationData', 'var') && ~isempty(calibrationData)
	% Set the OmniDriver integration time to match up with what's in the
	% calibration file.
	od.IntegrationTime = calibrationData.describe.omniDriver.integrationTime;
	
	if verbose
		fprintf('- Using calibration data integration time.\n');
	end
	
else
	if verbose
		fprintf('- Dynamically finding OmniDriver integration time...');
	end
	
	% Create a OneLight object and turn on all the mirrors.
	ol = OneLight;
	ol.setAll(true);
	
	od.IntegrationTime = od.findIntegrationTime(1000, 2, 20000);
	od.IntegrationTime = round(0.95*o.IntegrationTime);
	
	% Turn all the mirrors off.
	ol.setAll(false);
	
	if verbose
		fprintf('Done\n');
	end
end
