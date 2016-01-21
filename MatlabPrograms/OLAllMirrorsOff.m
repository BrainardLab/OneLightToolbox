function OLAllMirrorsOff
% OLAllMirrorsOff - Turns all the OneLight mirrors off.
%
% Syntax:
% OLAllMirrorsOff
%
% Description:
% Convenience function to turn the OneLight mirrors completely off.  Even
% when off, there is still some light that is emitted.

ol = OneLight;
ol.setAll(false);
