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
    
    properties
        differentialPositive;
        differentialNegative;
        calibration;
        describe;
        background;
    end
    
    %% Constructor
    methods
        function this = OLDirection(background, differentialPositive, differentialNegative, calibration, varargin)
            % Constructor for OLDirection objects
            %
            %
            %
            
            % Parse input
            parser = inputParser();
            parser.addRequired('background',@(x) isa(x,'OLDirection') || isnumeric(x));
            parser.addRequired('differentialPositive',@isnumeric);
            parser.addRequired('differentialNegative',@isnumeric);
            parser.addRequired('calibration',@isstruct);
            parser.addOptional('describe',struct(),@isstruct);
            parser.StructExpand = false;
            parser.parse(background, differentialPositive, differentialNegative, calibration, varargin{:});
            
            % Assign
            this.differentialPositive = differentialPositive;
            this.differentialNegative = differentialNegative;
            this.calibration = calibration;
            this.describe = parser.Results.describe;
            this.background = background;
        end
    end
    
    %% Overloaded operators, to allow for direction algebra
    methods
        function out = times(a,b)
            % Overload the .* (elementwise multiplication) operator
            %
            % One of the operators has to be numerical, the other has to be
            % an (array of) OLDirection(s)
            %
            %   X.*Y denotes element-by-element multiplication. X and Y
            %   must have compatible sizes. In the simplest cases, they can
            %   be the same size or one can be a scalar. Two inputs have
            %   compatible sizes if, for every dimension, the dimension
            %   sizes of the inputs are either the same or one of them is
            %   1.
            
            % Input validation
            if isa(a,'OLDirection')
                assert(isnumeric(b),'OneLightToolbox:OLDirection:times:InvalidInput','One input has to be numerical.');
                directions = a;
                scalars = b;
            elseif isnumeric(a)
                assert(isa(b,'OLDirection'),'OneLightToolbox:OLDirection:times:InvalidInput','One input has to be an OLDirection object.');
                directions = b;
                scalars = a;
            else
                error('OneLightToolbox:OLDirection:times:InvalidInput','One input has to be numerical.');
            end
            assert(iscolumn(scalars) || isrow(scalars),'OneLightToolbox:OLDirection:times:InvalidInput','Can currently only handle 1-dimensional vectors of scalars.');
            assert(iscolumn(directions) || isrow(directions),'OneLightToolbox:OLDirection:times:InvalidInput','Can currently only handle 1-dimensional array of OLDirections.');
            
            % Fencepost output
            out = OLDirection.empty();
            
            % Create scaled directions
            d = 1;
            for s = scalars
                out = [out OLDirection(directions(d).background,s*directions(d).differentialPositive,s*directions(d).differentialNegative,directions(d).calibration,directions(d).describe)];
                if ~isscalar(directions)
                    d = d+1;
                end
            end
        end
        
        function mtimes(a,b)
            error('Undefined operator ''*'' for input arguments of type ''OLDirection''. Are you trying to use ''.*''?');
        end
        
        function out = plus(a,b)
            % Overload the a+b (addition) operator
            
        end
        
        function out = minus(a,b)
            % Overload the a-b operator
            
        end
    end
    
end