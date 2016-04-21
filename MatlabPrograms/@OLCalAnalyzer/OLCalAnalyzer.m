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
        verbosity;
    end
    
    properties (SetAccess = private)
        % the imported cal struct imported
        inputCal
        
        % the imported cal ID
        inputCalID
        
        % the directory where figures will be exported
        figuresDir
        
        % Smmary data
        summaryData
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
        function obj = OLCalAnalyzer()
            obj.importCalData();
            obj.init();
            obj.initSummaryTable();
            obj.updateSummaryTable();
        end
        
        % Method to plot raw SPDs
        plotSPD(obj,varargin);
        
        % Method to export all the generated figs
        exportFigs(obj, varargin);
    end
    
    methods (Access = private)
        importCalData(obj);
        luminance = luminanceFromSPD(obj, spd);
    end
    
end

