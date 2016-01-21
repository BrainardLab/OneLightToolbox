function OLAllMirrorsOn
% OLAllMirrorsOn - Turns all the OneLight mirrors on.
%
% Syntax:
% OLAllMirrorsOn
%
% Description:
% Convenience function to turn the OneLight full on.

ol = OneLight;
ol.setAll(true);
