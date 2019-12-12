classdef testOLTruncateGamutTolerance < matlab.unittest.TestCase
    %TESTOLTRUNCATEGAMUTTOLERANCE Summary of this class goes here
    %   Detailed explanation goes here
    
    methods (Test)
    	function truncateToStandardGamutTop(testCase)
            % Truncate value smaller than tolerance; truncates to gamut
            primaryValues = 1+1e-6;
            primaryTolerance = 1e-5;
            gamut = [0 1];

            truncatedPrimaryValues = OLTruncateGamutTolerance(primaryValues,...
            gamut, primaryTolerance);

            verifyEqual(testCase, truncatedPrimaryValues, 1, 'AbsTol',1e-5);
        end
        function truncateToStandardGamutBottom(testCase)
            % Truncate value smaller than tolerance; truncates to gamut
            primaryValues = 0-1e-6;
            primaryTolerance = 1e-5;
            gamut = [0 1];

            truncatedPrimaryValues = OLTruncateGamutTolerance(primaryValues,...
            gamut, primaryTolerance);

            verifyEqual(testCase, truncatedPrimaryValues, 0, 'AbsTol', 1e-5);
        end
        function trunacteToDifferentialGamutBottom(testCase)
            % Truncate value smaller than tolerance; truncates to gamut
            primaryValues = -1-1e-6;
            primaryTolerance = 1e-5;
            gamut = [-1 1];

            truncatedPrimaryValues = OLTruncateGamutTolerance(primaryValues,...
            gamut, primaryTolerance);

            verifyEqual(testCase, truncatedPrimaryValues, -1, 'AbsTol', 1e-5);
        end
        function truncateAboveStandardGamutTop(testCase)
            % Truncate value larger than tolerance; truncates by tolerance
            primaryValues = 1+1e-4;
            primaryTolerance = 1e-5;
            gamut = [0 1];

            truncatedPrimaryValues = OLTruncateGamutTolerance(primaryValues,...
            gamut, primaryTolerance);

            verifyEqual(testCase, truncatedPrimaryValues, 1+(1e-4)-(1e-5), 'AbsTol', 1e-5);
        end
        function truncateBelowStandardGamutBottom(testCase)
            % Truncate value larger than tolerance; truncates by tolerance
            primaryValues = 0-1e-4;
            primaryTolerance = 1e-5;
            gamut = [0 1];

            truncatedPrimaryValues = OLTruncateGamutTolerance(primaryValues,...
            gamut, primaryTolerance);

            verifyEqual(testCase, truncatedPrimaryValues, 0-(1e-4)+(1e-5), 'AbsTol', 1e-5);
        end
        function truncateWithinGamut(testCase)
            % Primary value initially in gamut remains unaffected
            primaryValues = .5;
            primaryTolerance = 1e-5;
            gamut = [0 1];

            truncatedPrimaryValues = OLTruncateGamutTolerance(primaryValues,...
            gamut, primaryTolerance);

            verifyEqual(testCase, truncatedPrimaryValues, primaryValues, 'AbsTol', 1e-5)
        end
        function truncateAll(testCase)
            % Truncate both top and bottom, in and out of gamut:
            primaryValues = [.9 1.04 1.1 .1 -.04 -.1];
            primaryTolerance = .05;
            gamut = [0 1];

            truncatedPrimaryValues = OLTruncateGamutTolerance(primaryValues,...
            gamut, primaryTolerance);

            verifyEqual(testCase, truncatedPrimaryValues, [.9 1 1.05 .1 0 -.05], 'AbsTol', 1e-5);
        end
    end
end