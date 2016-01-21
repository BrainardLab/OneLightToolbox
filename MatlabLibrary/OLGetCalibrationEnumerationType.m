function selectedCalType = OLGetCalibrationEnumerationType;
% selectedCalType = OLGetCalibrationEnumerationType
%
% This function prompts for the enumeration type to be used.
%
% Output:
%   selectedCalType - calibration type selected from enumeration.
%
% 1/21/14       ms      Made as a function.

calTypes = enumeration('OLCalibrationTypes');
while true
    fprintf('- Available calibration types:\n');
    
    for i = 1:length(calTypes)
        fprintf('%d: %s\n', i, calTypes(i).char);
    end
    
    x = GetInput('Selection', 'number', 1);
    if x >= 1 && x <= length(calTypes)
        break;
    end
end
selectedCalType = calTypes(x);