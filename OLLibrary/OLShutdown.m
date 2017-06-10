function OLShutdown
% OLShutdown - Puts the OneLight into the shutdown state.
%
% Syntax:
% OLShutdown
%
% Description:
% Puts the OneLight into the shutdown state.  Shutdown state lasts around 2
% minutes at which time the main lamp fan turns off.  Then it's safe to
% cut the power.

ol = OneLight;
ol.shutdown;
