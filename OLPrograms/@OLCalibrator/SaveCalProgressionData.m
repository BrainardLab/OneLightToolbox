% SaveCalProgressionData(calProgressionTemporaryFileName, methodName, spdData, temperatureData)
%
% Save cal progression.
%
% 06/13/18  npc     Wrote it
function SaveCalProgressionData(calProgressionTemporaryFileName, methodName, spdData, temperatureData)

    % Load the previous calProgression
    load(calProgressionTemporaryFileName, 'calProgression');
        
    % assemble all in a struct
    newData = struct(...
        'methodName', methodName, ...
        'spdData', spdData, ...
        'tempertureData', temperatureData ...
    );
        
    % write that struct at the end
    calProgression{numel(calProgression)+1} = newData;
    % Overwrite file with new stuff
    save(calProgressionTemporaryFileName, 'calProgression');
    fprintf('\n<strong>Updated remporary calibration file: %s</strong>\n\n', calProgressionTemporaryFileName);
end
