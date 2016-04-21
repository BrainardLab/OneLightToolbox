function updateSummaryTable(obj)

    % Compute some luminances
    obj.summaryData.darkLumPre = obj.luminanceFromSPD(squeeze(obj.inputCal.raw.darkMeas(:,1)));
    obj.summaryData.darkLumPost  = obj.luminanceFromSPD(squeeze(obj.inputCal.raw.darkMeas(:,2)));
    obj.summaryData.halfOnLumPre = obj.luminanceFromSPD(squeeze(obj.inputCal.raw.halfOnMeas(:,1)));
    obj.summaryData.halfOnLumPost  = obj.luminanceFromSPD(squeeze(obj.inputCal.raw.halfOnMeas(:,2)));
    obj.summaryData.fullOnLumPre = obj.luminanceFromSPD(squeeze(obj.inputCal.raw.fullOn(:,1)));
    obj.summaryData.fullOnLumPost  = obj.luminanceFromSPD(squeeze(obj.inputCal.raw.fullOn(:,2)));
    
    obj.summaryTable.Data = [...
        obj.summaryData.darkLumPre   obj.summaryData.darkLumPost; ...
        obj.summaryData.halfOnLumPre obj.summaryData.halfOnLumPost; ...
        obj.summaryData.fullOnLumPre obj.summaryData.fullOnLumPost ...
        ];
    

    
end

