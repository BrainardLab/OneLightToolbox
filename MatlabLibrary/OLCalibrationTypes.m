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
        BoxBRandomizedLongCableBEyePiece2_ND00('OLBoxBRandomizedLongCableBEyePiece2_ND00');
        BoxDRandomizedLongCableAEyePiece2_ND03('OLBoxDRandomizedLongCableAEyePiece2_ND03');
        BoxCRandomizedLongCableBStubby1_ND00('OLBoxCRandomizedLongCableBStubby1_ND00');
        BoxDRandomizedLongCableAEyePiece2_ND06('OLBoxDRandomizedLongCableAEyePiece2_ND06');
    end
end
