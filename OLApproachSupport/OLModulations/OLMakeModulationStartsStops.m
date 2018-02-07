function OLMakeModulationStartsStops(waveformNames,directionNames,protocolParams,varargin)
%OLMakeModulationStartsStops  Make the modulations starts/stops for a protocol subject/date/session
%
% Usage:
%     OLMakeModulationStartsStops(waveformNames,directionNames,protocolParams)
%
% Description:
%     This script reads in the primaries for the modulations in the experiment and computes the starts stops.
%     Typically, we only generate the primaries for the extrema of the modulations, so this routine is also responsible
%     for filling in the intermediate contrasts (by scaling the primaries) and then taking each of these through the 
%     calibration file to get the arrays of starts and stops that are cached for the experimental program.
%
%     This calculation is subject and data specific.  It is subject specific
%     because the primaries depend on age specific receptor fundamentals.  Is
%     is date specific because we often do spectrum seeking.
%
%      The output is cached in a directory under
%      getpref(protocolParams.approach,'ModulationStartsStopsDir');
%
% Input:
%      waveformNames (cell array)         Cell array with the names of the modulations that are used in
%                                           the current protocol.
%      directionNames (cell array)          Cell array with the names of the directions that are used in
%                                           the current protocol.
%      protocolParams (struct)              Parameter structure for protocol.
%                                             NEED TO SAY OR POINT TO DESCRIPTION OF WHAT KEY FIELDS ARE.
%
% Output:
%       None.
%
% Optional key/value pairs
%     'verbose' (boolean)    Print out diagnostic information?
%
% See also:

% 6/18/17  dhb  Added descriptive comment.

%% Parse input to get key/value pairs
p = inputParser;
p.addRequired('waveformNames',@iscell);
p.addRequired('directionNames', @iscell);
p.addRequired('protocolParams',@isstruct);
p.addParameter('verbose',true,@islogical);
p.parse(waveformNames,directionNames,protocolParams,varargin{:});

%% Update session log file
OLSessionLog(protocolParams,mfilename,'StartEnd','start');

%% Set up the input and output directories
% We count on the standard relative directory structure that we always use
% in our (Aguirre/Brainard Lab) experiments.
%
% Get where the input corrected direction files live.  This had better exist.
directionCacheDir = fullfile(getpref(protocolParams.protocol,'DirectionCorrectedPrimariesBasePath'), protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
if (~exist(directionCacheDir,'dir'))
    error('Corrected direction primaries directory does not exist');
end

% Output for starts/stops. Create if it doesn't exist.
protocolParams.modulationDir = fullfile(getpref(protocolParams.protocol, 'ModulationStartsStopsBasePath'),protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
if(~exist(protocolParams.modulationDir,'dir'))
    mkdir(protocolParams.modulationDir)
end

%% Load the calibration file and tack it onto the modulationParams structure.
% Not entirely sure whether that structure is the right place for the calibration information
% but leaving it be for now.
cType = OLCalibrationTypes.(protocolParams.calibrationType);
oneLightCal = LoadCalFile(cType.CalFileName, [], fullfile(getpref(protocolParams.approach, 'OneLightCalDataPath')));

%% Setup a cache object for read, and do the read.
directionCacheDir = fullfile(getpref(protocolParams.protocol,'DirectionCorrectedPrimariesBasePath'), protocolParams.observerID, protocolParams.todayDate, protocolParams.sessionName);
directionOLCache = OLCache(directionCacheDir, oneLightCal);

%% Do each modulation
for ii = 1:length(waveformNames)
    waveformName = waveformNames{ii};
    directionName = directionNames{ii};
    
    % Say hello
    if (p.Results.verbose); fprintf('\nComputing modulation %s+%s\n',waveformName,directionName); end
    
    % Load direction data, check for staleness, and pull out what we want
    % These are currently in a cache file. These particular files should never
    % be stale, so the role of using a cache file is to allow us to keep things
    % separate by calibration and to detect staleness.  But, given that these
    % are written in subject/date/session specific directories, staleness is
    % and multiple cal files are both unlikely.
    directionCacheFile = fullfile(getpref(protocolParams.protocol,'DirectionCorrectedPrimariesBasePath'), protocolParams.observerID,protocolParams.todayDate,protocolParams.sessionName, sprintf('Direction_%s', directionName));
    [cacheData,isStale] = directionOLCache.load(directionCacheFile);
    assert(~isStale,'Cache file is stale, aborting.');
    directionParams = cacheData.directionParams;
    directionData = cacheData.data(protocolParams.observerAgeInYrs);
    clear cacheData

    % Get modulation params, override with trialTypeParams passed by
    % current protocol
    waveformParams = OLWaveformParamsFromName(waveformName);
    waveformParams = UpdateStructWithStruct(waveformParams,protocolParams.trialTypeParams(ii));
    
    % Construct the waverform from parameters
    [directionWaveform, timestep, waveformDuration] = OLWaveformFromParams(waveformParams);
    
    % Assemble modulation
    modulation = OLAssembleModulation(directionData, directionWaveform, oneLightCal);
    modulation.timestep = timestep;
    modulation.stimulusDuration = waveformDuration;

    % We're treating the background real special here.
    modulation.background.primaries = directionData.backgroundPrimary;
    [modulation.background.starts, modulation.background.stops] = OLPrimaryToStartsStops(modulation.background.primaries, oneLightCal);

    % Put everything into a return strucure
    modulationData.modulationParams = waveformParams;
    modulationData.calibration = oneLightCal;
    modulationData.protocolParams = protocolParams;
    modulationData.modulation = modulation;
    
    % Save
    fullModulationName = sprintf('ModulationStartsStops_%s_%s_trialType_%d', waveformName, directionName, ii);
    modulationDir = protocolParams.modulationDir;
    modulationData.modulationCacheFile = fullfile(modulationDir, fullModulationName);
    save(modulationData.modulationCacheFile, 'modulationData');
    if (p.Results.verbose); fprintf(['\tSaved modulation to ' modulationData.modulationCacheFile '\n']); end    
end

%% Update session log file
OLSessionLog(protocolParams,mfilename,'StartEnd','end');
