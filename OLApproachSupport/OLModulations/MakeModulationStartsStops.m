function protocolParams = MakeModulationStartsStops(protocolParams)
% MakeModulationStartsStops
%
% Description:
%   This script reads in the primaries for the modulations in the experiment and computes the starts stops.
%   Typically, we only generate the primaries for the extrema of the modulations, so this routine is also responsible
%   for filling in the intermediate contrasts (by scaling the primaries) and then taking each of these through the 
%   calibration file to get the arrays of starts and stops that are cached for the experimental program.
%
%   This calculation is subject and data specific.  It is subject specific
%   because the primaries depend on age specific receptor fundamentals.  Is
%   is date specific because we often do spectrum seeking.
%
%    The output is cached in the directory specified by
%    getpref('MaxPulsePsychophysics','ModulationStartsStopsDir');

% 6/18/17  dhb  Added descriptive comment.

% LMS; Melanopsin; Light Flux
tic;
% Update session log file
protocolParams = Psychophysics.SessionLog(protocolParams,mfilename,'StartEnd','start');

customSuffix = ['_' protocolParams.observerID '_' protocolParams.todayDate];
OLReceptorIsolateMakeModulationStartsStops('Modulation-PulseMaxLMS_3s_MaxContrast3sSegment', customSuffix, protocolParams);
OLReceptorIsolateMakeModulationStartsStops('Modulation-PulseMaxMel_3s_MaxContrast3sSegment', customSuffix, protocolParams);
OLReceptorIsolateMakeModulationStartsStops('Modulation-PulseMaxLightFlux_3s_MaxContrast3sSegment', customSuffix, protocolParams);

% Update session log file
protocolParams = Psychophysics.SessionLog(protocolParams,mfilename,'StartEnd','end');
toc;
