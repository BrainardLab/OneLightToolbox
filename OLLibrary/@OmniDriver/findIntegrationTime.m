function integrationTime = findIntegrationTime(obj, increment, factor, minTime, maxTime)
% findIntegrationTime - Finds the largest integration time without saturation.
%
% Syntax:
% integrationTime = obj.findIntegrationTime;
% integrationTime = obj.findIntegrationTime(increment)
% integrationTime = obj.findIntegrationTime(increment, factor)
% integrationTime = obj.findIntegrationTime(increment, factor, minTime)
% integrationTime = obj.findIntegrationTime(increment, factor, minTime, maxTime)
%
% Description:
% The spectrometer can vary the integration time of spectral measurements.
% If there is too much light the a measurment becomes saturated.  If there
% is too little light the measurement will be noiser.  This function tries
% to find the largest integration time within the specified or default
% bounds before it gets saturated.
%
% Input:
% increment (scalar) - The integer number of microseconds to step.
%     Default: 1000
% factor (scal) - The number to divide by between tests.
%     Default: 2
% minTime (scalar) - The starting integration time of the search in
%     microseconds. Default: The value of obj.MinIntegrationTime
% maxTime (scalar) - The max integration time of the search in microseconds.
%     Default: The value of obj.MaxIntegrationTime
%
% 7/19/12 kds, pl, ms Edited to make more efficient

%% Basic checks
assert(nargin >= 1 && nargin <= 5, 'OmniDriver:findIntegrationTime:NumInputs', ...
    'Invalid number of inputs.');
assert(obj.IsOpen, 'OmniDriver:findIntegrationTime:NotOpen', 'Not connected to the spectrometer.');

%% Setup some defaults.
if ~exist('increment', 'var') || isempty(increment)
	increment = 1000;
end
if ~exist('factor', 'var') || isempty(factor)
    factor = 2;
end
if ~exist ('minTime', 'var') || isempty(increment)
	minTime = obj.MinIntegrationTime;
end
if ~exist('maxTime', 'var') || isempty(maxTime)
	%maxTime = obj.MaxIntegrationTime;
    maxTime = 200000;
end

% Round the parameters to integer values.
increment = round(increment);
minTime = round(minTime);
maxTime = round(maxTime);

% Validate the input.
assert(increment > 0, 'OmniDriver:findIntegrationTime:InvalidInput', ...
	'Increment value of %d out of range.');
assert(factor > 1, 'OmniDriver:findIntegrationTime:InvalidInput', ...
	'Factor value of %d out of range.');
assert(minTime >= obj.MinIntegrationTime && minTime <= obj.MaxIntegrationTime, ...
	'OmniDriver:findIntegrationTime:InvalidInput', 'MinTime value of %d is out of range.', ...
	minTime);
assert(maxTime >= obj.MinIntegrationTime && maxTime <= obj.MaxIntegrationTime, ...
	'OmniDriver:findIntegrationTime:InvalidInput', 'MaxTime value of %d is out of range.', ...
	maxTime);
assert(minTime <= maxTime, 'OmniDriver:findIntegrationTime:InvalidInput', ...
	'MinTime must be less than or equal to MaxTime.');

%% Create initial list of integration times.
% We start at max and come down by a fixed
% factor until we are not saturated.
maxToMinPower = log(maxTime/minTime)/log(factor);
fractionsOfMaxTime = 1./factor.^(0:1:maxToMinPower);
timesToTest = round(maxTime * fractionsOfMaxTime);
if ~any(timesToTest == minTime)
    timesToTest(end+1) = minTime;
end

%% Make a copy of the original integration time so we can restore it before
% we leave this function.
integrationTime0 = obj.IntegrationTime;

%% Start our great mission
if obj.Debug
	fprintf('- Finding integration time\n');
end

%% But, firt test that minimum possible integration time doesn't saturate.  If it
% does, don't bother testing other times.
obj.IntegrationTime = minTime;
if obj.Debug
    fprintf('- Testing time %d\n', minTime);
end

try
    obj.getSpectrum;
catch se
    % If we get a saturated error on the minimum tested value, throw an
    % error.
    if strcmp(se.identifier, 'OmniDriver:getSpectrum:Saturated')
        error('Cannot find an integration time.');
    else
        rethrow(se);
    end
end
            
%% Loop over our test integration times.  Jump out of the loop when we find
% the saturation point.
for i = 1:length(timesToTest)
	% Set the test integration time.
	obj.IntegrationTime = timesToTest(i);
	if obj.Debug
		fprintf('- Testing time %d\n', timesToTest(i));
	end
	
	try
		obj.getSpectrum;
	catch se
		% If we're still above the saturation point, drop the integration
		% time back down a little bit then take another measurement.
		if strcmp(se.identifier, 'OmniDriver:getSpectrum:Saturated')
			% If we saturate, skip the rest of the loop and try the next
			% lower integration time.
			continue;
		else
			rethrow(se);
		end
    end
    
    % If we reach this point, then the current integration time doesn't
    % produce saturation. But because we were using multiplicative
    % decrease, we may not be as high as we would like.  So now
    % we creep back up linearly to a good value.
    if i == 1
        % If the highest value we try doesn't saturate, we can use it.
        integrationTime = timesToTest(i);
        break
    else
        % Now we want to try incrementing until we reach
        % saturation or get back to the lowest value that we know produces
        % saturation.
        newTimesToTest = timesToTest(i):increment:timesToTest(i-1);
        for j = 2:numel(newTimesToTest)
            % Set the test integration time.
            obj.IntegrationTime = newTimesToTest(j);
            if obj.Debug
                fprintf('- Testing time %d\n', newTimesToTest(j));
            end
            
            try
                obj.getSpectrum;
            catch se
                % If we've reached the saturation point, use the last 
                % integration time that didn't hit saturation.
                if strcmp(se.identifier, 'OmniDriver:getSpectrum:Saturated')
                    integrationTime = newTimesToTest(j-1);
                    break;
                else
                    rethrow(se);
                end
            end
        end
        
        % If we successfully found an integration time that doesn't
        % saturate, we want to stop testing and use it.
        if exist('integrationTime','var') && (integrationTime == newTimesToTest(j-1))
            break
        end
    end
end

%% Reset the original integration time.
if obj.Debug
    if (exist('integrationTime','var'))
        fprintf('- Found integration time of %d\n', integrationTime);
    else
        fprintf('- Did not find a working integration time, returning passed value\n');
        integrationTime = integrationTime0;
    end
end

%% We think this line has no purpose
obj.IntegrationTime = integrationTime0;
