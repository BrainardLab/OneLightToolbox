classdef testOLCheckPrimaryGamut < matlab.unittest.TestCase
    %TESTOLCHECKPRIMARYGAMUT Summary of this class goes here
    %   Detailed explanation goes here
    
    methods (Test)
        % Test basic error throwing
        function error(testCase)
            verifyError(testCase, @() OLCheckPrimaryGamut(1.1),'')
            verifyError(testCase, @() OLCheckPrimaryGamut(-.1),'')
        end
        function noError(testCase)
            verifyWarningFree(testCase, @() OLCheckPrimaryGamut(.8));
        end
        
        % Test tolerance
        function withinTolerance(testCase)
            verifyWarningFree(testCase, @() OLCheckPrimaryGamut(1+1e-8));
            verifyWarningFree(testCase, @() OLCheckPrimaryGamut(0-1e-8));
        end
        function outOfTolerance(testCase)
            verifyError(testCase, @() OLCheckPrimaryGamut(1+1e-5),'');
            verifyError(testCase, @() OLCheckPrimaryGamut(0-1e-5),'');
        end
        
        % Test return arguments
        function returnArgPrimary(testCase)
            primary = OLCheckPrimaryGamut([.3 .6]);
            verifyEqual(testCase,primary,[.3 .6]);
        end
        function returnArgInGamut(testCase)
            [~,inGamut] = OLCheckPrimaryGamut([0 1]);
            verifyTrue(testCase,inGamut);
        end
        function returnArgInGamutTolerance(testCase)
            [~,inGamut] = OLCheckPrimaryGamut([0-1e-8 1+1e-8]);
            verifyTrue(testCase,inGamut);
        end
        function gamutMarginTolerance(testCase)
            [~, ~, gamutMargin] = OLCheckPrimaryGamut([0-1e-8, 1+1e-8]);
            verifyEqual(testCase,gamutMargin,0,'AbsTol',1e-6);
        end
        function gamutMarginInGamut(testCase)
            [~, ~, gamutMargin] = OLCheckPrimaryGamut([0.1, .8]);
            verifyEqual(testCase,gamutMargin,-0.1,'AbsTol',1e-6);
        end
        
        % Test truncation
        function truncationWithinTolerance(testCase)
            verifyEqual(testCase,OLCheckPrimaryGamut(1+1e-8),1,'AbsTol',1e-6);
            verifyEqual(testCase,OLCheckPrimaryGamut(0-1e-8),0,'AbsTol',1e-6);
            verifyEqual(testCase,OLCheckPrimaryGamut([0-1e-8, 1+1e-8]),[0 1],'AbsTol',1e-6);
        end
        
        % Test differentialMode
        function differentialModeNoError(testCase)
            verifyWarningFree(testCase, @() OLCheckPrimaryGamut(-.8,'differentialMode',true));
        end
        function differentialModeError(testCase)
            verifyError(testCase, @() OLCheckPrimaryGamut(1.1,'differentialMode',true),'')
            verifyError(testCase, @() OLCheckPrimaryGamut(-1.1,'differentialMode',true),'')
        end
        function differentialModeWithinTolerance(testCase)
            verifyWarningFree(testCase, @() OLCheckPrimaryGamut(-1-1e-8,'differentialMode',true));
        end
        function differentialModeTruncation(testCase)
            verifyEqual(testCase,OLCheckPrimaryGamut([-1-1e-8, 1+1e-8],'differentialMode',true),[-1 1],'AbsTol',1e-8);
        end
        function differentialModeInGamut(testCase)
            [~,inGamut] = OLCheckPrimaryGamut([-1 1],'differentialMode', true);
            verifyTrue(testCase,inGamut);
        end
        function differentialModeGamutMargin(testCase)
            [~, ~, gamutMargin] = OLCheckPrimaryGamut([0.1, .8],'differentialMode',true);
            verifyEqual(testCase,gamutMargin,-0.2,'AbsTol',1e-6);
        end
        
        % Test argument primaryTolerance
        function adjustedTolerance(testCase)
            verifyError(testCase, @() OLCheckPrimaryGamut(0-1e-4),'');
            verifyError(testCase, @() OLCheckPrimaryGamut(1+1e-4),'');
            verifyWarningFree(testCase, @() OLCheckPrimaryGamut(1+1e-4,'primaryTolerance',1e-3));
            verifyWarningFree(testCase, @() OLCheckPrimaryGamut(0-1e-4,'primaryTolerance',1e-3));
        end
        function truncationWithinAdjustedTolerance(testCase)
            verifyEqual(testCase,OLCheckPrimaryGamut(1+1e-4,'primaryTolerance',1e-3),1);
            verifyEqual(testCase,OLCheckPrimaryGamut(0-1e-4,'primaryTolerance',1e-3),0);
            verifyEqual(testCase,OLCheckPrimaryGamut([0-1e-4, 1+1e-4],'primaryTolerance',1e-3),[0 1]);
        end
        function gamutMarginAdjustedTolerance(testCase)
            [~, ~, gamutMargin] = OLCheckPrimaryGamut([0-1e-4, 1+1e-4],'primaryTolerance',1e-3);
            verifyEqual(testCase,gamutMargin,0,'AbsTol',1e-6);
        end
        
        % Test argument primaryHeadroom
        function adjustedPrimaryHeadroom(testCase)
            verifyWarningFree(testCase, @() OLCheckPrimaryGamut(.02));
            verifyWarningFree(testCase, @() OLCheckPrimaryGamut(.98));
            verifyWarningFree(testCase, @() OLCheckPrimaryGamut([.02 .98]));
            verifyError(testCase, @() OLCheckPrimaryGamut(.02,'primaryHeadroom',.05),'');
            verifyError(testCase, @() OLCheckPrimaryGamut(.98,'primaryHeadroom',.05),'');
            verifyError(testCase, @() OLCheckPrimaryGamut([.6,.98],'primaryHeadroom',.05),'');
        end
        function gamutMarginAdjustedHeadroom(testCase)
            [~, ~, gamutMargin] = OLCheckPrimaryGamut([.6, .94],'primaryHeadroom',.05);
            verifyEqual(testCase,gamutMargin,-.01,'AbsTol',1e-6);
        end
        
        % Test argument checkPrimaryOutOfRange
        function noErrorNoCheckOutOfRange(testCase)
            verifyWarningFree(testCase, @() OLCheckPrimaryGamut(1.1,'checkPrimaryOutOfRange',false))
            verifyWarningFree(testCase, @() OLCheckPrimaryGamut(-.1,'checkPrimaryOutOfRange',false))
        end
        function truncateNoCheckOutOfRange(testCase)
            primary = OLCheckPrimaryGamut([-1 1.1],'checkPrimaryOutOfRange',false);
            verifyEqual(testCase,primary,[0 1])
        end
        function inGamutNoCheckOutOfRange(testCase)
            [~,inGamut] = OLCheckPrimaryGamut([0 1.1],'checkPrimaryOutOfRange',false);
            verifyFalse(testCase,inGamut);
        end
        function gamutMarginNoCheckOutOfRange(testCase)
            [~, ~, gamutMargin] = OLCheckPrimaryGamut([-.1, 1.2],'checkPrimaryOutOfRange',false);
            verifyEqual(testCase,gamutMargin,0.2,'AbsTol',1e-6);
        end
        
    end
end