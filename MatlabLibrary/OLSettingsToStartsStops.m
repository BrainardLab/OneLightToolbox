function [starts,stops] = OLSettingsToStartsStops(cal, settings, verbose)
% OLSettingsToStartsStops - Converts OneLight settings values to starts and stops.
%
% Syntax:
% [starts,stops] = OLSettingsToStartsStops(oneLightCal, settings)
% [starts,stops] = OLSettingsToStartsStops(oneLightCal, settings, verbose)
%
% Description:
% Take one light settings values, which are 0-1 numbers that give the gamma
% corrected fraction of the mirrors to turn on for each effective primary,
% and convert to start and stop values for every mirror column.  These
% are integers which can be passed directly to the setMirrors method of a
% OneLight object.
%
% These integers are in the range [0,NumRows-1], where NumRows is the number of
% rows in the DLP mirror.  Starts/stops of [0,0] turns on the first mirror,
% stats/stops of [0,NumRows-1] turns on all the mirrors.  You can set any
% consecutive range of mirrors.
%
% One trick is to handle the special case of zero, which requires start = NumRows+1
% and stop = 0.
%
% We also take some care in how we fill up the columns within a single primary.
%
% Input:
% oneLightCal (struct)              - OneLight calibration file after it has been processed by OLInitCal.
% settings (nPrimaries x nSpectra)  - The normalized and gamma corrected power level for each effective primary.
%                                     These are in the range [0,1] and correspond to the fraction of mirrors turned on
%                                     for that primary.
%                                     NumPrimaries is the number of effective primaries.
%                                     NSpectra is the number of spectra to be processed.
% verbose (logical)                 - Enables/disables verbose diagnostic information.
%                                     Defaults to false.
%
% Output:
% starts (nSpectra x nCols)         - The starts values for the OneLight, where NumCols is the number
%                                     of columns on the DMD chip in the OneLight.
% stops (nSpectrax nCols)           - The stops values for the OneLight.
%
% Note that the output is transposed from the input by convention, to match what the setMirrors method
% expects.
%
% See also: OLSettingsToStartsStopsTest, OLPrimaryToSettings
%
% 1/17/14  dhb, ms    Wrote it.
% 2/16/14  dhb        Convert to take settings for each primary, not each mirror.
%                     Getting clever about how to fill up the mirrors within the full
%                     set of columns within a primary.

% Validate the number of inputs.
error(nargchk(2, 3, nargin));

% Setup some defaults.
if ~exist('verbose', 'var') || isempty(verbose)
    verbose = false;
end

% Make sure that the calibration file has been processed by OLInitCal.
%assert(isfield(cal, 'computed'), 'OLSettingsToStartStops:InvalidCalFile', ...
%    'The calibration file needs to be processed by OLInitCal.');

% Get sizes
nRows = cal.describe.numRowMirrors;
if (rem(nRows,3) ~= 0)
    error('Number of DLP chip rows not divisible by four');
end
nCols = cal.describe.numColMirrors;
nPrimaries = size(settings,1);
if (nPrimaries ~= cal.describe.numWavelengthBands)
    error('Passed number of primaries does not match calibration data');
end
nSpectra = size(settings,2);

% Map [0,1] input settings into the range of mirrors on we actually want to
% use.
maxUseFraction = 1;
settings = settings*maxUseFraction;

% Sanity check
if (any(settings < 0) | (any(settings > 1)))
    error('Passed settings values not in range 0 to 1 inclusive');
end

% Allocate starts and stops.  Here in
% PTB convention to keep our brains from
% exploding, will transpose at the end.
%
% We begin by filling these with values that
% turn off all the mirrors, which is the weird
% thing of putting starts off the long end of
% the DLP rows.
starts = (nRows+1)*ones(nCols,nSpectra);
stops = zeros(nCols,nSpectra);

% The calibration file tells us many useful things,
% and in particular the width in columns of each
% primary and the number of skipped primaries at
% the short and long ends of the spectrum
nColsPerPrimary = cal.describe.bandWidth;
primaryStartCols = cal.describe.primaryStartCols;
primaryStopCols = cal.describe.primaryStopCols;
nMirrorsPerPrimary = nColsPerPrimary*nRows;

% Specify column types to cycle through.
%
% Number of columns per primary must be a multiple of the length
% of this order vector.
%
% This is set up for bandWidth of 16.
columnTypeOrder = {'TopDown' 'BottomUp' ...
    'BottomUp' 'TopDown' ...
    'QuarterUp' 'QuarterDown' ...
    'MiddleOut' 'MiddleOut' ...
    'MiddleOut' 'MiddleOut' ...
    'QuarterUp' 'QuarterDown' ...
    'BottomUp' 'TopDown' ...
    'TopDown' 'BottomUp'};
columnTypeOrder = {'TopDown' 'BottomUp' ...
    'MiddleOut' 'MiddleOut' ...
    'BottomUp' 'TopDown' ...
    'MiddleOut' 'MiddleOut' ...
    'TopDown' 'BottomUp' ...
    'MiddleOut' 'MiddleOut' ...
    'BottomUp' 'TopDown' ...
    'MiddleOut' 'MiddleOut'};
if (rem(nColsPerPrimary,length(columnTypeOrder)) ~= 0)
    error('Bandwidth of primaries must be multiple of list of column type orders.');
end


% Compute column order to fill within each primary.
% We fill first, then last, then second, then second to
% last, working our way towards the center.  The columnTypeOrder
% vector is used to determine the type of each column as we fill
% it up.
for k = 1:nColsPerPrimary/2
    withinPrimaryColumnOnOrder(2*k-1) = k;
    withinPrimaryColumnOnOrder(2*k) = nColsPerPrimary+1-k;
end

% Go through all the spectra, one at a time
for i = 1:nSpectra
    
    % For each spectrum, go through all the primaries, one at a time
    for j = 1:nPrimaries
        % Since we've set up starts and stops so that all
        % columns are off unless we turn them on, we only
        % have to do anyting for cases where the settings
        % are not zero.
        if (settings(j,i) ~= 0)
            % Convert settings from [0-1] to an integer number of
            % mirrors to turn on for the whole primary.
            nMirrorsOnThisPrimary = round(settings(j,i)*nMirrorsPerPrimary);
            
            % Divide this into the number of mirrors to turn on for each
            % column of the primary.
            %
            % Use a slow but conceptually simple algorithm.  Just loop through
            % all the mirrors we need to turn on, incrementing the next columns
            % accumulator by 1 each time through.
            maxMirrorsOnPerColumn = ceil(nMirrorsOnThisPrimary/nColsPerPrimary);
            nMirrorsOnPerColumn = zeros(1,nColsPerPrimary);
            mirrorsLeftToAllocate = nMirrorsOnThisPrimary;
            columnIndex = 1;
            for l = 1:nMirrorsOnThisPrimary
                % Bump accumulator this column
                whichColumn = withinPrimaryColumnOnOrder(columnIndex);
                nMirrorsOnPerColumn(whichColumn) = nMirrorsOnPerColumn(whichColumn) + 1;
                
                % Bump column indexer
                columnIndex = columnIndex + 1;
                if (columnIndex > nColsPerPrimary)
                    columnIndex = 1;
                end
            end
            if (sum(nMirrorsOnPerColumn) ~= nMirrorsOnThisPrimary)
                error('Logic error in how we allocate mirrors across primaries (mismatchin number on)');
            end
            if (any(nMirrorsOnPerColumn > nRows))
                error('Logic error in how we allocate mirrors across primaries (one col has > nRows)');
            end
            
            % Figure out starts and stops for each column
            columnTypeIndex = 1;
            columnIndex = 1;
            startsThisPrimary = (nRows+1)*ones(nColsPerPrimary,1);
            stopsThisPrimary = zeros(nColsPerPrimary,1);
            
            for k = 1:nColsPerPrimary
                % Get which column within primary that we are working on
                whichColumn = withinPrimaryColumnOnOrder(columnIndex);
                
                % Turn on appropriate mirrors, if number for this column
                % is greater than zero
                if (nMirrorsOnPerColumn(whichColumn) > 0)
                    switch (columnTypeOrder{columnTypeIndex})
                        case 'TopDown'
                            startsThisPrimary(whichColumn) = 0;
                            stopsThisPrimary(whichColumn) = nMirrorsOnPerColumn(whichColumn)-1;
                        case 'BottomUp'
                            startsThisPrimary(whichColumn) = (nRows-1) - (nMirrorsOnPerColumn(whichColumn)-1);
                            stopsThisPrimary(whichColumn) = nRows-1;
                        case 'MiddleOut'
                            rawStart = nRows/2;
                            nUpFromStart = round(nMirrorsOnPerColumn(whichColumn)/2);
                            nDownFromStart = nMirrorsOnPerColumn(whichColumn)-nUpFromStart;
                            startsThisPrimary(whichColumn) = rawStart-nUpFromStart;
                            stopsThisPrimary(whichColumn) = rawStart+nDownFromStart-1;
                        case 'QuarterDown'
                            rawStart = nRows/4;
                            nUpFromStart = round(nMirrorsOnPerColumn(whichColumn)/4);
                            nDownFromStart = nMirrorsOnPerColumn(whichColumn)-nUpFromStart;
                            startsThisPrimary(whichColumn) = rawStart-nUpFromStart;
                            stopsThisPrimary(whichColumn) = rawStart+nDownFromStart-1;
                         case 'QuarterUp'
                            rawStart = 3*nRows/4;
                            nUpFromStart = round(3*nMirrorsOnPerColumn(whichColumn)/4);
                            if (nUpFromStart > nMirrorsOnPerColumn(whichColumn))
                                nUpFromStart = nMirrorsOnPerColumn(whichColumn);
                            end
                            nDownFromStart = nMirrorsOnPerColumn(whichColumn)-nUpFromStart;
                            startsThisPrimary(whichColumn) = rawStart-nUpFromStart;
                            stopsThisPrimary(whichColumn) = rawStart+nDownFromStart-1;
                        otherwise
                            error('Bad column type specified')
                    end
                    if (any(startsThisPrimary(whichColumn) < 0) || any(startsThisPrimary(whichColumn) > nRows-1) || ...
                            any(stopsThisPrimary(whichColumn) < 0 || any(stopsThisPrimary(whichColumn) > nRows-1)))
                        error('Logic error in setting starts/stops from number mirrors on and column type');
                    end
                    if (stopsThisPrimary(whichColumn)-startsThisPrimary(whichColumn)+1 ~= nMirrorsOnPerColumn(whichColumn))
                        error('Difference between stops and starts inconsisent with desired number of mirrors on');
                    end
                end
                
                 % Debugging printout
                if (verbose)
                    fprintf('Spectrum %d, raw primary column %d, actual primary column %d\n',i,k,whichColumn);
                    fprintf('\tPrimary type %s\n',columnTypeOrder{columnTypeIndex});
                    fprintf('\tSettings value this primary %g, total mirrors on %d, mirrors on this column %d\n',...
                        settings(j,i),nMirrorsOnThisPrimary,nMirrorsOnPerColumn(whichColumn));
                    fprintf('\tStarts: %d, stops: %d\n',startsThisPrimary(whichColumn),stopsThisPrimary(whichColumn));
                end
                
                % Bump column type index
                columnTypeIndex = columnTypeIndex + 1;
                if (columnTypeIndex > length(columnTypeOrder))
                    columnTypeIndex = 1;
                end
                
                % Bump column indexer
                columnIndex = columnIndex + 1;
                if (columnIndex > nColsPerPrimary)
                    columnIndex = 1;
                end
            end
            
            % Insert what we just derived for this primary into the
            % full chips starts/stops matrices
            beginIndex = cal.describe.primaryStartCols(j);
            endIndex = cal.describe.primaryStopCols(j);
            starts(beginIndex:endIndex,i) = startsThisPrimary;
            stops(beginIndex:endIndex,i) = stopsThisPrimary;
        end
    end
end

% Transpose starts/stops so that they now live in the OL World.
starts = starts';
stops = stops';
