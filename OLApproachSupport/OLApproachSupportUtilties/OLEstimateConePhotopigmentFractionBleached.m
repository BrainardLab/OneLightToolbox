function fractionBleached = OLEstimateConePhotopigmentFractionBleached(S,theSpd,pupilDiameterMm,fieldSizeDegrees,observerAgeInYears,photoreceptorClasses)
% OLEstimateConePhotopigmentFractionBleached  Estimate cone photopigment fraction bleached
%
% Usage:
%     fractionBleached = OLEstimateConePhotopigmentFractionBleached(S,spd,pupilDiameterMm,fieldSizeDegrees,observerAgeInYears,photoreceptorClasses)
%
% Description:
%     Compute fraction of pigment bleached in passed photoreceptor classes. This is a wrapper for the SilentSubstitutionToolbox routine
%     GetConeFractionBleachedFromSpectrum.
%
% Input:
%     S                          Wavelength sampling as row vector: [startWl deltaWl nWls],
%                                wavelengths in nm.
%
%     theSpd                     Spectral radiance in WattsPerM2Sr per wavelength band (not
%                                per nm)
%
%     pupilDiameterMm            Pupil diameter in mm to use when computing
%                                retinal irradiance.  Eye length is assumed to be 17 mm.
%
%     fieldSizeDegrees           Field size in degrees for cone spectral sensitivity computations.
%
%     observerAgeInYears         Observer age in years for cone spectral sensitivity computations.
%
%     photoreceptorClasses       Cell array of strings describing photoreceptor classes of interest.
%                                Options are 'LCone', 'MCone', 'SCone','LConePenumbral', 'MConePenumbral', 'SConePenumbral.
%                                See GetHumanPhotoreceptorSS for description of exactly what these denote.
%
% Output:
%     fractionBleached           Vector of fraction photopigment bleached
%                                for specified classes.  For any other classes passed, fraction
%                                bleached is returned as zero.
%
% See also: GetConeFractionBleachedFromSpectrum.

% 07/05/17  dhb  Pulled this out as its own function.
% 07/21/17  dhb  Call into SST routine rather than doing calcs de novo here.
%           dhb  Change 'Hemo' -> 'Penumbral'.

%% Call into SST routine to get fraction bleached for LMS cones and penumbral cones.
[fractionBleachedFromIsom, fractionBleachedFromIsomHemo] = GetConeFractionBleachedFromSpectrum(S, theSpd, fieldSizeDegrees, observerAgeInYears, pupilDiameterMm, [], []);

% Assign the fraction bleached for each photoreceptor class.
%
% We have a lot of receptor types.  Only some support fraction bleached.  This throws an error if the code ends 
% up here with something that is surprising.  It might be OK, particularly if a new type was recently defined
% within GetHumanPhotoreceptorSS, but throwing an error will force a check by hand, which seems wise.
for p = 1:length(photoreceptorClasses)
    switch photoreceptorClasses{p}
        case {'LConeTabulatedAbsorbance', 'LConeTabulatedAbsorbance2Deg', 'LConeTabulatedAbsorbance10Deg'}
            fractionBleached(p) = fractionBleachedFromIsom(1);
        case {'MConeTabulatedAbsorbance', 'MConeTabulatedAbsorbance2Deg', 'MConeTabulatedAbsorbance10Deg'}
            fractionBleached(p) = fractionBleachedFromIsom(2);
        case {'SConeTabulatedAbsorbance' 'SConeTabulatedAbsorbance2Deg', 'SConeTabulatedAbsorbance10Deg'}
            fractionBleached(p) = fractionBleachedFromIsom(3);
        case 'LConeTabulatedAbsorbancePenumbral'
            fractionBleached(p) = fractionBleachedFromIsomHemo(1);
        case 'MConeTabulatedAbsorbancePenumbral'
            fractionBleached(p) = fractionBleachedFromIsomHemo(2);
        case 'SConeTabulatedAbsorbancePenumbral'
            fractionBleached(p) = fractionBleachedFromIsomHemo(3);
        case {'Melanopsin', 'Rods'}
            fractionBleached(p) = 0;
        otherwise
            error('Using receptor type %s and trying to get fraction bleached, but this is not supported',photoreceptorClasses{p});
    end
end
