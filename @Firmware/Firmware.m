classdef Firmware < FirmwareBase

    methods (Access=public)
        
        function obj = Firmware()
        
            fwFolder = fileparts(fileparts(mfilename('fullpath')));
            tablesFolder = [fwFolder filesep '+Pipe' filesep 'tables'];
            
            obj@FirmwareBase(tablesFolder, @Pipe.bootCalcs);
            
        end
      
    end
    
end

