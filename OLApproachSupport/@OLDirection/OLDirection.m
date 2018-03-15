classdef (Abstract) OLDirection < handle & matlab.mixin.Heterogeneous
    % Class defining a direction for use with OneLight devices
    %
    % Description:
    %    A direction of modulation, is a direction (vector) in primary space
    %    that corresponds to some desired direction in spectral or receptor
    %    space. An OLDirection object defines a direction as 2 vector
    %    componenents in primary space: the positive differential vector, and
    %    the negative differential vector. The positive and negative component
    %    of the direction are defined separately, because they can be
    %    asymmetric. Since these specifications are device/calibration
    %    dependent, the OLDirection object also stores a OneLight calibration
    %    struct.
    
    % History:
    %    03/02/18  jv  wrote it.
    %    03/12/18  jv  converted into abstract superclass.
    
    properties
        calibration;
        SPDdesired;
        describe;
    end
      
    %% Overloaded operators, to allow for direction algebra
    methods   
        function varargout = mtimes(~,~) %#ok<STOUT>
            error('Undefined operator ''*'' for input arguments of type ''OLDirection''. Are you trying to use ''.*''?');
        end
        
        function out = eq(A,B)
            % Determine equality
            assert(isa(A,'OLDirection'),'OneLightToolbox:OLDirection:plus:InvalidInput','Inputs have to be OLDirection.');
            assert(isa(B,'OLDirection'),'OneLightToolbox:OLDirection:plus:InvalidInput','Inputs have to be OLDirection.');            
                
            if ~strcmp(class(A),class(B))
                out = false;
            else
                out = matchingCalibration(A,B);
            end
        end
    end
    
    %% 
    methods (Sealed)
        primaryWaveform = OLPrimaryWaveform(directions, waveforms, varargin);
        modulation = OLAssembleModulation(directions, waveforms, varargin);
        [excitations, SPDs] = ToReceptorExcitations(direction, receptors);
        [contrast, excitation, excitationDiff] = ToReceptorContrast(direction, receptors);

        function out = matchingCalibration(A,B)
            % Determine if OLDirections share a calibration
            assert(isa(A,'OLDirection'),'OneLightToolbox:OLDirection:plus:InvalidInput','Inputs have to be OLDirection');
            assert(isa(B,'OLDirection'),'OneLightToolbox:OLDirection:plus:InvalidInput','Inputs have to be OLDirection');        

            % Check if calibrations match
            Acalibrations = [A.calibration];
            Bcalibrations = [B.calibration];
            Acalibrations = [Acalibrations.describe];
            Bcalibrations = [Bcalibrations.describe];
            Acalibrations = {Acalibrations.calID};
            Bcalibrations = {Bcalibrations.calID};
            out = strcmp(Acalibrations,Bcalibrations);
        end
    end
end