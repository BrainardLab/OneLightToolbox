classdef OLDirection_unipolar < OLDirection
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
    %    03/12/18  jv  separated from OLDirection_bipolar
    
    properties
        differentialPrimaryValues;
    end
    
    %% Constructor
    methods
        function this = OLDirection_unipolar(differentialPrimaryValues, calibration, varargin)
            % Constructor for OLDirection objects
            %
            %
            %
            
            % Parse input
            parser = inputParser();
            parser.addRequired('differentialPrimaryValues',@isnumeric);
            parser.addRequired('calibration',@isstruct);
            parser.addOptional('describe',struct(),@isstruct);
            parser.StructExpand = false;
            parser.parse(differentialPrimaryValues, calibration, varargin{:});
            
            % Assign
            this.differentialPrimaryValues = differentialPrimaryValues;
            this.calibration = calibration;
            this.describe = parser.Results.describe;
        end        
    end
    
    %% Overloaded operators
    methods
        function out = eq(A,B)
            % Determine equality
            %
            %
            assert(isa(A,'OLDirection'),'OneLightToolbox:OLDirection:plus:InvalidInput','Inputs have to be OLDirection');
            assert(isa(B,'OLDirection'),'OneLightToolbox:OLDirection:plus:InvalidInput','Inputs have to be OLDirection');
            
            % Compare if calibrations match
            outCal = matchingCalibration(A,B);
            
            % Check if differentials match
            outDiffs = all([A.differentialPrimaryValues] == [B.differentialPrimaryValues]);
              
            % Combine
            out = outCal & outDiffs;
        end
        
        function out = times(A,B)
            % Scale OLDirection; overloads the .* operator
            %
            % One of the operators has to be numerical, the other has to be
            % an (array of) OLDirection_unipolar(s)
            %
            %   X.*Y denotes element-by-element multiplication. X and Y
            %   must have compatible sizes. In the simplest cases, they can
            %   be the same size or one can be a scalar. Two inputs have
            %   compatible sizes if, for every dimension, the dimension
            %   sizes of the inputs are either the same or one of them is
            %   1.
            
            % Input validation
            if isa(A,'OLDirection')
                assert(isnumeric(B),'OneLightToolbox:OLDirection:times:InvalidInput','One input has to be numerical.');
                directions = A;
                scalars = B;
            elseif isnumeric(A)
                assert(isa(B,'OLDirection'),'OneLightToolbox:OLDirection:times:InvalidInput','One input has to be an OLDirection object.');
                directions = B;
                scalars = A;
            else
                error('OneLightToolbox:OLDirection:times:InvalidInput','One input has to be numerical.');
            end
            assert(iscolumn(scalars) || isrow(scalars),'OneLightToolbox:OLDirection:times:InvalidInput','Can currently only handle 1-dimensional vectors of scalars.');
            assert(iscolumn(directions) || isrow(directions),'OneLightToolbox:OLDirection:times:InvalidInput','Can currently only handle 1-dimensional array of OLDirections.');
            
            % Fencepost output
            out = OLDirection_unipolar.empty();
            
            % Create scaled directions
            d = 1;
            for s = scalars
                % Get the current direction
                direction = directions(d);
                if ~isscalar(directions)
                    d = d+1;
                end
                
                % Create new direction
                newDescribe = struct('createdFrom',struct('a',direction,'b',s,'operator','.*'),'correction',[],'validation',[]);
                newDirection = OLDirection_unipolar(s*direction.differentialPrimaryValues,direction.calibration,newDescribe);
                out = [out newDirection];
            end
        end
        
        function out = plus(A,B)
            % Add OLDirection_unipolar; overloads the a+b (addition) operator
            
            % Input validation
            assert(isa(A,'OLDirection_unipolar'),'OneLightToolbox:OLDirection:plus:InvalidInput','Inputs have to be OLDirection_unipolar');
            assert(isa(B,'OLDirection_unipolar'),'OneLightToolbox:OLDirection:plus:InvalidInput','Inputs have to be OLDirection_unipolar');
            assert(all(size(A) == size(B)) || (isscalar(A) || isscalar(B)),'OneLightToolbox:OLDirection:plus:InvalidInput','Inputs have to be the same size, or one input must be scalar');
            assert(all(matchingCalibration(A,B)),'OneLightToolbox:OLDirection:plus:InvalidInput','Directions have different calibrations');
            
            % Fencepost output
            out = OLDirection_unipolar.empty();
            
            % Do additions
            if numel(A) == 1 && numel(B) == 1
                % Add 2 directions
                newDescribe = struct('createdFrom',struct('a',A,'b',B,'operator','plus'),'correction',[],'validation',[]);
                out = OLDirection_unipolar(A.differentialPrimaryValues+B.differentialPrimaryValues,A.calibration,newDescribe);
            elseif all(size(A) == size(B))
                % Sizes match, send each pair to be added.
                for i = 1:numel(A)
                    out = [out plus(A(i),B(i))];
                end
            elseif ~isscalar(A)
                % A is not scalar, loop over A
                for i = 1:numel(A)
                    out = [out plus(A(i),B)];
                end
            elseif ~isscalar(B)
                % B is not scalar, loop over B
                for i = 1:numel(B)
                    out = [out plus(A,B(i))];
                end
            end
        end
        
        function out = minus(A,B)
            % Subtract OLDirection_unipolar; overloads the a-b (subtract) operator
            
            % Input validation
            assert(isa(A,'OLDirection_unipolar'),'OneLightToolbox:OLDirection:plus:InvalidInput','Inputs have to be OLDirection_unipolar');
            assert(isa(B,'OLDirection_unipolar'),'OneLightToolbox:OLDirection:plus:InvalidInput','Inputs have to be OLDirection_unipolar');
            assert(all(size(A) == size(B)) || (isscalar(A) || isscalar(B)),'OneLightToolbox:OLDirection:plus:InvalidInput','Inputs have to be the same size, or one input must be scalar');
            assert(all(matchingCalibration(A,B)),'OneLightToolbox:OLDirection:plus:InvalidInput','Directions have different calibrations');
            
            % Fencepost output
            out = OLDirection_unipolar.empty();
            
            % Do subtractions (recursively if necessary)
            if numel(A) == 1 && numel(B) == 1
                % Subtract 2 directions
                newDescribe = struct('createdFrom',struct('a',A,'b',B,'operator','minus'),'correction',[],'validation',[]);
                out = OLDirection_unipolar(A.differentialPrimaryValues-B.differentialPrimaryValues,A.calibration,newDescribe);
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
        
    %% Static methods
    methods (Static)
        function direction = Null(calibration)
            nPrimaries = calibration.describe.numWavelengthBands;
            newDescribe = struct('NullDirection','NullDirection');
            direction = OLDirection_unipolar(zeros(nPrimaries,1),calibration, newDescribe);
        end
        function direction = FullOn(calibration)
            nPrimaries = calibration.describe.numWavelengthBands;
            newDescribe = struct('FullOnDirection','FullOnDirection');
            direction = OLDirection_unipolar(ones(nPrimaries,1),calibration, newDescribe);
        end
    end    
    
end

