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
        %GlobeShortCable ('OLGlobeShortCable')
        %GlobeShortCableND ('OLGlobeShortCableND')
        %GlobeLongCable ('OLGlobeLongCable')
        %GlobeLongCableND ('OLGlobeLongCableND')
        %GogglesShortCable ('OLGogglesShortCable')
        %GogglesLongCable ('OLGogglesLongCable');
        %EyeTrackerShortCable ('OLEyeTrackerShortCable');
        %EyeTrackerLongCableCheck('OLEyeTrackerLongCableCheck');
        %EyeTrackerLongCable ('OLEyeTrackerLongCable');
        %EyeTrackerLongCableEyePiece1 ('OLEyeTrackerLongCableEyePiece1');
        %EyeTrackerLongCableEyePiece1_ND20 ('OLEyeTrackerLongCableEyePiece1_ND20');
        %EyeTrackerLongCableEyePiece2 ('OLEyeTrackerLongCableEyePiece2');
        %EyeTrackerLongCableEyePiece2_ND10 ('OLEyeTrackerLongCableEyePiece2_ND10');
        %EyeTrackerLongCableEyePiece2_ND15 ('OLEyeTrackerLongCableEyePiece2_ND15');
        %EyeTrackerLongCableEyePiece2_ND20 ('OLEyeTrackerLongCableEyePiece2_ND20');
        %EyeTrackerShortCableEyePiece1 ('OLEyeTrackerShortCableEyePiece1');
        %LongCableAEyePiece1 ('OLLongCableAEyePiece1');
        %ShortCableAEyePiece1 ('OLShortCableAEyePiece1');
        %BoxBLongCableAEyePiece2 ('OLBoxBLongCableAEyePiece2');
        %BoxBLongCableAEyePiece1 ('OLBoxBLongCableAEyePiece1');
        %BoxALongCableBEyePiece1 ('OLBoxALongCableBEyePiece1');
        %BoxBLongCableBEyePiece1 ('OLBoxBLongCableBEyePiece1');
        %BoxBLongCableBEyePiece2 ('OLBoxBLongCableBEyePiece2');
        %BoxBLongCableBEyePiece2 ('OLBoxBLongCableBEyePiece2');
        %BoxBLongCableBEyePiece2_ND20 ('OLBoxBLongCableBEyePiece2_ND20');
        %BoxBLongCableBEyePiece2_ND10 ('OLBoxBLongCableBEyePiece2_ND10');
        %BoxBLongCableCEyePiece2_03ND ('OLBoxBLongCableCEyePiece2_03ND');
        %BoxBLongCableBEyePiece2_03ND ('OLBoxBLongCableBEyePiece2_03ND');
        %BoxBLongCableBEyePiece1BeamsplitterProjectorOn ('OLBoxBLongCableBEyePiece1BeamsplitterProjectorOn');
        %BoxBLongCableBEyePiece1BeamsplitterProjectorOff ('OLBoxBLongCableBEyePiece1BeamsplitterProjectorOff');
        %BoxALongCableBEyePiece2_03ND ('OLBoxALongCableBEyePiece2_03ND');
        %BoxBLongCableAEyePiece2('OLBoxBLongCableAEyePiece2');
        %BoxCLongCableAEyePiece2('OLBoxCLongCableAEyePiece2');
        %BoxALongCableCEyePiece1('OLBoxALongCableCEyePiece1');
        %BoxALongCableCEyePiece2('OLBoxALongCableCEyePiece2');
        %BoxALongCableCEyePiece1BeamsplitterProjectorOn ('OLBoxALongCableCEyePiece1BeamsplitterProjectorOn');
        BoxBLongCableCEyePiece2('OLBoxBLongCableCEyePiece2');
        %BoxBShortCableDEyePiece1('OLBoxBShortCableDEyePiece1'); Note this
        %cal is for the AO Smilow setup. 
        %BoxALongCableCEyePiece2('OLBoxALongCableCEyePiece2');
        %BoxALongCableCEyePiece1_ND06('OLBoxALongCableCEyePiece1_ND06');
        %BoxCLongCableBEyePiece1('OLBoxCLongCableBEyePiece1');
        %BoxALongCableBEyePiece1('OLBoxALongCableBEyePiece1');
        %BoxCShortCableBEyePiece1_ND06('OLBoxCShortCableBEyePiece1_ND06');
        %BoxAShortCableBEyePiece2('OLBoxAShortCableBEyePiece2');
        %BoxAShortCableBEyePiece2Bandwidth8('OLBoxAShortCableBEyePiece2Bandwidth8');
        %BoxALongCableBEyePiece2('OLBoxALongCableBEyePiece2');
        %BoxAShortCableBEyePiece2_ND06('OLBoxAShortCableBEyePiece2_ND06');
        %BoxAShortCableBEyePiece2_ND10('OLBoxAShortCableBEyePiece2_ND10');
        %BoxAShortCableBEyePiece2_ND15('OLBoxAShortCableBEyePiece2_ND15');
        %BoxAShortCableBEyePiece2_ND20('OLBoxAShortCableBEyePiece2_ND20');
        %BoxCLongCableCEyePiece3BeamsplitterOff('OLBoxCLongCableCEyePiece3BeamsplitterOff');
        %BoxCLongCableCEyePiece3BeamsplitterOn('OLBoxCLongCableCEyePiece3BeamsplitterOn');
        %BoxCLongCableCEyePiece3BeamsplitterOff('OLBoxCLongCableCEyePiece3BeamsplitterOff');
        %BoxCShortCableAEyePiece3BeamsplitterOn('OLBoxCShortCableAEyePiece3BeamsplitterOn');
        %BoxALongCableBEyePiece2_ND06('OLBoxAShortCableBEyePiece2_ND06');
        %BoxALongCableBEyePiece2('OLBoxAShortCableBEyePiece2');
        %         BoxALongCableCEyePiece2('OLBoxALongCableCEyePiece2');
        %         BoxALongCableCEyePiece2_ND03('OLBoxALongCableCEyePiece2_ND03');
        %         BoxALongCableCEyePiece2_ND06('OLBoxALongCableCEyePiece2_ND06');
        %         BoxALongCableCEyePiece2_ND10('OLBoxALongCableCEyePiece2_ND10');
        %         BoxALongCableCEyePiece2_ND15('OLBoxALongCableCEyePiece2_ND15');
        %         BoxALongCableCEyePiece2_ND20('OLBoxALongCableCEyePiece2_ND20');
%         BoxAShortCableCEyePiece2('OLBoxAShortCableCEyePiece2');
%         BoxAShortCableCEyePiece2_ND03('OLBoxAShortCableCEyePiece2_ND03');
%         BoxAShortCableCEyePiece2_ND05('OLBoxAShortCableCEyePiece2_ND05');
%         BoxAShortCableCEyePiece2_ND06('OLBoxAShortCableCEyePiece2_ND06');
%         BoxAShortCableCEyePiece2_ND10('OLBoxAShortCableCEyePiece2_ND10');
%         BoxAShortCableCEyePiece2_ND15('OLBoxAShortCableCEyePiece2_ND15');
%         BoxAShortCableCEyePiece2_ND20('OLBoxAShortCableCEyePiece2_ND20');
%         BoxCShortCableAEyePieceStubby1('OLBoxCShortCableShortCableAEyePieceStubby1');
%         BoxCLongCableBEyePieceStubby1('OLBoxCLongCableBEyePieceStubby1');
%         BoxDShortCableDEyePieceSphere('OLBoxDShortCableDEyePieceSphere');
%         BoxDLongCableCEyePieceSphere('OLBoxDLongCableCEyePieceSphere');
%         BoxAShortCableBEyePiece2('OLBoxAShortCableBEyePiece2');
%         BoxAShortCableBEyePiece2_ND10('OLBoxAShortCableBEyePiece2_ND10');
%         BoxDLongCableCEyePiece2('OLBoxDLongCableCEyePiece2');
%         BoxDShortCableBEyePiece2('OLBoxDShortCableBEyePiece2');
%         BoxDShortCableBEyePiece2_ND15('OLBoxDShortCableBEyePiece2_ND15');
%         BoxDShortCableBEyePiece2_ND10('OLBoxDShortCableBEyePiece2_ND10');
%         BoxDRandomizedLongCableAEyePiece2('OLBoxDRandomizedLongCableAEyePiece2');
%         BoxDRandomizedLongCableAEyePiece2_ND10('OLBoxDRandomizedLongCableAEyePiece2_ND10');
        %BoxCRandomizedLongCableBEyePiece1BeamSplitterOff('OLBoxCRandomizedLongCableBEyePiece1BeamSplitterOff');
        BoxCRandomizedLongCableBEyePiece1('OLBoxCRandomizedLongCableBEyePiece1');
        BoxARandomizedLongCableBEyePiece1('OLBoxARandomizedLongCableBEyePiece1');
        BoxCRandomizedLongCableCStubby1_ND05('OLBoxCRandomizedLongCableCStubby1_ND05');
        BoxCRandomizedLongCableCStubby1_ND10('OLBoxCRandomizedLongCableCStubby1_ND10');
        BoxARandomizedLongCableBEyePiece1_ND10('OLBoxARandomizedLongCableBEyePiece1_ND10');
        BoxCRandomizedLongCableCStubby1NoLens_ND10('OLBoxCRandomizedLongCableCStubby1NoLens_ND10');
        BoxCRandomizedLongCableCStubby1NoLens_ND10_ContactLens_0_5mm('OLBoxCRandomizedLongCableCStubby1NoLens_ND10_ContactLens_0_5mm');
        BoxDRandomizedLongCableAEyePiece2_ND10CassetteB('OLBoxDRandomizedLongCableAEyePiece2_ND10CassetteB');
        BoxDRandomizedLongCableAEyePiece2_ND05CassetteB('OLBoxDRandomizedLongCableAEyePiece2_ND05CassetteB');
        BoxBShortCableDEyePiece3_ND00('OLBoxBShortCableDEyePiece3_ND00');
        BoxARandomizedLongCableCStubby1_ND00('OLBoxARandomizedLongCableCStubby1_ND00');
        BoxBRandomizedLongCableBEyePiece1_ND00('OLBoxBRandomizedLongCableBEyePiece1_ND00');
        BoxBRandomizedLongCableBStubbyEyePiece1_ND00('OLBoxBRandomizedLongCableBStubbyEyePiece1_ND00');
        BoxDRandomizedLongCableAEyePiece2_ND07CassetteB('OLBoxDRandomizedLongCableAEyePiece2_ND07CassetteB');
        BoxDRandomizedLongCableAEyePiece2_ND05('OLBoxDRandomizedLongCableAEyePiece2_ND05');
    end
end
