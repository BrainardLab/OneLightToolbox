function open(obj)
% open - Opens an OceanOptics specrometer.
%
% Syntax:
% obj.open

% Only open the device if we're not already open.
if ~obj.IsOpen
	% Get the number of spectrometers attached.
	fprintf('- Opening OmniDriver spectrometers (This may take up to 30 seconds)...');
	tic;
	obj.NumSpectrometers = obj.Wrapper.openAllSpectrometers;
	fprintf('Done (%gs)\n', toc);
	
	obj.IsOpen = true;
	
	% Make sure our target spectrometer is within range.  Setting it to
	% itself will call the proper error checking routines.  Prior to
	% opening the device, the set function for TargetSpectrometer doesn't
	% bother checking anything since we don't know the number of
	% spectrometers yet.
	obj.TargetSpectrometer = obj.TargetSpectrometer;
end
