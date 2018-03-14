classdef OLDirection_bipolar < OLDirection
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
    %    03/12/18  jv  converted to OLDirection_bipolar
    
    properties
        differentialPositive;
        differentialNegative;
    end
    
    methods
        function this = OLDirection_bipolar(differentialPositive, differentialNegative, calibration, varargin)
            % Constructor for OLDirection_bipolar objects
            
            % Input validation
            parser = inputParser();
            parser.addRequired('differentialPositive',@isnumeric);
            parser.addRequired('differentialNegative',@isnumeric);
            parser.addRequired('calibration',@isstruct);
            parser.addOptional('describe',struct(),@isstruct);
            parser.StructExpand = false;
            parser.parse(differentialPositive, differentialNegative, calibration, varargin{:});
            
            % Assign
            this.differentialPositive = differentialPositive;
            this.differentialNegative = differentialNegative;
            this.calibration = calibration;
            this.describe = parser.Results.describe;
        end
    end
    
    %% Overloaded
    methods
        function out = eq(A,B)
            % Determine equality
            out = eq@OLDirection(A,B) && ...% same class, calibrations match
                ( all([A.differentialPositive] == [B.differentialPositive]) && ...% positive differentials match
                  all([A.differentialNegative] == [B.differentialNegative]) ); % negative differentials match
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
            out = OLDirection_bipolar.empty();
            
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
                newDirection = OLDirection_bipolar(s*direction.differentialPositive,s*direction.differentialNegative,direction.calibration,newDescribe);
                out = [out newDirection];
            end
        end
        
        function out = minus(A,B)
            % Subtract OLDirections; overloads the a-b (subtract) operator
            %
            % Syntax:
            %   subtractedUnipolar = minus(A_bipolar, B_unipolar)
            %   subtractedUnipolar = A_bipolar - B_unipolar
            %   subtractedUnipolar = A_bipolar.minus(B_unipolar)
            %
            % Description:
            %    Subtracts an OLDirection_unipolar object (B, righthand
            %    side) from OLDirection_bipolar object (A, left hand side).
            %    The differentialPrimaryValues property of the unipolar
            %    direction are subtracted from both the
            %    differentialPositive and differentialNegative properties
            %    of the bipolar direction. The output is always an
            %    OLDirection_unipolar object.
            %
            % Inputs:
            %    A                  - OLDirection_bipolar object
            %    B                  - OLDirection_unipolar object
            %
            % Outputs:
            %    subtractedBipolar  - a new OLDirection_bipolar object,
            %                         with the subtracted differential
            %                         values
            %
            % Optional key/value pairs:
            %    None.
            %
            % See also:
            %    OLDirection, OLDirection_unipolar, OLDirection_bipolar
            
            % Input validation
            assert(isa(A,'OLDirection_bipolar'),'OneLightToolbox:OLDirection:plus:InvalidInput','Left hand input has to be OLDirection');
            assert(isa(B,'OLDirection_unipolar'),'OneLightToolbox:OLDirection:plus:InvalidInput','Right hand input has to be OLDirection_unipolar; cannot subtract _bipolar from _bipolar.');
            assert(all(size(A) == size(B)) || (isscalar(A) || isscalar(B)),'OneLightToolbox:OLDirection:plus:InvalidInput','Inputs have to be the same size, or one input must be scalar');
            assert(all(matchingCalibration(A,B)),'OneLightToolbox:OLDirection:plus:InvalidInput','Directions have different calibrations');
            
            % Fencepost output
            out = OLDirection_bipolar.empty();
            
            % Do subtractions (recursively if necessary)
            if numel(A) == 1 && numel(B) == 1
                % Subtract 2 directions
                newDescribe = struct('createdFrom',struct('a',A,'b',B,'operator','minus'),'correction',[],'validation',[]);
                out = OLDirection_bipolar(A.differentialPositive-B.differentialPrimaryValues,A.differentialNegative-B.differentialPrimaryValues,A.calibration,newDescribe);
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
end