function [modulationPrimary, modulationSpd, backgroundReceptors, fractionBleached] = OLReceptorIsolateCalculateIsolatingPrimary(S, T_receptors, cal, cacheFileName, B_primary, backgroundPrimary, ambientSpd, photoreceptorClasses, params, observerAgeInYears, pupilDiameterMm, initialPrimary,whichPrimariesToPin,whichReceptorsToIsolate, whichReceptorsToIgnore,whichReceptorsToMinimize, desiredContrasts)

% Calculate the receptor activations to the background
backgroundReceptors = T_receptors*(B_primary*backgroundPrimary + ambientSpd);

% If the config contains a field called Klein check, get the Klein
% XYZ also
if isfield(params, 'checkKlein') && params.checkKlein;
    T_klein = GetKleinK10AColorimeterXYZ(S);
    T_receptors = [T_receptors ; T_klein];
    photoreceptorClasses = [photoreceptorClasses kleinLabel];
end

% If the modulation we want is an isochromatic one, we simply scale
% the background Spectrum. Otherwise, we call ReceptorIsolate. Due
% to the ambient, we play a little game of adding a little bit to
% scale the background just right.
if strfind(cacheFileName, 'Isochromatic')
    modulationPrimary = backgroundPrimary+backgroundPrimary*max(desiredContrasts);
else
    try
        %% Isolate the receptors by calling the wrapper
        modulationPrimary = ReceptorIsolate(T_receptors, whichReceptorsToIsolate, ...
            whichReceptorsToIgnore,whichReceptorsToMinimize,B_primary,backgroundPrimary,...
            initialPrimary,whichPrimariesToPin,params.primaryHeadRoom,params.maxPowerDiff,...
            desiredContrasts,ambientSpd);
    catch e
        cacheData = [];
        return
    end
    
end
modulationSpd = B_primary*modulationPrimary + ambientSpd;
modulationReceptors = T_receptors*modulationSpd;