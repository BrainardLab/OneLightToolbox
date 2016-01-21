function [calID calIDTitle] = OLGetCalID(cal);
% [calID calIDTitle] = OLGetCalID(cal);
%
% Obtain the unique calibration ID, consisting of cal type, bulb and date.
%
% 2/9/14  ms Wrote it.
if isfield(cal.describe, 'bulbNumber')
    if ~isfield(cal.describe, 'calID')
        calID = [cal.describe.calType.CalFileName '_Bulb' num2str(cal.describe.bulbNumber,'%03d') '_' cal.describe.date];
    else
        calID = cal.describe.calID;
    end
else
    if ~isfield(cal.describe.calType, 'CalFileName')
        calID = [cal.describe.calType.ValueNames{:} '_Bulb000_' cal.describe.date];
    else
        calID = [cal.describe.calType.CalFileName '_Bulb000_' cal.describe.date];
    end
end
calID = strrep(strrep(calID, ' ', '_'), ':', '_');
calIDTitle = strrep(calID, '_', '\_');