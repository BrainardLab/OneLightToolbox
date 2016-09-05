classdef OLCalibrationTypes
    % OLCalibrationTypes - Enumeration class for the different OneLight calibration types.
    %
    % OLCalibrationTypes properties:
    % CalFileName - The calibration file name associated with the calibration type.
    
    properties
        CalFileName;
    end
    
    methods
        function obj = OLCalibrationTypes(s)
            obj.CalFileName = s;
        end
    end
    
    enumeration
        BoxDRandomizedLongCableAEyePiece2_ND06('OLBoxDRandomizedLongCableAEyePiece2_ND06');
        BoxDRandomizedLongCableAEyePiece2_ND06_Warmup('OLBoxDRandomizedLongCableAEyePiece2_ND06_Warmup');
        BoxDRandomizedLongCableAEyePiece2_ND06_Debug('OLBoxDRandomizedLongCableAEyePiece2_ND06_Debug');
        BoxBRandomizedLongCableBStubby1_ND10('BoxBRandomizedLongCableBStubby1_ND10');
        BoxBRandomizedLongCableBStubby1_ND10_TestTracking('BoxBRandomizedLongCableBStubby1_ND10_TestTracking');  
        BoxBRandomizedLongCableBStubby1_ND00('BoxBRandomizedLongCableBStubby1_ND00');
    end
end
