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
            % Constructor for OLDirection_unipolar objects
            
            % Input validation
            parser = inputParser();
            parser.addRequired('differentialPrimaryValues',@isnumeric);
            parser.addRequired('calibration',@isstruct);
            parser.addOptional('describe',struct('createdFrom',struct('constructor','construtor','arguments',{{differentialPrimaryValues,calibration,varargin}}),'correction',[],'validation',[]),@isstruct);
            parser.StructExpand = false;
            parser.parse(differentialPrimaryValues, calibration, varargin{:});
            
            % Assign
            this.differentialPrimaryValues = differentialPrimaryValues;
            this.calibration = calibration;
            this.describe = parser.Results.describe;
            
            this.SPDdifferentialDesired = this.ToPredictedSPD;
        end
        
        function new = copy(direction)
            % Return an unlinked copy of given direction
            new = OLDirection_unipolar(direction.differentialPrimaryValues, direction.calibration, direction.describe);
        end
    end
    
    %% Overloaded operators
    methods
        function out = eq(A,B)
            % Determine equality
            out = eq@OLDirection(A,B) && ...% same class, calibrations match
                all([A.differentialPrimaryValues] == [B.differentialPrimaryValues]); % differentials match
        end
        
        function out = times(A,B)
            % Scale OLDirection; overloads the .* operator
            
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
            % Add OLDirections; overloads the a+b (addition) operator
            %
            % Syntax:
            %   summedUnipolar = plus(A_unipolar, B_unipolar)
            %   summedUnipolar = plus(A_unipolar, B_bipolar)
            %   summedUnipolar = A_unipolar + B_unipolar
            %   summedUnipolar = A_unipolar + B_bipolar
            %   summedUnipolar = A_unipolar.plus(B_unipolar)
            %   summedUnipolar = A_unipolar.plus(B_bipolar)
            %
            % Description:
            %    Adds an OLDirection_unipolar object to another OLDirection
            %    object. When adding two unipolar objects, their
            %    differentialPrimaryValues properties are summed. When
            %    adding a unipolar to a bipolar object, the unipolar's
            %    differentialPrimaryValues are added to
            %    differentialPositive property of the bipolar direction.
            %    The output is always an OLDirection_unipolar object.
            %
            % Inputs:
            %    A              - OLDirection_unipolar object
            %    B              - OLDirection_unipolar, or
            %                     OLDirection_bipolar, object
            %
            % Outputs:
            %    summedUnipolar - a new OLDirection_unipolar object,
            %                     with the summed
            %                     differentialPrimaryValues
            %
            % Optional key/value pairs:
            %    None.
            %
            % See also:
            %    OLDirection, OLDirection_unipolar, OLDirection_bipolar
            
            % Input validation
            assert(isa(A,'OLDirection_unipolar'),'OneLightToolbox:OLDirection:plus:InvalidInput','Inputs have to be OLDirection');
            assert(isa(B,'OLDirection'),'OneLightToolbox:OLDirection:plus:InvalidInput','Inputs have to be OLDirection');
            assert(all(size(A) == size(B)) || (isscalar(A) || isscalar(B)),'OneLightToolbox:OLDirection:plus:InvalidInput','Inputs have to be the same size, or one input must be scalar');
            assert(all(matchingCalibration(A,B)),'OneLightToolbox:OLDirection:plus:InvalidInput','Directions have different calibrations');
            
            % Fencepost output
            out = OLDirection_unipolar.empty();
            
            % Do additions
            if numel(A) == 1 && numel(B) == 1
                % Add 2 directions
                newDescribe = struct('createdFrom',struct('a',A,'b',B,'operator','plus'),'correction',[],'validation',[]);
                if isa(B,'OLDirection_bipolar')
                    Bdifferential = B.differentialPositive;
                else
                    Bdifferential = B.differentialPrimaryValues;
                end
                out = OLDirection_unipolar(A.differentialPrimaryValues+Bdifferential,A.calibration,newDescribe);
                out.SPDdifferentialDesired = A.SPDdifferentialDesired + B.SPDdifferentialDesired(:,1);
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
            % Subtract OLDirections; overloads the a-b (subtract) operator
            %
            % Syntax:
            %   subtractedUnipolar = minus(A_unipolar, B_unipolar)
            %   subtractedUnipolar = minus(A_unipolar, B_bipolar)
            %   subtractedUnipolar = A_unipolar - B_unipolar
            %   subtractedUnipolar = A_unipolar - B_bipolar
            %   subtractedUnipolar = A_unipolar.minus(B_unipolar)
            %   subtractedUnipolar = A_unipolar.minus(B_bipolar)
            %
            % Description:
            %    Subtracts an OLDirection object (B, righthand side) from
            %    OLDirection_unipolar object (A, left hand side). When
            %    subracting two unipolar objects, their
            %    differentialPrimaryValues properties are subtracted. When
            %    subtracting a bipolar from a unipolar object, the
            %    bipolar's differentialNegative property is subtracted from
            %    the differentialPrimaryValues property of the unipolar
            %    direction. The output is always an OLDirection_unipolar
            %    object.
            %
            % Inputs:
            %    A                  - OLDirection_unipolar object
            %    B                  - OLDirection_unipolar, or
            %                         OLDirection_bipolar, object
            %
            % Outputs:
            %    subtractedUnipolar - a new OLDirection_unipolar object,
            %                         with the subtracted
            %                         differentialPrimaryValues
            %
            % Optional key/value pairs:
            %    None.
            %
            % See also:
            %    OLDirection, OLDirection_unipolar, OLDirection_bipolar
            
            % Input validation
            assert(isa(A,'OLDirection_unipolar'),'OneLightToolbox:OLDirection:plus:InvalidInput','Inputs have to be OLDirection_unipolar');
            assert(isa(B,'OLDirection'),'OneLightToolbox:OLDirection:plus:InvalidInput','Inputs have to be OLDirection');
            assert(all(size(A) == size(B)) || (isscalar(A) || isscalar(B)),'OneLightToolbox:OLDirection:plus:InvalidInput','Inputs have to be the same size, or one input must be scalar');
            assert(all(matchingCalibration(A,B)),'OneLightToolbox:OLDirection:plus:InvalidInput','Directions have different calibrations');
            
            % Fencepost output
            out = OLDirection_unipolar.empty();
            
            % Do subtractions (recursively if necessary)
            if numel(A) == 1 && numel(B) == 1
                % Subtract 2 directions
                newDescribe = struct('createdFrom',struct('a',A,'b',B,'operator','minus'),'correction',[],'validation',[]);
                if isa(B,'OLDirection_bipolar')
                    Bdifferential = B.differentialNegative;
                    BSPD = B.SPDdifferentialDesired(:,2);
                else
                    Bdifferential = -B.differentialPrimaryValues;
                    BSPD = -B.SPDdifferentialDesired;                    
                end
                out = OLDirection_unipolar(A.differentialPrimaryValues+Bdifferential,A.calibration,newDescribe);
                out.SPDdifferentialDesired = A.SPDdifferentialDesired + BSPD;
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