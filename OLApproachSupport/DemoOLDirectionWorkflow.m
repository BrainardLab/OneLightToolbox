%% Demo of OLDirection-based workflow
%
%

%% Retrieve calibration information to use
calibration = OLGetCalibrationStructure('CalibrationFolder',fullfile(tbLocateToolbox('OneLightToolbox'),'OLDemoCal'),...
                                        'CalibrationType','OLDemoCal');

%% Define directions to use
% The modulation will be an LMS-isolating step. 
% Pull parameters from dictionary:
directionParams = OLDirectionParamsFromName('MaxLMS_bipolar_275_60_667');
[direction, background] = OLDirectionNominalFromParams(directionParams,calibration,'observerAge',32);
nominalContrasts = ToReceptorContrast([background, background+direction],direction.describe.directionParams.T_receptors);
nominalContrasts(:,1)