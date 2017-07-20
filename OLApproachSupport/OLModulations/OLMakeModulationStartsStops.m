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
%      The output is cached in the directory specified by
%      getpref('MaxPulsePsychophysics','ModulationStartsStopsDir');
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
p.addRequired('protocolParams',@isstruct);
p.addParameter('verbose',true,@isstr);
p.parse(modulationNames,protocolParams,varargin{:});

% Update session log file
OLSessionLog(protocolParams,mfilename,'StartEnd','start');

%customSuffix = ['_' protocolParams.observerID '_' protocolParams.todayDate];
for ii = 1:length(modulationNames)
    OLReceptorIsolateMakeModulationStartsStops(modulationNames{ii}, directionNames{ii}, protocolParams,'verbose',p.Results.verbose);
end

% Update session log file
OLSessionLog(protocolParams,mfilename,'StartEnd','end');
