function modulation = OLCalculateStartsStopsModulation(waveformParams, cal, backgroundPrimary, diffPrimaryPos, diffPrimaryNeg)
%%OLCalculateStartsStopsModulation  Calculate various modulations given background and pos/neg primary differences.
%
% Usage:
%     modulation = OLCalculateStartsStopsModulation(waveformParams, cal, backgroundPrimary, diffPrimaryPos, diffPrimaryNeg)
%
% Description:
%     This programes takes the waveform parameters and turns them into
%     modulations.
%
%     This is called by OLReceptorIsolateMakeModulationStartsStops to make the starts/stops
%     that implement a particular modulation, for a specific choice of waveform parameters.
%
%     It looks like if diffPrimayNeg is empty, only the positive arm is used (i.e. to make a pulse).
%
% Input:
%
% Output:
%    modulation             Structure containing (among other things) the starts/stops matrices that produce the modulation.
%
% Optional key/value pairs.
%    None.
%
% See also: OLMakeModulationsStartsStops, OLReceptorIsolateMakeModulationStartsStops, OLWaveformParamsDictionary.

% 7/21/17  dhb        Tried to improve comments.
% 8/09/17  dhb, mab   Compute pos/neg diff more flexibly.
% 01/28/18  dhb, jv  Moved waveform generation to OLWaveformFromParams. 

%% Generate the waveform
[waveform, timestep, waveformDuration] = OLWaveformFromParams(waveformParams);

%% Convert waveform to starts/stops
% Store parameters for return
modulation.waveformParams = waveformParams;

% Grab number of settings and the power levels over time.
% Note that nSettings is the same thing as the number of time
% points.
nSettings = length(waveform);
modulation.powerLevels = waveform;

% Allocate memory
modulation.starts = zeros(nSettings, cal.describe.numColMirrors);
modulation.stops = zeros(nSettings, cal.describe.numColMirrors);
modulation.settings = zeros(length(backgroundPrimary),nSettings);
modulation.primaries = zeros(length(backgroundPrimary),nSettings);

% Figure out the weight of the background and modulation primary
% Use a little matrix algebra to add the weighted difference primary
% to the background at each time point.
%
% This matrix w has the amount of the background and the amount of the
% difference primary we want at each time.  Each column is for one time,
% with 2 entries per column.  The number of columns is the number of time
% points.
w = [ones(1, nSettings) ; waveform];

% The matrix [backgroundPrimary diffPrimaryPos] has the primary values
% for the background in its first column and those for the difference at
% full power in the second.  And similarly for diffPrimaryNeg.
%
% Thus the matrix multiply expressed here creates a matrix with one column
% for each time point, with the entries of the column giving the desired
% primaries for that time point.
%
% We allow for asymmetric positive and negative excursions.
index = find(waveform >= 0);
if (~isempty(index))
    modulation.primaries(:,index) = [backgroundPrimary diffPrimaryPos]*w(:,index);
end
index = find(waveform < 0);
if (~isempty(index))
    assert(~isempty(diffPrimaryNeg),'diffPrimaryNeg cannot be empty if there are negative power values');
    modulation.primaries(:,index) = [backgroundPrimary -diffPrimaryNeg]*w(:,index);
end

% Make sure primaries are all within gamut.  If not, something has gone wrong and the
% user needs to think about and fix it.
tolerance = 1e-10;
if (any(modulation.primaries(:) < -tolerance) || any(modulation.primaries(:) > 1+tolerance))
    error('Primary value out of gamut. You need to look into why and fix it.');
end
modulation.primaries(modulation.primaries < 0) = 0;
modulation.primaries(modulation.primaries > 1) = 1;

% This next bit of code is designed to save us a little time.  For a pulse,
% there are many time points where the primaries are the same, and it is
% a little slow to compute settings and starts/stops.  So, we find the
% the unique primaries values and only do the conversion to settings and
% starts/stops we got back into all the places the go in the returned
% matrices.  This might be too clever for words, but we think it is robuse.

% Find the unique primary settings.  Note the two transposes because
% unique operates along the rows. Note also (see the help text for unique)
% that with this calling form modulation.primaries' = uniqPrimariesBuffer(IC,:);
[uniqPrimariesBuffer, ~, IC] = unique(modulation.primaries', 'rows');
uniqPrimariesBuffer = uniqPrimariesBuffer';

% Convert the unique primaries to starts and stops.  Primaries and settings are column
% vectors (or in the columns of their matrices), while starts and stops live in the rows
% The switch is handled inside of OLSettingsToStartsStops.  If you're curious, the logic
% here is that primaries and settings are abstract quanties and by convention for DHB
% this type of quantity always lives as a column.  But, starts and stops are OneLight
% hardware dependent things and get passed as rows into the low-level OneLight routine.
settingsBuffer = OLPrimaryToSettings(cal, uniqPrimariesBuffer);
for si = 1:size(settingsBuffer, 2)
    [startsBuffer(si,:), stopsBuffer(si,:)] = OLSettingsToStartsStops(cal, settingsBuffer(:, si));
end

% Use IC to fill out the full return matrices, taking care with the various row/col conventions.
modulation.settings = settingsBuffer(:, IC);
modulation.starts = startsBuffer(IC,:);
modulation.stops = stopsBuffer(IC,:);
for ww = 1:size(modulation.primaries,2)
    modulation.spd(:,ww) = OLPrimaryToSpd(cal,modulation.primaries(:,ww));
end

%% Make the starts/stops for the background
modulation.background.primaries = backgroundPrimary;
[modulation.background.starts, modulation.background.stops] = OLSettingsToStartsStops(cal, OLPrimaryToSettings(cal, backgroundPrimary));