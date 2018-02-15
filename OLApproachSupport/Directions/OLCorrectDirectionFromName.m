function correctedDirection = OLCorrectDirectionFromName(directionName, observerAge, calibration, oneLight, radiometer, varargin)
% Corrects direction specified by name iteratively to attain predicted SPD
%
% Syntax:
%   correctedDirectionStruct = OLCorrectDirection(directionName, calibration, OneLight, radiometer)
%   correctedDirectionStruct = OLCorrectDirection(directionName, calibration, SimulatedOneLight)
%
% Description:
%    Detailed explanation goes here
%
% Inputs:
%    directionStruct    - a single struct defining a direction, with at 
%                         least the following fields:
%                         * backgroundPrimary   : the primary values for
%                                                 the background.
%                         * differentialPositive: the difference in primary
%                                                 values to be added to the
%                                                 background primary to
%                                                 create the positive
%                                                 direction
%                         * differentialNegative: the difference in primary
%                                                 values to be added to the
%                                                 background primary to
%                                                 create the negative
%                                                 direction
%                         * describe            : structure with additional
%                                                 metadata; data about
%                                                 corrections gets added to
%                                                 this
%    observerAge        - age (in years) of the observer for which to
%                         generated corrected direction. Required, because
%                         we don't want to deal with correcting a series of
%                         observer ages.
%    calibration        - struct containing calibration for oneLight
%    oneLight           - a OneLight device driver object to control a
%                         OneLight device, can be real or simulated
%    radiometer         - Radiometer object to control a
%                         spectroradiometer. Can be passed empty when
%                         simulating
%
% Outputs:
%    correctedDirection - the updated directionStruct, with the corrected
%                         primaries. Additional meta- and
%                         debugging-information got added to the structure
%                         in the 'describe' field.
%
% Optional key/value pairs:
%    nIterations            - Number of iterations. Default is 20.
%    learningRate           - Learning rate. Default is .8.
%    learningRateDecrease   - Decrease learning rate over iterations?
%                             Default is true.
%    asympLearningRateFactor- If learningRateDecrease is true, the 
%                             asymptotic learning rate is
%                             (1-asympLearningRateFactor)*learningRate. 
%                             Default = .5.
%    smoothness             - Smoothness parameter for OLSpdToPrimary.
%                             Default .001.
%    iterativeSearch        - Do iterative search with fmincon on each
%                             measurement interation? Default is false.
%
% See also:
%    OLCorrectDirection, OLCorrectPrimaryValues,
%    OLValidateDirectionFromName

% History:
%    01/21/14  dhb, ms  Convert to use OLSettingsToStartsStops.
%    01/30/14  ms       Added keyword parameters to make this useful.
%    07/06/16  npc      Adapted to use PR650dev/PR670dev objects
%    10/20/16  npc      Added ability to record temperature measurements
%    12/21/16  npc      Updated for new class @LJTemperatureProbe
%    01/03/16  dhb      Refactoring, cleaning, documenting.
%    06/05/17  dhb      Remove old style verbose arg from calls to OLSettingsToStartsStops
%    07/27/17  dhb      Massive interface redo.
%    07/29/17  dhb      Pull out radiometer open to one level up.
%    08/09/17  dhb, mab Comment out code that stores difference, just 
%                       return background and max modulations.
%                       Also, don't try to use the now non-extant 
%                       difference when we get the input.
%    08/21/17  dhb      Remove useAverageGamma, zeroPrimariesAwayFromPeak parameters.  These should be set in the calibration file and not monkey'd with.
%    02/09/18  jv       Inserted new corrections stack guts.
%    02/12/18  jv       Moved to fit new role as name-based correction

%% Input validation
parser = inputParser;
parser.addRequired('directionName',@ischar);
parser.addRequired('observerAge',@isscalar);
parser.addRequired('calibration',@isstruct);
parser.addRequired('oneLight',@(x) isa(x,'OneLight'));
parser.addOptional('radiometer',[],@(x) isempty(x) || isa(x,'Radiometer'));
parser.addParameter('cacheFilePath','',@ischar);
parser.KeepUnmatched = true; % allows fastforwarding of kwargs to OLCorrectPrimaryValues
parser.parse(directionName,observerAge,calibration,oneLight,radiometer,varargin{:});

%% Generate nominal direction
directionParams = OLDirectionParamsFromName(directionName);
backgroundPrimary = OLBackgroundNominalPrimaryFromName(directionParams.backgroundName,calibration);
directionStruct = OLDirectionNominalStructFromParams(directionParams,backgroundPrimary,calibration,'observerAge',observerAge);

%% Correct direction struct
correctedDirection = OLCorrectDirection(directionStruct, calibration, oneLight, radiometer, varargin{:});

end