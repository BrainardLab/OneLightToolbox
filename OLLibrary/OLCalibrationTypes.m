classdef OLCalibrationTypes
    %OLCalibrationTypes - Enumeration class for the different OneLight calibration types.
    %
    % OLCalibrationTypes properties:
    %   CalFileName - The calibration file name associated with the calibration type.
    %
    % Given the type object, the calibration filename is given by
    %   calType.CalFileName.
    %
    % We name all of our calibration types here.  Then, we can get a list
    % of the currently enumerated calibration types by executing:
    %   calTypes = enumeration('OLCalibrationTypes');
    %   for i = 1:length(calTypes)
    %     calFileName{i} = calTypes(i).CalFileName;
    %   end
    % We can also look at this list from the reference page for
    % OLCalibrationTypes as they get listed out.
    %   doc OLCalibrationTypes
    %
    % This routine doesn't actually know whether the calibration files
    % really exist, it just associates filenames with calibration types.
    % Typically, we read the calibration files using
    %   OLGetCalibrationStructure.
    % This function, by default, respects the preference
    % getpref('OneLight','OneLightCalData') to decide where to look for
    % calibration files.
    %
    % Calling
    %   availableCalTypes = OLGetAvailableCalibrationTypes
    % gets the available calibration types, that is those where there is an actual
    % calibration file corresponding to the specified type.
    %
    % See also OLGetAvailableCalibrationTypes, OLGetCalibrationStructure.
    
    properties
        CalFileName;
    end
    
    methods
        function obj = OLCalibrationTypes(s)
            obj.CalFileName = s;
        end
    end
    
    enumeration
        % Demo cal file.  We always have this so that demos can run.
        OLDemoCal('OlDemoCal');
        
        % Classic eye pieces (pupil/psychophysics)
        BoxBRandomizedLongCableBEyePiece2_ND00('OLBoxBRandomizedLongCableBEyePiece2_ND00');
        BoxBRandomizedLongCableBEyePiece1_ND02('OLBoxBRandomizedLongCableBEyePiece1_ND02');
        BoxDRandomizedLongCableAEyePiece2_ND01('OLBoxDRandomizedLongCableAEyePiece2_ND01');
        BoxDRandomizedLongCableAEyePiece2_ND02('OLBoxDRandomizedLongCableAEyePiece2_ND02');
        BoxDRandomizedLongCableAEyePiece2_ND03('OLBoxDRandomizedLongCableAEyePiece2_ND03');
        BoxDRandomizedLongCableAEyePiece2_ND06('OLBoxDRandomizedLongCableAEyePiece2_ND06');
        
        % Note: Short RandomizedShortCableA is the collimating lens cable w/o collimating lens.
        BoxCRandomizedShortCableAEyePiece1_ND05('OLBoxCRandomizedShortCableAEyePiece1_ND05');
        
        % Stubby Eye piece (scanner)
        BoxBRandomizedLongCableDStubby1_ND00('OLBoxBRandomizedLongCableDStubby1_ND00');
        BoxBRandomizedLongCableDStubby1_ND02('OLBoxBRandomizedLongCableDStubby1_ND02');
        BoxBRandomizedLongCableDStubby1_ND02_ND40CassetteB('OLBoxBRandomizedLongCableDStubby1_ND02_ND40CassetteB');
        BoxCRandomizedLongCableDStubby1_ND05('OLBoxCRandomizedLongCableDStubby1_ND05');
        BoxCRandomizedLongCableDStubby1_ND10('OLBoxCRandomizedLongCableDStubby1_ND10');
        BoxARandomizedShortCableBStubby1_ND00('OLBoxARandomizedShortCableBStubby1_ND00');
        
        % Hybrid configuration for psychophysics w/ MRI components
        BoxDRandomizedLongCableAStubby1_ND03('OLBoxDRandomizedLongCableAStubby1_ND03');
        BoxBRandomizedLongCableBStubby1_ND02('OLBoxBRandomizedLongCableBStubby1_ND02');
        BoxARandomizedLongCableBStubby1_ND02('OLBoxARandomizedLongCableBStubby1_ND02');
        BoxDRandomizedLongCableAStubby1_ND02('OLBoxDRandomizedLongCableAStubby1_ND02');
        BoxDRandomizedLongCableAStubby1_ND01('OLBoxDRandomizedLongCableAStubby1_ND01');
    end
end
