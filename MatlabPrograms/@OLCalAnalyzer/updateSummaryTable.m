function updateSummaryTable(obj)

    % Compute some luminances
    obj.summaryData.darkLumPre = obj.luminanceFromSPD(squeeze(obj.cal.raw.darkMeas(:,1)));
    obj.summaryData.darkLumPost  = obj.luminanceFromSPD(squeeze(obj.cal.raw.darkMeas(:,2)));
    obj.summaryData.halfOnLumPre = obj.luminanceFromSPD(squeeze(obj.cal.raw.halfOnMeas(:,1)));
    obj.summaryData.halfOnLumPost  = obj.luminanceFromSPD(squeeze(obj.cal.raw.halfOnMeas(:,2)));
    obj.summaryData.fullOnLumPre = obj.luminanceFromSPD(squeeze(obj.cal.raw.fullOn(:,1)));
    obj.summaryData.fullOnLumPost  = obj.luminanceFromSPD(squeeze(obj.cal.raw.fullOn(:,2)));
    
    obj.summaryTable.Data = [...
        obj.summaryData.darkLumPre   obj.summaryData.darkLumPost; ...
        obj.summaryData.halfOnLumPre obj.summaryData.halfOnLumPost; ...
        obj.summaryData.fullOnLumPre obj.summaryData.fullOnLumPost ...
        ];
    
    
    obj.summaryData.nGammaLevels = obj.cal.describe.nGammaLevels;
    obj.summaryData.numRowMirrors = obj.cal.describe.numRowMirrors;
    obj.summaryData.numColMirrors = obj.cal.describe.numColMirrors;
    
    obj.summaryData.primaryStartCols = obj.cal.describe.primaryStartCols;
    obj.summaryData.primaryStopCols = obj.cal.describe.primaryStopCols;

    s = obj.summaryData;
    s.primaryStartCols(1)
    s.primaryStopCols(end)
    pause
    
end

