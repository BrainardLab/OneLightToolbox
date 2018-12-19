classdef testOLTruncatePrimaryValues < matlab.unittest.TestCase
    %TESTOLTRUNCATEPRIMARYVALUES Summary of this class goes here
    %   Detailed explanation goes here
    
    methods (Test)
        function standardMin(testCase)
            % Truncate to gamut-max
            primaryValues = 2;
            gamut = [0 1];
            truncatedPrimaryValues = OLTruncatePrimaryValues(primaryValues, gamut);
            
            % Check
            verifyEqual(testCase, truncatedPrimaryValues, 1, 'AbsTol', 1e-5);
        end
        function standardMax(testCase)
            % Truncate to gamut-min
            primaryValues = -1;
            gamut = [0 1];
            truncatedPrimaryValues = OLTruncatePrimaryValues(primaryValues, gamut);
            
            % Check
            verifyEqual(testCase, truncatedPrimaryValues, 0, 'AbsTol', 1e-5);
        end
        function standardGamut(testCase)
            % Truncate to gamut = [0 1]
            primaryValues = [-.5 0 .4 .8 1 1.6];
            gamut = [0 1];
            truncatedPrimaryValues = OLTruncatePrimaryValues(primaryValues, gamut);
            
            % Check
            verifyEqual(testCase, truncatedPrimaryValues, [0 0 .4 .8 1 1], 'AbsTol', 1e-5);
        end
        function inGamut(testCase)
            % Truncate to gamut = [-1 1]
            primaryValues = [-1 1];
            gamut = [-1 1];
            truncatedPrimaryValues = OLTruncatePrimaryValues(primaryValues, gamut);
            
            % Check
            verifyEqual(testCase, truncatedPrimaryValues, primaryValues);
        end
        function unsortedGamut(testCase)
            % Gamut is auto-sorted
            primaryValues = [-1 -1];
            gamut = [0 -1];
            truncatedPrimaryValues = OLTruncatePrimaryValues(primaryValues, gamut);
            
            % Check
            verifyEqual(testCase, truncatedPrimaryValues, primaryValues);
        end
        function headroom(testCase)
            % Leave some 'headroom' on primaries:
            primaryValues = [0 .8 1];
            gamut = [0.005 .995];
            truncatedPrimaryValues = OLTruncatePrimaryValues(primaryValues, gamut);
            
            % Check
            verifyEqual(testCase, truncatedPrimaryValues, [.005 .8 .995], 'AbsTol', 1e-5);
        end
    end
end