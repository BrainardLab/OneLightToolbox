classdef OLDirection < handle
% Class defining a direction for use with OneLight devices
%
% Description:
%    A direction of modulation, is a direction (vector) in primary space
%    that corresponds to some desired direction in spectral or receptor
%    space. An OLDirection object defines a direction as three vector
%    componenents in primary space: the background, the positive
%    differential vector, and the negative differential vector. The
%    background defines the starting point for the direction vector, and is
%    an inherent part of the specification of a direction. The background
%    is either the origin of primary space (i.e., a vector
%    zeros(nPrimaries)), or a (reference to a) direction itself. The
%    positive and negative component of the direction are defined
%    separately, because they can be asymmetric. Since these specifications
%    are device/calibration dependent, the OLDirection object also stores a
%    OneLight calibration struct.
%   

% History:
%    03/02/18  jv  wrote it.

    properties
        background;
        differentialPositive;
        differentialNegative;
        calibration;
        describe;
    end
    
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
            parser.addOptional('describe',@isstruct);
            parser.StructExpand = false;
            parser.parse(background, differentialPositive, differentialNegative, calibration, varargin{:});
            
            % Assign
            this.background = background;
            this.differentialPositive = differentialPositive;
            this.differentialNegative = differentialNegative;
            this.calibration = calibration;
            this.describe = parser.Results.describe;
        end
               
        function out = times(a,b)
            % Overload the .* operator
            
            % Figure out which argument is the OLDirection
            if isa(a,'OLDirection')
                scalars = b;
                this = a;
            else
                scalars = a;
                this = b;
            end
            
            % Scale the relevant differential vector
            if scalars == 0
               	out = 0 .* this.background;
            elseif scalars > 0
                out = 1 .* this.background + scalars .* this.differentialPositive;
            elseif scalars < 0
                out = 1 .* this.background + scalars .* this.differentialNegative;
            end
        end
        
        function out = mtimes(a,b)
            % Overload the * operator
            out = times(a,b);
        end
    end
    
end