classdef OLDirection < handle
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
        describe;
    end
      
    %% Overloaded operators, to allow for direction algebra
    methods   
        function varargout = mtimes(~,~) %#ok<STOUT>
            error('Undefined operator ''*'' for input arguments of type ''OLDirection''. Are you trying to use ''.*''?');
        end
                
        function out = sum(varargin)
            % Sum of array elements
            %
            % Sums array of OLDirections
            
            % Input validation
            parser = inputParser;
            parser.addRequired('A',@(x) isa(x,'OLDirection'));
            parser.addOptional('dim',0,@isnumeric);
            parser.parse(varargin{:});
            A = parser.Results.A;
            
            % Determine dimension to sum over
            if ~parser.Results.dim
                dim = find(size(A) > 1,1);
            else
                dim = parser.Results.dim;
            end
            
            % Determine new size
            newSize = size(A);
            newSize(dim) = 1;
            
            % Fencepost output
            out = OLDirection.empty();
            
            % Sum
            if dim == 1
                out(1,:) = plus(A(1,:),A(2:end,:));
            elseif dim == 2
                out(:,1) = plus(A(:,1),A(:,2:end));
            end
        end
        
        function out = minus(A,B)
            % Subtract OLDirections; overloads the a-b (subtract) operator
            
            % Input validation
            assert(isa(A,'OLDirection'),'OneLightToolbox:OLDirection:plus:InvalidInput','Inputs have to be OLDirection');
            assert(isa(B,'OLDirection'),'OneLightToolbox:OLDirection:plus:InvalidInput','Inputs have to be OLDirection');
            assert(all(size(A) == size(B)) || (isscalar(A) || isscalar(B)),'OneLightToolbox:OLDirection:plus:InvalidInput','Inputs have to be the same size, or one input must be scalar');
            
            % Fencepost output
            out = OLDirection.empty();
            
            % Do subtractions (recursively if necessary)
            if numel(A) == 1 && numel(B) == 1
                % Subtract 2 directions
                assert(all(AreStructsEqualOnFields(A.calibration.describe,B.calibration.describe,'calID')),'OneLightToolbox:OLDirection:plus:InvalidInput','Directions have different calibrations');
                newDescribe = struct('createdFrom',struct('a',A,'b',B,'operator','minus'),'correction',[],'validation',[]);
                out = OLDirection(A.differentialPositive-B.differentialPositive,A.differentialNegative-B.differentialNegative,A.calibration,newDescribe);
            elseif all(size(A) == size(B))
                % Sizes match, send each pair to be subtractd.
                for i = 1:numel(A)
                    out = [out minus(A(i),B(i))];
                end
            elseif ~isscalar(A)
                % A is not scalar, loop over A
                for i = 1:numel(A)
                    out = [out minus(A(i),B)];
                end
            elseif ~isscalar(B)
                % B is not scalar, loop over B
                for i = 1:numel(B)
                    out = [out minus(A,B(i))];
                end
            end
        end 
    end
    
    %% 
    methods
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