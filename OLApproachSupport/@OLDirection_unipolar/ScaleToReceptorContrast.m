function [scaledDirection, scalingFactor] = ScaleToReceptorContrast(direction, background, receptors, desiredContrast)
% Scales OLDirection to have the desired contrast with background
%
% Syntax:
%   scaledDirection = ScaleToReceptorContrast(direction, background, receptors, desiredContrasts)
%   scaledDirection = direction.ScaleToReceptorContrast(background, receptors, desiredContrasts)
%   [scaledDirection, scalingFactor] = ...
%
% Description:
%    Detailed explanation goes here
%
% Inputs:
%    direction       - OLDirection_unipolar object to scale to desired 
%                      contrast
%    background      - OLDirection_unipolar object specifying background,
%                      contrast on which to scale to
%    receptors       -
%    desiredContrast - Rx1 columnvector of desired contrast on R receptors
%
% Outputs:
%    scaledDirection - new OLDirection_unipolar object with the desired
%                      contrast on background
%    scalingFactor   - numerical scaling factor to scale input direction to
%                      scaled direction
%
% Optional key/value pairs:
%    None.
%
% See also:
%    OLDirection_unipolar.times, SPDToReceptorContrast

% History:
%    03/31/18  jv  wrote it.

%% Input validation

%% Current desired receptor contrast


%% 

end

