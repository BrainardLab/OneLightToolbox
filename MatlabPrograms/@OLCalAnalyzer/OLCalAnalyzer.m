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
    end
    
    
    % Public methods
    methods
        % Constructor
        function obj = OLCalAnalyzer(varargin)
            
            % Parse optional arguments
            parser = inputParser;
            parser.addParameter('refitGammaTablesUsingLinearInterpolation', false, @islogical);
            parser.addParameter('forceOLInitCal', false, @islogical);
            parser.addParameter('cal', []);
            %Execute the parser
            parser.parse(varargin{:});
            % Create a standard Matlab structure from the parser results.
            p = parser.Results;
            optionNames = fieldnames(p);
            for k = 1:numel(optionNames)
                obj.(optionNames{k}) = p.(optionNames{k});
            end
            
            obj.init();
            obj.importCalData(p.cal);
            obj.importResources();
            obj.generateSummaryData();
        end
        
        % Method to plot various SPDs
        plotSPD(obj,varargin);
        
        % Method to plot the gamma SPD measurements
        plotGammaSPD(obj, varargin);
        
        % Method to plot the gamma measurements
        plotGamma(obj, varargin);
        
        % Method to plot the various measured and predicted SPDs
        plotPredictions(obj, varargin);
        
        % Method to plot the collected (if any) temperature measurements
        plotTemperatureMeasurements(obj, varargin);
        
        % Method to export all the generated figs
        exportFigs(obj, varargin);
    end
    
    methods (Access = private)
        importCalData(obj, cal);
        luminance = luminanceFromSPD(obj, spd);
    end
    
end

