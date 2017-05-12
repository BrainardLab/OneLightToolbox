function OLAnalyzeCalibrationValidationTempData

    testFile = 'piprmaxpulse/041317/Cache-LMSDirectedSuperMaxLMS_MELA_0085_041317/13-Apr-2017_12_19_24/Cache-LMSDirectedSuperMaxLMS_MELA_0085_041317-BoxDRandomizedLongCableAEyePiece2_ND02-SpotCheck.mat';
    testFile = 'cache/stimuli/Cache-LMSDirectedSuperMaxLMS_MELA_0085_041317';
    
    % Spot checks
    testFile = 'PIPRMaxPulse/041317/Cache-LMSDirectedSuperMaxLMS_MELA_0085_041317/13-Apr-2017_14_58_29/Cache-LMSDirectedSuperMaxLMS_MELA_0085_041317-BoxDRandomizedLongCableAEyePiece2_ND02-SpotCheck.mat';
    testFile = 'PIPRMaxPulse/041317/Cache-LMSDirectedSuperMaxLMS_MELA_0085_041317/13-Apr-2017_12_19_24/Cache-LMSDirectedSuperMaxLMS_MELA_0085_041317-BoxDRandomizedLongCableAEyePiece2_ND02-SpotCheck.mat';
    
    % Cache files
    testFile = 'PIPRMaxPulse/041317/Cache-LMSDirectedSuperMaxLMS_MELA_0085_041317.mat';
    %testFile = 'cache/stimuli/Cache-MelanopsinDirectedSuperMaxMel_MELA_0085_041317.mat';
    
    calFile = 'OLBoxDRandomizedLongCableAEyePiece2_ND02.mat';
    %calFile = 'OLBoxDRandomizedLongCableAEyePiece2_ND03.mat';
    
    tempAnalyzer = OLTempAnalyzer(...
        'rootDir', '/Users1/DropBoxLinks/DropboxAguirreBrainardLabs/MELA_materials', ...
        'calibrationFile', fullfile('OneLightCalData', calFile), ...
        'testFile', testFile ...
        );
    
end

