classdef OLComputeMethods
    %OLComputeMethods  Define the available symbolic methods for the OLCache object.
    %
    % These are used just symbolic names that we can employ in a switch statement
    % in OLCache.compute.  But they are actually objects.
    %
    % You can list the available methods using
    %   availComputeMethods = enumeration('OLComputeMethods');
    %
    % And you can choose one using (e.g.)
    %   computeMethod = OLComputeMethods.Standard;
    %
    % Notes:
    %   This seems like an incredibly convoluted way to pass a string to a
    %   function, and perhaps we should get rid of it and pass key/value
    %   pairs to OLCache.compute.  But for now we are keeping it around
    %   because, well, life is short.
    %
    % See also: OLCache.
    
    % 6/6/17  dhb, mab  Added comments, what heros!
	enumeration
		Standard
        ReceptorIsolate
	end
end
