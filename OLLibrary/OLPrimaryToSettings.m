function settings = OLPrimaryToSettings(cal, primary, varargin)
% Convert OneLight primary values to gamma corrected mirror settings.
%
% Syntax:
%     settings = OLPrimaryToSettings(cal, primary)
%     settings = OLPrimaryToSettings(cal, primary, 'verbose', true)
%
% Description:
%     Take one light primary values, which are 0-1 numbers that give the
%     linear fraction of maximum light output for each primary, and gamma
%     correct these to get settings.  The settings values are also 0-1
%     numbers, but represent the fraction of the mirrors in the primary
%     that we want to turn on.
%
%     Note that this routine does not need to know about the number of
%     columns on the DLP chip, just the number of effective primaries that
%     we are using as we operate it.
%
%     To convert between the numbers returned by this routine and the
%     starts/stops vectors that get passed to the setMirrors routine of a
%     OneLight object use OLSettingsToStartsStops.  That routine knows both
%     about our primary parameters and about the chip.
%
% Input:
%     oneLightCal (struct)        - Struct. OneLight calibration file after it has been processed by OLInitCal.
%     primary                     - Matrix (NumPrimariesxNSpecta). The
%                                   normalized, ungamma corrected power level for each
%                                   effective primary (fraction of max
%                                   power) in the range [0,1]. NSpectra is
%                                   the number of spectra to process.
%
% Output:
%     settings (NumPrimaries x NSpecta) - The normalized, gamma corrected power level for each
%                                   effective primary.  These are also in the range [0,1].
%                                   NSpectra is the number of spectra to process.
% Optional Key-Value Pairs:
%    'verbose'                    - Boolean (default false). Provide more diagnostic output.
%    'primaryTolerance'           - Scalar (default 1e-6). Primaries can be this
%                                   much out of gamut and it will truncate them
%                                   into gamut without complaining.
%    'checkPrimaryOutOfRange'     - Boolean (default true). Throw error if any passed
%                                   primaries are out of the [0-1] range.

% 1/17/14  dhb, ms   Improved comments.
% 1/20/14  dhb, ms   Optimistically think that we've fixed this for full gamma table.
% 2/16/14  dhb       Convert to take input and output for each primery, not for each mirror.
% 06/05/17 dhb       Convert to input parser key/value pair.
% 01/24/18 dhb, jv   Add 'checkoutofrange' key and make default true.
% 04/12/18 dhb       Move to camelCase on key/value pairs.  Call
%                    OLCheckPrimaryGamut.
%          dhb       Header format to current standards.

%% Parse the input
p = inputParser;
p.addParameter('verbose', false, @islogical);
p.addParameter('primaryTolerance',1e-6, @isscalar);
p.addParameter('checkPrimaryOutOfRange', true, @islogical);
p.parse(varargin{:});
params = p.Results;

%% Make sure that the calibration file has been processed by OLInitCal.
assert(isfield(cal, 'computed'), 'OLSpdToPrimary:InvalidCalFile', ...
    'The calibration file needs to be processed by OLInitCal.');

%% Check on input.
% Number of rows in primary should match number of primaries
% as defined in the calibration file.
if (size(primary,1) ~= cal.describe.numWavelengthBands)
    error('Passed number of primaries does not match calibration data');
end

%% Check input range
primary = OLCheckPrimaryGamut(primary,...
    'primaryHeadroom',0, ...
    'primaryTolerance',p.Results.primaryTolerance, ...
    'checkPrimaryOutOfRange',p.Results.checkPrimaryOutOfRange);

%% Gamma correct
%
% If we've dummied up what looks like a gamma function measurement for
% every primary, then we can just use PTB's gamma correction directly.
if ~isfield(cal.describe, 'useAverageGamma') || (~cal.describe.useAverageGamma)
    cal.computed.gammaMode = 0;
    settings = PrimaryToSettings(cal.computed,primary);
    
% If we computed a single average gamma function, we have to use lower level
% routines.
else 
    settings = zeros(size(primary));
    nSpectra = size(primary, 2);
    for i = 1:nSpectra
        % Gamma correct the primary values.
        %
        % This is hard to read because of the transposes, which work
        % in the special case of a one primary gamma table.  Once
        % we make each primary have a separate gamma function in OL cal files,
        % we should be able to call PrimaryToSettings here and be done with it.
        settings(:,i) = GamutToSettingsSch(cal.computed.gammaInput, cal.computed.gammaTableAvg, primary(:,i)')';
        
        if params.verbose
            gammaCorrectedCurve = GamutToSettingsSch(cal.computed.gammaInput, ...
                cal.computed.gammaTableAvg,cal.computed.gammaInput');
            figure; clf; hold on
            plot(primary(:,i), settings(:,i), 'ro');
            plot(cal.computed.gammaInput, gammaCorrectedCurve', 'k');
            xlabel('Linear Settings');
            ylabel('Gamma Corrected Settings');
            title('Gamma Correction')
            ylim([0 1]);
            
            % Plot settings
            figure; clf; hold on
            plot(primary(:,i), 'ro', 'MarkerFaceColor', 'r');
            xlabel('Column Number');
            ylabel('Column Setting');
            title('Settings');
            ylim([0 1]);
        end
    end
end
