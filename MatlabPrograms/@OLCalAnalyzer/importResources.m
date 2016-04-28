function importResources(obj)
    % Load the CIE '31 CMFs and intepolate them according to the S-vector found in the inputCal
    load T_xyz1931
    obj.T_xyz = SplineCmf(S_xyz1931, 683*T_xyz1931, obj.cal.computed.pr650S);
    
    % Compute the wavelength axis
    obj.waveAxis = obj.cal.computed.pr650Wls;
end

