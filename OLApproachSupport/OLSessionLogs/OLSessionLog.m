function protocolParams = OLSessionLog(protocolParams,theStep,varargin)
% Session Record Keeping
%
% Usage:
%     [DHB NOTE: Provide an example of how this would be called here.]
%
% Description:
%     This function creates a session specific directory for each subject
%     within an experiment. This will also check for the existance of prior
%     session with the option to append or create new session. This
%     function will output a text file documenting general information
%     about the session **more info to be added here once specifics have
%     been decided on**
%
% Inputs:
%     [DHB NOTE: PLEASE SAY WHAT THE INPUTS ARE]
%
% Outputs:
%     [DHB NOTE: PLEASE SAY WHAT THE INPUTS ARE]
%
% Optional key/value pairs:
%     [DHB NOTE: PLEASE SAY WHAT THESE ARE]

% History:
%     06/23/17  mab,jar  Created file and green text.
%     06/26/17  mab,jar  Added switch.
%     08/21/17  dhb      Save currentSessionNumber as field in returned 
%                        protocol params on init.
%     02/02/18  jv       more flexible session naming, so that 
%                        protocolParams  can override defaults. Outsourced
%                        finding latest session number to '
%                        OLLatestSessionNumber.

%% Set up vars
p = inputParser;
p.addParameter('StartEnd',[],@isstr);
p.addParameter('PrePost',[],@isstr);
p.parse(varargin{:});
p = p.Results;

%% Swtich on what we are doing now.
switch theStep
    case 'OLSessionInit'
        
        % Create figure out session name, number.
        if ~isfield(protocolParams,'sessionName') || isempty(protocolParams.sessionName)
            
            % Find latest session, add 1.
            protocolParams.sessionName = sprintf('session_%d',OLLatestSessionNumber(protocolParams.protocol,protocolParams.observerID,protocolParams.todayDate)+1);
        end
        
        % Convert specified date to yyyy-mm-dd
        try
            protocolParams.todayDate = datestr(protocolParams.todayDate,'yyyy-mm-dd');
        catch
            warning('OneLightToolbox:OLApproachSupport:Cache:OLSessionLog:InvalidDate',...
                'Could not convert to ''yyyy-mm-dd'' datestring. Using provided string, which might not be a datestr...');
            protocolParams.todayDate = parser.Results.date;
        end
        
        % Create log dir.
        protocolParams.sessionLogOutDir = fullfile(getpref(protocolParams.protocol,'SessionRecordsBasePath'),protocolParams.observerID,protocolParams.todayDate,protocolParams.sessionName);
        if ~exist(protocolParams.sessionLogOutDir,'dir')
        	mkdir(protocolParams.sessionLogOutDir);
        end        
        
        % Start Log File
        fileName = [protocolParams.observerID '_' protocolParams.sessionName '.log'];
        protocolParams.fullFileName = fullfile(protocolParams.sessionLogOutDir,fileName);
        
        fprintf('* <strong> Session Started</strong>: %s\n',protocolParams.sessionName)
        fileID = fopen(protocolParams.fullFileName,'w');
        fprintf(fileID,'Experiment Started: %s.\n',protocolParams.protocol);
        fprintf(fileID,'Observer ID: %s.\n',protocolParams.observerID);
        if isfield(protocolParams,'currentSessionNumber')
            fprintf(fileID,'Session Number: %s.\n',num2str(protocolParams.currentSessionNumber));
        end
        fprintf(fileID,'Session Date: %s\n',datestr(now,'mm-dd-yyyy'));
        fprintf(fileID,'Session Start Time: %s.\n',datestr(now,'HH:MM:SS'));
        fclose(fileID);
        
    case 'OLMakeDirectionCorrectedPrimaries'
        fileID = fopen(protocolParams.fullFileName,'a');
        switch p.StartEnd
            case 'start'
                fprintf(fileID,'\n%s Started @ %s.\n',theStep,datestr(now,'HH:MM:SS'));
            case 'end'
                fprintf(fileID,'%s Finished @ %s.\n',theStep,datestr(now,'HH:MM:SS'));
        end
        fclose(fileID);
        
    case 'OLMakeModulationStartsStops'
        fileID = fopen(protocolParams.fullFileName,'a');
        switch p.StartEnd
            case 'start'
                fprintf(fileID,'\n%s Started @ %s.\n',theStep,datestr(now,'HH:MM:SS'));
            case 'end'
                fprintf(fileID,'%s Finished @ %s.\n',theStep,datestr(now,'HH:MM:SS'));
        end
        fclose(fileID);
        
    case 'OLValidateDirectionCorrectedPrimaries'
        fileID = fopen(protocolParams.fullFileName,'a');
        switch p.StartEnd
            case 'start'
                fprintf(fileID,'\n%s%s: Started @ %s.\n',p.PrePost,theStep,datestr(now,'HH:MM:SS'));
            case 'end'
                fprintf(fileID,'%s%s: Finished @ %s.\n',p.PrePost, theStep,datestr(now,'HH:MM:SS'));
        end
        fclose(fileID);
    
    case 'Demo'
        fileID = fopen(protocolParams.fullFileName,'a');
        switch p.StartEnd
            case 'start'
                fprintf(fileID,'\n%s: Started @ %s.\n',theStep,datestr(now,'HH:MM:SS'));
            case 'end'
                fprintf(fileID,'%s: Finished @ %s.\n',theStep,datestr(now,'HH:MM:SS'));
        end
        fclose(fileID);
        
    case 'Experiment'
        fileID = fopen(protocolParams.fullFileName,'a');
        switch p.StartEnd
            case 'start'
                fprintf(fileID,'\n%s%s: %s -- acquisition # %s started @ %s.\n',p.PrePost,theStep,protocolParams.protocolOutputName, num2str(protocolParams.acquisitionNumber), datestr(now,'HH:MM:SS'));
            case 'end'
                fprintf(fileID,'%s%s: %s -- acquisition # %s finished @ %s.\n',p.PrePost,theStep,protocolParams.protocolOutputName, num2str(protocolParams.acquisitionNumber), datestr(now,'HH:MM:SS'));
        end
        fclose(fileID);
        
    otherwise
        warning('%s unkown as a step.',theStep)
end

end