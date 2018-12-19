classdef testOLGamutMargins < matlab.unittest.TestCase
%TESTOLCHECKPRIMARYVALUES Summary of this class goes here
%   Detailed explanation goes here

% History:
%    04/12/18  dhb  wrote OLCheckPrimaryGamut.
%    12/19/18  jv   extracted OLPrimaryGamut from
%                   OLCheckPrimaryGamut, and wrote tests

    methods (Test)
        function gamutMarginInDefaultGamut(testCase)
            gamutMargins = OLGamutMargins([0.1, .8],[0 1]);
            verifyEqual(testCase,gamutMargins,[0.1, .2],'AbsTol',1e-6);
        end
        function gamutMarginOutOfDefaultGamut(testCase)
            gamutMargins = OLGamutMargins([-0.1, 1.8],[0 1]);
            verifyEqual(testCase,gamutMargins,[-0.1, -.8],'AbsTol',1e-6);
        end
        
        function gamutMarginInDifferentialGamut(testCase)
            gamutMargins = OLGamutMargins([-0.1, .8],[-1 1]);
            verifyEqual(testCase,gamutMargins,[0.9, .2],'AbsTol',1e-6);
        end
        function gamutMarginOutOfDifferentialGamut(testCase)
            gamutMargins = OLGamutMargins([-1.1, 1.8],[-1 1]);
            verifyEqual(testCase,gamutMargins,[-0.1, -.8],'AbsTol',1e-6);
        end
        
        function gamutMarginInCustomGamut(testCase)
            gamutMargins = OLGamutMargins([-0.1, .8],[-.8 .8]);
            verifyEqual(testCase,gamutMargins,[0.7, 0],'AbsTol',1e-6);
        end
        function gamutMarginOutOfCustomGamut(testCase)
            gamutMargins = OLGamutMargins([-1.1, 1.8],[-.8 .8]);
            verifyEqual(testCase,gamutMargins,[-.3, -1],'AbsTol',1e-6);
        end
    end
end