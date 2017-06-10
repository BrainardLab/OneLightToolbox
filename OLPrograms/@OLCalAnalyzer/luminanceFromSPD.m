function luminance = luminanceFromSPD(obj,spd)
    luminance = obj.T_xyz(2,:) * spd;
end

