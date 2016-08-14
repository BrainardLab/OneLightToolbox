classdef OLCalAnalyzer < handle
%OLCalAnalyzer Class for analyzing an OLCal file
%
%Usage:
%   calAnalyzer = OLCalAnalyzer();
%   calAnalyzer.verbosity = 'normal';
%   calAnalyzer.plotRawSpd('name', 'darkMeas');

%4/21/2016   npc   Wrote it
%

    properties
        
    end
    
    properties (SetAccess = private)
        % the imported cal struct imported
        cal
        
        % the imported cal ID
        calID
        
        % the directory where figures will be exported
        figuresDir
        
        % Summary data
        summaryData
        
        % Initializer options
        refitGammaTablesUsingLinearInterpolation
        forceOLInitCal
    end
    
    properties (Access = private)
        % The CIE1931 CMFs (interpolated according the S-vector found in the inputCal
        T_xyz
        
        % The wavelength axis
        waveAxis
        
        % List with all the generated figure handles
        figsList
        
        summaryTableFigure
        summaryTable
    end
    
    
    % Public methods
    methods
        % Constructor
        function obj = OLCalAnalyzer(varargin)
            
            defaultRefitGammaTablesUsingLinearInterpolation = false;
            
            % Parse optional arguments
            parser = inputParser;
            parser.addParameter('refitGammaTablesUsingLinearInterpolation', defaultRefitGammaTablesUsingLinearInterpolation, @islogical);
            parser.addParameter('forceOLInitCal', false, @islogical);
            %Execute the parser
            parser.parse(varargin{:});
            % Create a standard Matlab structure from the parser results.
            p = parser.Results;
            optionNames = fieldnames(p);
            for k = 1:numel(optionNames)
                obj.(optionNames{k}) = p.(optionNames{k});
            end
            
            obj.init();
            
            obj.importCalData();
            obj.importResources();
            
            obj.initSummaryTable();
            obj.updateSummaryTable();
        end
        
        % Method to plot various SPDs
        plotSPD(obj,varargin);
        
        % Method to plot the gamma SPD measurements
        plotGammaSPD(obj, varargin);
        
        % Method to plot the gamma measurements
        plotGamma(obj, varargin);
        
        % Method to plot the various measured and predicted SPDs
        plotPredictions(obj, varargin);
        
        % Method to export all the generated figs
        exportFigs(obj, varargin);
    end
    
    methods (Access = private)
        importCalData(obj);
        luminance = luminanceFromSPD(obj, spd);
    end
    
end

