function [mirrorMatrix] = OLStartStopsToMirrorMatrix(cal,starts,stops)
% [mirrorMatrix] = OLStartStopsToMirrorMatrix(cal,starts,stops)
%
% Convert starts/stops vectors to a visualization of the state of
% each mirror
%
% 2/16/14  dhb  Wrote it.

mirrorMatrix = zeros(cal.describe.numRowMirrors,cal.describe.numColMirrors);

for i = 1:cal.describe.numColMirrors
    if (starts(i) == cal.describe.numRowMirrors+1)
        if (stops(i) ~= 0)
            error('Mispecification for zero on in starts/stops');
        end
    else
        if (starts(i) < 0 || starts(i) > cal.describe.numRowMirrors-1 ...
                || stops(i) < 0 || stops(i) > cal.describe.numRowMirrors-1)
            error('Illegal value for starts or stops');
        end
        mirrorMatrix(starts(i)+1:stops(i)+1,i) = 1;
    end  
end
