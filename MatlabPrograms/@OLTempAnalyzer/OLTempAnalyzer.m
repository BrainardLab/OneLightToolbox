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
    end
    
    properties (Access = private)
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
        
        % Method to plot a temperature data set
        plotTemperatureData(obj, dataSetName);
    end
    
    methods (Access = private)
        importData(obj);
    end
end