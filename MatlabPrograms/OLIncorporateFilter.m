function OLIncorporateFilter
% OLIncorporateFilter - Incorprate the presence of an ND filter
%   into an OL calibration file.
%
% Prompts for the name of the file and filter, as well as the output
% filename.  Input and output must be chosen from the ennumerated
% list of OL calibration types.
%
% Syntax:
% OLIncorporateFilter
%
% 7/3/13   dhb  Wrote it.

% Get the calibration file
calIn = OLGetCalibrationStructure;

% Get the filter info
filterName = GetWithDefault('Enter filter name','ND20');
filterDate = GetWithDefault('Enter filter measurement date','070313');
filterFile = ['srf_filter_' filterName '_' filterDate];
theFilter = load(fullfile(getpref('OneLight', 'OneLightCalData'),'xNDFilters',filterFile));
eval(['S_filter = theFilter.S_filter_' filterName ';']);
eval(['srf_filter = theFilter.srf_filter_' filterName ';']);

% Update for filter
calOut = OLFilterizeCal(calIn,S_filter,srf_filter);
calOut.describe.filterName = filterName;
calOut.describe.filterDate = filterDate;

% Get output calibraion type from enumerated list
calTypes = enumeration('OLCalibrationTypes');
while true
    fprintf('\n- Available output calibration types:\n');
    
    for i = 1:length(calTypes)
        fprintf('%d: %s\n', i, calTypes(i).char);
    end
    
    x = GetInput('Selection', 'number', 1);
    if x >= 1 && x <= length(calTypes)
        break;
    end
end
calOut.describe.calType = calTypes(x);
if (~strcmp([calIn.describe.calType.CalFileName '_' filterName],calOut.describe.calType.CalFileName))
    error('You are mucking with our filename conventions.  Think.');
end

% Save
SaveCalFile(calOut, calOut.describe.calType.CalFileName, fullfile(getpref('OneLight', 'OneLightCalData')));
    