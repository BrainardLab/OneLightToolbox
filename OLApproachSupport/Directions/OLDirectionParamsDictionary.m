function dictionary = OLDirectionParamsDictionary(varargin)
% Defines a dictionary with parameters for named nominal directions
%
% Syntax:
%   dictionary = OLDirectionParamsDictionary()
%
% Description:
%    Define a dictionary of named directions of modulation, with
%    corresponding nominal parameters. Types of directions, and their
%    corresponding fields, are defined in OLDirectionParamsDefaults,
%    and validated by OLDirectionParamsValidate.
%
% Inputs:
%    None.
%
% Outputs:
%    dictionary - dictionary with all parameters for all desired directions
%
% Optional key/value pairs:
%    'alternateDictionaryFunc' - String with name of alternate dictionary
%                          function to call. This must be a function on the
%                          path. Default of empty results in using this
%                          function.
%
% Notes:
%    None.
%
% See also: OLBackgroundParamsDictionary

% History:
%    06/22/17  npc  Wrote it. 06/28/18  dhb  backgroundType ->
%                   backgroundName. Use names of routine that creates
%                   backgrounds.
%              dhb  Add name field. 
%              dhb  Explicitly set contrasts in each case, rather than rely
%                   on defaults. 
%              dhb  Bring in params.photoreceptorClasses.  These go with
%                   directions/backgrounds. 
%              dhb  Bring in params.useAmbient. This goes with directions/
%                   backgrounds.
%    07/05/17  dhb  Bringing up to speed. :
%    07/19/17  npc  Added a type for each background. For now, there is 
%                   only one type: 'pulse'. Defaults and checking are done 
%                   according to type. params.photoreceptorClasses is now a
%                   cell array
%    07/22/17  dhb  No more modulationDirection field. 
%    07/23/17  dhb  Comment field meanings. 
%    07/27/17  dhb  Light flux entry 
%    01/24/18  dhb,jv  Finished adding support for modulations
%              jv   Renamed direction types: pulse is now unipolar,
%                   modulation is now bipolar
%	 01/25/18  jv	Extract defaults generation, validation of params.
%    02/15/18  jv   Parameters are now objects
%    03/31/18  dhb  Add alternateDictionaryFunc key/value pair.
%              dhb  Delete obsolete notes and see alsos.
%    04/09/18  dhb  Removing light flux parameters. Use a local dictionary!
%    05/18/20  dhb  Remove () from call to dictionaryFunction, which fixes
%                   an error. This might be a Matlab version thing.

% Parse input
p = inputParser;
p.KeepUnmatched = true;
p.addParameter('alternateDictionaryFunc','',@ischar);
p.parse(varargin{:});

% Check for alternate dictionary, call if so and then return.
% Otherwise this is the dictionary function and we execute it.
% The alternate function must be on the path.
if (~isempty(p.Results.alternateDictionaryFunc))
    dictionaryFunction = str2func(sprintf('@%s',p.Results.alternateDictionaryFunc));
    dictionary = dictionaryFunction;
    return;
end

%% Initialize dictionary
dictionary = containers.Map();

%% MaxMel_unipolar_275_80_667
% Direction for maximum unipolar contrast melanopsin step
%   Field size: 27.5 deg
%   Pupil diameter: 8 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% 
% unipolar contrast step up relative to the background.
params = OLDirectionParams_Unipolar;
params.baseName = 'MaxMel';
params.primaryHeadRoom = 0.01;
params.baseModulationContrast = 2/3;
params.fieldSizeDegrees = 27.5;
params.pupilDiameterMm = 8.0;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = [params.baseModulationContrast];
params.whichReceptorsToIsolate = [4];
params.whichReceptorsToIgnore = [];
params.whichReceptorsToMinimize = [];
params.backgroundName = 'MelanopsinDirected_275_80_667';
params.name = OLDirectionNameFromParams(params);
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxMel_bipolar_275_80_667
% Direction for maximum bipolar contrast melanopsin modulation
%   Field size: 27.5 deg
%   Pupil diameter: 8 mm
%   Bipolar contrast: 66.7%
params = OLDirectionParams_Bipolar;
params.baseName = 'MaxMel';
params.primaryHeadRoom = 0.01;
params.baseModulationContrast = 2/3;
params.fieldSizeDegrees = 27.5;
params.pupilDiameterMm = 8.0;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = [params.baseModulationContrast];
params.whichReceptorsToIsolate = [4];
params.whichReceptorsToIgnore = [];
params.whichReceptorsToMinimize = [];
params.backgroundName = 'MelanopsinDirected_275_80_667';
params.name = OLDirectionNameFromParams(params);
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxMel_unipolar_275_60_667
% Direction for maximum unipolar contrast melanopsin step
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm -- for use with 6 mm artificial pupil as part of
%   pupillometry
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
params = OLDirectionParams_Unipolar;
params.baseName = 'MaxMel';
params.primaryHeadRoom = 0.0;
params.baseModulationContrast = 2/3;
params.fieldSizeDegrees = 27.5;
params.pupilDiameterMm = 6.0;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = [params.baseModulationContrast];
params.whichReceptorsToIsolate = [4];
params.whichReceptorsToIgnore = [];
params.whichReceptorsToMinimize = [];
params.backgroundName = 'MelanopsinDirected_275_60_667';
params.name = OLDirectionNameFromParams(params);
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxMel_unipolar_275_60_500
% Direction for maximum unipolar contrast melanopsin step
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm -- for use with 6 mm artificial pupil as part of
%   pupillometry
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
params = OLDirectionParams_Unipolar;
params.baseName = 'MaxMel';
params.primaryHeadRoom = 0.01;
params.baseModulationContrast = 1/2;
params.fieldSizeDegrees = 27.5;
params.pupilDiameterMm = 6.0;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = [params.baseModulationContrast];
params.whichReceptorsToIsolate = [4];
params.whichReceptorsToIgnore = [];
params.whichReceptorsToMinimize = [];
params.backgroundName = 'MelanopsinDirected_275_60_667';
params.name = OLDirectionNameFromParams(params);
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxMel_unipolar_600_80_667
% Direction for maximum unipolar contrast melanopsin step
%   Field size: 60.0 deg
%   Pupil diameter: 8 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
params = OLDirectionParams_Unipolar;
params.baseName = 'MaxMel';
params.primaryHeadRoom = 0.01;
params.baseModulationContrast = 2/3;
params.fieldSizeDegrees = 60.0;
params.pupilDiameterMm = 8.0;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = [params.baseModulationContrast];
params.whichReceptorsToIsolate = [4];
params.whichReceptorsToIgnore = [];
params.whichReceptorsToMinimize = [];
params.backgroundName = 'MelanopsinDirected_600_80_667';
params.name = OLDirectionNameFromParams(params);
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxLMS_unipolar_275_80_667
% Direction for maximum unipolar contrast LMS step
%   Field size: 27.5 deg
%   Pupil diameter: 8 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
params = OLDirectionParams_Unipolar;
params.baseName = 'MaxLMS';
params.primaryHeadRoom = 0.01;
params.baseModulationContrast = 2/3;
params.fieldSizeDegrees = 27.5;
params.pupilDiameterMm = 8.0;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = [params.baseModulationContrast params.baseModulationContrast params.baseModulationContrast];
params.whichReceptorsToIsolate = [1 2 3];
params.whichReceptorsToIgnore = [];
params.whichReceptorsToMinimize = [];
params.backgroundName = 'LMSDirected_275_80_667';
params.name = OLDirectionNameFromParams(params);
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxLMS_unipolar_275_60_667
% Direction for maximum unipolar contrast LMS step
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm -- for use with 6 mm artificial pupil with
%   pupillometry
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
params = OLDirectionParams_Unipolar;
params.baseName = 'MaxLMS';
params.primaryHeadRoom = 0.0;
params.baseModulationContrast = 2/3;
params.fieldSizeDegrees = 27.5;
params.pupilDiameterMm = 6.0;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = [params.baseModulationContrast params.baseModulationContrast params.baseModulationContrast];
params.whichReceptorsToIsolate = [1 2 3];
params.whichReceptorsToIgnore = [];
params.whichReceptorsToMinimize = [];
params.backgroundName = 'LMSDirected_275_60_667';
params.name = OLDirectionNameFromParams(params);
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxLMS_unipolar_275_60_500
% Direction for maximum unipolar contrast LMS step
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm -- for use with 6 mm artificial pupil with
%   pupillometry
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
params = OLDirectionParams_Unipolar;
params.baseName = 'MaxLMS';
params.primaryHeadRoom = 0.01;
params.baseModulationContrast = 1/2;
params.fieldSizeDegrees = 27.5;
params.pupilDiameterMm = 6.0;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = [params.baseModulationContrast params.baseModulationContrast params.baseModulationContrast];
params.whichReceptorsToIsolate = [1 2 3];
params.whichReceptorsToIgnore = [];
params.whichReceptorsToMinimize = [];
params.backgroundName = 'LMSDirected_275_60_667';
params.name = OLDirectionNameFromParams(params);
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxLMS_bipolar_275_60_667
% Direction for maximum bipolar contrast LMS step
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm -- for use with 6 mm artificial pupil with
%   pupillometry
%   bipolar contrast: 66.7%
%
params = OLDirectionParams_Bipolar;
params.baseName = 'MaxLMS';
params.primaryHeadRoom = 0.01;
params.baseModulationContrast = 2/3;
params.fieldSizeDegrees = 27.5;
params.pupilDiameterMm = 6.0;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = [params.baseModulationContrast params.baseModulationContrast params.baseModulationContrast];
params.whichReceptorsToIsolate = [1 2 3];
params.whichReceptorsToIgnore = [];
params.whichReceptorsToMinimize = [];
params.backgroundName = 'LMSDirected_275_60_667';
params.name = OLDirectionNameFromParams(params);
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxLMS_unipolar_600_80_667
% Direction for maximum unipolar contrast LMS step
%   Field size: 60.0 deg
%   Pupil diameter: 8 mm
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
params = OLDirectionParams_Unipolar;
params.baseName = 'MaxLMS';
params.primaryHeadRoom = 0.01;
params.baseModulationContrast = 2/3;
params.fieldSizeDegrees = 60.0;
params.pupilDiameterMm = 8.0;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = [params.baseModulationContrast params.baseModulationContrast params.baseModulationContrast];
params.whichReceptorsToIsolate = [1 2 3];
params.whichReceptorsToIgnore = [];
params.whichReceptorsToMinimize = [];
params.backgroundName = 'LMSDirected_600_80_667';
params.name = OLDirectionNameFromParams(params);
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

%% MaxMelLMS_unipolar_275_60_667
% Direction for maximum unipolar contrast melanopsin step
%   Field size: 27.5 deg
%   Pupil diameter: 6 mm -- for use with 6 mm artificial pupil as part of
%   pupillometry
%   bipolar contrast: 66.7%
%
% Bipolar contrast is specified to generate, but the result is a 400% unipolar
% contrast step up relative to the background.
params = OLDirectionParams_Unipolar;
params.baseName = 'MaxMelLMS';
params.primaryHeadRoom = 0.0;
params.baseModulationContrast = 2/3;
params.fieldSizeDegrees = 27.5;
params.pupilDiameterMm = 6.0;
params.photoreceptorClasses = {'LConeTabulatedAbsorbance','MConeTabulatedAbsorbance','SConeTabulatedAbsorbance','Melanopsin'};
params.modulationContrast = [params.baseModulationContrast params.baseModulationContrast params.baseModulationContrast params.baseModulationContrast];
params.whichReceptorsToIsolate = [1, 2, 3, 4];
params.whichReceptorsToIgnore = [];
params.whichReceptorsToMinimize = [];
params.backgroundName = 'MelanopsinDirected_275_60_667';
params.name = OLDirectionNameFromParams(params);
if OLDirectionParamsValidate(params)
    % All validations OK. Add entry to the dictionary.
    dictionary(params.name) = params;
end

end