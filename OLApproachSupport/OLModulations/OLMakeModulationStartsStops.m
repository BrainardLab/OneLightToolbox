function OLMakeModulationStartsStops(modulationNames,directionNames,protocolParams,varargin)
%OLMakeModulationStartsStops  Make the modulations starts/stops for a protocol subject/date/session
%
% Usage:
%     OLMakeModulationStartsStops(modulationNames,directionNames,protocolParams)
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
%      modulationNames (cell array)         Cell array with the names of the modulations that are used in
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
p.addRequired('modulationNames',@iscell);
p.addRequired('directionNames', @iscell);
p.addRequired('protocolParams',@isstruct);
p.addParameter('verbose',true,@islogical);
p.parse(modulationNames,directionNames,protocolParams,varargin{:});

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

%% Populate waveformParamsDictionary
waveformParamsDictionary = OLWaveformParamsDictionary;

%% Do each modulation
for ii = 1:length(modulationNames)
    modulationName = modulationNames{ii};
    directionName = directionNames{ii};
    
    % Say hello
    if (p.Results.verbose); fprintf('\nComputing modulation %s+%s\n',modulationName,directionName); end
    
    % Get modulation params
    modulationParams = waveformParamsDictionary(modulationName);
    
    % Override with trialTypeParams passed by the current protocol
    modulationParams = UpdateStructWithStruct(modulationParams,protocolParams.trialTypeParams(ii));
    modulationParams.modulationDir = protocolParams.modulationDir;
    modulationParams.oneLightCal = oneLightCal;
    
    % Create modulation
    OLReceptorIsolateMakeModulationStartsStops(ii,modulationParams, directionName, protocolParams,'verbose',p.Results.verbose);
end

%% Update session log file
OLSessionLog(protocolParams,mfilename,'StartEnd','end');
