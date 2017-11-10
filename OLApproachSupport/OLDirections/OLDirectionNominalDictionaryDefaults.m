function entry = OLDirectionNominalDictionaryDefaults(type)
%OLDIRECTIONNOMINALDICTIONARYDEFAULTS Generates a nominal direction
%dictionary entry with all the default values for all the parameters.
%   Detailed explanation goes here
entry = struct();
entry.type = type;
entry.name = '';

switch (type)
    case {'pulse', 'flicker'}
        entry.dictionaryType = 'Direction';                                     % What type of dictionary is this?
        entry.baseModulationContrast = 4/6;                                     % How much symmetric modulation contrast do we want to enable?  Used to generate background name.    
        entry.primaryHeadRoom = 0.005;                                          % How close to edge of [0-1] primary gamut do we want to get?
        entry.whichReceptorGenerator = 'SSTPhotoreceptorSensitivity';           % How will receptor fundamentals be generated: 'SSTPhotoreceptorSensitivity', 'SSTReceptorHuman'
        entry.photoreceptorClasses = ...                                        % Names of photoreceptor classes being considered, must make sense to the specified receptor generator.
            {'LConeTabulatedAbsorbance', 'MConeTabulatedAbsorbance', 'SConeTabulatedAbsorbance', 'Melanopsin'};
        entry.fieldSizeDegrees = 27.5;                                          % Field size. Affects fundamentals.
        entry.pupilDiameterMm = 8.0;                                            % Pupil diameter used in background seeking. Affects fundamentals.
        entry.maxPowerDiff = 0.1;                                               % Smoothing parameter for routine that finds backgrounds.
        entry.modulationContrast = [entry.baseModulationContrast];             % Vector of constrasts sought in isolation.
        entry.whichReceptorsToIsolate = {[4]};                                  % Which receptor classes are not being silenced.
        entry.whichReceptorsToIgnore = {[]};                                    % Receptor classes ignored in calculations.
        entry.whichReceptorsToMinimize = {[]};                                  % These receptors are minimized in contrast, subject to other constraints.
        entry.directionsYoked = [0];                                            % See ReceptorIsolate.
        entry.directionsYokedAbs = [0];                                         % See ReceptorIsolate.
        entry.receptorIsolateMode = 'Standard';                                 % See ReceptorIsolate.
        entry.useAmbient = true;                                                % Use measured ambient in calculations if true. If false, set ambient to zero.
        entry.doSelfScreening = false;                                          % Adjust photoreceptors for self-screening?
        entry.backgroundType = 'optimized';                                     % Type of background
        entry.backgroundName = '';                                              % Name of background 
        entry.backgroundObserverAge = 32;                                       % Observer age expected in background 
        entry.correctionPowerLevels = [0 1];                                    % Power levels to measure at during correction
        entry.validationPowerLevels = [0 1];                                    % Power levels to measure at during validation
        entry.cacheFile = '';                                                   % Cache filename goes here

    case 'lightfluxchrom'
        entry.dictionaryType = 'Direction';                                     % What type of dictionary is this?
        entry.primaryHeadRoom = 0.01;                                           % How close to edge of [0-1] primary gamut do we want to get? (Check if actually used someday.) 
        entry.lightFluxDesiredXY = [0.54 0.38];                                 % Background chromaticity.
        entry.lightFluxDownFactor = 5;                                          % Factor to decrease background after initial values found.  Determines how big a pulse we can put on it.
        entry.useAmbient = true;                                                % Use measured ambient in calculations if true. If false, set ambient to zero.
        entry.backgroundType = 'lightfluxchrom';                                % Type of background
        entry.backgroundName = '';                                              % Name of background 
        entry.backgroundObserverAge = 32;                                       % Observer age expected in background
        entry.correctionPowerLevels = [0 1];                                    % Power levels to measure at during correction
        entry.validationPowerLevels = [0 1];                                    % Power levels to measure at during validation
        entry.cacheFile = '';                                                   % Cache filename goes here
        
    otherwise
        error('Unknown direction type specified: ''%s''.\n', type);
end
end

