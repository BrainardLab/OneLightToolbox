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
        BoxDRandomizedLongCableAEyePiece2('OLBoxDRandomizedLongCableAEyePiece2');
        BoxDRandomizedLongCableAEyePiece2_ND10('OLBoxDRandomizedLongCableAEyePiece2_ND10');
        BoxCRandomizedLongCableBEyePiece1('OLBoxCRandomizedLongCableBEyePiece1');
        BoxARandomizedLongCableBEyePiece1('OLBoxARandomizedLongCableBEyePiece1');
        BoxCRandomizedLongCableCStubby1_ND05('OLBoxCRandomizedLongCableCStubby1_ND05');
        BoxCRandomizedLongCableCStubby1_ND10('OLBoxCRandomizedLongCableCStubby1_ND10');
        BoxARandomizedLongCableBEyePiece1_ND10('OLBoxARandomizedLongCableBEyePiece1_ND10');
        BoxCRandomizedLongCableCStubby1NoLens_ND10('OLBoxCRandomizedLongCableCStubby1NoLens_ND10');
        BoxCRandomizedLongCableCStubby1NoLens_ND10_ContactLens_0_5mm('OLBoxCRandomizedLongCableCStubby1NoLens_ND10_ContactLens_0_5mm');
        BoxDRandomizedLongCableAEyePiece2_ND10CassetteB('OLBoxDRandomizedLongCableAEyePiece2_ND10CassetteB');
        BoxDRandomizedLongCableAEyePiece2_ND05CassetteB('OLBoxDRandomizedLongCableAEyePiece2_ND05CassetteB');
        BoxDRandomizedLongCableAEyePiece2_ND07CassetteB('OLBoxDRandomizedLongCableAEyePiece2_ND07CassetteB');
        BoxARandomizedLongCableBEyePiece1_ND06('OLBoxARandomizedLongCableBEyePiece1_ND06');
    end
end
