function params = OLDirectionNominalParamsDefaults(type)
% Returns structure with default parameters for a direction type
%
% Syntax:
%   params = OLDirectionNominalDictionaryDefaults(type)
%
% Description:
%    Since a lot of direction specifications are small variations, this
%    function generates a set of default parameters; the parameters of
%    interest can then be overridden afterwards (either in the 
%    OLDirectionNominalParamsDictionary, or elsewhere), before using the
%    parameters to generate direction primary values.
%
% Inputs:
%    type   - string name of the type of direction. Currently available:
%               'bipolar'       : bipolar contrast on some receptors
%               'unipolar'      : unipolar contrast on some receptors
%               'lightfluxchrom': a light flux step at given chromaticity
%
% Outputs:
%    params - a struct with the default parameters for the given type of
%             direction
%
% Optional key/value pairs:
%    None.
%
% See also:
%    OLDirectionNominalParamsValidate, OLDirectionNominalParamsDictionary 

% History:
%    01/25/18  jv  Extracted from OLDirectionNominalParamsDictionary

params = struct();
params.type = type;
params.name = '';

switch (type)
    case {'unipolar', 'bipolar'}
        params.dictionaryType = 'Direction';                               % What type of dictionary is this?
        params.baseModulationContrast = 4/6;                               % How much symmetric modulation contrast do we want to enable?  Used to generate background name.    
        params.primaryHeadRoom = 0.005;                                    % How close to edge of [0-1] primary gamut do we want to get?
        params.whichReceptorGenerator = 'SSTPhotoreceptorSensitivity';     % How will receptor fundamentals be generated: 'SSTPhotoreceptorSensitivity', 'SSTReceptorHuman'
        params.photoreceptorClasses = ...                                  % Names of photoreceptor classes being considered, must make sense to the specified receptor generator.
            {'LConeTabulatedAbsorbance', 'MConeTabulatedAbsorbance', 'SConeTabulatedAbsorbance', 'Melanopsin'};
        params.fieldSizeDegrees = 27.5;                                    % Field size. Affects fundamentals.
        params.pupilDiameterMm = 8.0;                                      % Pupil diameter used in background seeking. Affects fundamentals.
        params.maxPowerDiff = 0.1;                                         % Smoothing parameter for routine that finds backgrounds.
        params.modulationContrast = [params.baseModulationContrast];       % Vector of constrasts sought in isolation.
        params.whichReceptorsToIsolate = {[4]};                            % Which receptor classes are not being silenced.
        params.whichReceptorsToIgnore = {[]};                              % Receptor classes ignored in calculations.
        params.whichReceptorsToMinimize = {[]};                            % These receptors are minimized in contrast, subject to other constraints.
        params.directionsYoked = [0];                                      % See ReceptorIsolate.
        params.directionsYokedAbs = [0];                                   % See ReceptorIsolate.
        params.receptorIsolateMode = 'Standard';                           % See ReceptorIsolate.
        params.useAmbient = true;                                          % Use measured ambient in calculations if true. If false, set ambient to zero.
        params.doSelfScreening = false;                                    % Adjust photoreceptors for self-screening?
        params.backgroundType = 'optimized';                               % Type of background
        params.backgroundName = '';                                        % Name of background 
        params.backgroundObserverAge = 32;                                 % Observer age expected in background 
        params.correctionPowerLevels = [0 1];                              % Power levels to measure at during correction
        params.validationPowerLevels = [0 1];                              % Power levels to measure at during validation
        params.cacheFile = '';                                             % Cache filename goes here

    case 'lightfluxchrom'
        params.dictionaryType = 'Direction';                               % What type of dictionary is this?
        params.primaryHeadRoom = 0.01;                                     % How close to edge of [0-1] primary gamut do we want to get? (Check if actually used someday.) 
        params.lightFluxDesiredXY = [0.54 0.38];                           % Background chromaticity.
        params.lightFluxDownFactor = 5;                                    % Factor to decrease background after initial values found.  Determines how big a pulse we can put on it.
        params.useAmbient = true;                                          % Use measured ambient in calculations if true. If false, set ambient to zero.
        params.backgroundType = 'lightfluxchrom';                          % Type of background
        params.backgroundName = '';                                        % Name of background 
        params.backgroundObserverAge = 32;                                 % Observer age expected in background
        params.correctionPowerLevels = [0 1];                              % Power levels to measure at during correction
        params.validationPowerLevels = [0 1];                              % Power levels to measure at during validation
        params.cacheFile = '';                                             % Cache filename goes here
        
    otherwise
        error('Unknown direction type specified: ''%s''.\n', type);
end

end