function cal = OLCalBackwardsCompatibility(cal)
% cal = OLCalBackwardsCompatibility(cal)
%
% We changed field name conventions etc.  This makes
% old calibration structures work with new OLInitCal.
%
% But gamma correction code will not work unless you
% re-run OLInitCal on the old structure.
%
% This routine also implements some defaults in a
% forwards compatible fashion.
%
% 1/20/14  dhb, ms  Wrote it.
% 4/9/16   dhb      Handle specified background field.

%% Add new fields
if (~isfield(cal.describe,'numWavelengthBands'))
    cal.describe.numWavelengthBands = cal.describe.numColMirrors/cal.describe.bandWidth;
end
if (~isfield(cal.describe,'useOmni'))
    cal.describe.useOmni = 1;
end
if (~isfield(cal.describe,'gammaNumberWlUseIndices'))
    cal.describe.gammaNumberWlUseIndices = 10;
end

if (~isfield(cal.describe,'nGammaFitLevels'))
    cal.describe.nGammaFitLevels = 1024;
end
if (~isfield(cal.describe,'gammaFitType'))
    cal.describe.gammaFitType = 6;
end
if (~isfield(cal.describe,'useAverageGamma'))
    cal.describe.useAverageGamma = 0;
end
if (~isfield(cal.describe,'correctLinearDrift'))
    cal.describe.correctLinearDrift = 0;
end
if (~isfield(cal.computed,'describe'))
    cal.computed.describe = [];
end
if (~isfield(cal.describe,'specifiedBackground'))
    cal.describe.specifiedBackground = false;
end


%% Rename old fields
if (~isfield(cal.raw,'gamma'))
    cal.raw.gamma = cal.raw.power;
    cal.raw = rmfield(cal.raw,'power');
    cal.describe.gamma = cal.describe.power;
    cal.describe = rmfield(cal.describe,'power');
    
    cal.describe.gamma.gammaBands = cal.describe.gamma.colSets;
    cal.describe.gamma = rmfield(cal.describe.gamma,'colSets');
    cal.describe.gamma.nGammaBands = cal.describe.gamma.numColSets;
    cal.describe.gamma = rmfield(cal.describe.gamma,'numColSets');

    cal.raw.gamma.stops = cal.raw.gamma.rows;
    cal.raw.gamma = rmfield(cal.raw.gamma,'rows');
    
    if (~isfield(cal.describe,'nGammaBands'))
        cal.describe.nGammaBands = size(cal.raw.gamma.rad,2);
    end
    if (~isfield(cal.describe,'nGammaLevels'))
        cal.describe.nGammaLevels = size(cal.raw.gamma.rad(1).meas,2);
    end
end

