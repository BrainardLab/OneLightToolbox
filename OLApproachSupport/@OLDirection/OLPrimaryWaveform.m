function primaryWaveform = OLPrimaryWaveform(directions, waveforms, varargin)
% Combine OLDirections and waveforms into waveform-matrix of primaries
%
% Syntax:
%   primaryWaveform = OLPrimaryWaveform(OLDirection, waveform)
%   primaryWaveform = OLPrimaryWaveform(...,'differential',false)
%   primaryWaveform = OLPrimaryWaveform(..., 'truncateGamut',true)
%
% Description:
%
% Inputs:
%    directions      - OLDirection object specifying the directions to
%                      create primary waveform for.
%    waveforms       - Waveforms of temporal modulation, in a Nxt matrix
%                      of scalars for each of the N directions at each
%                      timepoint t.
%
% Outputs:
%    primaryWaveform - The primary values at each timepoint t, in a Pxt
%                      matrix. If multiple directions and corresponding
%                      waveforms were passed in (i.e. N > 1), these have
%                      been combined into a single waveform-matrix.
%
% Optional key/value pairs:
%    differential    - Boolean flag for treating primary values as
%                      differentials, i.e. in range [-1, +1]. Default
%                      true.
%
% Notes:
%    None.
%
% See also:
%    OLPrimaryWaveform, OLDirection, OLPlotPrimaryWaveform

% History:
%    01/29/18  jv  wrote it.
%    03/09/18  jv  overloaded for OLDirection objects

%% Input validation
parser = inputParser();
parser.addRequired('direction',@(x) isa(x,'OLDirection'));
parser.addRequired('waveform',@isnumeric);
parser.addParameter('differential',true,@islogical);
parser.parse(directions,waveforms,varargin{:});
assert(size(waveforms,1) == numel(directions),'OneLightToolbox:OLApproachSupport:OLPrimaryWaveform:MismatchedSizes',...
    'Number of directions does not match number of waveforms');
if ~isscalar(directions)
    assert(all(matchingCalibration(directions(1), directions(2:end))),'OneLightToolbox:OLApproachSupport:OLPrimaryWaveform:MismatchedCalibrations',...
    'Directions do not share a calibration');
end

%% Split waveforms into positive and negative components
waveformsPos = (waveforms >= 0) .* waveforms;
waveformsNeg = (waveforms < 0) .* -waveforms;
waveforms = [waveformsPos; waveformsNeg];

%% Assemble primary values matrix
% initialize empty primary values matrix
primaryValues = zeros([directions(1).calibration.describe.numWavelengthBands, numel(directions)*2]);
for i = 1:numel(directions)
    if isa(directions(i),'OLDirection_unipolar')
        primaryValues(:,i) = any(waveformsPos(i,:)) * directions(i).differentialPrimaryValues;
        primaryValues(:,numel(directions)+i) = any(waveformsNeg(i,:)) * -directions(i).differentialPrimaryValues;
    else
        primaryValues(:,i) = directions(i).differentialPositive;
        primaryValues(:,numel(directions)+i) = directions(i).differentialNegative;
    end
end

%% Construct primary waveform
primaryWaveform = OLPrimaryWaveform(primaryValues, waveforms);

end