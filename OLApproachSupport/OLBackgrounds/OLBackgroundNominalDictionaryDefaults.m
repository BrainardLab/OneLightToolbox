function entry = OLBackgroundNominalDictionaryDefaults(type)
%OLBACKGROUNDDICTIONARYDEFAULTS Generates a backgroud dictionary entry with
%all the default values for all the parameters.

entry = struct();
entry.type = type;
entry.name = '';

switch (type)
    % Background is optimized to allow a maximal modulation.
    case 'optimized'
        entry.dictionaryType = 'Background';                                     % What type of dictionary is this?
        entry.pegBackground = false;                                             % Passed to the routine that optimizes backgrounds.         
        entry.baseModulationContrast = 4/6;                                      % How much symmetric modulation contrast do we want to enable?  Used to generate background name.
        entry.primaryHeadRoom = 0.01;                                            % How close to edge of [0-1] primary gamut do we want to get?
        entry.photoreceptorClasses = ...                                         % Names of photoreceptor classes being considered.
            {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
        entry.fieldSizeDegrees = 27.5;                                           % Field size used in background seeking. Affects fundamentals.
        entry.pupilDiameterMm = 8.0;                                             % Pupil diameter used in background seeking. Affects fundamentals.
        entry.backgroundObserverAge = 32;                                        % Observer age used in background seeking. Affects fundamentals.
        entry.maxPowerDiff = 0.1;                                                % Smoothing parameter for routine that finds backgrounds.
        entry.modulationContrast = [entry.baseModulationContrast];              % Vector of constrasts sought in isolation.
        entry.whichReceptorsToIsolate = {[4]};                                   % Which receptor classes are not being silenced.
        entry.whichReceptorsToIgnore = {[]};                                     % Receptor classes ignored in calculations.
        entry.whichReceptorsToMinimize = {[]};                                   % These receptors are minimized in contrast, subject to other constraints.
        entry.directionsYoked = [0];                                             % See ReceptorIsolate.
        entry.directionsYokedAbs = [0];                                          % See ReceptorIsolate.
        entry.useAmbient = true;                                                 % Use measured ambient in calculations if true. If false, set ambient to zero.
        entry.cacheFile = '';                                                    % Place holder, modulation name and type-specific . Just declaring the field here.
        
    case 'lightfluxchrom'
        entry.dictionaryType = 'Background';                                     % What type of dictionary is this?
        entry.primaryHeadRoom = 0.01;                                            % How close to edge of [0-1] primary gamut do we want to get? (Check if actually used someday.) 
        entry.lightFluxDesiredXY = [0.54 0.38];                                  % Background chromaticity.
        entry.lightFluxDownFactor = 5;                                           % Factor to decrease background after initial values found.  Determines how big a pulse we can put on it.
        entry.useAmbient = true;                                                 % Use measured ambient in calculations if true. If false, set ambient to zero.
        entry.cacheFile = '';                                                    % Place holder, modulation name and type-specific . Just declaring the field here.

    otherwise
        error('Unknown background type specified: ''%s''.\n', type)
end % switch
end