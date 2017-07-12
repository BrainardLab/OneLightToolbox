function [protocolParams] = SessionLog(protocolParams,theStep,varargin)
% SessionLog -- Session Record Keeping
%
%  Description:
%     This function creates a session specific directory for each subject
%     within an experiment. This will also check for the existance of prior
%     session with the option to append or create new session. This
%     function will output a text file documenting general information
%     about the session **more info to be added here once specifics have
%     been decided on**
%  Output:
%     status - general output to be decided later.
%     params - updated param struct with session info.

%  06/23/17 mab,jar created file and green text.
%  06/26/17 mab,jar added switch


% set up vars
p = inputParser;
p.addParameter('StartEnd',[],@isstr);
p.addParameter('PrePost',[],@isstr);
p.parse(varargin{:});
p = p.Results;

%% Swtich
switch theStep
    case 'SessionInit'
        
        %% Check for prior sessions
        sessionDir = fullfile(getpref(protocolParams.approach,'SessionRecordsBasePath'),protocolParams.observerID,protocolParams.todayDate);
        dirStatus = dir(sessionDir);
        dirStatus=dirStatus(~ismember({dirStatus.name},{'.','..','.DS_Store'}));
        
        if exist(sessionDir) && ~isempty(dirStatus)
            dirString = ls(sessionDir);
            priorSessionNumber = str2double(regexp(dirString, '(?<=session_[^0-9]*)[0-9]*\.?[0-9]+', 'match'));
            currentSessionNumber = max(priorSessionNumber) + 1;
            protocolParams.sessionName =['session_' num2str(currentSessionNumber)];
            protocolParams.sessionLogOutDir = fullfile(getpref(protocolParams.approach,'SessionRecordsBasePath'),protocolParams.observerID,protocolParams.todayDate,protocolParams.sessionName);
            if ~exist(protocolParams.sessionLogOutDir)
                mkdir(protocolParams.sessionLogOutDir)
            end
        else
            currentSessionNumber = 1;
            protocolParams.sessionName =['session_' num2str(currentSessionNumber)];
            protocolParams.sessionLogOutDir = fullfile(getpref(protocolParams.approach,'SessionRecordsBasePath'),protocolParams.observerID,protocolParams.todayDate,protocolParams.sessionName);
            if ~exist(protocolParams.sessionLogOutDir)
                mkdir(protocolParams.sessionLogOutDir)
            end
        end
        
        %% Start Log File
        fileName = [protocolParams.observerID '_' protocolParams.sessionName '.log'];
        protocolParams.fullFileName = fullfile(protocolParams.sessionLogOutDir,fileName);
        
        fprintf('* <strong> Session Started</strong>: %s\n',protocolParams.sessionName)
        fileID = fopen(protocolParams.fullFileName,'w');
        fprintf(fileID,'Experiment Started: %s.\n',protocolParams.protocol);
        fprintf(fileID,'Observer ID: %s.\n',protocolParams.observerID);
        fprintf(fileID,'Session Number: %s.\n',num2str(currentSessionNumber));
        fprintf(fileID,'Session Date: %s\n',datestr(now,'mm-dd-yyyy'));
        fprintf(fileID,'Session Start Time: %s.\n',datestr(now,'HH:MM:SS'));
        fclose(fileID);
        
    case 'MakeDirectionCorrectedPrimaries'
        fileID = fopen(protocolParams.fullFileName,'a');
        switch p.StartEnd
            case 'start'
                fprintf(fileID,'\n%s Started @ %s.\n',theStep,datestr(now,'HH:MM:SS'));
            case 'end'
                fprintf(fileID,'%s Finished @ %s.\n',theStep,datestr(now,'HH:MM:SS'));
        end
        fclose(fileID);
    case 'MakeModulationStartsStops'
        fileID = fopen(protocolParams.fullFileName,'a');
        switch p.StartEnd
            case 'start'
                fprintf(fileID,'\n%s Started @ %s.\n',theStep,datestr(now,'HH:MM:SS'));
            case 'end'
                fprintf(fileID,'%s Finished @ %s.\n',theStep,datestr(now,'HH:MM:SS'));
        end
        fclose(fileID);
    case 'ValidateDirectionCorrectedPrimaries'
        fileID = fopen(protocolParams.fullFileName,'a');
        switch p.StartEnd
            case 'start'
                fprintf(fileID,'\n%s%s: Started @ %s.\n',p.PrePost,theStep,datestr(now,'HH:MM:SS'));
            case 'end'
                fprintf(fileID,'%s%s: Finished @ %s.\n',p.PrePost, theStep,datestr(now,'HH:MM:SS'));
        end
    case 'Demo'
        fileID = fopen(protocolParams.fullFileName,'a');
        switch p.StartEnd
            case 'start'
                fprintf(fileID,'\n%s: Started @ %s.\n',theStep,datestr(now,'HH:MM:SS'));
            case 'end'
                fprintf(fileID,'%s: Finished @ %s.\n',theStep,datestr(now,'HH:MM:SS'));
        end
    case 'Experiment'
        fileID = fopen(protocolParams.fullFileName,'a');
        switch p.StartEnd
            case 'start'
                fprintf(fileID,'\n%s%s: Started @ %s.\n',p.PrePost,theStep,datestr(now,'HH:MM:SS'));
            case 'end'
                fprintf(fileID,'%s%s: Finished @ %s.\n',p.PrePost, theStep,datestr(now,'HH:MM:SS'));
        end
    otherwise
        warning('%s unkown as a step.',theStep)
end

end