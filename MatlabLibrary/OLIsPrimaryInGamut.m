function isInGamut = OLIsPrimaryInGamut(x)
% isInGamut = OLIsPrimaryInGamut(x)
%
% Tests if the primary values are within the 0-1 gamut.
%
% 11/23/15  ms      Pulled out of nulling code.

isInGamut = (~(any(x > 1) | any(x < 0)));