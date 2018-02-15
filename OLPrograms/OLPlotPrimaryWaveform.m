function OLPlotPrimaryWaveform(primaryWaveform)
% Plots a primary waveform in 3D
%
% Syntax:
%   OLPlotPrimaryWaveform(primaryWaveform)
%
% Description:
%    A primary waveform is a matrix defining the power on each primary over
%    time. This can be plotted in 3D, which is this function does.
%
% Inputs:
%    primaryWaveform - PxT matrix describing the primary waveform, where P
%                      is the number of (effective) device primaries, and T
%                      is the number of timepoints
%
% Outputs:
%    None.
%
% Optional key/value pairs:
%    None.
%
% Notes:
%    None.
%
% See also:
%    OLPrimaryWaveform
%

% History:
%    01/30/18  jv  wrote it, mainly for debugging purposes.

% Plot3 expects three matrices: X, Y, Z.
% It will then plot point X(1,1),Y(1,1),Z(1,1), X(2,1),Y(2,1),Z(2,1)
% connected by a line. IT PLOTS ONE LINE PER COLUMN.

% If we have a single primary, we have a rowvector 1xt power levels.

% For a single primary, this would mean that:
% X is a columnvector of 1:t, i.e., 1:size(primary,2);
X = (1:size(primaryWaveform,2))';

% Y is a columnvector of ones(length(x),1), i.e., ones(size(primary,2),1)
Y = ones(size(primaryWaveform,2),1);

% Z is a columnvector of differentialScalars, of length size(primary,2), obviously.
Z = primaryWaveform(1,:)';

% To generalise this to multiple lines (i.e. multiple primaries):
% X, Y and Z are TxP matrices, i.e. size(primary,2)xsize(primary,1);
% X is specifically 1:T in each column, so 1:size(primary,2) for each of
% the size(primary,1) columns
X = repmat(X,[1 size(primaryWaveform,1)]);

% Y is a fixed value in each column, so the rows are 1:P, i.e.
% 1:size(primary,1)
Y = repmat(1:size(primaryWaveform,1),[size(primaryWaveform,2) 1]);

% Z is primary'
Z = primaryWaveform';

plot3(X,Y,primaryWaveform');
xlabel('Time-point');
ylabel('Device primary number');
zlabel('power');
zlim([0,1]);

end