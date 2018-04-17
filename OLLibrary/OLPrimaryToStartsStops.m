function [starts, stops] = OLPrimaryToStartsStops(primary, calibration, varargin)
% Convert OneLight primary values to starts and stops for mirror columns
%
% Syntax:
%   [starts, stops] = OLPrimaryToStartsStops(primary, calibration)
%
% Description:
%    Take OneLight primary values, which are [0,1] numbers that give the
%    linear fraction of maximum light output for each primary, gamma
%    correct these and convert to start and stop values for every mirror
%    column.  These are integers which can be passed directly to the
%    setMirrors method of a OneLight object.
%
%    The starts/stops are in the range [0,NumRows-1], where NumRows is the
%    number of rows in the DLP mirror.  Starts/stops of [0,0] turns on the
%    first mirror, stats/stops of [0,NumRows-1] turns on all the mirrors.
%    You can set any consecutive range of mirrors. A primary value of 0 is
%    a special case, for which start = NumRows+1, stop = 0. This is handled
%    by the underlying OLSettingsToStartsStops.
%
%    This routine uses an 'optimized' algorithm, where it only converts
%    unique primary values. This is probably correct, but the underlying
%    OLPrimaryToSettings and OLSettingsToStartsStops don't use this.
%
%
% Inputs:
%    primary       - The primary values, i.e., the normalized gamma
%                    uncorrected power level for each effective primary
%                    (fraction of max power) in the range [0,1]. Can be a
%                    1xP column vector for P effective device primaries, or
%                    an NxP matrix for N vectors of primary values, e.g.
%                    multiple spetra, or a temporal waveform of a spectrum.
%    calibration   - A OneLight calibration structure (see OLDemoCal.mat)
%
% Outputs:
%    starts        - The starts values for the OneLight, in a 1xnCols,
%                    where nCols is the number of columns on the DMD chip
%                    in the OneLight. If N vectors of primary values are
%                    passed in, this becomes NxnCols.
%    stops         - The stops values for the OneLight, in a 1xnCols vector
%                    similar to starts.
%
% Optional key/value pairs:
%    'primaryTolerance'           - Scalar (default 1e-6). Primaries can be this
%                                   much out of gamut and it will truncate them
%                                   into gamut without complaining.
%    'uniqueTolerance'            - Scalar (default 1e-6). Primaries closer
%                                   together than this are considered the
%                                   same. Speeds calculation.
%    'checkPrimaryOutOfRange'     - Boolean (default true). Throw error if any passed
%                                   primaries are out of the [0-1] range.
%
% Examples are provided in the source code.
%
% Notes:
%
% See also:
%    OLPrimaryToSettings, OLSettingsToStartsStops

% History:
%    01/29/18  jv  Wrote it.
%    04/12/18  dhb Updating primary gamut checking.  Provide separate
%                  tolerances for gamut checking and uniqueness.

% Examples:
%{
    calibration = OLGetCalibrationStructure('CalibrationFolder',fileparts(which('OLDemoCal.mat')),'CalibrationType','DemoCal');
    P = calibration.describe.numWavelengthBands;  % number of effective device primaries
    primary = .5 * ones(P,1); % all primaries half-on

    %% Use OLPrimaryToStartsStops
    [starts,stops] = OLPrimaryToStartsStops(primary,calibration);
%}
%{
    %% Compare the speed of this routine vs. OLPrimaryTosettings ->
    %   OLSettingsToStartsStops for a  steady signal.
    calibration = OLGetCalibrationStructure('CalibrationFolder',fileparts(which('OLDemoCal.mat')),'CalibrationType','DemoCal');
    P = calibration.describe.numWavelengthBands;  % number of effective device primaries
    
    % Sinusoidal flicker
    timebase = linspace(0,5,200*20);     % 20 seconds sampled at 200 hz
    temporalWaveform = ones(1,numel(timebase));     % rectify, differentialScalars are [0-1]

    %% Combine primary and temporal waveform
	primary = .5 * ones(P,1);      % all primaries half-on
    primaryWaveform = OLPrimaryWaveform(primary,temporalWaveform);

    %% Use OLPrimaryToStartsStops
    tic;
    [startsFast,stopsFast] = OLPrimaryToStartsStops(primaryWaveform,calibration);
    tFast = toc

    %% Use OLPrimaryToStartsStops
    tic;
    settingsSlow = OLPrimaryToSettings(calibration,primaryWaveform);
    [startsSlow,stopsSlow] = OLSettingsToStartsStops(calibration,settingsSlow);
    tSlow = toc

    %% Compare output
    assert(all(all(startsSlow == startsFast)),'Starts are not the same');
    assert(all(all(stopsSlow == stopsFast)),'Stops are not the same');
%}
%{
    %% Compare the speed of this routine vs. OLPrimaryTosettings ->
    %   OLSettingsToStartsStops for a periodic signal.
    calibration = OLGetCalibrationStructure('CalibrationFolder',fileparts(which('OLDemoCal.mat')),'CalibrationType','DemoCal');
    P = calibration.describe.numWavelengthBands;  % number of effective device primaries
    
    % Sinusoidal flicker
    timebase = linspace(0,5,200*20);     % 20 seconds sampled at 200 hz
    sinewave = sin(2*pi*10*timebase);    % 10 Hz sinewave carrier
    flickerWaveform = abs(sinewave);     % rectify, differentialScalars are [0-1]

    %% Combine primary and temporal waveform
	primary = .5 * ones(P,1);      % all primaries half-on
    primaryWaveform = OLPrimaryWaveform(primary,flickerWaveform);

    %% Use OLPrimaryToStartsStops
    tic;
    [startsFast,stopsFast] = OLPrimaryToStartsStops(primaryWaveform,calibration);
    tFast = toc

    %% Use OLPrimaryToStartsStops
    tic;
    settingsSlow = OLPrimaryToSettings(calibration,primaryWaveform);
    [startsSlow,stopsSlow] = OLSettingsToStartsStops(calibration,settingsSlow);
    tSlow = toc

    %% Compare output
    assert(all(all(startsSlow == startsFast)),'Starts are not the same');
    assert(all(all(stopsSlow == stopsFast)),'Stops are not the same');
%}

%% Input validation
parser = inputParser();
parser.addRequired('primary',@isnumeric);
parser.addRequired('calibration',@isstruct);
parser.addParameter('primaryTolerance',1e-6, @isscalar);
parser.addParameter('uniqueTolerance', 1e-6, @isscalar);
parser.addParameter('checkPrimaryOutOfRange', true, @islogical);
parser.parse(primary,calibration,varargin{:});

%% Check primaries within gamut
primary = OLCheckPrimaryGamut(primary,...
    'primaryHeadroom',0, ...
    'primaryTolerance',parser.Results.primaryTolerance, ...
    'checkPrimaryOutOfRange',parser.Results.checkPrimaryOutOfRange);

%% Find unique primary values
%
% We need to convert any value for a given primary only once. However, the
% same primary value (for a given primary) value can appear often, e.g. if
% we pass in a periodic signal. Thus, we can speed things up by finding
% only the unique values. 
%
% Note that here we're finding the unique columns of primary, i.e.,
% entire Px1 vectors of primary values, rather than the unique values per
% primary. The overhead necessary to do the latter likely defeats the
% gains.
[uniquePrimaryVals, ~, indices] = uniquetol(primary',parser.Results.uniqueTolerance,'ByRows',true);

%% Convert to settings
settings = OLPrimaryToSettings(calibration,uniquePrimaryVals');

%% Convert to starts/stops
[starts,stops] = OLSettingsToStartsStops(calibration, settings);

%% Back fill in
starts = starts(indices,:);
stops = stops(indices,:);

end