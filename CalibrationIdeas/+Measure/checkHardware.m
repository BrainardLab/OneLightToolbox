function checkHardware(radiometerType)
    spectroRadiometerOBJ = [];
    ol = [];
    pause(1.0);
    
    try
        spectroRadiometerOBJ = Measure.initRadiometerObject(radiometerType);

        spectroRadiometerOBJ.shutDown();
        fprintf('PR670 is good!\n');
        pause(0.5);
        
        ol = OneLight;
        fprintf('One Light is good!\n');
        fprintf('Hit enter to continue  ');
        pause
        
    catch err  
        if (~isempty(spectroRadiometerOBJ))
            % Shutdown spectroradiometer
            spectroRadiometerOBJ.shutDown();
        end
        
        rethrow(err); 
    end
end