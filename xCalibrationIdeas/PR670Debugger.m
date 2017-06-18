function PR670Debugger

    verbosity = 1;
    radiometer = [];
    
    try
        radiometer = PR670dev(...
                'verbosity',        verbosity, ...    
                'devicePortString', [] ...       % empty -> automatic port detection)
            );
        
        fprintf('Hit enter to shutdown radiometer object\n');
        pause
        radiometer.shutDown();
       
        
    catch err
        if (~isempty(radiometer))
            radiometer.shutDown();
        end
        
        rethrow(err);
    end
end


