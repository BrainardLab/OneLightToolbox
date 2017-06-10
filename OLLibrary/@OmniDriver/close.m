function close(obj)
% close - Closes any open OceanOptics spectrometers.
%
% Syntax:
% obj.close

if obj.IsOpen
	fprintf('- Closing all open OmniDriver spectrometers...');
	obj.Wrapper.closeAllSpectrometers;
	fprintf('Done\n');
end

obj.IsOpen = false;
