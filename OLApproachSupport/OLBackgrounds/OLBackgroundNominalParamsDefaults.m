function params = OLBackgroundNominalParamsDefaults(type)
% Returns structure with default parameters for a background type
%
% Syntax:
%   params = OLBackgroundNominalDictionaryDefaults(type)
%
% Description:
%    Since a lot of background specifications are small variations, this
%    function generates a set of default parameters; the parameters of
%    interest can then be overridden afterwards (either in the 
%    OLBackgroundNominalParamsDictionary, or elsewhere), before using the
%    parameters to generate background primary values.
%
% Inputs:
%    type   - string name of the type of background. Currently available:
%               'optimized':      background is optimized for a direction
%               'lightfluxchrom': background for a flux modulation at a
%                                 specific chromaticity
%
% Outputs:
%    params - a struct with the default parameters for the given type of
%             background
%
% Optional key/value pairs:
%    None.
%
% See also:
%    OLBackgroundNominalParamsValidate, OLBackgroundNominalParamsDictionary 

% History:
%    01/25/18  jv  Extracted from OLBackgroundNominalParamsDictionary
 
params = struct();
params.type = type;
params.name = '';

switch (type)
    % Background is optimized to allow a maximal modulation.
    case 'optimized'
        params.dictionaryType = 'Background';                              % What type of dictionary is this?
        params.pegBackground = false;                                      % Passed to the routine that optimizes backgrounds.         
        params.baseModulationContrast = 4/6;                               % How much symmetric modulation contrast do we want to enable?  Used to generate background name.
        params.primaryHeadRoom = 0.01;                                     % How close to edge of [0-1] primary gamut do we want to get?
        params.photoreceptorClasses = ...                                  % Names of photoreceptor classes being considered.
            {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
        params.fieldSizeDegrees = 27.5;                                    % Field size used in background seeking. Affects fundamentals.
        params.pupilDiameterMm = 8.0;                                      % Pupil diameter used in background seeking. Affects fundamentals.
        params.backgroundObserverAge = 32;                                 % Observer age used in background seeking. Affects fundamentals.
        params.maxPowerDiff = 0.1;                                         % Smoothing parameter for routine that finds backgrounds.
        params.modulationContrast = [params.baseModulationContrast];       % Vector of constrasts sought in isolation.
        params.whichReceptorsToIsolate = {[4]};                            % Which receptor classes are not being silenced.
        params.whichReceptorsToIgnore = {[]};                              % Receptor classes ignored in calculations.
        params.whichReceptorsToMinimize = {[]};                            % These receptors are minimized in contrast, subject to other constraints.
        params.directionsYoked = [0];                                      % See ReceptorIsolate.
        params.directionsYokedAbs = [0];                                   % See ReceptorIsolate.
        params.useAmbient = true;                                          % Use measured ambient in calculations if true. If false, set ambient to zero.
        params.cacheFile = '';                                             % Place holder, modulation name and type-specific . Just declaring the field here.
        
    case 'lightfluxchrom'
        params.dictionaryType = 'Background';                              % What type of dictionary is this?
        params.primaryHeadRoom = 0.01;                                     % How close to edge of [0-1] primary gamut do we want to get? (Check if actually used someday.) 
        params.lightFluxDesiredXY = [0.54 0.38];                           % Background chromaticity.
        params.lightFluxDownFactor = 5;                                    % Factor to decrease background after initial values found.  Determines how big a pulse we can put on it.
        params.useAmbient = true;                                          % Use measured ambient in calculations if true. If false, set ambient to zero.
        params.cacheFile = '';                                             % Place holder, modulation name and type-specific . Just declaring the field here.

    otherwise
        error('Unknown background type specified: ''%s''.\n', type)
end % switch

end