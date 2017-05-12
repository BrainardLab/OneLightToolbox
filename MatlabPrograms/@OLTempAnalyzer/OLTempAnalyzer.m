classdef OLTempAnalyzer < handle
%OLTempAnalyzer Class for analyzing temperatures across OL cal/validation files
%
%Usage:

% 5/10/2017   npc   Wrote it
%

    properties
        
    end
    
    properties (SetAccess = private)
        rootDir;
        calibrationFile;
        testFile;
        
        calData;
        testData;
        combSPDPlotColors = [...
            0.2 0.4 1.0; ...
            0.4 0.8 0.8; ...
            0.7 0.4 0.4; ...
            1.0 0.3 0.1 ...
            ];
        combSPDNominalPeaks = [497 556 614 670];
        combSPDActualPeaks;
    end
    
    properties (Access = private)
        gui
    end
    
    properties (Constant)
        defaultRootDir = '/Users1/DropBoxLinks/DropboxAguirreBrainardLabs/MELA_materials';
        defaultCalibrationFile = 'OneLightCalData/OLBoxDRandomizedLongCableAEyePiece2_ND02.mat';
        defaultTestFile = 'cache/stimuli/Cache-MelanopsinDirectedSuperMaxMel_MELA_0085_041317.mat';
    end
    
    % Public methods
    methods
        % Constructor
        function obj = OLTempAnalyzer(varargin)
            
            % Parse optional arguments
            parser = inputParser;
            parser.addParameter('rootDir', OLTempAnalyzer.defaultRootDir, @ischar);
            parser.addParameter('calibrationFile', OLTempAnalyzer.defaultCalibrationFile, @ischar);
            parser.addParameter('testFile', []);
            %Execute the parser
            parser.parse(varargin{:});
            % Create a standard Matlab structure from the parser results.
            p = parser.Results;
            optionNames = fieldnames(p);
            for k = 1:numel(optionNames)
                obj.(optionNames{k}) = p.(optionNames{k});
            end
            
            obj.importData();
        end
        
    end
    
    methods (Access = private)
        importData(obj);
        [allTemperatureData, stabilitySpectra, dateStrings, fileName] = retrieveData(obj, dataFile, theTargetCalType);
        [combPeakTimeSeries, combSPDActualPeaks] = computeSpectralShiftTimeSeries(obj, stabilitySpectra, entryIndex);
        presentGUI(obj);
        plotTemperatureData(obj, dataSetName, entryIndex, plotAxes, dataSetNameEditBox);
        plotSpectralStabilityData(obj, dataSetName, entryIndex, plotAxes, dataSetNameEditBox);
    end
end