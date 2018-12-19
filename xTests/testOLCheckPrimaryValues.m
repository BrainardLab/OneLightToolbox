classdef testOLCheckPrimaryValues < matlab.unittest.TestCase
%TESTOLCHECKPRIMARYVALUES Summary of this class goes here
%   Detailed explanation goes here

% History:
%    04/12/18  dhb  wrote OLCheckPrimaryGamut.
%    12/19/18  jv   extracted OLCheckPrimaryValues from
%                   OLCheckPrimaryGamut, and wrote tests

    methods (Test)
        % Test basic check
        function outOfDefaultGamut(testCase)
            verifyFalse(testCase,OLCheckPrimaryValues(1.1,[0 1]));
            verifyFalse(testCase,OLCheckPrimaryValues(-.1,[0 1]));
        end
        function inDefaultGamut(testCase)
            verifyTrue(testCase,OLCheckPrimaryValues(.8,[0 1]));
        end
        function inDifferentialGamut(testCase)
            verifyTrue(testCase,OLCheckPrimaryValues(-.4,[-1 1]));
            verifyFalse(testCase,OLCheckPrimaryValues(-.4,[0 1]));
        end
        function outOfDifferentialGamut(testCase)
            verifyFalse(testCase,OLCheckPrimaryValues(-1.4,[-1 1]));
        end
        function inCustomGamut(testCase)
            verifyTrue(testCase,OLCheckPrimaryValues(.6,[.2 .8]));
        end
        function outOfCustomGamut(testCase)
            verifyFalse(testCase,OLCheckPrimaryValues(.9,[.2 .8]));
        end
    end
end