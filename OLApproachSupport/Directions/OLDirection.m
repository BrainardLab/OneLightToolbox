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
    end
        background;
    
    %% Constructor
    methods
        function this = OLDirection(background, differentialPositive, differentialNegative, calibration, varargin)
            % Constructor for OLDirection objects
            %
            %
            %
            
            % Parse input
            parser = inputParser();
            parser.addRequired('differentialPositive',@isnumeric);
            parser.addRequired('differentialNegative',@isnumeric);
            parser.addRequired('calibration',@isstruct);
            parser.addOptional('describe',@isstruct);
            parser.addRequired('background',@(x) isa(x,'OLDirection') || isnumeric(x));
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
        function out = uplus(this)
            % Overload the +a operator
            out = this.differentialPositive;
        end
        function out = uminus(this)
            % Overload the -a operator
            out = this.differentialNegative;
        end
        
        function out = mtimes(a,b)
            % Overload the a*b operator
            
            % Figure out which argument is the OLDirection
            if isa(a,'OLDirection')
                scalars = b(:);
                this = a;
            else
                scalars = a(:);
                this = b;
            end
            
            % Do the scaling
            out = zeros(size(this.differentialPositive,1),numel(scalars));
            if any(scalars > 0)
                out(:,scalars > 0) = scalars(scalars > 0) .* +this;
            end
            if any(scalars < 0)
                out(:,scalars < 0) = scalars(scalars < 0) .* -this;
            end
        end
        

        function out = plus(a,b)
            % Overload the a+b operator
            
            % Figure out which argument is the OLDirection
            if isa(a,'OLDirection')
                additives = b;
                this = a;
            else
                additives = a;
                this = b;
            end
            
            out = +this + additives;
        end
        
        function out = minus(a,b)
            % Overload the a-b operator
            
            % Figure out which argument is the OLDirection
            if isa(a,'OLDirection')
                additives = b;
                this = a;
            else
                additives = a;
                this = b;
            end
            
            out = -this - additives;
        end
    end
    
end